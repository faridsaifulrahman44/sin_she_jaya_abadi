# 🏥 Sin She Jaya Abadi — Master Progress Tracker

## Tujuan file ini
File ini hanya untuk **status kerja terbaru**: apa yang sudah selesai, apa yang sedang dikerjakan, dan langkah berikutnya.

## Posisi terakhir
- **Branch aktif:** `latihan-plugin`
- **Tanggal update:** 2026-06-06
- **Fase aktif:** F0.5 — redesign halaman Flutter mengikuti Stitch KEEP (16 folder di `STITCH_SOURCE_OF_TRUTH.md`)
- **Fase sebelumnya (selesai):** F0.4 — token migration selesai di 4 commit (`104cdda` dashboard, `945eee1` transaksi-form, `14cd20d` dashboard cleanup, `1e3dee2` riwayat). 1 raw `BorderRadius.circular(10)` residual di `transaksi_form_page.dart:1556` terdokumentasi sebagai pengecualian inline (tidak ada token matching, menjaga konsistensi visual chip).
- **Next action:** pilih 1 halaman KEEP prioritas, terapkan visual + behavior sesuai Stitch. 1 logical unit = 1 commit. Konsultasi skill `impeccable` + `ui-ux-pro-max` untuk setiap halaman.
- **Aset Stitch:** `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/` (eksternal, di luar repo). Stitch MCP nonaktif per 2026-06-06.
- **Standar skill visual/UX:** setiap eksekusi besar yang menyentuh visual/UX **WAJIB** konsultasi skill `impeccable` (P0/P1/P2) dan `ui-ux-pro-max` (style/palette/token). Aturan tercatat permanen di `CLAUDE.md`. **Tidak direlaksasi** — skill consultation tetap wajib.
- **Relaksasi rules (2026-06-06):** untuk fase F0.5 redesign, aturan md yang sebelumnya kaku (token lock di step1-token-map.md, "zero hardcoded" di design-system-establish.md, "1 file = 1 commit" di CLAUDE.md, "P0 blocker" di cluster-a audit) sudah dilonggarkan. Detail di file md masing-masing. Yang **tetap ketat:** role guard (Owner/Admin), schema/RLS/RPC, logika stok/auth/printer, INSERT butuh SQL dulu.

## Ringkasan fase selesai
### Fase historis (F3–F12.6)
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
- **F0.4 — Refactor 3 file target (Selesai 2026-06-06)**
  - Target: `dashboard_page.dart` (= operasional dashboard), `transaksi_form_page.dart`, `riwayat_transaksi_page.dart`
  - 4 commit: `104cdda` dashboard, `945eee1` transaksi-form, `14cd20d` dashboard cleanup, `1e3dee2` riwayat
  - Hasil: 0 raw `Color(0xFF...)`, 0 raw `SizedBox`, 1 raw `BorderRadius.circular(10)` (terdokumentasi), 9 raw `fontSize` off-grid (12.5/13/14/17) — belum di-token-kan
  - Catatan: `operasional_dashboard_page.dart` di step1-token-map.md ternyata adalah `dashboard_page.dart` (alias)
- **F0.5 — Redesign halaman KEEP (dimulai 2026-06-06)**
  - 16 KEEP folder Stitch jadi target redesign visual
  - Prinsip: terapkan 1 halaman = 1 logical unit = 1 commit
  - Skill consultation tetap WAJIB (impeccable + ui-ux-pro-max)
  - Token boleh di-extend dari KEEP #16 DESIGN.md (40+ Material 3 token)
  - Halaman prioritas (urutan saran, bukan strict): `login_premium` → `operational_dashboard_owner_redux` → `hub_inventaris_final` → `profil_pasien_crm_final` → `rapid_pos_form_final` → `riwayat_transaksi_stok` → `antrean_cetak_final` → `laporan_eksekutif_owner` → `struk_pembayaran_digital` → `form_master_obat` → `detail_inventaris_obat` → `peringatan_stok_owner_only` → `sinkronisasi_inventaris` → `ringkasan_operasional_final` → `teal_clinical_intelligence` (design system variant)

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
- **F0.5** — Pilih 1 halaman KEEP, terapkan redesign visual + behavior sesuai Stitch. Konsultasi skill `impeccable` + `ui-ux-pro-max` dulu.
- **Backend prerequisites (cek dulu sebelum redesign halaman yang butuh data baru):**
  - `login_premium` — tidak butuh backend
  - `operational_dashboard_owner_redux` — summary cards sudah ada, mungkin perlu widget test
  - `hub_inventaris_final` — list + filter, sudah ada di `obat_hub_page`
  - `profil_pasien_crm_final` — detail pasien + tab, perlu cek apakah layout sudah sesuai
  - `rapid_pos_form_final` — form transaksi (cluster A, perlu effort besar)
  - `riwayat_transaksi_stok` — list + tab, sudah ada di `riwayat_transaksi_page`
  - `antrean_cetak_final` — print queue (perlu cek apakah ada)
  - `laporan_eksekutif_owner` — owner-only, perlu cek apakah sudah ada
  - `struk_pembayaran_digital` — receipt (BW per keputusan F7)
  - `form_master_obat` — form obat (perlu cek layout)
  - `detail_inventaris_obat` — detail obat (perlu cek layout)
  - `peringatan_stok_owner_only` — owner-only, perlu cek
  - `sinkronisasi_inventaris` — sinkronisasi stok (perlu cek)
  - `ringkasan_operasional_final` — ringkasan harian owner
  - `teal_clinical_intelligence` — variant palet (referensi saja)
- **Setelah F0.5 halaman pertama selesai:** tentukan halaman KEEP berikutnya, atau move ke F1 (sesuai master plan lama).
- **Known issues yang harus dijaga:**
  - 9 raw `fontSize` off-grid (12.5/13/14/17) di 3 file target F0.4 — bisa di-handle di F0.5 atau tetap
  - 1 raw `BorderRadius.circular(10)` di `transaksi_form_page.dart:1556` — terdokumentasi

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
