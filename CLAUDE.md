# CLAUDE.md — Panduan Kerja Claude Code
# Proyek: Klinik Sin She Jaya Abadi

## Tujuan file ini
File ini adalah **instruksi kerja untuk Claude Code**, bukan dokumen desain.  
Gunakan file ini untuk memahami cara kerja, batasan, urutan baca, dan aturan aman saat mengubah kode.

## Urutan baca saat sesi baru
Baca dalam urutan ini:

1. `docs/PROJECT_PROGRESS.md` — status terakhir dan langkah berikutnya
2. `STITCH_SOURCE_OF_TRUTH.md` — rujukan visual final
3. `design.md` — spesifikasi teknis arsitektur dan alur data
4. Proyek Stitch (eksternal, di luar repo): `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/` — akses via filesystem, **bukan** lewat MCP (Stitch MCP sudah nonaktif per 2026-06-06)

## Prinsip utama
- Jangan mengarang konteks dari memori jika sudah ada di dokumen.
- Jangan menulis ulang informasi desain yang sudah ada di `design.md`.
- Jangan menulis status progres di file desain.
- Jangan menyalin referensi visual dari Stitch ke file lain kecuali sebagai pointer singkat.
- Kalau ada konflik antar dokumen, ikuti hierarki: `PROJECT_PROGRESS.md` → `STITCH_SOURCE_OF_TRUTH.md` → `design.md`.

## Konteks proyek
Aplikasi Flutter untuk operasional Klinik Sin She Jaya Abadi.
Target utama: Android APK untuk dipakai staf klinik di lapangan.
Backend: Supabase.
Gaya kerja: perubahan kecil, terukur, dan aman untuk produksi.

## Lokasi aset Stitch (eksternal)
- Proyek Stitch `stitch_duplicate_of_jaya_abadi_premium_redesign` berada di filesystem lokal, di LUAR repo ini: `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/`
- Stitch MCP NONAKTIF (per 2026-06-06). Akses ke proyek Stitch hanya lewat filesystem biasa (Read/Glob/Bash `ls`), BUKAN lewat MCP tools.
- Daftar KEEP/IGNORE dan rujukan visual final tetap di `docs/STITCH_SOURCE_OF_TRUTH.md`.

## Standar skill visual/UX (permanen, TETAP WAJIB)
Untuk setiap eksekusi besar yang menyentuh visual/UX/typography/color/layout/motion/a11y/design system, **WAJIB** konsultasi 2 skill:
- `impeccable` — `.agents/skills/impeccable/` + `.claude/skills/impeccable/`. Severity tagging P0/P1/P2, root-cause analysis, drift detection, polish checklist (22 dimensi). Framework audit + craft.
- `ui-ux-pro-max` — `.agents/skills/ui-ux-pro-max/`. Prescriptive reference: 50+ style, 161 palette, 161 product type, 99 UX guideline, 25 chart, 10 stack (termasuk Flutter). Library style/token/font.

Aturan operasional:
- Severity P0/P1/P2 selalu mengikuti framework `impeccable/audit.md` & `critique.md`.
- Style, palette, font, token, a11y baseline selalu mengecek `ui-ux-pro-max` (cocokkan ke product type Healthcare / Clinic POS).
- Untuk project ini: product type = Healthcare POS. Style default = Restrained color strategy + Material 3 + Plus Jakarta Sans + 4dp base + 12-16dp premium-soft radius + 48dp touch target.
- Tidak boleh pakai style generik (cream-warm, Inter default, purple-blue gradient). Ikuti filter anti-generic dari impeccable.
- Refactor besar tanpa widget test **tetap wajib** tambah minimal 1 widget test per halaman KEEP prioritas. Untuk refactor kecil (token migration, hardcoded value replace) yang tidak menambah behavior baru, test existing dianggap cukup.

## Role & akses
- Role dibaca lewat `AdminSession`.
- Jangan hardcode role.
- Jangan menampilkan nominal/laporan ke admin/petugas.
- Transaksi tipe Obat harus `id_pasien = null`.
- Transaksi tipe Praktek harus punya `id_pasien`.

## Aturan kerja git
- Branch utama/stabil: `master`.
- Untuk perubahan besar atau yang menyentuh DB / auth / stok / transaksi, kerja di branch fitur dulu.
- Untuk perubahan UI kecil yang tidak menyentuh logika sensitif, boleh tetap di branch aktif jika aman.
- Sebelum ubah file besar, audit dulu file terkait dan cari overlap.
- **Commit policy (direlaksasi 2026-06-06):** 1 logical unit = 1 commit. Definisi logical unit: 1 halaman KEEP yang selesai diterapkan, atau 1 batch refactor token di beberapa file kecil, atau 1 audit + fix. Bukan 1 file = 1 commit (terlalu kecil, noisy) dan bukan 1 fase = 1 commit (terlalu besar, susah review). Pesan commit format: `scope(F0.x): ringkasan perubahan`.

