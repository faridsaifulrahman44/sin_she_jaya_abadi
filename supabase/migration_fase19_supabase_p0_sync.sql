-- ============================================================
-- FASE 19 / P0: Supabase live sync for Flutter contract
-- Project ref: cdfklvbzbffqvhgifesk
--
-- Safe for existing data:
-- - No DROP table/data.
-- - Uses ADD COLUMN IF NOT EXISTS.
-- - Replaces RPC bodies only to match the final table contract.
--
-- Compatibility note:
-- Flutter still calls RPC names with "stock_opname".
-- The final data table is public.sinkronisasi_stok.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sinkronisasi_stok (
  id_opname bigserial PRIMARY KEY,
  id_obat bigint NOT NULL REFERENCES public.obat(id_obat) ON DELETE RESTRICT,
  tanggal_opname date NOT NULL,
  stok_sistem integer NOT NULL DEFAULT 0,
  stok_fisik integer NOT NULL DEFAULT 0,
  selisih integer NOT NULL DEFAULT 0,
  alasan_penyesuaian text,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sinkronisasi_stok_tanggal
  ON public.sinkronisasi_stok(tanggal_opname DESC);
CREATE INDEX IF NOT EXISTS idx_sinkronisasi_stok_id_obat
  ON public.sinkronisasi_stok(id_obat);

ALTER TABLE public.transaksi_item
  ADD COLUMN IF NOT EXISTS satuan_terjual varchar(30);

COMMENT ON COLUMN public.transaksi_item.satuan_terjual IS
  'Satuan aktual yang dipilih saat transaksi. Null untuk data legacy.';

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS foto_key text,
  ADD COLUMN IF NOT EXISTS foto_updated_at timestamptz;

COMMENT ON COLUMN public.obat.foto_key IS
  'Storage object key untuk bucket obat-images. Null untuk data legacy.';

COMMENT ON COLUMN public.obat.foto_updated_at IS
  'Waktu terakhir metadata foto obat diperbarui.';

CREATE OR REPLACE FUNCTION public.fn_recalculate_obat_stok_single(
  p_id_obat bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_stok integer;
  mut record;
BEGIN
  SELECT o.stok_awal
  INTO v_stok
  FROM public.obat o
  WHERE o.id_obat = p_id_obat
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF v_stok < 0 THEN
    v_stok := 0;
  END IF;

  FOR mut IN
    WITH mutations AS (
      SELECT
        om.tanggal_masuk AS mutation_date,
        1 AS priority,
        om.created_at AS recorded_at,
        om.id_masuk AS sequence_id,
        om.jumlah_masuk AS delta,
        false AS is_reset
      FROM public.obat_masuk om
      WHERE om.id_obat = p_id_obat

      UNION ALL

      SELECT
        ok.tanggal_terjual AS mutation_date,
        2 AS priority,
        COALESCE(oki.created_at, ok.created_at) AS recorded_at,
        oki.id_item AS sequence_id,
        -oki.jumlah AS delta,
        false AS is_reset
      FROM public.obat_keluar_item oki
      JOIN public.obat_keluar ok
        ON ok.id_terjual = oki.id_terjual
      WHERE oki.id_obat = p_id_obat
        AND oki.is_legacy = false

      UNION ALL

      SELECT
        so.tanggal_opname AS mutation_date,
        3 AS priority,
        so.created_at AS recorded_at,
        so.id_opname AS sequence_id,
        so.stok_fisik AS delta,
        true AS is_reset
      FROM public.sinkronisasi_stok so
      WHERE so.id_obat = p_id_obat
    )
    SELECT
      mutations.delta,
      mutations.is_reset
    FROM mutations
    ORDER BY
      mutations.mutation_date ASC,
      mutations.priority ASC,
      mutations.recorded_at ASC NULLS FIRST,
      mutations.sequence_id ASC
  LOOP
    IF mut.is_reset THEN
      v_stok := GREATEST(mut.delta, 0);
    ELSE
      v_stok := GREATEST(v_stok + mut.delta, 0);
    END IF;
  END LOOP;

  UPDATE public.obat
  SET stok_saat_ini = v_stok
  WHERE id_obat = p_id_obat;
END;
$$;

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
  v_transaksi       public.transaksi%ROWTYPE;
  v_item            jsonb;
  v_id_obat         int;
  v_jumlah          int;
  v_harga           numeric(12, 2);
  v_subtotal        numeric(12, 2);
  v_satuan_terjual  varchar(30);
BEGIN
  INSERT INTO public.transaksi (
    tanggal, jenis_transaksi, total, metode_bayar,
    id_pasien, keterangan, durasi_harian, id_admin
  )
  VALUES (
    p_tanggal, p_jenis_transaksi, p_total, p_metode_bayar,
    p_id_pasien, p_keterangan, p_durasi_harian, p_id_admin
  )
  RETURNING * INTO v_transaksi;

  IF p_jenis_transaksi = 'obat_ready_stock'
     AND jsonb_typeof(p_items) = 'array'
     AND jsonb_array_length(p_items) > 0 THEN

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
      v_id_obat        := (v_item->>'id_obat')::int;
      v_jumlah         := (v_item->>'jumlah')::int;
      v_harga          := (v_item->>'harga_satuan')::numeric(12, 2);
      v_subtotal       := (v_item->>'subtotal')::numeric(12, 2);
      v_satuan_terjual := NULLIF(BTRIM(v_item->>'satuan_terjual'), '');

      INSERT INTO public.transaksi_item (
        id_transaksi,
        id_obat,
        jumlah,
        harga_satuan,
        subtotal,
        satuan_terjual,
        id_admin
      )
      VALUES (
        v_transaksi.id_transaksi,
        v_id_obat,
        v_jumlah,
        v_harga,
        v_subtotal,
        v_satuan_terjual,
        p_id_admin
      );

      UPDATE public.obat
      SET stok_saat_ini = GREATEST(0, stok_saat_ini - v_jumlah)
      WHERE id_obat = v_id_obat;
    END LOOP;
  END IF;

  RETURN NEXT v_transaksi;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_insert_atomic(
  p_id_obat bigint,
  p_tanggal_opname date,
  p_stok_sistem integer,
  p_stok_fisik integer,
  p_alasan_penyesuaian text,
  p_id_admin bigint
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_opname bigint;
BEGIN
  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  IF COALESCE(p_stok_sistem, -1) < 0 THEN
    RAISE EXCEPTION 'stok_sistem tidak valid';
  END IF;

  IF COALESCE(p_stok_fisik, -1) < 0 THEN
    RAISE EXCEPTION 'stok_fisik tidak valid';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  INSERT INTO public.sinkronisasi_stok (
    id_obat,
    tanggal_opname,
    stok_sistem,
    stok_fisik,
    selisih,
    alasan_penyesuaian,
    id_admin
  )
  VALUES (
    p_id_obat,
    p_tanggal_opname,
    p_stok_sistem,
    p_stok_fisik,
    p_stok_fisik - p_stok_sistem,
    NULLIF(BTRIM(COALESCE(p_alasan_penyesuaian, '')), ''),
    p_id_admin
  )
  RETURNING id_opname INTO v_id_opname;

  PERFORM public.fn_recalculate_obat_stok_single(p_id_obat);

  RETURN v_id_opname;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_update_atomic(
  p_id_opname bigint,
  p_id_obat bigint,
  p_tanggal_opname date,
  p_stok_sistem integer,
  p_stok_fisik integer,
  p_alasan_penyesuaian text,
  p_id_admin bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_id_obat bigint;
  v_affected_ids bigint[];
BEGIN
  IF COALESCE(p_id_opname, 0) <= 0 THEN
    RAISE EXCEPTION 'id_opname tidak valid';
  END IF;

  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  IF COALESCE(p_stok_sistem, -1) < 0 THEN
    RAISE EXCEPTION 'stok_sistem tidak valid';
  END IF;

  IF COALESCE(p_stok_fisik, -1) < 0 THEN
    RAISE EXCEPTION 'stok_fisik tidak valid';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  SELECT so.id_obat
  INTO v_old_id_obat
  FROM public.sinkronisasi_stok so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'sinkronisasi stok tidak ditemukan: %', p_id_opname;
  END IF;

  UPDATE public.sinkronisasi_stok
  SET
    id_obat = p_id_obat,
    tanggal_opname = p_tanggal_opname,
    stok_sistem = p_stok_sistem,
    stok_fisik = p_stok_fisik,
    selisih = p_stok_fisik - p_stok_sistem,
    alasan_penyesuaian = NULLIF(BTRIM(COALESCE(p_alasan_penyesuaian, '')), ''),
    id_admin = p_id_admin
  WHERE id_opname = p_id_opname;

  SELECT array_agg(DISTINCT x.id_obat)
  INTO v_affected_ids
  FROM (
    SELECT v_old_id_obat AS id_obat
    UNION ALL
    SELECT p_id_obat AS id_obat
  ) x
  WHERE x.id_obat IS NOT NULL;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_delete_atomic(
  p_id_opname bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_obat bigint;
BEGIN
  IF COALESCE(p_id_opname, 0) <= 0 THEN
    RAISE EXCEPTION 'id_opname tidak valid';
  END IF;

  SELECT so.id_obat
  INTO v_id_obat
  FROM public.sinkronisasi_stok so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'sinkronisasi stok tidak ditemukan: %', p_id_opname;
  END IF;

  DELETE FROM public.sinkronisasi_stok
  WHERE id_opname = p_id_opname;

  PERFORM public.fn_recalculate_obat_stok_single(v_id_obat);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(
  p_tanggal_opname date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  SELECT array_agg(DISTINCT so.id_obat)
  INTO v_affected_ids
  FROM public.sinkronisasi_stok so
  WHERE so.tanggal_opname = p_tanggal_opname
    AND so.id_obat IS NOT NULL;

  DELETE FROM public.sinkronisasi_stok
  WHERE tanggal_opname = p_tanggal_opname;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_recalculate_obat_stok_single(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_transaksi_insert(date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_insert_atomic(bigint, date, integer, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_update_atomic(bigint, bigint, date, integer, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(date) TO authenticated;
