-- ============================================================
-- FASE 1: Master Obat = Source of Truth Harga
-- Ditambahkan 2026-04-27
--
-- Struktur harga utama dan eceran di tabel obat.
-- Phase ini fokus pada struktur + display di Master Obat.
-- Flow transaksi belum berubah.
-- ============================================================

-- Tambah kolom harga di tabel obat
ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS harga_jual numeric(12, 2)
    CHECK (harga_jual IS NULL OR harga_jual >= 0);

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS satuan_jual varchar(30);

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS bisa_ecer boolean NOT NULL DEFAULT false;

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS harga_ecer numeric(12, 2)
    CHECK (harga_ecer IS NULL OR harga_ecer >= 0);

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS satuan_ecer varchar(30);

-- Buat idx pada kolom harga untuk filter/urut di masa depan
CREATE INDEX IF NOT EXISTS idx_obat_harga_jual ON public.obat(harga_jual);
CREATE INDEX IF NOT EXISTS idx_obat_bisa_ecer ON public.obat(bisa_ecer);

-- ============================================================
-- DATA AWAL: harga untuk 13 obat yang sudah ada
-- Update harga_jual, satuan_jual, dan ecer untuk setiap obat.
-- Kode ini idempotent — aman dijalankan ulang.
-- ============================================================

-- 1. die_da_tay_ping_yao_jing -> Rp 32.000
UPDATE public.obat
SET
  harga_jual = 32000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%die da tay ping yao jing%';

-- 2. extractum_astragali -> Rp 43.000
UPDATE public.obat
SET
  harga_jual = 43000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%extractum astragali%';

-- 3. four_season_medicated_oil_40ml -> Rp 45.000
UPDATE public.obat
SET
  harga_jual = 45000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%four season medicated oil%'
  AND nama_obat ILIKE '%40ml%';

-- 4. lohankuo_infusion -> Rp 25.000
UPDATE public.obat
SET
  harga_jual = 25000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%lohankuo%' AND nama_obat ILIKE '%infusion%';

-- 5. minyak_batu_sai_kong_liong_30ml -> Rp 55.000
UPDATE public.obat
SET
  harga_jual = 55000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%minyak batu sai kong liong%'
  AND nama_obat ILIKE '%30ml%';

-- 6. panax_ginseng_extractum_oral_liquid -> Rp 75.000
UPDATE public.obat
SET
  harga_jual = 75000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%panax ginseng%' AND nama_obat ILIKE '%oral liquid%';

-- 7. zheng_gu_shui -> Rp 73.000
UPDATE public.obat
SET
  harga_jual = 73000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%zheng gu shui%';

-- 8. dilong_cacing_kapsul -> Rp 60.000 (botol), ecer Rp 1.000/kapsul
UPDATE public.obat
SET
  harga_jual = 60000,
  satuan_jual = 'botol',
  bisa_ecer = true,
  harga_ecer = 1000,
  satuan_ecer = 'kapsul'
WHERE nama_obat ILIKE '%dilong%' AND nama_obat ILIKE '%cacing%' AND nama_obat ILIKE '%kapsul%';

-- 9. four_season_medicated_oil_20ml -> Rp 30.000
UPDATE public.obat
SET
  harga_jual = 30000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%four season medicated oil%'
  AND nama_obat ILIKE '%20ml%';

-- 10. hsiang_sha_yang_wei_pien -> Rp 50.000
UPDATE public.obat
SET
  harga_jual = 50000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%hsiang sha yang wei pien%';

-- 11. lohankuo_zhenzhu_juhua -> Rp 30.000
UPDATE public.obat
SET
  harga_jual = 30000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%lohankuo%' AND nama_obat ILIKE '%zhenzhu juhua%';

-- 12. minyak_batu_sai_kong_liong_70ml -> Rp 75.000
UPDATE public.obat
SET
  harga_jual = 75000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%minyak batu sai kong liong%'
  AND nama_obat ILIKE '%70ml%';

-- 13. xiaoshi_pian -> Rp 75.000
UPDATE public.obat
SET
  harga_jual = 75000,
  satuan_jual = 'botol'
WHERE nama_obat ILIKE '%xiaoshi pian%';