-- Migration FASE 9: safe delete pasien dengan guard relasi histori.
-- Aturan:
-- 1) Pasien hanya boleh dihapus jika tidak direferensikan histori:
--    kehadiran_pasien.
-- 2) Cek + delete dilakukan atomik dalam satu function untuk mencegah race condition.

CREATE OR REPLACE FUNCTION public.fn_pasien_delete_if_unused(
  p_id_pasien bigint
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_used_in_kehadiran_pasien boolean;
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

  SELECT EXISTS(
    SELECT 1
    FROM public.kehadiran_pasien kp
    WHERE kp.id_pasien = p_id_pasien
  )
  INTO v_used_in_kehadiran_pasien;

  IF v_used_in_kehadiran_pasien THEN
    RETURN jsonb_build_object(
      'deleted', false,
      'used_in_kehadiran_pasien', true
    );
  END IF;

  DELETE FROM public.pasien
  WHERE id_pasien = p_id_pasien;

  RETURN jsonb_build_object(
    'deleted', true,
    'used_in_kehadiran_pasien', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_if_unused(bigint) TO authenticated;
