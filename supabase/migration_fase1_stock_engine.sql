-- Migration FASE 1: baseline stok_awal untuk engine stok tunggal
-- Tujuan:
-- 1) Menambahkan kolom immutable `stok_awal` pada master obat.
-- 2) Backfill aman dari data existing agar stok saat ini tetap konsisten.
-- 3) Menyiapkan fondasi full recalculation dari histori valid.

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS stok_awal integer;

-- Backfill stok_awal dari stok saat ini dan histori mutasi agar
-- nilai stok akhir tetap stabil setelah engine baru aktif.
UPDATE public.obat o
SET stok_awal = GREATEST(
  0,
  o.stok_saat_ini
    - COALESCE((
        SELECT SUM(om.jumlah_masuk)::integer
        FROM public.obat_masuk om
        WHERE om.id_obat = o.id_obat
      ), 0)
    + COALESCE((
        SELECT SUM(oki.jumlah)::integer
        FROM public.obat_keluar_item oki
        WHERE oki.id_obat = o.id_obat
          AND oki.is_legacy = false
      ), 0)
)
WHERE o.stok_awal IS NULL;

UPDATE public.obat
SET stok_awal = 0
WHERE stok_awal IS NULL;

ALTER TABLE public.obat
  ALTER COLUMN stok_awal SET NOT NULL,
  ALTER COLUMN stok_awal SET DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_stok_awal_check'
      AND conrelid = 'public.obat'::regclass
  ) THEN
    ALTER TABLE public.obat
      ADD CONSTRAINT obat_stok_awal_check CHECK (stok_awal >= 0);
  END IF;
END
$$;
