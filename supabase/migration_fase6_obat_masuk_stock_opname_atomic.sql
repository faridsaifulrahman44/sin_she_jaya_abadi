-- Migration FASE 6: jadikan obat_masuk & stock_opname atomik via RPC SQL
-- Cakupan atomik:
-- 1) obat_masuk insert/update/delete (+ delete by tanggal)
-- 2) stock_opname insert/update/delete
-- 3) setiap write langsung recalculate stok obat terkait dalam transaksi yang sama

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_insert_atomic(
  p_id_obat bigint,
  p_tanggal_masuk date,
  p_jumlah_masuk integer,
  p_keterangan text,
  p_id_admin bigint
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_masuk bigint;
BEGIN
  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_masuk IS NULL THEN
    RAISE EXCEPTION 'tanggal_masuk wajib diisi';
  END IF;

  IF COALESCE(p_jumlah_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'jumlah_masuk harus lebih dari 0';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  INSERT INTO public.obat_masuk (
    id_obat,
    tanggal_masuk,
    jumlah_masuk,
    keterangan,
    id_admin
  )
  VALUES (
    p_id_obat,
    p_tanggal_masuk,
    p_jumlah_masuk,
    NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    p_id_admin
  )
  RETURNING id_masuk INTO v_id_masuk;

  PERFORM public.fn_recalculate_obat_stok_single(p_id_obat);

  RETURN v_id_masuk;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_update_atomic(
  p_id_masuk bigint,
  p_id_obat bigint,
  p_tanggal_masuk date,
  p_jumlah_masuk integer,
  p_keterangan text,
  p_id_admin bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_id_obat bigint;
  v_affected_ids bigint[];
BEGIN
  IF COALESCE(p_id_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'id_masuk tidak valid';
  END IF;

  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_masuk IS NULL THEN
    RAISE EXCEPTION 'tanggal_masuk wajib diisi';
  END IF;

  IF COALESCE(p_jumlah_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'jumlah_masuk harus lebih dari 0';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  SELECT om.id_obat
  INTO v_old_id_obat
  FROM public.obat_masuk om
  WHERE om.id_masuk = p_id_masuk
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi obat masuk tidak ditemukan: %', p_id_masuk;
  END IF;

  UPDATE public.obat_masuk
  SET
    id_obat = p_id_obat,
    tanggal_masuk = p_tanggal_masuk,
    jumlah_masuk = p_jumlah_masuk,
    keterangan = NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    id_admin = p_id_admin
  WHERE id_masuk = p_id_masuk;

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

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_delete_atomic(
  p_id_masuk bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_obat bigint;
BEGIN
  IF COALESCE(p_id_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'id_masuk tidak valid';
  END IF;

  SELECT om.id_obat
  INTO v_id_obat
  FROM public.obat_masuk om
  WHERE om.id_masuk = p_id_masuk
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi obat masuk tidak ditemukan: %', p_id_masuk;
  END IF;

  DELETE FROM public.obat_masuk
  WHERE id_masuk = p_id_masuk;

  PERFORM public.fn_recalculate_obat_stok_single(v_id_obat);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_delete_by_tanggal_atomic(
  p_tanggal_masuk date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  IF p_tanggal_masuk IS NULL THEN
    RAISE EXCEPTION 'tanggal_masuk wajib diisi';
  END IF;

  SELECT array_agg(DISTINCT om.id_obat)
  INTO v_affected_ids
  FROM public.obat_masuk om
  WHERE om.tanggal_masuk = p_tanggal_masuk
    AND om.id_obat IS NOT NULL;

  DELETE FROM public.obat_masuk
  WHERE tanggal_masuk = p_tanggal_masuk;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
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

  INSERT INTO public.stock_opname (
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
  FROM public.stock_opname so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'stock opname tidak ditemukan: %', p_id_opname;
  END IF;

  UPDATE public.stock_opname
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
  FROM public.stock_opname so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'stock opname tidak ditemukan: %', p_id_opname;
  END IF;

  DELETE FROM public.stock_opname
  WHERE id_opname = p_id_opname;

  PERFORM public.fn_recalculate_obat_stok_single(v_id_obat);
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_insert_atomic(bigint, date, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_update_atomic(bigint, bigint, date, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_insert_atomic(bigint, date, integer, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_update_atomic(bigint, bigint, date, integer, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_atomic(bigint) TO authenticated;
