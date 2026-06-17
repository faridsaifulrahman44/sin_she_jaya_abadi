# STITCH SOURCE OF TRUTH — Jaya Abadi Premium

> **Tanggal audit terakhir:** 2026-06-06
> **Auditor:** Claude (Sonnet 4.6) — sesi atas nama user faridsaifulrahman44
> **Proyek Stitch:** `stitch_duplicate_of_jaya_abadi_premium_redesign`
> **Proyek Stitch (via MCP):** `4910840135092048917` (Duplicate of Jaya Abadi Premium Redesign)
> **Branch aktif saat commit:** `latihan-plugin`
> **Status Stitch MCP:** AKTIF (per 2026-06-07). Akses ke proyek Stitch via MCP tools (`mcp__stitch__*`).
> **MCP Endpoint:** HTTP `https://stitch.googleapis.com/mcp` + header `X-Goog-Api-Key`
> **Cara akses:** `mcp__stitch__list_screens(projectId: "4910840135092048917")` → `mcp__stitch__get_screen(projectId, screenId)` → screenshot PNG

## Peran file ini
File ini adalah **rujukan visual final**. Gunakan untuk memilih desain mana yang boleh dipakai saat implementasi UI.

Aturan:
- KEEP = satu-satunya referensi visual final
- IGNORE = jangan dijadikan alasan desain
- File ini **bukan** tempat menulis progress, arsitektur, atau status implementasi
- Daftar IGNORE di bawah ini adalah **daftar historis** dari audit 2026-06-04; folder-folder IGNORE sudah tidak ada lagi di proyek Stitch per 2026-06-06 (lihat catatan pasca-tabel)

---

## 🟩 DAFTAR KEEP — Source of Truth
Gunakan entri KEEP ini sebagai rujukan visual saat membuat atau memperbarui kode di `lib/`. Jangan merujuk ke folder IGNORE untuk justifikasi desain apa pun.

| #  | Folder                                  | Fungsi / Layar                                                                              | Catatan Teknis                                                                              |
|----|-----------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| 1  | `login_premium`                         | Halaman login                                                                              | Acuan halaman login Flutter                                                                 |
| 2  | `operational_dashboard_owner_redux`     | Dashboard utama owner (versi redux)                                                         | Header biru + jam real-time + nominal penjualan                                             |
| 3  | `hub_inventaris_final`                  | Hub inventaris / etalase (final)                                                            | Final setelah iterasi sebelumnya                                                           |
| 4  | `detail_inventaris_obat`                | Detail master obat                                                                          | Resolusi foto via `foto_key`                                                                |
| 5  | `form_master_obat`                      | Form tambah/edit master obat                                                                | Sumber kebenaran form obat                                                                  |
| 6  | `peringatan_stok_owner_only`            | Peringatan stok (owner-only)                                                                | Dilarang tampilkan ke role admin                                                            |
| 7  | `sinkronisasi_inventaris`               | Sinkronisasi stok audit                                                                     | Koreksi stok fisik vs sistem                                                                |
| 8  | `profil_pasien_crm_final`               | Profil pasien CRM (final)                                                                   | Pengganti varian sebelumnya                                                                 |
| 9  | `rapid_pos_form_final`                  | Form transaksi / kasir terbaru                                                              | Target `lib/pages/transaksi_form_page.dart`                                                 |
| 10 | `riwayat_transaksi_stok`                | Riwayat transaksi + stok                                                                    | Sumber kebenaran list riwayat                                                               |
| 11 | `antrean_cetak_final`                   | Antrean cetak (print queue)                                                                 | Final setelah varian sebelumnya                                                             |
| 12 | `ringkasan_operasional_final`           | Ringkasan operasional                                                                       | Ringkasan harian untuk owner                                                                |
| 13 | `laporan_eksekutif_owner`               | Laporan eksekutif owner                                                                     | Dilarang tampilkan ke role admin                                                            |
| 14 | `struk_pembayaran_digital`              | Struk pembayaran digital                                                                    | Final, bukan varian custom                                                                  |
| 15 | `teal_clinical_intelligence`            | Design system variant (teal)                                                                | Acuan palet teal `#008080`                                                                   |
| 16 | `klinik_sin_she_jaya_abadi_design_system` | Design system final                                                                         | Token desain final: Plus Jakarta Sans, radius 8/12/16/20, spacing 4/8/12/16/20/24          |

## 🟥 DAFTAR IGNORE — Aset Lampau
Daftar ini adalah **referensi historis** dari audit 2026-06-04. Per 2026-06-06, semua folder IGNORE sudah **tidak ada lagi** di lokasi proyek Stitch `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/`. Tetap dicantumkan di sini agar jelas varian mana yang ditolak dan tidak boleh dimunculkan lagi sebagai justifikasi desain.

