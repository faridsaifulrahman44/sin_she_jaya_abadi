-- Migration FASE 15: finalisasi kontrak delete pasien.
--
-- Tujuan:
-- 1) Hapus RPC legacy `fn_pasien_delete_if_unused` agar kontrak tidak ambigu.
-- 2) Tegaskan RPC final `fn_pasien_delete_and_renumber` sebagai satu-satunya
--    kontrak delete pasien yang dipakai aplikasi.

DROP FUNCTION IF EXISTS public.fn_pasien_delete_if_unused(bigint);

GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_and_renumber(bigint)
  TO authenticated;
