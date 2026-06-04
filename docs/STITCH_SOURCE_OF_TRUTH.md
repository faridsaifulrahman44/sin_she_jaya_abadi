# STITCH SOURCE OF TRUTH — Jaya Abadi Premium

> **Tanggal audit:** 2026-06-04
> **Auditor:** Claude (Sonnet 4.6) — sesi atas nama user faridsaifulrahman44
> **Proyek Stitch:** `stitch_duplicate_of_jaya_abadi_premium_redesign`
> **Branch aktif saat commit:** `latihan-plugin`
> **Total folder di Stitch:** 37 instance (15 KEEP screens + 1 design system + 1 teal variant + 18 IGNORE + 2 misc/unaccounted)

---

## 🟩 DAFTAR KEEP — Source of Truth (WAJIB dipakai saat implementasi)

Gunakan 16 entri ini sebagai **satu-satunya rujukan visual** saat membuat atau memperbarui kode di `lib/`. Jangan merujuk ke folder IGNORE untuk justifikasi desain apa pun.

| #  | Folder                                  | Fungsi / Layar                                                                              | Catatan Teknis                                                                              |
|----|-----------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| 1  | `login_premium`                         | Halaman login (mockup final Emil Kowalski-style)                                            | Acuan halaman login Flutter                                                                 |
| 2  | `operational_dashboard_owner_redux`     | Dashboard utama owner (versi redux)                                                         | Header biru + jam real-time + nominal penjualan                                             |
| 3  | `hub_inventaris_final`                  | Hub inventaris / etalase (final)                                                            | Final setelah iterasi `hub_inventaris_obat` dan `hub_inventaris_etalase_fix`                |
| 4  | `detail_inventaris_obat`                | Detail master obat                                                                          | Resolusi foto via `foto_key`                                                                |
| 5  | `form_master_obat`                      | Form tambah/edit master obat                                                                | Sumber kebenaran form obat                                                                  |
| 6  | `peringatan_stok_owner_only`            | Peringatan stok (owner-only)                                                                | **DILARANG** tampilkan ke role admin                                                        |
| 7  | `sinkronisasi_inventaris`               | Sinkronisasi stok audit                                                                     | Koreksi stok fisik vs sistem                                                                |
| 8  | `profil_pasien_crm_final`               | Profil pasien CRM (final)                                                                   | Pengganti `profil_pasien_crm`, `profil_pasien_revised`, `profil_pasien_no_phone`            |
| 9  | `rapid_pos_form_final`                  | **Form Transaksi / Kasir terbaru** → target `lib/pages/transaksi_form_page.dart`            | Pengganti 7 varian form transaksi lampau                                                    |
| 10 | `riwayat_transaksi_stok`                | Riwayat transaksi + stok                                                                    | Sumber kebenaran list riwayat                                                              |
| 11 | `antrean_cetak_final`                   | Antrean cetak (print queue)                                                                 | Final setelah `antrean_cetak_petugas`                                                       |
| 12 | `ringkasan_operasional_final`           | Ringkasan operasional                                                                       | Ringkasan harian untuk owner                                                                |
| 13 | `laporan_eksekutif_owner`               | Laporan eksekutif owner                                                                     | **DILARANG** tampilkan ke role admin                                                        |
| 14 | `struk_pembayaran_digital`              | Struk pembayaran digital                                                                    | Final — bukan `struk_pembayaran_custom`                                                     |
| 15 | `teal_clinical_intelligence`            | Design system variant (teal)                                                                | Acuan palet teal #008080 (DESIGN.md ada, screen.png mungkin belum di-render)                |
| 16 | `klinik_sin_she_jaya_abadi_design_system` | **Design system final** (Plus Jakarta Sans, radius 8/12/16/20, spacing 4/8/12/16/20/24)  | Sumber kebenaran token desain untuk `lib/core/design_system/app_tokens.dart`               |

### Alasan KEEP

- **Owner-only screen** (`peringatan_stok_owner_only`, `laporan_eksekutif_owner`) disimpan terpisah dari varian admin agar jelas batas aksesnya.
- **Form Transaksi** versi final (`rapid_pos_form_final`) dipilih karena konsolidasi 7 varian form lampau (lihat IGNORE) — `lib/pages/transaksi_form_page.dart` (1.478 baris) akan mengikuti mockup ini.
- **Design system** final (`klinik_sin_she_jaya_abadi_design_system`) tetap dipakai meskipun ada `teal_clinical_intelligence` sebagai variant — variant teal hanya untuk referensi palet, bukan token utama.

---

## 🟥 DAFTAR IGNORE — Aset Lampau (JANGAN dirujuk saat coding)

