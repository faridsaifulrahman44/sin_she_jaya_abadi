-- Migration FASE 7: hardening atomic sinkronisasi stok (delete by tanggal)
-- Tujuan:
-- 1) Menyamakan fitur bulk delete sinkronisasi_stok dengan alur transaksi lain.
-- 2) Menjaga histori + stok tetap konsisten saat hapus massal per tanggal.
--
-- Compatibility note:
-- RPC name stays fn_stock_opname_delete_by_tanggal_atomic for Flutter.
-- The final data table is public.sinkronisasi_stok.

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

GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(date) TO authenticated;