## Aturan database
### Boleh tanpa izin
- SELECT via MCP / query read-only
- Eksplorasi filesystem proyek (`ls`, `find`, `grep`, `read`) — termasuk baca folder Stitch eksternal di `D:/stitch/...`
- Baca dokumentasi, token, helper, dan file `.md` di project

### Tidak boleh tanpa izin eksplisit
- INSERT / UPDATE ke data produksi
- DELETE / DROP / TRUNCATE
- ALTER TABLE / CREATE TABLE
- ubah migration, trigger, RPC, RLS, schema

Jika user meminta operasi tulis data, tampilkan SQL final dulu dan tunggu izin eksplisit.

## Batas eksplorasi vs eksekusi
- **Eksplorasi (tanpa izin):** baca file, baca folder Stitch eksternal, baca tabel lewat SELECT, identifikasi raw value yang perlu dimigrasi
- **Eksekusi kecil (boleh langsung):** rename `const SizedBox(height: 24)` jadi `AppSpacing.xxl`, ganti `BorderRadius.circular(8)` jadi `AppRadius.sm`, refactor widget privat dalam 1 file
- **Eksekusi besar (butuh izin):** rename helper antar-file, hapus file, ubah signature fungsi publik, refactor halaman transaksi
- **Threshold "besar" revisi (2026-06-06):** menyentuh **logic bisnis** (stok/auth/role/printer/DB), atau **menghapus** file/function publik. Bukan sekadar "menyentuh ≥3 file sekaligus" — itu sudah biasa untuk 1 halaman KEEP.
- **Eksekusi menengah (boleh langsung untuk penerapan Stitch KEEP):** refactor halaman 1 KEEP folder (mis. `login_premium`, `profil_pasien_crm_final`), tambah token baru di `app_tokens.dart` sesuai KEEP #16, extend `AppTextStyles` untuk scale ≥ 1.25, override font family di ThemeData, set tap target ≥ 48dp, ganti `Icons.*` ke `AppSymbols.*`. Untuk refactor 1 halaman KEEP, tidak butuh izin per-file.
- **Eksekusi besar (butuh izin):** rename helper antar-file yang dipakai di ≥ 5 file, hapus file, ubah signature fungsi publik, refactor halaman `transaksi_form_page.dart` (1595 LOC), ubah schema/auth/stok/role/printer.

## Aturan coding
- Jangan refactor besar tanpa alasan yang jelas.
- Jaga perubahan seminimal mungkin.
- Hindari duplikasi logika antar file.
- Jangan menambah kompleksitas ke `transaksi_form_page.dart` tanpa alasan kuat.
- Gunakan helper/token yang sudah ada.
- Kalau ada file besar, cari titik edit paling sempit dulu.
- **Fase redesign Stitch KEEP (F0.5+, mulai 2026-06-06):** "Perubahan besar" yang punya justifikasi visual dari `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/<folder-KEEP>/` **dianggap punya alasan yang jelas**. Boleh refactor layout, radius, typography, motion, icon style, dan struktur widget selama sesuai KEEP. Yang tetap dijaga: logic bisnis, repository signature, schema DB.

## Design system & UI
- Ikuti token yang sudah ada di codebase.
- Jangan mendefinisikan ulang token visual di file kerja kalau sudah tersedia di `lib/core/design_system/`.
- Untuk referensi visual final, lihat `STITCH_SOURCE_OF_TRUTH.md`.
- Untuk spesifikasi teknis, lihat `design.md`.

## Testing
Setelah perubahan:
- jalankan `flutter analyze`
- jalankan `flutter test` bila perubahan menyentuh logic atau widget penting

Jika test failure terlihat pre-existing, tulis dengan jelas bahwa itu bukan regresi baru.

## Format laporan akhir
Saat selesai, laporkan dengan format ringkas:

- File yang diubah
- File yang sengaja tidak diubah
- Hasil analyze / test
- Risiko atau isu yang perlu diketahui

## Larangan
- Jangan menulis dua kali informasi yang sama di dokumen berbeda.
- Jangan menjadikan `PROJECT_PROGRESS.md` sebagai dokumen arsitektur.
- Jangan menjadikan `STITCH_SOURCE_OF_TRUTH.md` sebagai dokumen implementasi.
- Jangan menjadikan `design.md` sebagai catatan status kerja.

## Checklist sebelum mengubah kode
1. Baca `PROJECT_PROGRESS.md`
2. Cek apakah ada overlap di `design.md`
3. Cek apakah desain visual final sudah ada di `STITCH_SOURCE_OF_TRUTH.md`
4. Ubah kode sesedikit mungkin
5. Laporkan hasil dengan jelas
