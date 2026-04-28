-- ============================================================
-- FASE 3: Ecer Sederhana — Dukungan Satuan Jual di Transaksi
-- Ditambahkan 2026-04-27
--
-- Tambahan: kolom satuan_terjual di transaksi_item.
-- Isi field ini saat transaksi item dibuat:
--   - satuan utama  → satuan_jual dari Master Obat
--   - satuan ecer   → satuan_ecer dari Master Obat
--
-- Kolom ini ringan, nullable, backward-compatible.
-- Tidak mengubah FK atau primary key.
-- ============================================================

-- Tambah kolom satuan_terjual ke transaksi_item
ALTER TABLE public.transaksi_item
  ADD COLUMN IF NOT EXISTS satuan_terjual varchar(30);

COMMENT ON COLUMN public.transaksi_item.satuan_terjual IS
  'Satuan aktual yang dipilih saat transaksi. '
  'Contoh: "botol" (satuan utama) atau "kapsul" (eceran). '
  'Null untuk transaksi legacy sebelum FASE 3 atau transaksi custom.';