| #  | Folder                              | Alasan Di-IGNORE                                                                          | Status MCP |
|----|-------------------------------------|-------------------------------------------------------------------------------------------|------------|
| 1  | `dashboard_utama_owner`             | Digantikan `operational_dashboard_owner_redux`                                            | screen `719fdf0c` (Laporan Operasional) |
| 2  | `dashboard_utama_branded`           | Varian branded lama                                                                      | screen `674ab065` (Dashboard Branded) |
| 3  | `dashboard_utama_final`             | Varian final lama                                                                        | screen `ff5eeb01` (Dashboard Final) |
| 4  | `hub_inventaris_obat`               | Iterasi lama                                                                            | screen `5b95f312` (Hub Inventaris Obat) |
| 5  | `hub_inventaris_etalase_fix`        | Iterasi antara                                                                          | screen `b2a2751a` (Hub Inventaris Etalase Fix) |
| 6  | `profil_pasien_crm`                 | Iterasi awal                                                                            | screen `95147233` (Laporan Ops Updated) |
| 7  | `profil_pasien_revised`             | Iterasi revisi                                                                          | screen `806a3e93` (Profil Pasien Revised) |
| 8  | `profil_pasien_no_phone`            | Iterasi tanpa kolom phone                                                               | screen `304bdbf4` (Profil Pasien No Phone) |
| 9  | `patient_crm_detail_insight_redux`  | Varian redux yang tidak dipakai                                                         | screen `303bc641` (Patient CRM Detail Redux) |
| 10 | `form_transaksi_petugas`            | Varian untuk petugas                                                                   | screen `a6e3ad41` (Form Transaksi Petugas) |
| 11 | `form_transaksi_pos`                | Varian POS lama                                                                        | screen `52783e63` (Struk Custom) |
| 12 | `form_transaksi_pos_final`          | Varian POS lama yang sudah tergantikan                                                  | screen `2e132e51` (Form Transaksi POS Final) |
| 13 | `form_transaksi_simplified`         | Varian simplifikasi                                                                     | screen `e0da684d` (Form Transaksi Simplified) |
| 14 | `rapid_pos_form_speed_optimized`   | Varian optimasi kecepatan                                                               | screen `9d745305` (Rapid POS Speed Optimized) |
| 15 | `antrean_cetak_petugas`             | Varian untuk petugas                                                                   | screen `21831574` (Antrean Cetak Petugas) |
| 16 | `laporan_operasional_updated`       | Varian updated lama                                                                     | screen `95147233` (Laporan Ops Updated) |
| 17 | `laporan_operasional_revised`       | Varian revisi                                                                          | screen `39315133` (Laporan Operasional Revised) |
| 18 | `struk_pembayaran_custom`           | Varian custom                                                                           | screen `52783e63` (Struk Custom) |

## 🟦 File lain di proyek Stitch (di luar KEEP/IGNORE)
Item-item ini bisa diakses via MCP Stitch — bukan dari filesystem lokal.

| #  | Nama                                       | Jenis         | Keterangan                                                                                  |
|----|--------------------------------------------|---------------|---------------------------------------------------------------------------------------------|
| A  | `complete_redesign_proposal_strategy.md`  | Dokumen       | Dokumen strategi proposal redesign. Bukan rujukan visual; boleh dibaca untuk konteks saja.   |
| B  | `design.md`                                | Dokumen       | Catatan desain umum dari sesi Stitch. Bukan rujukan visual final; token tetap di KEEP #16.   |
| C  | `logo_sinshe_versi_png.png`                | Aset gambar   | Logo klinik varian PNG. Aset pendukung, bukan screen.                                       |

## Aturan operasional
1. Dilarang menulis kode baru di `lib/` yang dijustifikasi dari folder IGNORE.
2. Dilarang menyebut folder IGNORE sebagai referensi desain.
3. KEEP adalah satu-satunya rujukan visual saat user meminta implementasi desain.
4. `rapid_pos_form_final` adalah form transaksi/kasir yang dipakai sebagai acuan.
5. Token desain tetap dari design system final; variant teal hanya referensi palet.

## Standar audit visual/UX
Setiap eksekusi besar yang menyentuh visual/UX/typography/color/layout/motion/a11y/design system WAJIB mengikuti 2 skill:
- **`impeccable`** (`.agents/skills/impeccable/`): severity tagging P0/P1/P2, root-cause analysis, drift detection, polish checklist.
- **`ui-ux-pro-max`** (`.agents/skills/ui-ux-pro-max/`): prescriptive style, palette, font, token reference.

Untuk project ini: product type = **Healthcare / Clinic POS**. Style default = **Restrained** (Material 3, Medical Teal `#006565`/`#008080`, Plus Jakarta Sans, 4dp base, 12-16dp premium-soft radius, 48dp touch target). Dilarang style generik (cream-warm, Inter default, purple-blue gradient).

## Penutup
Dokumen ini sengaja dibuat spesifik dan disiplin agar tidak bercampur dengan progress atau arsitektur teknis.
