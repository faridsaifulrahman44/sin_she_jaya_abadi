-- OBSOLETE (FASE 3)
-- Jangan apply migration ini pada environment baru maupun existing.
-- Alasan:
-- 1) Ini draft redesign awal dan overlap dengan migration final.
-- 2) Dapat mismatch dengan schema final (nullable `id_obat` untuk data legacy).
-- 3) Sudah digantikan oleh `migration_obat_keluar_item_final.sql`.

-- ============================================================
-- Migration: Redesain Domain Transaksi Obat Keluar
-- Tanggal: 2026-04-02
--
-- RINGKASAN PERUBAHAN:
--   1. Buat tabel baru `obat_keluar_item` — detail item transaksi
--      menghubungkan transaksi keluar ke obat spesifik.
--   2. `obat_keluar` menjadi header transaksi (tanpa `jumlah_transaksi`,
--      `total_nominal` — nanti dihitung dari item).
--   3. Backfill record lama dengan `obat_keluar_item` bertanda `is_legacy`
--      agar data lama tetap bisa dibaca tanpa hilang.
--   4. `stok_saat_ini` sekarang dihitung dari:
--        stok_awal + SUM(obat_masuk.jumlah_masuk)
--                    - SUM(obat_keluar_item.jumlah)
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. TAMBAH TABEL BARU: obat_keluar_item
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.obat_keluar_item (
  id_item         bigserial PRIMARY KEY,
  id_terjual      bigint   NOT NULL
                    REFERENCES public.obat_keluar(id_terjual)
                    ON DELETE CASCADE,
  id_obat         bigint   NOT NULL
                    REFERENCES public.obat(id_obat)
                    ON DELETE RESTRICT,
  jumlah          integer  NOT NULL CHECK (jumlah > 0),
  harga_satuan    numeric(14, 2) NOT NULL CHECK (harga_satuan >= 0),
  subtotal        numeric(14, 2) NOT NULL CHECK (subtotal >= 0),
  -- is_legacy = true untuk data lama yang di-backfill dari
  -- kolom jumlah_transaksi / total_nominal sebelum redesign.
  -- Baris dengan is_legacy=true TIDAK boleh mengubah stok.
  is_legacy       boolean  NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Indeks untuk query per transaksi dan per obat.
CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_terjual
  ON public.obat_keluar_item(id_terjual);
CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_obat
  ON public.obat_keluar_item(id_obat);

-- Trigger: pastikan subtotal = jumlah × harga_satuan secara otomatis.
CREATE OR REPLACE FUNCTION public.fn_obat_keluar_item_set_subtotal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.subtotal := NEW.jumlah * NEW.harga_satuan;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_obat_keluar_item_set_subtotal
  BEFORE INSERT OR UPDATE OF jumlah, harga_satuan
  ON public.obat_keluar_item
  FOR EACH ROW
  WHEN (NEW.is_legacy = false)
  EXECUTE FUNCTION public.fn_obat_keluar_item_set_subtotal();

-- ─────────────────────────────────────────────
-- 2. RLS UNTUK tabel baru
-- ─────────────────────────────────────────────

ALTER TABLE public.obat_keluar_item ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated can manage obat_keluar_item"
  ON public.obat_keluar_item
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ─────────────────────────────────────────────
-- 3. BACKFILL: isi obat_keluar_item untuk
--    record obat_keluar yang sudah ada sebelum
--    migration ini.
--
--    STRATEGI:
--    Karena data lama TIDAK punya id_obat spesifik,
--    kita buat SATU synthetic item per transaksi:
--      - id_obat = NULL (tidak bisa dipetakan)
--      - jumlah  = COALESCE(jumlah_transaksi, 1)
--      - harga_satuan = COALESCE(total_nominal, 0)
--        (akan menjadi subtotal juga, agar total cocok)
--      - is_legacy = true
--
--    KETENTUAN:
--    - Record baru (setelah migration ini) WAJIB punya
--      minimal 1 baris obat_keluar_item dengan is_legacy=false.
--    - is_legacy=true TIDAK dihitung dalam recalculateStok.
--    - Data lama bisa dibaca tapi stoknya TIDAK berubah
--      sampai user mengedit transaksi dan mengisi id_obat.
-- ─────────────────────────────────────────────

INSERT INTO public.obat_keluar_item
  (id_terjual, id_obat, jumlah, harga_satuan, subtotal, is_legacy)
SELECT
  ok.id_terjual,
  NULL::bigint,                          -- id_obat tidak bisa dipetakan
  COALESCE(ok.jumlah_transaksi, 1),      -- jumlahTransaksi lama
  COALESCE(ok.total_nominal, 0)::numeric,
  COALESCE(ok.total_nominal, 0)::numeric,
  true                                   -- legacy
FROM public.obat_keluar ok
WHERE NOT EXISTS (
  SELECT 1 FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = ok.id_terjual
);

-- ─────────────────────────────────────────────
-- 4. OPSIONAL: hapus kolom yang sudah digantikan
--    oleh obat_keluar_item.
--    AKTIFKAN JIKA SUDAH PASTI SEMUA FORM SUDAH DIPERBAHARUI.
--
--    Langkah aman: kolom ini diabaikan oleh kode Dart yang baru.
--    Uncomment baris di bawah ini SETELAH fase 2 selesai
--    dan semua user sudah migrasi:
--
-- ALTER TABLE public.obat_keluar
--   DROP COLUMN IF EXISTS jumlah_transaksi,
--   DROP COLUMN IF EXISTS total_nominal;
--
-- ─────────────────────────────────────────────

-- Update komentar formula stok di tabel obat (jika masih ada).
COMMENT ON COLUMN public.obat.stok_saat_ini IS E
  'stok_saat_ini dihitung dari stok_awal + mutasi masuk/keluar '
  'dan reset sinkronisasi_stok. Di-maintain oleh aplikasi via recalculateStok().';
