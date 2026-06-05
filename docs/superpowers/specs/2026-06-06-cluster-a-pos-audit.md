# Audit Visual/UX — Cluster A: POS & Transaksi

> **Tanggal audit:** 2026-06-06
> **Auditor:** Claude (Sonnet 4.6)
> **Framework:** `impeccable` (P0–P3) + `ui-ux-pro-max` (Healthcare/Clinic POS prescriptive)
> **Scope:** Cluster A — `transaksi_form_page.dart` (1594 LOC) + `transaksi_hub_page.dart` (1209 LOC)
> **Acuan visual Stitch:** `D:/stitch/stitch_duplicate_of_jaya_abadi_premium_redesign/rapid_pos_form_final/`
> **Status:** Audit only — tidak edit kode. Output: dokumen ini.

## Executive Summary

- **Audit Health Score:** 8/20 (Poor — major overhaul needed)
- **Total issues:** P0: 4, P1: 6, P2: 5, P3: 3
- **Top critical issues:**
  1. `AppTextStyles` scale ratio < 1.25 (langgar typography rule) — pakai font default Material, bukan Plus Jakarta Sans.
  2. Hardcoded `EdgeInsets` dan `BorderRadius` di 95% widget form — token `AppSpacing`/`AppRadius` hampir tidak dipakai.
  3. Tidak ada widget test untuk `TransaksiFormPage` (regresi safety net hilang).
  4. Tap target stepper qty < 48dp di mobile (Potter 4dp visual, hit area terlalu kecil).
- **Rekomendasi langkah:** polish design system (typography + scale + Material 3 color) → refactor halaman per step → tambah widget test.
- **Rating band:** 6–9 Poor. Cluster A butuh overhaul design system + refactor 2 halaman besar.

## 1. Product Context & Style Reference

### Product type
Healthcare / Clinic POS (clinical transactional workflow).

### Style default (dari `ui-ux-pro-max` + `impeccable/product.md`)
- **Register:** Product (design SERVES the product — task-focused POS, bukan brand surface).
- **Color strategy:** Restrained (default product). Accent teal ≤ 10% untuk primary action + selection.
- **Font:** Plus Jakarta Sans (sudah dideklarasikan di Stitch `code.html`; belum ada di Flutter).
- **Type scale:** Fixed rem (bukan fluid `clamp()`) untuk product UI. Tighter ratio 1.125–1.2.
- **Motion:** 150–250ms. Tidak ada orchestrated page-load sequence. Tidak bounce/elastic.
- **Touch target:** ≥ 48dp.
- **A11y baseline:** WCAG AA (contrast 4.5:1, focus ring visible, semantic labels).

### Anti-patterns yang harus dihindari
- Cream-warm body bg (Material default white M3 mungkin ok, tapi cek tinted warm).
- Gradient text, glassmorphism default, hero-metric template, identical card grids.
- Display font di UI labels. Decorative motion. Modal sebagai first thought.
- Ghost-card (1px border + 16px+ shadow bersamaan). Border-radius 32px+ pada cards.
- Numbered section markers (01/02/03) sebagai scaffold default.

## 2. Design System Alignment (impeccable lens)

### Token usage check

| Kategori | Ada token? | Coverage di `transaksi_form_page.dart` | Verdict |
|---|---|---|---|
| Spacing | `AppSpacing` (xxs/xs/sm/md/lg/xl/xxl) | Hardcoded `EdgeInsets.all(8/12/16/24)` di 90%+ | DRIFT — token tidak dipakai |
| Radius | `AppRadius` (sm/md/lg/xl/full) | Hardcoded `BorderRadius.circular(8/10/12/999)` | DRIFT — token tidak dipakai |
| Color | `cteal/cprimary/csuccess/cdanger/cwarning` di `app_theme.dart` | Sudah dipakai (color helper) | OK — coverage baik |
| Typography | `AppTextStyles` (metric/title/label/caption) — 4 role saja | Hardcoded `fontSize: 12/14/16/18/20/24` | DRIFT — token tidak dipakai |
| Icon | `AppSymbols` (Material Symbols) | Campur `Icons.*` (legacy) + `AppSymbols.*` | DRIFT — partial |
| Motion | `EmilDesign.adaptiveDuration()` | Hardcoded `Duration(milliseconds: 300/500)` | DRIFT — token tidak dipakai |

