-- Migration FASE 3: Schema cleanup & final alignment
-- Tujuan:
-- 1) Mengonvergensikan DB existing ke schema final.
-- 2) Menutup gap dari migration lama yang saling overlap.
-- 3) Menjamin objek inti sinkron dengan kode saat ini.

-- ============================================
-- A. Pastikan struktur obat_keluar_item final
-- ============================================

CREATE TABLE IF NOT EXISTS public.obat_keluar_item (
  id_item bigserial PRIMARY KEY,
  id_terjual bigint NOT NULL
    REFERENCES public.obat_keluar(id_terjual) ON DELETE CASCADE,
  id_obat bigint
    REFERENCES public.obat(id_obat) ON DELETE RESTRICT,
  jumlah integer NOT NULL CHECK (jumlah > 0),
  harga_satuan numeric(14, 2) NOT NULL CHECK (harga_satuan >= 0),
  subtotal numeric(14, 2) NOT NULL CHECK (subtotal >= 0),
  is_legacy boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.obat_keluar_item
  ADD COLUMN IF NOT EXISTS jumlah integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS harga_satuan numeric(14, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS subtotal numeric(14, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_legacy boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

UPDATE public.obat_keluar_item
SET jumlah = 1
WHERE jumlah IS NULL;

UPDATE public.obat_keluar_item
SET harga_satuan = 0
WHERE harga_satuan IS NULL;

UPDATE public.obat_keluar_item
SET subtotal = 0
WHERE subtotal IS NULL;

ALTER TABLE public.obat_keluar_item
  ALTER COLUMN jumlah SET NOT NULL,
  ALTER COLUMN harga_satuan SET NOT NULL,
  ALTER COLUMN subtotal SET NOT NULL,
  ALTER COLUMN id_obat DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_terjual
  ON public.obat_keluar_item(id_terjual);
CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_obat
  ON public.obat_keluar_item(id_obat);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_keluar_item_id_terjual_fkey'
      AND conrelid = 'public.obat_keluar_item'::regclass
  ) THEN
    ALTER TABLE public.obat_keluar_item
      ADD CONSTRAINT obat_keluar_item_id_terjual_fkey
      FOREIGN KEY (id_terjual)
      REFERENCES public.obat_keluar(id_terjual)
      ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_keluar_item_id_obat_fkey'
      AND conrelid = 'public.obat_keluar_item'::regclass
  ) THEN
    ALTER TABLE public.obat_keluar_item
      ADD CONSTRAINT obat_keluar_item_id_obat_fkey
      FOREIGN KEY (id_obat)
      REFERENCES public.obat(id_obat)
      ON DELETE RESTRICT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_keluar_item_jumlah_check'
      AND conrelid = 'public.obat_keluar_item'::regclass
  ) THEN
    ALTER TABLE public.obat_keluar_item
      ADD CONSTRAINT obat_keluar_item_jumlah_check CHECK (jumlah > 0);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_keluar_item_harga_satuan_check'
      AND conrelid = 'public.obat_keluar_item'::regclass
  ) THEN
    ALTER TABLE public.obat_keluar_item
      ADD CONSTRAINT obat_keluar_item_harga_satuan_check CHECK (harga_satuan >= 0);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'obat_keluar_item_subtotal_check'
      AND conrelid = 'public.obat_keluar_item'::regclass
  ) THEN
    ALTER TABLE public.obat_keluar_item
      ADD CONSTRAINT obat_keluar_item_subtotal_check CHECK (subtotal >= 0);
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_item_set_subtotal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_legacy = false THEN
    NEW.subtotal := NEW.jumlah * NEW.harga_satuan;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_obat_keluar_item_set_subtotal
  ON public.obat_keluar_item;

CREATE TRIGGER trg_obat_keluar_item_set_subtotal
  BEFORE INSERT OR UPDATE OF jumlah, harga_satuan
  ON public.obat_keluar_item
  FOR EACH ROW
  WHEN (NEW.is_legacy = false)
  EXECUTE FUNCTION public.fn_obat_keluar_item_set_subtotal();

ALTER TABLE public.obat_keluar_item ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can manage obat_keluar_item"
  ON public.obat_keluar_item;
CREATE POLICY "authenticated can manage obat_keluar_item"
  ON public.obat_keluar_item
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Backfill item legacy untuk transaksi yang belum punya item sama sekali.
INSERT INTO public.obat_keluar_item
  (id_terjual, id_obat, jumlah, harga_satuan, subtotal, is_legacy)
SELECT
  ok.id_terjual,
  NULL::bigint,
  GREATEST(COALESCE(ok.jumlah_transaksi, 1), 1),
  COALESCE(ok.total_nominal, 0)::numeric(14, 2),
  COALESCE(ok.total_nominal, 0)::numeric(14, 2),
  true
FROM public.obat_keluar ok
WHERE NOT EXISTS (
  SELECT 1
  FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = ok.id_terjual
);

-- ============================================
-- B. Pastikan baseline stok_awal final
-- ============================================

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS stok_awal integer;

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
WHERE stok_awal IS NULL OR stok_awal < 0;

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

COMMENT ON COLUMN public.obat.stok_saat_ini IS
  'stok_saat_ini dihitung dari stok_awal + mutasi masuk/keluar '
  'dan reset stock_opname. Di-maintain oleh recalculateStok().';

-- ============================================
-- C. Pastikan indeks inti
-- ============================================

CREATE INDEX IF NOT EXISTS idx_stock_opname_tanggal
  ON public.stock_opname(tanggal_opname DESC);
CREATE INDEX IF NOT EXISTS idx_stock_opname_id_obat
  ON public.stock_opname(id_obat);
CREATE INDEX IF NOT EXISTS idx_pasien_tanggal_janjian
  ON public.pasien(tanggal_janjian DESC);
CREATE INDEX IF NOT EXISTS idx_obat_masuk_tanggal
  ON public.obat_masuk(tanggal_masuk DESC);
CREATE INDEX IF NOT EXISTS idx_obat_masuk_id_obat
  ON public.obat_masuk(id_obat);
CREATE INDEX IF NOT EXISTS idx_obat_keluar_tanggal
  ON public.obat_keluar(tanggal_terjual DESC);

-- ============================================
-- D. Pastikan RPC atomik tersedia
-- ============================================
-- Untuk mencegah divergensi environment lama, jalankan ulang migration fase 2.
-- File: supabase/migration_fase2_obat_keluar_atomic.sql
