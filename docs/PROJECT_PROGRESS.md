# 🏥 Sin She Jaya Abadi — Master Progress Tracker
# Baca file ini PERTAMA setiap kali memulai sesi baru

---

## 📍 POSISI TERAKHIR
- **Branch aktif:** `latihan-plugin`
- **Sedang mengerjakan:** F2 — Phase 1 (Material Symbols + Schema)
- **Task berikutnya:** Task 4 Batch 4C — obat_keluar pages
- **Terakhir dikerjakan:** 18 Mei 2026 (~18:00)

---

## ✅ F1 — SELESAI
Semua fitur F1 sudah selesai dan di-merge ke master:
- [x] Dashboard owner final (card biru, jam, tanggal, penjualan)
- [x] Ikon QRIS/Tunai di SegmentedButton (sudah pakai HugeIcons → swap ke AppSymbols di Phase 1)
- [x] Fix upload foto → foto_key + foto_updated_at
- [x] Aktivasi _existingFotoKey di obat_form_page
- [x] Deskripsi obat etalase 1 & 2 terisi
- [x] Fix test harness (173 passed, 0 failed)
- [x] Pisah halaman Pasien & Kehadiran
- [x] Filter chip aktif (Total/Jadwal/Hadir) di tab Data Pasien
- [x] Kalender interaktif + riwayat obat masuk
- [x] Perbaikan visual chip filter pasien
- [x] Hapus emoji di awal deskripsi obat
- [x] CLAUDE.md dibuat + Claude Mem installed
- [x] Hapus dead code kehadiran_tab_content.dart

---

## 🔄 F2 — SEDANG DIKERJAKAN
Spec lengkap: `docs/superpowers/specs/2026-05-18-f2-feature-maturity-design.md`
Plan Phase 1: `docs/superpowers/plans/2026-05-18-f2-phase1-material-symbols-schema.md`

### Phase 1 — Material Symbols + Schema (AKTIF)

**Selesai:**
- [x] Task 1: AppSymbols wrapper (61 icons) → commit `875f8cb`
- [x] Task 2: pubspec.yaml — add material_symbols_icons, pdf, printing, csv; remove hugeicons → commit `875f8cb`
- [x] Task 3: transaksi_form_page.dart icon swap (tunai/qris) → commit `234f98b`
- [x] Task 4 Batch 4a: dashboard, login, login_layouts, app_error_view, app_empty_view + app_widgets.dart → commit terpisah

**Lagi (in-progress):**
- [x] Task 4 Batch 4a: dashboard, login, login_layouts, app_error_view, app_empty_view, app_widgets.dart → commit `7ca282f` (beserta batch 4b, jadi batch 4a+4b selesai bersamaan)

**Belum selesai:**
- [ ] Task 4 Batch 4C: obat_keluar pages ← NEXT
  - `lib/pages/obat_keluar_page.dart`
  - `lib/pages/obat_keluar_detail_page.dart`
  - `lib/pages/obat_keluar_form_page.dart`
  - `lib/pages/obat_keluar/widgets/obat_keluar_item_row.dart`
  - `lib/pages/obat_keluar_tanggal_form_page.dart`
- [ ] Task 4 Batch 4D: pasien & kehadiran pages
  - `lib/pages/pasien_detail_page.dart`
  - `lib/pages/pasien_form_page.dart`
  - `lib/pages/kehadiran_tab_content.dart`
  - `lib/pages/kehadiran_detail_page.dart`
  - `lib/pages/kehadiran_form_page.dart`
- [ ] Task 4 Batch 4E: transaksi & laporan pages
  - `lib/pages/laporan_page.dart`
  - `lib/pages/kunjungan_form_page.dart`
  - `lib/pages/sinkronisasi_stok_page.dart`
  - `lib/pages/sinkronisasi_stok_form_page.dart`
  - `lib/pages/sinkronisasi_stok/widgets/sinkronisasi_stok_panels.dart`
  - `lib/pages/laporan/widgets/laporan_components.dart`
- [ ] Task 4 Batch 4F: auth pages
  - `lib/pages/forgot_password_page.dart`
  - `lib/pages/reset_password_page.dart`
