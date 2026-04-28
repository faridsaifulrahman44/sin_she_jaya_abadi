-- Migration FASE 2: transaksi obat keluar atomik via SQL RPC
-- Cakupan atomik:
-- 1) insert/update/delete header obat_keluar
-- 2) insert/update/delete obat_keluar_item
-- 3) refresh total header (jumlah_transaksi, total_nominal)
-- 4) recalculate stok obat terkait

-- Helper: refresh total header dari item non-legacy.
CREATE OR REPLACE FUNCTION public.fn_obat_keluar_refresh_totals(
  p_id_terjual bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.obat_keluar ok
  SET
    jumlah_transaksi = agg.total_items,
    total_nominal = agg.total_nominal
  FROM (
    SELECT
      COUNT(*)::integer AS total_items,
      COALESCE(SUM(oki.subtotal), 0)::numeric(14, 2) AS total_nominal
    FROM public.obat_keluar_item oki
    WHERE oki.id_terjual = p_id_terjual
      AND oki.is_legacy = false
  ) AS agg
  WHERE ok.id_terjual = p_id_terjual;
END;
$$;

-- Helper: recalculate stok untuk satu obat dari histori valid.
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
      FROM public.stock_opname so
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

-- Helper: recalculate stok untuk banyak obat.
CREATE OR REPLACE FUNCTION public.fn_recalculate_obat_stok_bulk(
  p_ids bigint[]
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_id bigint;
BEGIN
  IF p_ids IS NULL OR COALESCE(array_length(p_ids, 1), 0) = 0 THEN
    RETURN;
  END IF;

  FOR v_id IN
    SELECT DISTINCT id_obat
    FROM unnest(p_ids) AS id_obat
    ORDER BY id_obat
  LOOP
    IF v_id IS NOT NULL AND v_id > 0 THEN
      PERFORM public.fn_recalculate_obat_stok_single(v_id);
    END IF;
  END LOOP;
END;
$$;

-- RPC: insert transaksi keluar atomik.
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

-- RPC: update transaksi keluar atomik.
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

  -- Jika langkah setelah ini gagal, seluruh update (termasuk delete item lama)
  -- ikut rollback karena masih dalam satu transaksi function.
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

-- RPC: delete satu transaksi keluar atomik.
CREATE OR REPLACE FUNCTION public.fn_obat_keluar_delete_atomic(
  p_id_terjual bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  PERFORM 1
  FROM public.obat_keluar
  WHERE id_terjual = p_id_terjual
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi tidak ditemukan: %', p_id_terjual;
  END IF;

  SELECT array_agg(DISTINCT oki.id_obat)
  INTO v_affected_ids
  FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = p_id_terjual
    AND oki.is_legacy = false
    AND oki.id_obat IS NOT NULL;

  DELETE FROM public.obat_keluar
  WHERE id_terjual = p_id_terjual;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

-- RPC: delete transaksi keluar by tanggal atomik.
CREATE OR REPLACE FUNCTION public.fn_obat_keluar_delete_by_tanggal_atomic(
  p_tanggal_terjual date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  SELECT array_agg(DISTINCT oki.id_obat)
  INTO v_affected_ids
  FROM public.obat_keluar ok
  JOIN public.obat_keluar_item oki
    ON oki.id_terjual = ok.id_terjual
  WHERE ok.tanggal_terjual = p_tanggal_terjual
    AND oki.is_legacy = false
    AND oki.id_obat IS NOT NULL;

  DELETE FROM public.obat_keluar
  WHERE tanggal_terjual = p_tanggal_terjual;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_refresh_totals(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_recalculate_obat_stok_single(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_recalculate_obat_stok_bulk(bigint[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_insert_atomic(date, text, text, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_update_atomic(bigint, date, text, text, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_by_tanggal_atomic(date) TO authenticated;
