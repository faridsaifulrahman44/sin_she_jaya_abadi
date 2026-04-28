-- Migration: Tambahkan guard oversell pada fn_obat_keluar_insert_atomic & update
--
-- Purpose:
--   Mencegah transaksi obat keluar yang qty-nya melebihi stok tersedia.
--   Guard dilakukan SEBELUM insert/update obat_keluar_item, sehingga
--   transaksi gagal atomik dan tidak meninggalkan stok korup.
--
-- Behavior:
--   INSERT:  Cek tiap item baru terhadap stok_saat_ini terkini.
--   UPDATE:  Cek tiap item terhadap (stok_saat_ini + old_qty transaksi ini).
--            Ini mengizinkan EDIT naik/turun selama tidak ada oversell bersih.
--
-- Jika environment sudah menjalankan schema.sql versi terbaru:
--   Jalankan ulang CREATE OR REPLACE FUNCTION (idempotent).
-- Jika environment lama (belum ada function ini):
--   Function baru akan tercipta dari baseline schema.sql.

-- ============================================================
-- A. Guard oversell di fn_obat_keluar_insert_atomic
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_insert_atomic(
  p_tanggal_terjual date,
  p_no_etalase text,
  p_keterangan text,
  p_id_admin bigint,
  p_items jsonb
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_terjual bigint;
  v_item_count integer;
  v_affected_ids bigint[];
BEGIN
  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'items transaksi keluar wajib minimal 1 baris';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS i(
      id_obat bigint,
      jumlah integer,
      harga_satuan numeric
    )
    WHERE COALESCE(i.id_obat, 0) <= 0
       OR COALESCE(i.jumlah, 0) <= 0
       OR i.harga_satuan IS NULL
       OR i.harga_satuan < 0
  ) THEN
    RAISE EXCEPTION 'data item transaksi keluar tidak valid';
  END IF;

  -- Guard oversell: cek tiap item baru terhadap stok_saat_ini terkini.
  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS i(id_obat bigint, jumlah integer)
    JOIN public.obat o ON o.id_obat = i.id_obat
    WHERE i.jumlah > o.stok_saat_ini
  ) THEN
    RAISE EXCEPTION USING
      MESSAGE = 'oversell: qty melebihi stok tersedia',
      HINT = 'CHECK_STOCK_FAILED';
  END IF;

  SELECT COUNT(*)
  INTO v_item_count
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  IF COALESCE(v_item_count, 0) <= 0 THEN
    RAISE EXCEPTION 'items transaksi keluar wajib minimal 1 baris';
  END IF;

  INSERT INTO public.obat_keluar (
    tanggal_terjual,
    no_etalase,
    keterangan,
    id_admin
  )
  VALUES (
    p_tanggal_terjual,
    NULLIF(BTRIM(COALESCE(p_no_etalase, '')), ''),
    NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    p_id_admin
  )
  RETURNING id_terjual INTO v_id_terjual;

  INSERT INTO public.obat_keluar_item (
    id_terjual,
    id_obat,
    jumlah,
    harga_satuan,
    is_legacy
  )
  SELECT
    v_id_terjual,
    i.id_obat,
    i.jumlah,
    i.harga_satuan,
    false
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  PERFORM public.fn_obat_keluar_refresh_totals(v_id_terjual);

  SELECT array_agg(DISTINCT i.id_obat)
  INTO v_affected_ids
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);

  RETURN v_id_terjual;
END;
$$;

-- ============================================================
-- B. Guard oversell di fn_obat_keluar_update_atomic
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_update_atomic(
  p_id_terjual bigint,
  p_tanggal_terjual date,
  p_no_etalase text,
  p_keterangan text,
  p_id_admin bigint,
  p_items jsonb
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_ids bigint[];
  v_new_ids bigint[];
  v_affected_ids bigint[];
BEGIN
  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'items transaksi keluar wajib minimal 1 baris';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS i(
      id_obat bigint,
      jumlah integer,
      harga_satuan numeric
    )
    WHERE COALESCE(i.id_obat, 0) <= 0
       OR COALESCE(i.jumlah, 0) <= 0
       OR i.harga_satuan IS NULL
       OR i.harga_satuan < 0
  ) THEN
    RAISE EXCEPTION 'data item transaksi keluar tidak valid';
  END IF;

  PERFORM 1
  FROM public.obat_keluar
  WHERE id_terjual = p_id_terjual
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi tidak ditemukan: %', p_id_terjual;
  END IF;

  -- Guard oversell untuk UPDATE.
  -- available = stok_saat_ini + old_qty_for_same_obat
  -- karena old_qty sudah termasuk dalam stok_saat_ini saat ini.
  IF EXISTS (
    WITH old_qty_per_obat AS (
      SELECT oki.id_obat, SUM(oki.jumlah)::integer AS old_qty
      FROM public.obat_keluar_item oki
      WHERE oki.id_terjual = p_id_terjual
        AND oki.is_legacy = false
        AND oki.id_obat IS NOT NULL
      GROUP BY oki.id_obat
    )
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS ni(id_obat bigint, jumlah integer)
    JOIN public.obat o ON o.id_obat = ni.id_obat
    LEFT JOIN old_qty_per_obat oo ON oo.id_obat = ni.id_obat
    WHERE ni.jumlah > (o.stok_saat_ini + COALESCE(oo.old_qty, 0))
  ) THEN
    RAISE EXCEPTION USING
      MESSAGE = 'oversell: qty melebihi stok tersedia saat update',
      HINT = 'CHECK_STOCK_FAILED';
  END IF;

  SELECT array_agg(DISTINCT oki.id_obat)
  INTO v_old_ids
  FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = p_id_terjual
    AND oki.is_legacy = false
    AND oki.id_obat IS NOT NULL;

  UPDATE public.obat_keluar
  SET
    tanggal_terjual = p_tanggal_terjual,
    no_etalase = NULLIF(BTRIM(COALESCE(p_no_etalase, '')), ''),
    keterangan = NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    id_admin = p_id_admin
  WHERE id_terjual = p_id_terjual;

  DELETE FROM public.obat_keluar_item
  WHERE id_terjual = p_id_terjual;

  INSERT INTO public.obat_keluar_item (
    id_terjual,
    id_obat,
    jumlah,
    harga_satuan,
    is_legacy
  )
  SELECT
    p_id_terjual,
    i.id_obat,
    i.jumlah,
    i.harga_satuan,
    false
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  PERFORM public.fn_obat_keluar_refresh_totals(p_id_terjual);

  SELECT array_agg(DISTINCT i.id_obat)
  INTO v_new_ids
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  SELECT array_agg(DISTINCT x.id_obat)
  INTO v_affected_ids
  FROM (
    SELECT unnest(COALESCE(v_old_ids, ARRAY[]::bigint[])) AS id_obat
    UNION ALL
    SELECT unnest(COALESCE(v_new_ids, ARRAY[]::bigint[])) AS id_obat
  ) x
  WHERE x.id_obat IS NOT NULL;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;
