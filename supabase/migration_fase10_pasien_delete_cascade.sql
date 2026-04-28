-- Migration FASE 10: selaraskan hapus pasien dengan ON DELETE CASCADE.
-- Tujuan:
-- 1) Relasi kehadiran_pasien.id_pasien tidak lagi memblokir delete pasien.
-- 2) Function hapus pasien tidak lagi memperlakukan kehadiran_pasien sebagai blocker.

DO $$
DECLARE
  v_constraint_name text;
BEGIN
  FOR v_constraint_name IN
    SELECT c.conname
    FROM pg_constraint c
    WHERE c.contype = 'f'
      AND c.conrelid = 'public.kehadiran_pasien'::regclass
      AND c.confrelid = 'public.pasien'::regclass
  LOOP
    EXECUTE format(
      'ALTER TABLE public.kehadiran_pasien DROP CONSTRAINT %I',
      v_constraint_name
    );
  END LOOP;
END;
$$;

ALTER TABLE public.kehadiran_pasien
  ADD CONSTRAINT kehadiran_pasien_id_pasien_fkey
  FOREIGN KEY (id_pasien)
  REFERENCES public.pasien(id_pasien)
  ON DELETE CASCADE;

CREATE OR REPLACE FUNCTION public.fn_pasien_delete_if_unused(
  p_id_pasien bigint
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
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

  DELETE FROM public.pasien
  WHERE id_pasien = p_id_pasien;

  RETURN jsonb_build_object(
    'deleted', true
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_if_unused(bigint) TO authenticated;
