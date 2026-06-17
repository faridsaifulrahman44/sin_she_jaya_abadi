-- ============================================================
-- FASE 14: Transaksi Oversell Guard
-- Project: Flutter Klinik
-- Purpose:
--   1) Tambahkan guard oversell ke fn_transaksi_insert —
--      cek stok tersedia SEBELUM insert item & kurangi stok.
--   2) Tambahkan guard oversell ke fn_obat_kurangi_stok —
--      agar tidak membiarkan oversell dalam fallback path manapun.
--   3) Beri hak EXECUTE pada fn_transaksi_insert & fn_obat_kurangi_stok
--      untuk user authenticated.
-- ============================================================

-- ============================================================
-- A. fn_transaksi_insert dengan oversell guard
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_transaksi_insert(
  p_tanggal            date,
  p_jenis_transaksi    varchar(30),
  p_total              numeric(12, 2),
  p_metode_bayar       varchar(20),
  p_id_pasien          bigint,
  p_keterangan         text,
  p_durasi_harian      int,
  p_id_admin           bigint,
  p_items              jsonb DEFAULT '[]'::jsonb
)
RETURNS SETOF public.transaksi
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_transaksi  public.transaksi%ROWTYPE;
  v_item       jsonb;
  v_id_obat    int;
  v_jumlah     int;
  v_harga      numeric(12, 2);
  v_subtotal   numeric(12, 2);
  v_satuan_terjual varchar(30);
BEGIN
  -- Insert header transaksi
  INSERT INTO public.transaksi (
    tanggal, jenis_transaksi, total, metode_bayar,
    id_pasien, keterangan, durasi_harian, id_admin
  )
  VALUES (
    p_tanggal, p_jenis_transaksi, p_total, p_metode_bayar,
    p_id_pasien, p_keterangan, p_durasi_harian, p_id_admin
  )
  RETURNING * INTO v_transaksi;

  -- Jika ready stock dan ada items, proses item & kurangi stok
  IF p_jenis_transaksi = 'obat_ready_stock'
     AND jsonb_typeof(p_items) = 'array'
     AND jsonb_array_length(p_items) > 0 THEN

    -- Guard oversell: cek semua item terhadap stok terkini SEBELUM
    -- memproses satu pun. Jika ada yang oversell, seluruh transaksi gagal.
    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_items) AS i(id_obat bigint, jumlah integer)
      JOIN public.obat o ON o.id_obat = i.id_obat
      WHERE i.jumlah > o.stok_saat_ini
    ) THEN
      RAISE EXCEPTION USING
        MESSAGE = 'oversell: jumlah melebihi stok tersedia',
        HINT    = 'CHECK_STOCK_FAILED';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_id_obat  := (v_item->>'id_obat')::int;
      v_jumlah   := (v_item->>'jumlah')::int;
      v_harga    := (v_item->>'harga_satuan')::numeric(12, 2);
      v_subtotal := (v_item->>'subtotal')::numeric(12, 2);
      v_satuan_terjual := NULLIF(BTRIM(v_item->>'satuan_terjual'), '');

      -- Insert item — id_transaksi sudah terikat dengan header di atas
      INSERT INTO public.transaksi_item (
        id_transaksi, id_obat, jumlah, harga_satuan, subtotal,
        satuan_terjual, id_admin
      )
      VALUES (
        v_transaksi.id_transaksi,
        v_id_obat, v_jumlah, v_harga, v_subtotal,
        v_satuan_terjual, p_id_admin
      );

      -- Kurangi stok
      UPDATE public.obat
      SET stok_saat_ini = GREATEST(0, stok_saat_ini - v_jumlah)
      WHERE id_obat = v_id_obat;
    END LOOP;
  END IF;

  RETURN NEXT v_transaksi;
END;
$$;

-- ============================================================
-- B. fn_obat_kurangi_stok dengan oversell guard
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_obat_kurangi_stok(
  p_id_obat  int,
  p_jumlah   int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stok_sekarang integer;
BEGIN
  -- Guard oversell: cek stok tersedia sebelum mengurangi
  SELECT stok_saat_ini INTO v_stok_sekarang
  FROM public.obat
  WHERE id_obat = p_id_obat
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Obat dengan ID % tidak ditemukan', p_id_obat;
  END IF;

  IF p_jumlah > v_stok_sekarang THEN
    RAISE EXCEPTION USING
      MESSAGE = 'oversell: jumlah melebihi stok tersedia',
      HINT    = 'CHECK_STOCK_FAILED';
  END IF;

  UPDATE public.obat
  SET stok_saat_ini = GREATEST(0, stok_saat_ini - p_jumlah)
  WHERE id_obat = p_id_obat;
END;
$$;

-- ============================================================
-- C. Hak akses untuk authenticated
-- ============================================================
GRANT EXECUTE ON FUNCTION public.fn_transaksi_insert(
  date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.fn_obat_kurangi_stok(int, int)
TO authenticated;