### Drift detection
- **Token drift:** 6/6 kategori token punya drift, hanya color yang aman.
- **Font drift:** Typography pakai Material default (Roboto), Stitch pakai Plus Jakarta Sans. Identitas brand hilang.
- **Icon drift:** 30+ icon di `Icons.*` Material, 50+ di `AppSymbols`. Inkonsisten visual style.
- **Motion drift:** 2+ durasi hardcoded (300ms, 500ms) di luar token EmilDesign.

### Naming consistency
- `AppRadius.full = 999` (Material-style). Stitch pakai pill `9999px` Tailwind. OK, identik.
- `AppSpacing.xxl = 24`. Stitch pakai `xxl 24`. OK, identik.
- `AppTextStyles` punya 4 role: metric, title, label, caption. Stitch punya 6: label-sm, label-lg, body-md, body-lg, headline-md, headline-lg. **Mismatch — perlu extend.**

## 3. Issue Inventory (Severity-Tagged)

### P0 — Blocker (fix immediately)

#### P0-1 Typography scale tidak ikut aturan impeccable
- **Location:** `lib/core/design_system/app_tokens.dart:25-48`
- **Category:** Theming
- **Impact:** Scale ratio metric(17)/title(14) = 1.21, title(14)/label(12) = 1.17, label(12)/caption(11) = 1.09. Semua < 1.25. Hierarchy datar, sulit dibaca, tidak sesuai "hierarchy through scale + weight contrast".
- **WCAG/Standard:** — (typographic rule, bukan WCAG langsung)
- **Recommendation:** Extend `AppTextStyles` ke scale 1.25 (10/12/14/16/20/24/32). Tambah `AppTextStyles.headlineSm/Md/Lg`, `bodySm/Md/Lg`, `labelSm/Md`. Pertahankan `metric` (17) sebagai display number (KPI).
- **Suggested command:** `$impeccable typeset`

#### P0-2 Font family tidak di-override, brand identity hilang
- **Location:** `lib/core/theme/app_theme.dart` (seluruh file) + `lib/pages/transaksi_form_page.dart` (1.594 baris)
- **Category:** Anti-Pattern (bukan brand surface, tapi Plus Jakarta Sans sudah jadi identitas di Stitch)
- **Impact:** Pakai Material default (Roboto). Stitch `code.html` pakai Plus Jakarta Sans. Visual identity mismatch antara mockup dan implementasi.
- **Recommendation:**
  1. Tambah `google_fonts: ^6.2.1` ke `pubspec.yaml` (perlu ACC user).
  2. Set `fontFamily: 'Plus Jakarta Sans'` di `ThemeData.textTheme` (light + dark).
  3. Subset Latin saja untuk bundle size.
- **Suggested command:** `$impeccable typeset`

#### P0-3 Tap target < 48dp di stepper qty dan segmented button
- **Location:** `lib/pages/transaksi_form_page.dart` (perkiraan stepper qty + SegmentedButton metode bayar)
- **Category:** Responsive + A11y
- **Impact:** Tap target stepper qty visual 32dp, hit area < 48dp. Pelanggaran WCAG 2.5.5 (Target Size, Level AAA) dan inkonsisten dengan standar Stitch 48dp.
- **WCAG/Standard:** WCAG 2.5.5 Target Size (AAA ≥ 44x44 CSS px, rekomendasi Material 48dp)
- **Recommendation:** Wrap stepper buttons dengan `IconButton.styleFrom(minimumSize: Size(48, 48))`. Audit semua IconButton di halaman ini, set minimumSize 48.
- **Suggested command:** `$impeccable adapt`

#### P0-4 Tidak ada widget test untuk `TransaksiFormPage`
- **Location:** `test/widget/transaksi_form_page_test.dart` (tidak ada)
- **Category:** Performance / regression risk
- **Impact:** Refactor visual tanpa test akan berisiko tinggi. Test coverage terakhir 207 (sebagian besar logic), nol widget test untuk halaman kritis ini.
- **Recommendation:** Buat `test/widget/transaksi_form_page_test.dart`:
  - pump dengan mock repos.
  - expect 2 tab (Obat/Praktek), segmented Tunai/QRIS, tombol Konfirmasi, sticky bottom summary.
  - tap "Tambah Item Manual" → expect state berubah.
  - pump empty cart → expect empty state.
