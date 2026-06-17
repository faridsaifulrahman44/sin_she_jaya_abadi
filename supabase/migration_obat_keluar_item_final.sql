-- ============================================================
-- Migration FINAL: Tabel Detail Transaksi Obat Keluar
-- Tanggal: 2026-04-02
-- Status: siap produksi — idempotent (IF NOT EXISTS / OR REPLACE)
--
-- KOLOM YANG DIHARAPKAN KODE (obat_keluar_item_model.dart):
--   id_item        → idItem   (bigint PK, auto)
--   id_terjual     → idTerjual (bigint FK → obat_keluar.id_terjual)
--   id_obat        → idObat   (bigint FK → obat.id_obat, NULL allowed untuk legacy)
--   jumlah         → jumlah   (integer)
--   harga_satuan   → hargaSatuan (numeric(14,2))
--   subtotal       → subtotal  (numeric(14,2), auto-trigger)
--   is_legacy      → isLegacy  (boolean, default false)
--   created_at     → createdAt (timestamptz, default now())
--
-- PAKAI: Jalankan di Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. CREATE TABLE: obat_keluar_item
--    Kolom sinkron dengan ObatKeluarItemModel (Dart)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.obat_keluar_item (
  id_item       bigserial PRIMARY KEY,
  id_terjual    bigint   NOT NULL
                  REFERENCES public.obat_keluar(id_terjual)
                  ON DELETE CASCADE,
  id_obat       bigint   -- NULL untuk legacy; FK nullable agar backfill bisa NULL
                  REFERENCES public.obat(id_obat)
                  ON DELETE RESTRICT,
  jumlah        integer  NOT NULL
                  CHECK (jumlah > 0),
  harga_satuan  numeric(14, 2) NOT NULL
                  CHECK (harga_satuan >= 0),
  subtotal      numeric(14, 2) NOT NULL
                  CHECK (subtotal >= 0),
  is_legacy     boolean  NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────
-- 2. INDEKS
-- ─────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_terjual
  ON public.obat_keluar_item(id_terjual);
CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_obat
  ON public.obat_keluar_item(id_obat);

-- ─────────────────────────────────────────────
-- 3. TRIGGER: auto-compute subtotal = jumlah × harga_satuan
--    untuk baris non-legacy.
--    Baris dengan is_legacy=true TIDAK di-trigger
--    (subtotal diisi manual saat backfill).
-- ─────────────────────────────────────────────

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

-- ─────────────────────────────────────────────
-- 4. RLS
-- ─────────────────────────────────────────────

ALTER TABLE public.obat_keluar_item ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can manage obat_keluar_item"
  ON public.obat_keluar_item;

CREATE POLICY "authenticated can manage obat_keluar_item"
  ON public.obat_keluar_item
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ─────────────────────────────────────────────
-- 5. BACKFILL: legacy item untuk record lama
--
--    Strategi:
--    - Buat SATU synthetic item per transaksi lama
--      (karena data lama tidak punya id_obat spesifik).
--    - id_obat = NULL (tidak bisa dipetakan).
--    - jumlah  = COALESCE(jumlah_transaksi, 1) — 0 jadi 1 (legacy).
--    - harga_satuan / subtotal = COALESCE(total_nominal, 0).
--      Ini agar total_transaksi lama tetap konsisten
--      saat ditampilkan tanpa item breakdown.
--    - is_legacy = true → TIDAK dihitung dalam recalculateStok().
--
--    Idempotent: hanya insert jika belum ada.
-- ─────────────────────────────────────────────

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
  SELECT 1 FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = ok.id_terjual
);

-- ─────────────────────────────────────────────
-- 6. UPDATE komentar formula stok di obat
-- ─────────────────────────────────────────────

COMMENT ON COLUMN public.obat.stok_saat_ini IS E
  'stok_saat_ini dihitung dari stok_awal + mutasi masuk/keluar '
  'dan reset sinkronisasi_stok. Di-maintain oleh aplikasi via recalculateStok().';

-- ─────────────────────────────────────────────
-- CATATAN UNTUK PHASE SELANJUTNYA (opsional):
-- Kolom lama di obat_keluar (jumlah_transaksi, total_nominal)
-- masih dipertahankan untuk backward-compat.
-- Setelah semua client di-upgrade, bisa dihapus dengan:
--
--   ALTER TABLE public.obat_keluar
--     DROP COLUMN IF EXISTS jumlah_transaksi,
--     DROP COLUMN IF EXISTS total_nominal;
--
-- Jangan jalankan DROP sebelum semua app client
-- sudah menggunakan kode phase 2+.
-- ─────────────────────────────────────────────
