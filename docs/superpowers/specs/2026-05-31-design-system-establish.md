# SPEC: Design System Establishment — Sin She Jaya Abadi

**Tanggal:** 2026-05-31
**Fase:** F9.5 — Design System Polish
**Status:** DRAFT

---

## 1. Tujuan

Establish desain foundation yang seragam agar semua halaman (F1-F11) punya "look & feel" konsisten tanpa perlu polish terpisah di tiap fase.

---

## 2. Aspek yang Perlu Diseragamkan

### 2.1 Spacing Rhythm
**Current:** `AppSpacing` dari `app_tokens.dart` — sudah ada, belum dipakai merata.

| Token | Value | Pakai di |
|-------|-------|----------|
| `xxs` | 2px | Tight internal padding |
| `xs` | 4px | Icon-to-text gap |
| `sm` | 8px | Default gap antar elemen kecil |
| `md` | 12px | Padding dalam card |
| `lg` | 16px | Default page padding |
| `xl` | 20px | Section spacing |
| `xxl` | 24px | Major section break |

**Signature rule:** Semua page pakai `AppSpacing` — **sebaiknya** pakai token; outlier 1-2px karena grid alignment visual boleh di-justifikasi (mis. chip dengan radius 10px untuk konsistensi dengan mockup yang bukan 4dp base, didokumentasikan sebagai pengecualian inline).

### 2.2 Border Radius
**Current:** mix of `BorderRadius.circular()` hardcoded di banyak tempat.

| Token | Value | Pakai di |
|-------|-------|----------|
| `sm` | 8px | Buttons, chips, small inputs |
| `md` | 12px | Cards, large inputs, containers |
| `lg` | 16px | Bottom sheets, modals |
| `xl` | 20px | Dialogs |

**Signature rule:** Semua komponen pakai `AppRadius` — `BorderRadius.circular(AppRadius.md)`, dst. Outlier karena pad ke visual Stitch KEEP (mis. 10px, 14px) **boleh** dipakai dan didokumentasikan sebagai pengecualian inline. Token radius tambahan (10, 14) boleh ditambah di `AppRadius` jika dipakai ≥ 3 tempat.

### 2.3 Animation & Motion (Emil Design)
**Current:** `emil_design.dart` sudah ada tapi belum dipakai.

| Token | Value | Pakai di |
|-------|-------|----------|
| `fast` | 150ms | Hover, toggle, icon change |
| `normal` | 300ms | Page transitions, modal open |
| `slow` | 500ms | Chart animations, heavy reveals |

**Signature rules:**
- Page transitions: pakai `EmilDesign.pageRoute()` — fade transition 300ms easeOutCubic
- Button press: scale `EmilDesign.pressScale` (0.97) + 150ms
- Bottom sheet: pakai default Material 3 dengan `EmilDesign.normal`
- Reduced motion: semua animasi auto-disable kalau system prefer reduced motion

### 2.4 Color Usage
**Current:** `app_theme.dart` sudah punya `cprimary()`, `cscaffoldBg()`, dll. — sudah konsisten.

**Signature rules:**
- Background: selalu `cscaffoldBg(context)`
- Card: selalu `ccardBg(context)`
- Primary action: `cprimary(context)`
- Text: `ctextPrimary(context)` / `ctextSecondary(context)`
- No hardcoded hex colors untuk background/text

### 2.5 Typography
**Current:** Flutter default `TextTheme` + `app_tokens.dart`.

| Token | Pakai di |
|-------|----------|
| `AppTextStyles.metric` | Angka besar di dashboard (omzet, total) |
| `AppTextStyles.title` | Card title, section header |
| `AppTextStyles.label` | Labels, chips, status badges |
| `AppTextStyles.caption` | Timestamps, metadata |

---

## 3. Signature Decisions (3-5 points)

1. **Spacing:** Semua page pakai `AppSpacing` tokens — zero hardcoded pixel values untuk hal baru; outlier terdokumentasi inline OK.
2. **Radius:** Cards: `AppRadius.md` (12px), Buttons: `AppRadius.sm` (8px), Bottom sheets: `AppRadius.lg` (16px). Outlier (10/14) OK jika dari Stitch KEEP.
3. **Motion:** Page transition = fade 300ms easeOutCubic; Button press = scale 0.97 + 150ms
4. **Color:** Pakai helper functions dari `app_theme.dart` — `cprimary()`, `cscaffoldBg()`, dst. — **dianjurkan**; raw `Colors.blue` / hex langsung untuk hal baru di luar KEEP harus di-justify.
5. **Reduced Motion:** Semua animasi auto-disable kalau `accessibilityFeatures.reduceMotion = true`

---

## 4. Scope — Halaman yang Perlu Disesuaikan

### Prioritas 1 — Most Visible
- [ ] `dashboard_page.dart` — apply spacing, radius, color helpers
- [ ] `obat_hub_page.dart` — tabs + content apply tokens
- [ ] `transaksi_hub_page.dart` — form sections apply tokens

### Prioritas 2 — Supporting Pages
- [ ] `login_page.dart` — already Emil-style (F6)
- [ ] `laporan_page.dart` — already clean (F8)
- [ ] `akun_page.dart` — apply tokens
- [ ] `obat_masuk_page.dart` / `obat_keluar_page.dart` / `stok_alert_page.dart`
- [ ] `transaksi_form_page.dart` — 1478 lines, hati-hati
- [ ] `struk_pembayaran_page.dart` / `riwayat_transaksi_page.dart`

### Yang Sudah Konsisten
- ✅ F7 receipt pages — text-only, sudah simpel
- ✅ Print queue pages — nanti dibuat setelah F9

---

## 5. Implementation Steps

1. Update `app_tokens.dart` — tambahkan missing tokens jika ada
2. Update `emil_design.dart` — export `AppSpacing` + `AppRadius` agar 1 import dapat semua
3. Audit 3 halaman prioritas — identify where hardcoded values exist
4. Apply tokens ke 3 halaman prioritas
5. Apply tokens ke halaman pendukung
6. Verify: `flutter analyze` clean + visual check

---

## 6. Constraints

- **Tidak ubah logic** — hanya ganti value (spacing, radius, color)
- **Tidak ubah layout** — repositioning hanya jika ada inkonsistensi yang jelas, atau sesuai Stitch KEEP
- **Hati-hati dengan `transaksi_form_page.dart`** — 1595 lines (post F0.4), refactor visual bertahap per section OK, jangan 1 PR besar
- **Dark mode** — semua helper functions sudah handle dark/light, pastikan konsisten
- **Penerapan Stitch KEEP** — untuk fase redesign mengikuti KEEP folder, **boleh** mengubah layout, radius, typography, dan motion selama sesuai `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/<folder-KEEP>/`. Tetap jaga logic bisnis (stok/auth/role/printer) dan struktur repository.

---

## 7. Deliverables

- Updated `lib/core/design_system/app_tokens.dart`
- Updated `lib/core/design_system/emil_design.dart`
- Refactored pages (prioritas 1 + 2)
- Commit: `chore(F9.5): establish design system — AppSpacing, AppRadius, EmilDesign applied`