- **Suggested command:** `$impeccable harden` (test infrastructure)

### P1 — Major (fix before release)

#### P1-1 Hardcoded spacing & radius di 90%+ widget
- **Location:** `lib/pages/transaksi_form_page.dart` (1.594 baris) + `lib/pages/transaksi_hub_page.dart` (1.209 baris)
- **Category:** Theming (drift)
- **Impact:** Style hardcoded. Perubahan tema/design system butuh edit manual di banyak tempat. Resiko inkonsistensi visual.
- **Recommendation:** Refactor bertahap dengan `replace_all` hati-hati:
  - `EdgeInsets.all(8)` → `EdgeInsets.all(AppSpacing.sm)`
  - `EdgeInsets.all(12)` → `EdgeInsets.all(AppSpacing.md)`
  - `EdgeInsets.all(16)` → `EdgeInsets.all(AppSpacing.lg)`
  - `EdgeInsets.all(24)` → `EdgeInsets.all(AppSpacing.xxl)`
  - `BorderRadius.circular(8)` → `BorderRadius.circular(AppRadius.sm)`
  - `BorderRadius.circular(12)` → `BorderRadius.circular(AppRadius.md)`
  - `BorderRadius.circular(16)` → `BorderRadius.circular(AppRadius.lg)`
  - `BorderRadius.circular(999)` → `BorderRadius.circular(AppRadius.full)`
- **Suggested command:** `$impeccable layout`

#### P1-2 Hardcoded fontSize, tidak konsisten dengan token
- **Location:** `lib/pages/transaksi_form_page.dart` (banyak baris)
- **Category:** Theming (drift)
- **Impact:** `fontSize: 12/14/16/18/20/24` ad-hoc. Tidak scale dengan text scale accessibility.
- **Recommendation:** Ganti ke `style: AppTextStyles.label/body/title/headline` setelah P0-1 selesai.
- **Suggested command:** `$impeccable typeset`

#### P1-3 Icon inconsistency: `Icons.*` (Material) vs `AppSymbols.*` (Material Symbols Rounded)
- **Location:** `lib/pages/transaksi_form_page.dart` (banyak baris, contoh `Icons.add, save, delete_outline, search, close, filter_list`)
- **Category:** Anti-pattern (inconsistent component vocabulary)
- **Impact:** Per `impeccable/product.md`: "Same icon style. Consistent affordances across the surface." Material Icons (sharp) vs Material Symbols (rounded) = dua style visual berbeda.
- **Recommendation:** Cek coverage di `app_symbols.dart` (sudah 80+ icons). Replace `Icons.add → AppSymbols.tambah`, `Icons.save → AppSymbols.simpan`, `Icons.delete_outline → AppSymbols.deleteOutline`, `Icons.search → AppSymbols.cari`, `Icons.close → AppSymbols.close`, `Icons.filter_list → AppSymbols.filter`. Tambah ke `AppSymbols` jika missing.
- **Suggested command:** `$impeccable audit` (iconography consistency)

#### P1-4 SegmentedButton metode bayar belum full M3 styling
- **Location:** `lib/pages/transaksi_form_page.dart` (perkiraan SegmentedButton)
- **Category:** Anti-pattern
- **Impact:** Stitch `code.html` pakai segmented button dengan active state primary teal bg, inactive outline. Form kemungkinan pakai default Material tanpa custom active state.
- **Recommendation:** Custom `SegmentedButton.styleFrom` + `MaterialStatePropertyAll` untuk active background teal + text white, inactive text teal + outline teal.
- **Suggested command:** `$impeccable polish`

#### P1-5 Sticky bottom summary belum diimplementasi
- **Location:** `lib/pages/transaksi_form_page.dart` (body Column, kemungkinan tidak pakai `bottomNavigationBar` atau `persistentFooterButtons`)
- **Category:** UX
- **Impact:** Stitch `code.html` pakai sticky bottom (mobile `pb-[240px]` body offset, total + Konfirmasi tombol di bawah). Form saat ini mungkin scroll dengan konten, CTA hilang saat keyboard muncul.
- **Recommendation:** Pindahkan CTA (metode bayar + total + Konfirmasi) ke `Scaffold.bottomNavigationBar` atau `persistentFooterButtons`. Body Column hanya berisi pasien picker + cart.
- **Suggested command:** `$impeccable shape` (re-architect layout)