Folder-folder ini tetap ada di Stitch dan **tidak boleh dihapus** (sesuai instruksi eksplisit user), tetapi **abaikan dan jangan dipakai** sebagai rujukan desain saat menulis atau memperbarui kode.

| #  | Folder                              | Alasan Di-IGNORE                                                                                                  |
|----|-------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| 1  | `dashboard_utama_owner`             | Digantikan `operational_dashboard_owner_redux` (redux lebih final)                                                |
| 2  | `dashboard_utama_branded`           | Varian branded lama — bukan versi final                                                                           |
| 3  | `dashboard_utama_final`             | Varian final lama — tersingkron oleh `operational_dashboard_owner_redux`                                          |
| 4  | `hub_inventaris_obat`               | Iterasi lama sebelum `hub_inventaris_etalase_fix`                                                                 |
| 5  | `hub_inventaris_etalase_fix`        | Iterasi antara — tersingkron oleh `hub_inventaris_final`                                                          |
| 6  | `profil_pasien_crm`                 | Iterasi awal, digantikan `profil_pasien_revised`                                                                  |
| 7  | `profil_pasien_revised`             | Iterasi revisi, digantikan `profil_pasien_no_phone`                                                               |
| 8  | `profil_pasien_no_phone`            | Iterasi tanpa kolom phone — tersingkron oleh `profil_pasien_crm_final`                                            |
| 9  | `patient_crm_detail_insight_redux`  | Varian redux yang tidak dipakai — tidak ada di KEEP                                                               |
| 10 | `form_transaksi_petugas`            | Varian form untuk petugas (admin) — bukan final                                                                   |
| 11 | `form_transaksi_pos`                | Varian POS lama                                                                                                   |
| 12 | `form_transaksi_pos_final`          | Varian POS "final" lama — tersingkron oleh `rapid_pos_form_final`                                                 |
| 13 | `form_transaksi_simplified`         | Varian simplifikasi — bukan acuan                                                                                 |
| 14 | `rapid_pos_form_speed_optimized`   | Varian optimasi kecepatan — `rapid_pos_form_final` adalah sumber kebenaran                                        |
| 15 | `antrean_cetak_petugas`             | Varian untuk petugas (admin) — `antrean_cetak_final` adalah final                                                 |
| 16 | `laporan_operasional_updated`       | Varian updated lama — `laporan_eksekutif_owner` adalah final                                                      |
| 17 | `laporan_operasional_revised`       | Varian revisi — bukan acuan                                                                                       |
| 18 | `struk_pembayaran_custom`           | Varian custom — `struk_pembayaran_digital` adalah final                                                           |

### Alasan IGNORE

- **3 varian dashboard** → 1 final (`operational_dashboard_owner_redux`)
- **4 varian profil pasien** → 1 final (`profil_pasien_crm_final`)
- **6 varian form transaksi** → 1 final (`rapid_pos_form_final`) — varian terbanyak di IGNORE
- **2 varian hub inventaris** → 1 final (`hub_inventaris_final`)
- **2 varian laporan** → 1 final (`laporan_eksekutif_owner`)
- **2 varian antrean cetak** → 1 final (`antrean_cetak_final`)
- **2 varian struk** → 1 final (`struk_pembayaran_digital`)

**Total varian tersingkron:** 18 folder → tersisa 16 entitas final (KEEP).

---

## 📌 ATURAN OPERASIONAL UNTUK CLAUDE (SESI INI DAN SELANJUTNYA)

1. ❌ **DILARANG** menulis kode baru di `lib/` yang di-justify dari folder IGNORE.
2. ❌ **DILARANG** menyebut nama folder IGNORE di commit message, code comment, atau dokumentasi sebagai referensi desain.
3. ✅ KEEP adalah **satu-satunya rujukan visual** saat user meminta "lihat mockup X" atau "implement sesuai desain Y".
4. ✅ `rapid_pos_form_final` = Form Transaksi/Kasir = target implementasi `lib/pages/transaksi_form_page.dart`.
5. ✅ Token desain tetap dari `klinik_sin_she_jaya_abadi_design_system/DESIGN.md` dan `lib/core/design_system/app_tokens.dart`:
   - Palet teal `#008080`
   - Font: **Plus Jakarta Sans** (headline & body)
   - Radius: **8 / 12 / 16 / 20**
   - Spacing: **4 / 8 / 12 / 16 / 20 / 24**

---

## 🔒 FILE INI TIDAK BOLEH DIHAPUS

Dokumen ini adalah **sumber kebenaran** untuk alur kerja Stitch → Flutter. Menghapus atau memodifikasinya harus melalui diskusi eksplisit dengan user.

---

**Status:** ✅ Disetujui user faridsaifulrahman44, 2026-06-04
**Commit berikutnya:** siap di-commit ke branch `latihan-plugin`
