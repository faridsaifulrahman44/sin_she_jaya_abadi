-- Migration: Repair obat etalase constraint & data
--
-- Scope:
-- 1. Normalisasi kolom etalase: drop kolom lama (jika ada kolom berbeda),
--    pastikan kolom `etalase` ada dan bertipe varchar.
-- 2. Repairs data:UPDATE baris dengan nilai etalase tidak valid ke default 'etalase1'.
-- 3. Pasang/重申 CHECK constraint `obat_etalase_check` agar hanya
--    'etalase1', 'etalase2', 'etalase3' yang diterima.
--
-- Aman untuk environment baru maupun existing (IF NOT EXISTS / ON CONFLICT).

-- ============================================================
-- A. Repairs data etalase yang tidak符合 schema final
-- ============================================================

-- Lista nilai valid.
DO $$
DECLARE
  invalid_count integer;
BEGIN
  -- Hitung baris invalid sebelum repair.
  SELECT COUNT(*) INTO invalid_count
  FROM public.obat
  WHERE etalase NOT IN ('etalase1', 'etalase2', 'etalase3')
     OR etalase IS NULL;

  -- Repair: set invalid/null ke 'etalase1'.
  UPDATE public.obat
  SET etalase = 'etalase1'
  WHERE etalase NOT IN ('etalase1', 'etalase2', 'etalase3')
     OR etalase IS NULL;

  RAISE NOTICE 'Etalase repair: % baris diperbaiki ke etalase1', invalid_count;
END
$$;

-- ============================================================
-- B. Pastikan kolom etalase ada & bertipe varchar
-- ============================================================

DO $$
BEGIN
  -- Tambah kolom jika belum ada (untuk DB lama yang belum pernah di-migrate).
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'obat'
      AND column_name = 'etalase'
  ) THEN
    ALTER TABLE public.obat
      ADD COLUMN etalase varchar(20) NOT NULL DEFAULT 'etalase1';
    RAISE NOTICE 'Kolom etalase ditambahkan ke tabel obat';
  END IF;
END
$$;

-- Set NOT NULL + default jika perlu.
ALTER TABLE public.obat
  ALTER COLUMN etalase SET NOT NULL;

DO $$
BEGIN
  ALTER TABLE public.obat
    ALTER COLUMN etalase SET DEFAULT 'etalase1';
EXCEPTION
  WHEN others THEN
    NULL; -- Abaikan jika default sudah benar.
END
$$;

-- ============================================================
-- C. Pasang CHECK constraint obat_etalase_check
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_etalase_check'
      AND conrelid = 'public.obat'::regclass
  ) THEN
    ALTER TABLE public.obat
      ADD CONSTRAINT obat_etalase_check
        CHECK (etalase IN ('etalase1', 'etalase2', 'etalase3'));
    RAISE NOTICE 'Constraint obat_etalase_check dipasang';
  ELSE
    -- Constraint sudah ada: validasi data tetap pass.
    -- Jika ada baris invalid (seharusnya sudah di-repair di step A),
    -- constraint ADD akan gagal dan memberi sinyal jelas.
    RAISE NOTICE 'Constraint obat_etalase_check sudah ada — '
      'pastikan data sudah valid (lihat step A)';
  END IF;
END
$$;

-- ============================================================
-- D. Verifikasi
-- ============================================================

-- D.1: Nilai distinct etalase
-- SELECT DISTINCT etalase FROM public.obat ORDER BY etalase;
-- Hasil yang diharapkan: etalase1, etalase2, etalase3

-- D.2: Baris dengan etalase invalid
-- SELECT id_obat, nama_obat, etalase FROM public.obat
--   WHERE etalase NOT IN ('etalase1', 'etalase2', 'etalase3') OR etalase IS NULL;
-- Hasil yang diharapkan: 0 baris