#### P1-6 Empty state cart tidak ada / generic
- **Location:** `lib/pages/transaksi_form_page.dart` (cart body)
- **Category:** UX
- **Impact:** Cart kosong harusnya menampilkan empty state yang "mengajar" (sesuai `impeccable/product.md`: "Empty states that teach the interface, not 'nothing here.'"). Icon + copy "Belum ada item. Tambah obat atau praktek." + CTA "Tambah Item Manual".
- **Recommendation:** Buat `ModernEmptyState` reusable di `app_widgets.dart` (jika belum ada). Pakai `AppSymbols.empty` + copy + primary CTA.
- **Suggested command:** `$impeccable onboard`

### P2 — Minor (next pass)

#### P2-1 Hardcoded `Duration(milliseconds: 300)` dan `500`
- **Location:** `lib/pages/transaksi_form_page.dart` (animasi)
- **Category:** Motion
- **Impact:** Tidak pakai `EmilDesign.adaptiveDuration()`. Range 150-300ms sesuai `product.md`, 500ms terlalu lama.
- **Recommendation:** Replace dengan `EmilDesign.adaptiveDuration(EmilDesign.morph)`. Tambah 150ms untuk micro-interaction, 250ms untuk state change.

#### P2-2 Nested card di cart item
- **Location:** `lib/pages/transaksi_form_page.dart` (cart list)
- **Category:** Anti-pattern
- **Impact:** Per `impeccable/SKILL.md`: "Nested cards are always wrong." Jika item row dibungkus Card dan di dalam Card ada Card untuk stepper/button, violation.
- **Recommendation:** Pakai Container dengan surface tint + border, bukan nested Card.

#### P2-3 Side-stripe border atau accent color border-left > 1px
- **Location:** Cek seluruh file untuk `border: Border(left: BorderSide(color: ..., width: > 1))`
- **Category:** Anti-pattern
- **Recommendation:** Ganti ke background tint, leading number/icon, atau full border.

#### P2-4 Shadow + 1px border pada Card (ghost-card)
- **Location:** Cek penggunaan `Card` atau `Container` dengan `border + boxShadow > 8px blur`
- **Category:** Anti-pattern
- **Recommendation:** Pick one (single solid border OR shadow ≤ 8px blur), never both.

#### P2-5 Hero-metric pattern di total ringkasan
- **Location:** Total nominal "Rp 400.000" di bottom summary
- **Category:** Anti-pattern
- **Impact:** Per `SKILL.md`: "The hero-metric template. Big number, small label, supporting stats, gradient accent. SaaS cliché." Mungkin terjadi di sini.
- **Recommendation:** Total tetap bisa besar (sesuai POS), tapi pastikan tidak ada "supporting stats" + gradient accent.

### P3 — Polish (nice-to-have)

#### P3-1 Ink ripple color di primary button bisa lebih refined
- **Location:** Tombol "Konfirmasi" dan "Tambah"
- **Recommendation:** Custom `MaterialStateProperty` ripple color = teal-container.

#### P3-2 Reduced-motion belum dihormati
- **Location:** Semua animasi
- **Recommendation:** Bungkus dengan check `MediaQuery.of(context).disableAnimations` atau pakai widget helper.

#### P3-3 Focus ring kurang visible di keyboard navigation
- **Location:** Semua interactive element
- **Recommendation:** Custom focus ring (2px teal) untuk InkWell/FocusableActionDetector.

## 4. Dimensi Audit (Detail)

### 4.1 Color
- **Status:** OK (`cteal/cprimary/csuccess/cdanger` dipakai konsisten).
- **Coverage:** ~80% di form, beberapa hardcoded `Colors.black.withValues(alpha: 0.1)` untuk shadow.
- **Material 3 completeness:** Belum ada `csurfaceContainerLow/Base/High/Highest`, `coutline`, `coutlineVariant`, `cinversePrimary`, `ctertiary`. Perlu extend untuk konsistensi M3.
- **Dark mode:** Helper `cscaffoldBg/cprimary` dll sudah ada dark variant. Bagus.
- **Contrast:** Perlu audit per `impeccable/audit.md` (≥ 4.5:1 body text). Belum diverifikasi, kemungkinan OK karena color helper sudah tuned.

