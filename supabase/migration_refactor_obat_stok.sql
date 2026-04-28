-- OBSOLETE (FASE 3)
-- Jangan apply migration ini pada environment baru maupun existing.
-- Alasan:
-- 1) Script ini pernah DROP kolom `stok_awal`, padahal engine stok final butuh `stok_awal`.
-- 2) Sudah digantikan oleh baseline final `schema.sql` + `migration_fase1_stock_engine.sql`.

-- Migration: Refactor obat master to support dynamic stock and fixed etalase
-- Run this migration BEFORE deploying the Phase 2 Flutter update.

-- Step 1: Add new columns as nullable first
ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS stok_saat_ini integer,
  ADD COLUMN IF NOT EXISTS stok_minimum integer NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS etalase varchar(20) NOT NULL DEFAULT 'etalase1';

-- Step 2: Migrate existing stok_sisa data into stok_saat_ini
UPDATE public.obat SET stok_saat_ini = stok_sisa WHERE stok_sisa IS NOT NULL;

-- Step 3: Set stok_saat_ini default for any rows that are still null
UPDATE public.obat SET stok_saat_ini = 0 WHERE stok_saat_ini IS NULL;

-- Step 4: Make stok_saat_ini NOT NULL after data migration
ALTER TABLE public.obat
  ALTER COLUMN stok_saat_ini SET NOT NULL,
  ALTER COLUMN stok_saat_ini SET DEFAULT 0;

-- Step 5: Add check constraint for positive values
ALTER TABLE public.obat
  ADD CONSTRAINT obat_stok_saat_ini_check CHECK (stok_saat_ini >= 0),
  ADD CONSTRAINT obat_stok_minimum_check CHECK (stok_minimum >= 0),
  ADD CONSTRAINT obat_etalase_check CHECK (etalase IN ('etalase1', 'etalase2', 'etalase3'));

-- Step 6: Drop old columns (SAFE: data already migrated)
ALTER TABLE public.obat
  DROP COLUMN IF EXISTS stok_awal,
  DROP COLUMN IF EXISTS stok_sisa;

-- Step 7: Update RLS policy comment (no structural change needed for RLS)
-- The existing policy "authenticated can manage obat" covers all columns.

-- Verification query (optional):
-- SELECT id_obat, nama_obat, stok_saat_ini, stok_minimum, etalase FROM public.obat LIMIT 10;