- [ ] Task 4 — Grep verifikasi: semua `HugeIcon` / `import hugeicons` harus zero
- [ ] Task 5: Deprecate app_icons.dart (tambah notice, jangan hapus)
- [ ] Task 6: ALTER TABLE transaksi ADD status_lunas ⚠️ **WAJIB TAMPILKAN SQL → TUNGGU "LANJUT"**
- [ ] Task 7: CREATE TABLE kas_keluar + RLS ⚠️ **WAJIB TAMPILKAN SQL → TUNGGU "LANJUT"**
- [ ] Task 8: KasKeluar model + repository + tests
- [ ] Task 9: TransaksiModel tambah status_lunas field
- [ ] Task 10: Final verification (flutter analyze + flutter test) + push

### Phase 2 — F2-C: Stok Alert System
- [ ] Badge merah/orange di menu Obat
- [ ] Tab chip [Semua][Aman][Menipis][Habis] di ObatPage
- [ ] Halaman `/stok-alert` (Owner only)
- [ ] Cetak thermal laporan stok alert

### Phase 3 — F2-D: Jadwal + Reminder
- [ ] Halaman `/jadwal-praktik` (Owner only)
- [ ] Jadwal kontrol pasien rutin
- [ ] Extend kalender kehadiran dengan layer jadwal
- [ ] Badge reminder di PasienDetailPage

### Phase 4 — F2-B: Patient Timeline
- [ ] Tab Timeline di PasienDetailPage
- [ ] Data sources: transaksi + kehadiran + kunjungan + catatan
- [ ] Filter by date range + jenis
- [ ] Summary statistik (nominal owner only, count untuk admin)
- [ ] Quick note feature

### Phase 5 — F2-A: Laporan Export
- [ ] Tab Harian + Cetak Thermal + Export CSV di LaporanPage
- [ ] Tab Bulanan + Export PDF/A4
- [ ] Top 5 obat terjual
- [ ] Bar chart fl_chart (sudah ada)

### Phase 6 — F2-E: Mini Akuntansi
- [ ] Tab Kas Masuk (dari transaksi existing)
- [ ] Tab Kas Keluar (dari tabel kas_keluar baru)
- [ ] Tab Rugi-Laba + grafik tren 6 bulan
- [ ] Tab Piutang (transaksi belum_lunas)
- [ ] Halaman `/laporan-akuntansi` (Owner only)

---

## 📋 F3, F4, F5, F6 — BELUM DIMULAI
(akan diisi setelah F2 selesai dan brainstorming F3 dilakukan)

---

## ⚙️ INFO TEKNIS PERMANEN
- **Supabase project ref:** `cdfklvbzbffqvhgifesk`
- **Branch kerja:** `latihan-plugin` → merge ke `master` setelah approve
- **Push repo:** https://github.com/faridsaifulrahman44/sin_she_jaya_abadi/
- **Test target:** 173 passed, 0 failed (jalankan `flutter test` setiap selesai task)
- **AppSymbols:** `lib/core/ui/app_symbols.dart` — gunakan `Icon(AppSymbols.xxx)` di seluruh halaman
- **Spec & Plan F2:** `docs/superpowers/specs/` dan `docs/superpowers/plans/`
- **Package baru:** `material_symbols_icons: ^4.2928.1`, `pdf`, `printing`, `csv`
- **Package dihapus:** `hugeicons`

## ⛔ GARIS MERAH PERMANEN
- Task 6 & 7: **WAJIB tampilkan SQL → tunggu "LANJUT" sebelum eksekusi**
- Jangan ubah RLS/RPC/migration tanpa izin eksplisit
- Jangan DELETE/DROP/TRUNCATE tanpa izin eksplisit
- Jangan ubah logika stok sembarangan
- Jangan tampilkan nominal/laporan ke role admin
- Owner only gate untuk semua fitur yang menampilkan nominal/uang

---
## 📝 CARA UPDATE FILE INI
Setiap task selesai, update:
1. Centang `[x]` task yang selesai + tulis commit hash
2. Update "Posisi Terakhir" di atas
3. Commit PROJECT_PROGRESS.md bersamaan dengan commit task