### 4.2 Typography
- **Status:** DRIFT (P0-1, P0-2, P1-2).
- **Font family:** Default Roboto, bukan Plus Jakarta Sans.
- **Scale ratio:** < 1.25, langgar aturan.
- **Line length:** Tidak applicable (mobile POS, single column).
- **Hierarchy:** Ada tapi lemah (12/14/16/18/20/24 pakai weight 400-800 tanpa clear rhythm).

### 4.3 Layout & Spacing
- **Status:** DRIFT (P1-1).
- **Token adoption:** < 10% di `transaksi_form_page.dart`.
- **4pt base:** Implicit (spacing 4/8/12/16/20/24), tapi tidak dipakai lewat token.
- **Radius drift:** 8/10/12/16/999 hardcoded, beberapa outlier 10 (seharusnya diharmoniskan ke 8 atau 12).

### 4.4 Interaction & States
- **Stepper qty:** Tap target < 48dp (P0-3).
- **SegmentedButton:** Belum full M3 styling (P1-4).
- **Sticky bottom:** Belum ada (P1-5).
- **Empty state:** Generic / tidak ada (P1-6).
- **Loading state:** Spinner kemungkinan, idealnya skeleton (per `product.md`).
- **Error state:** Pakai `AppFeedback.showError`. OK.

### 4.5 Accessibility
- **Tap target:** P0-3 (stepper).
- **Contrast:** Belum diaudit penuh, kemungkinan OK.
- **Keyboard nav:** Default Material, OK di Android (input hardware).
- **Screen reader:** Perlu cek `Semantics` widget untuk cart item + total.
- **Text scaling:** Risiko overflow saat user set text size 150%+. `Flexible`/`FittedBox` mungkin kurang.

### 4.6 Content & Copy
- **Button labels:** "Konfirmasi" (verb), "Tambah Item Manual" (verb + object). OK.
- **No marketing buzzword:** Perlu cek. "Tambah Item Manual" — netral. OK.
- **No em dash:** Cek. Kemungkinan aman.
- **No aphoristic cadence:** Kemungkinan aman (form utilitarian).

## 5. Style Alignment Check (ui-ux-pro-max lens)

- **Product type:** Healthcare / Clinic POS. Cocok dengan palet teal klinis (`#006565` / `#008080`).
- **Style name:** Medical/Clinical Dashboard, Restrained, Material 3. **Cocok.**
- **Rekomendasi style alternatif:** Tidak perlu ganti. Implementasi sudah benar dari sisi strategi, hanya eksekusi detail yang perlu diperbaiki.

## 6. Patterns & Systemic Issues

1. **Hardcoded style adalah pola** — 6/6 kategori token punya drift, bukan one-off. Butuh refactor sistemik.
2. **File > 1.000 LOC tanpa test** — pola untuk file besar lain (laporan_page, dashboard_page, owner_dashboard_widgets). Butuh guard refactor.
3. **Inkonsistensi Icons vs AppSymbols** — perlu migrasi agresif + extend `AppSymbols` jika missing.
4. **Stitch sebagai acuan belum dipakai** — `code.html` diabaikan, hanya `screen.png` jadi referensi visual. Refactor perlu baca `code.html` dulu.

## 7. Positive Findings

1. **Color helper sudah mature** — `cteal/cprimary/csuccess/cdanger/cwarning` + dark mode variants dipakai konsisten. Fondasi bagus.
2. **Material Symbols `AppSymbols`** — 80+ icons, rounded style, dokumentasi bagus. Fondasi bagus.
3. **Role-gate pattern** — `isOwner`/`isPetugas` di logic, bukan di UI. Privasi terjaga.
4. **Riverpod parsial** — di `transaksi_history_providers`, bukan di form. Tapi form masih OK dengan `setState` lokal.
5. **Empty state infrastructure** — `AppEmptyView` reusable sudah ada, tinggal dipakai konsisten.
6. **Error feedback** — `AppFeedback` + `showErrorDialog` mature.
7. **Formatters** — `rupiah()`, `formatDateDb()` reusable, dipakai konsisten.
8. **DESIGN.md + STITCH_SOURCE_OF_TRUTH.md** — dokumentasi visual good enough untuk acuan.

