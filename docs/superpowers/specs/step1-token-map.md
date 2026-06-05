# Step 1 — Token Map (F12.6)

> **Tanggal:** 2026-06-06
> **Sesi:** ulang dari F12.5 token migration
> **Tujuan:** pastikan implementasi Flutter (KEEP Stitch) benar-benar pakai token yang sama dengan mockup_v7.html

## 0. Disclaimer sumber token numerik
File `mockup/mockup_v7.html` dan `mockup/styles.css` dipakai di step ini **hanya untuk membaca angka token** (hex, radius, fontSize, fontWeight, shadow). 

**Mockup_v7 BUKAN rujukan visual.** Rujukan visual 100% adalah folder Stitch KEEP yang tercantum di `docs/STITCH_SOURCE_OF_TRUTH.md` (16 folder KEEP, terutama `klinik_sin_she_jaya_abadi_design_system` sebagai acuan token final).

Alasan saya sentuh mockup_v7:
- Folder Stitch KEEP berisi gambar (PNG/visual), bukan CSS dengan nilai numerik yang bisa di-grep.
- mockup_v7 kebetulan punya nilai hex/radius yang konsisten dengan palet Stitch KEEP.
- mockup_v7 dipakai **cuma untuk angka**, dan angka itu akan saya cocokkan dengan folder Stitch KEEP kalau muncul ketidakcocokan.

Artinya:
- **Layout, hierarki, komposisi, copywriting, ikon, alur** → semua ke folder Stitch KEEP.
- **Nilai token (hex, radius, fontSize, fontWeight, shadow)** → boleh dari mockup_v7 selama konsisten dengan KEEP #16.

## 1. Tiga screen prioritas (F12.6)
Urutan eksekusi step 1, dipilih karena paling banyak raw value di file Dart:

| # | Halaman Flutter                              | Mockup rujukan (KEEP Stitch)              |
|---|----------------------------------------------|------------------------------------------|
| 1 | `lib/pages/operasional_dashboard_page.dart`  | `operational_dashboard_owner_redux`      |
| 2 | `lib/pages/transaksi_form_page.dart`         | `rapid_pos_form_final`                   |
| 3 | `lib/pages/riwayat_transaksi_page.dart`      | `riwayat_transaksi_stok`                 |

## 2. Palette (mockup_v7.html + styles.css)

| Token mockup | Hex       | Token Dart (`core/design_system/`) |
|--------------|-----------|-----------------------------------|
| `--teal`         | `#00897B` | `AppColors.primary`               |
| `--teal-dark`    | `#00695C` | `AppColors.primaryDark`           |
| `--teal-light`   | `#4DB6AC` | `AppColors.primaryLight`          |
| `--blue-header`  | `#1565C0` | `AppColors.headerBlue`            |
| `--blue-header-dark` | `#0D47A1` | `AppColors.headerBlueDark`    |
| `--coral`        | `#FF7043` | `AppColors.accentCoral`           |
| `--amber`        | `#FFB300` | `AppColors.accentAmber`           |
| `--green-accent` | `#26A69A` | `AppColors.accentGreen`           |
| `--surface`      | `#F5F7FA` | `AppColors.surface`               |
| `--card`         | `#FFFFFF` | `AppColors.card`                  |
| `--danger`       | `#EF5350` | `AppColors.danger`                |
| `--warning`      | `#FF9800` | `AppColors.warning`               |
| `--success`      | `#66BB6A` | `AppColors.success`               |
| `--text-primary` | `#1A1A2E` | `AppColors.textPrimary`           |
| `--text-secondary` | `#6B7280` | `AppColors.textSecondary`     |
| `--text-muted`   | `#9CA3AF` | `AppColors.textMuted`             |
| `--border`       | `#E5E7EB` | `AppColors.border`                |

> **Aturan:** setiap raw hex di tiga file target **harus** diganti dengan `AppColors.*`. Dilarang tambah hex baru di luar tabel ini.

## 3. Typography (Plus Jakarta Sans)

| Style mockup       | size / weight | Token Dart |
|--------------------|---------------|------------|
| Display amount     | 22px / 800    | `AppTextStyles.amountLg`  |
| Halaman title      | 18px / 700    | `AppTextStyles.titleLg`   |
| Subtitle           | 14px / 700    | `AppTextStyles.titleMd`   |
| Body / list item   | 13px / 600    | `AppTextStyles.bodyMd`    |
| Caption            | 11px / 600    | `AppTextStyles.caption`   |
| Tiny badge         | 9–10px / 700  | `AppTextStyles.badge`     |

> **Aturan:** family font tetap `Plus Jakarta Sans`; fallback `-apple-system, sans-serif`. Dilarang hardcode `'Roboto'` atau family lain.

## 4. Radius & spacing

| Token mockup | Value | Token Dart |
|--------------|-------|------------|
| `--radius-sm`   | 8px   | `AppRadius.sm`  |
| `--radius-md`   | 12px  | `AppRadius.md`  |
| `--radius-lg`   | 16px  | `AppRadius.lg`  |
| `--radius-xl`   | 20px  | `AppRadius.xl`  |
| `--radius-full` | 9999px | `AppRadius.full` |
| spacing scale   | 4 / 8 / 12 / 16 / 20 / 24 | `AppSpacing.xs..xl` |

## 5. Shadow

| Token mockup  | Value                            | Token Dart       |
|---------------|----------------------------------|------------------|
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.08)`     | `AppShadows.sm`  |
| `--shadow-md` | `0 4px 12px rgba(0,0,0,0.1)`     | `AppShadows.md`  |
| `--shadow-lg` | `0 8px 24px rgba(0,0,0,0.12)`    | `AppShadows.lg`  |

## 6. Cara kerja refactor (prinsip minim)
1. Buka salah satu dari 3 file target.
2. Cari baris yang pakai hex / radius / fontSize / fontWeight secara literal.
3. Ganti ke token di tabel di atas. **Jangan ubah logika** atau struktur widget.
4. Jalankan `flutter analyze` dan `flutter test` per file.
5. Setelah ketiganya lulus, commit per file.

## 7. Yang tidak boleh dilakukan
- Jangan tambah token baru tanpa izin (sesuai aturan PROJECT_PROGRESS.md).
- Jangan ubah logika stok / auth / role / printer.
- Jangan ubah schema / RLS / RPC.
- Jangan edit file di luar 3 target tanpa izin eksplisit.

## 8. Lokasi token Dart saat ini
- `lib/core/design_system/app_colors.dart`
- `lib/core/design_system/app_text_styles.dart`
- `lib/core/design_system/app_radius.dart`
- `lib/core/design_system/app_spacing.dart`
- `lib/core/design_system/app_shadows.dart`

(atau path setara — lihat `ls lib/core/design_system/` sebelum edit untuk konfirmasi nama file)
