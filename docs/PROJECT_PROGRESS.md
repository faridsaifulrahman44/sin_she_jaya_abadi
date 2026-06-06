# 🏥 Sin She Jaya Abadi — Master Progress Tracker

## Tujuan file ini
File ini hanya untuk **status kerja terbaru**: apa yang sudah selesai, apa yang sedang dikerjakan, dan langkah berikutnya.

## Posisi terakhir
- **Branch aktif:** `latihan-plugin`
- **Tanggal update:** 2026-06-06
- **Fase aktif:** F0.4 — refactor 3 file target berdasarkan step1-token-map.md
- **Next action:** eksekusi refactor operasional_dashboard_page.dart → transaksi_form_page.dart → riwayat_transaksi_page.dart. Satu file = satu commit, dengan `flutter analyze` + `flutter test` per file.
- **Aset Stitch:** `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/` (eksternal, di luar repo). Stitch MCP nonaktif per 2026-06-06.
- **Standar skill visual/UX:** setiap eksekusi besar yang menyentuh visual/UX WAJIB konsultasi skill `impeccable` (P0/P1/P2) dan `ui-ux-pro-max` (style/palette/token). Aturan tercatat permanen di `CLAUDE.md`.

## Ringkasan fase selesai
### Fase 0 — Reset & Clean Slate (2026-06-06)
- **F0.1 — Stitch audit (16 KEEP + 18 IGNORE)**
  - Verifikasi folder Stitch fisik di `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/`
  - Semua 16 KEEP folder hadir, 18 IGNORE folder sudah hilang dari Stitch
  - 3 file tak terdata dicatat: `complete_redesign_proposal_strategy.md`, `design.md`, `logo_sinshe_versi_png.png`
- **F0.2 — Source of truth update**
  - `docs/STITCH_SOURCE_OF_TRUTH.md` diperbarui dengan path baru + status MCP nonaktif
  - Tabel IGNORE ditandai sebagai "daftar historis"
  - Tabel tambahan untuk 3 file di luar KEEP/IGNORE
- **F0.3 — Token map (step1-token-map.md)**
  - 3 screen prioritas: operasional dashboard, transaksi form, riwayat transaksi
  - Tabel token lengkap: palette, typography, radius, spacing, shadow
  - Disclaimer sumber: mockup_v7 hanya untuk angka token, layout 100% dari Stitch KEEP
- **F0.4 — Refactor 3 file target (in progress 2026-06-06)**
  - Target: operasional_dashboard_page.dart, transaksi_form_page.dart, riwayat_transaksi_page.dart
  - Prinsip: ganti raw value → token per step1-token-map.md, satu file = satu commit
  - Sebelum F0.4: working tree F0.3 (commit `cdfcaf1`) dan skill assets (commit `af44882`) sudah di-commit

## Fase historis (F3–F12.6)
> **Catatan:** Fase-fase di bawah ini sudah selesai sebelum reset F0. Disimpan di sini sebagai arsip, bukan sebagai target kerja. Detail implementasi tetap di git history (commit sebelum F0).

| Fase   | Nama                            | Status          |
|--------|---------------------------------|-----------------|
| F3     | Akun Page                       | Selesai (historis) |
| F4     | Riwayat Transaksi               | Selesai (historis) |
| F5     | Obat Page Tab Strip             | Selesai (historis) |
| F6     | Login Page Redesign             | Selesai (historis) |
| F7     | Receipt BW Design               | Selesai (historis) |
| F8     | Laporan Owner                   | Selesai (historis) |
| F9     | Print Queue                     | Selesai (historis) |
| F10    | Transaksi Etalase Filter        | Selesai (historis) |
| F11    | AppBottomNav Integration        | Selesai (historis) |
| F12.3  | Foto Obat Upload Flow           | Selesai (historis) |
| F12.4  | Sinkronisasi Stok Enhancement   | Selesai (historis) |
| F12.5  | Design Token Migration (parsial)| Selesai (historis) |
| F12.6  | Sisa Token Migration (29 file)  | Di-cancel (historis) — diputuskan 2026-06-06, sisa migrasi token ke-29 file dianggap lampau, langsung lanjut F0.4. Tidak ada kode F12.6 yang perlu di-trace. |

## Pekerjaan berikutnya
- **F0.4** — Eksekusi refactor 3 file besar berdasarkan `docs/superpowers/specs/step1-token-map.md`:
  1. Operasional dashboard
  2. Transaksi form
  3. Riwayat transaksi
- Jaga agar perubahan tetap kecil dan aman (satu file = satu commit)
- Setelah F0.4 selesai, tentukan F0.5 (cleanup PROJECT_PROGRESS.md lanjutan? atau langsung F1?)

## Known issues / catatan
- Beberapa file besar mungkin masih memakai raw values
- Beberapa issue test lama bisa saja pre-existing
- Jangan ubah schema / RLS / RPC tanpa izin eksplisit
- `docs/STITCH_SOURCE_OF_TRUTH.md` adalah satu-satunya rujukan visual; folder IGNORE tidak boleh dipakai sebagai justifikasi

## Yang sengaja tidak ditaruh di sini
- Arsitektur detail
- Model data lengkap
- Routing lengkap
- Token desain lengkap
- Penjelasan Stitch

File itu ada di dokumen lain.

## Catatan operasional (2026-06-06)
- Stitch MCP NONAKTIF. Proyek Stitch `stitch_duplicate_of_jaya_abadi_premium_redesign` diakses lewat filesystem di `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/`, di luar repo ini.
- Rujukan visual final (KEEP/IGNORE) tetap di `docs/STITCH_SOURCE_OF_TRUTH.md`. Folder IGNORE yang tercantum di sana adalah daftar historis; per 2026-06-06 folder-folder IGNORE sudah tidak ada lagi di lokasi Stitch.
- `.mcp.json` saat ini hanya berisi `supabase`. Tidak ada MCP server Stitch yang perlu di-uninstall dari konfigurasi.
