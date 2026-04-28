-- Migration FASE 13: auto-renumber nomor_pasien 1..N setelah delete.
--
-- Kontrak final:
-- 1) Repository Dart memanggil fn_pasien_delete_and_renumber.
-- 2) FK kehadiran_pasien.id_pasien sudah ON DELETE CASCADE (fase10),
--    jadi hapus pasien boleh dilakukan dan histori kehadiran terkait ikut terhapus.
-- 3) Setelah delete, nomor_pasien dirapikan kembali tanpa gap.

CREATE OR REPLACE FUNCTION public.fn_pasien_delete_and_renumber(
  p_id_pasien bigint
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_nomor integer;
BEGIN
  IF COALESCE(p_id_pasien, 0) <= 0 THEN
    RAISE EXCEPTION 'id_pasien tidak valid';
  END IF;

  PERFORM 1
  FROM public.pasien
  WHERE id_pasien = p_id_pasien
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pasien tidak ditemukan: %', p_id_pasien;
  END IF;

  -- Kehadiran terkait ikut terhapus via ON DELETE CASCADE.
  DELETE FROM public.pasien
  WHERE id_pasien = p_id_pasien;

  SELECT COUNT(*) + 1
  INTO v_next_nomor
  FROM public.pasien;

  UPDATE public.pasien AS p
  SET nomor_pasien = renumber.new_nomor::varchar
  FROM (
    SELECT
      id_pasien,
      ROW_NUMBER() OVER (ORDER BY id_pasien ASC) AS new_nomor
    FROM public.pasien
  ) AS renumber
  WHERE renumber.id_pasien = p.id_pasien;

  RETURN jsonb_build_object(
    'deleted', true,
    'next_nomor', v_next_nomor
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_and_renumber(bigint)
  TO authenticated;