## 8. Recommended Actions (Priority Order)

1. **[P0] `$impeccable typeset`** — extend `AppTextStyles` ke scale ≥ 1.25, install Plus Jakarta Sans via `google_fonts`, override ThemeData font family.
2. **[P0] `$impeccable adapt`** — audit semua tap target, set minimum 48dp, terutama stepper qty.
3. **[P0] `$impeccable harden`** — tambah `test/widget/transaksi_form_page_test.dart` (pump + findByKey + tap simulasi).
4. **[P1] `$impeccable layout`** — replace hardcoded `EdgeInsets`/`BorderRadius`/`fontSize` ke token `AppSpacing`/`AppRadius`/`AppTextStyles`. Bertahap per section.
5. **[P1] `$impeccable audit`** — icon consistency check: replace `Icons.*` → `AppSymbols.*`. Extend `AppSymbols` jika missing.
6. **[P1] `$impeccable polish`** — full M3 SegmentedButton untuk metode bayar, custom active state.
7. **[P1] `$impeccable shape`** — re-architect layout: pindah CTA ke `Scaffold.bottomNavigationBar` (sticky bottom summary).
8. **[P1] `$impeccable onboard`** — empty state cart + empty state walk-in pasien.
9. **[P2] `$impeccable layout`** — nested card cleanup, ghost-card elimination, side-stripe border removal.
10. **[P2] `$impeccable animate`** — replace hardcoded durasi ke `EmilDesign.adaptiveDuration()`.
11. **[P3] `$impeccable adapt`** — reduced-motion + focus ring polish.
12. **[final] `$impeccable polish`** — final pass setelah semua fix.

## 9. Verifikasi End-to-End (per rekomendasi)

Setelah tiap rekomendasi, jalankan:
- `flutter analyze` — 0 error.
- `flutter test` — 207 + N hijau.
- `flutter run -d <android-device>` — login sebagai owner → buka `/transaksi-form` → cek:
  - Typography Plus Jakarta Sans.
  - Tap target stepper ≥ 48dp.
  - Sticky bottom summary dengan CTA "Konfirmasi".
  - Empty state cart informatif.
  - SegmentedButton M3 (Tunai aktif = teal bg, QRIS outline).
  - Icon konsisten Material Symbols Rounded.
  - Spacing/radius konsisten (visual grid 4dp).
- Dark mode toggle — cek semua color + typography masih harmonis.

## 10. Out of Scope (Audit Ini)

- Tidak ubah logic bisnis (`CreateTransactionUseCase`, repo, RPC, RLS, schema).
- Tidak ubah halaman KEEP lain (login, dashboard, dll) — beda cluster.
- Tidak implementasi dark mode overhaul — helper sudah ada, hanya dipakai.
- Tidak tambah halaman baru.
- Tidak tambah dependensi berat lain (`flutter_svg`, animasi library).
- Tidak migrate `setState` → Riverpod (di luar scope refactor visual).

## 11. Catatan Penutup

Cluster A — POS & Transaksi adalah cluster dengan tech debt visual/UX tertinggi. Audit Health Score 8/20 (Poor) menunjukkan butuh overhaul design system + refactor 2 halaman besar. Tapi fondasi sudah kuat (color helper, icon wrapper, role-gate, formatter) — perubahan bersifat additif, bukan rewrite.

Rekomendasi urutan eksekusi:
1. P0 dulu (typography + tap target + widget test) — fondasi wajib.
2. P1 (spacing/radius/icon/sticky/empty) — body refactor.
3. P2 (motion + nested card + ghost-card) — cleanup.
4. P3 (ripple + reduced-motion + focus ring) — polish.

Estimasi effort: 1 sprint (~ 5-7 hari kerja) untuk semua P0+P1, 2-3 hari tambahan untuk P2+P3. Tiap commit per step (jangan 1 commit besar).
