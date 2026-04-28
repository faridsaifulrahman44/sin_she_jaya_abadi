-- Migration FASE 8: safe delete obat dengan guard histori transaksi.
-- Aturan:
-- 1) Obat hanya boleh dihapus jika tidak direferensikan histori:
--    obat_masuk, obat_keluar_item, stock_opname.
-- 2) Cek + delete dilakukan atomik dalam satu function untuk mencegah race condition.

CREATE OR REPLACE FUNCTION public.fn_obat_delete_if_unused(
  p_id_obat bigint
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_used_in_obat_masuk boolean;
  v_used_in_obat_keluar_item boolean;
  v_used_in_stock_opname boolean;
BEGIN
  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  PERFORM 1
  FROM public.obat
  WHERE id_obat = p_id_obat
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'obat tidak ditemukan: %', p_id_obat;
  END IF;

  SELECT EXISTS(
      SELECT 1
      FROM public.obat_masuk om
      WHERE om.id_obat = p_id_obat
    ),
    EXISTS(
      SELECT 1
      FROM public.obat_keluar_item oki
      WHERE oki.id_obat = p_id_obat
    ),
    EXISTS(
      SELECT 1
      FROM public.stock_opname so
      WHERE so.id_obat = p_id_obat
    )
  INTO
    v_used_in_obat_masuk,
    v_used_in_obat_keluar_item,
    v_used_in_stock_opname;

  IF v_used_in_obat_masuk
     OR v_used_in_obat_keluar_item
     OR v_used_in_stock_opname THEN
    RETURN jsonb_build_object(
      'deleted', false,
      'used_in_obat_masuk', v_used_in_obat_masuk,
      'used_in_obat_keluar_item', v_used_in_obat_keluar_item,
      'used_in_stock_opname', v_used_in_stock_opname
    );
  END IF;

  DELETE FROM public.obat
  WHERE id_obat = p_id_obat;

  RETURN jsonb_build_object(
    'deleted', true,
    'used_in_obat_masuk', false,
    'used_in_obat_keluar_item', false,
    'used_in_stock_opname', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_obat_delete_if_unused(bigint) TO authenticated;
