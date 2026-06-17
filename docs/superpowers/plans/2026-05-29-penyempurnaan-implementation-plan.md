# Implementation Plan — Penyempurnaan Klinik Sin She Jaya Abadi

## Context

```
Specs  : docs/superpowers/specs/2026-05-29-penyempurnaan-mockup-design.md
Branch : latihan-plugin
Goal   : Implementasi循 spec dari brainstorming
```

## Project Overview

- **Ringkasan:** Penyempurnaan UI/UX app klinik: bottom nav 3 tab, dashboard redesign, role-based akses etalase 1/2/3, transaksi pisah Jual Obat/Praktek, laporan komprehensif Owner, print queue, logo SinShe, rename app, struk hitam putih
- **Skala:** ~20+ file berubah
- **Urgency:** Normal
- **Dependencies:** Supabase DB (tabel print_queue perlu dibuat via migration)

## Task Breakdown

### Phase 0 — Mockup
1. [ ] Buat `mockup/mockup_v7.html` komprehensif (semua halaman, role Owner+Admin)
2. [ ] Review mockup dengan user sebelum implementasi

### Phase 1 — Assets & Config (induk)
3. [ ] Copy logo SinShe dari `mockup/screenshot/` ke `assets/logo/`
4. [ ] Rename app global: pubspec.yaml, AndroidManifest.xml, strings.xml, build.gradle
5. [ ] Generate app icon untuk APK dari logo PNG

### Phase 2 — Database
6. [ ] Buat tabel `print_queue` (via SQL, tampilkan dulu ke user)
7. [ ] Verifikasi tabel print_queue

### Phase 3 — Navigation & Routing
8. [ ] Update bottom nav: `[Dashboard] [Riwayat] [Akun]`
9. [ ] Hapus route `/stok-alert`, merge ke dalam Obat page
10. [ ] Tambah route `/riwayat` (transaksi + restock/keluar tabs)

### Phase 4 — Dashboard & Login
11. [ ] Login page: update desain dari login_app.jpeg + logo SinShe
12. [ ] Dashboard Owner redesign: card biru + jam/tanggal + shortcut cards
13. [ ] Dashboard Admin redesign: card terbatas tanpa nominal
14. [ ] Akun page: dark mode toggle + logout

### Phase 5 — Obat & Stok Management
15. [ ] Obat page: tambah TabBar 5 tab (Obat, Obat Masuk, Obat Keluar, Keterangan Stok, Sinkronisasi)
16. [ ] Role filter: Admin hanya lihat eta 1&2 di filter chips
17. [ ] Stok alert logic: rename label "Keterangan Stok Obat"

### Phase 6 — Transaksi
18. [ ] Ubah transaksi form: segment [Jual Obat] [Praktek]
19. [ ] Validasi: Jual Obat → hanya eta 1&2, Praktek → hanya eta 3 + WAJIB pilih pasien
20. [ ] Update transaksi hub page
21. [ ] Preview cetak struk: ubah ke hitam putih
22. [ ] Print service: satu desain struk hitam putih

### Phase 7 — Print Queue
23. [ ] Print queue page: list pending, preview, cetak, status
24. [ ] Owner input Praktek → notifikasi push ke Admin
25. [ ] Admin cetak dari queue → update status printed

### Phase 8 — Riwayat Transaksi
26. [ ] Halaman riwayat: Tab 1 (transaksi), Tab 2 (restock + obat keluar)
27. [ ] Filter + search per tab

### Phase 9 — Laporan Owner
28. [ ] Overhaul halaman laporan: Tab Harian / Bulanan / Tahunan
29. [ ] Tab Harian: grafik per jam, top 10 obat, breakdown Obat vs Praktek, operasional
30. [ ] Tab Bulanan: tren harian, breakdown %, operasional
31. [ ] Tab Tahunan: tren bulanan, ringkasan stok
32. [ ] Export CSV + Cetak Thermal (hitam putih)
33. [ ] Role guard: Admin tidak punya akses halaman ini

### Phase 10 — Hapus Akuntansi
34. [ ] Hapus menu/page Akuntansi dari routing + navigasi

### Phase 11 — Emil Design (Motion)
35. [ ] Buat `lib/core/design_system/emil_design.dart` dengan token duration/curve
36. [ ] Apply animasi ke halaman baru yang dibuat (minimal, fade + slide)

### Phase 12 — Testing
37. [ ] Jalankan `flutter analyze`
38. [ ] Jalankan `flutter test`
39. [ ] Build APK debug

## File Changes Summary

```
TAMBAH:
  assets/logo/logo_sinshe.png
  assets/logo/logo_salin_login.png
  lib/core/design_system/emil_design.dart
  lib/features/print_queue/
  mockup/mockup_v7.html

UBAH:
  pubspec.yaml
  android/app/build.gradle
  android/app/src/main/AndroidManifest.xml
  android/app/src/main/res/values/strings.xml
  lib/core/routing/app_router.dart
  lib/core/routing/app_route_registry.dart
  lib/core/services/receipt_printer_service.dart
  lib/pages/login_page.dart
  lib/pages/dashboard_page.dart
  lib/pages/obat_page.dart
  lib/pages/stok_alert_page.dart
  lib/pages/transaksi_form_page.dart
  lib/pages/transaksi_hub_page.dart
  lib/pages/preview_cetak_page.dart
  lib/pages/riwayat_transaksi_page.dart
  lib/pages/laporan_page.dart
  lib/pages/akun_page.dart
  lib/widgets/bottom_nav.dart

HAPUS:
  lib/pages/akuntansi_page.dart (jika ada)
```

## Execution Order

```
Phase 0 (Mockup) → Phase 1 (Assets+Config) → Phase 2 (DB) →
Phase 3 (Nav) → Phase 4 (Login+Dash+Akun) → Phase 5 (Obat+Stok) →
Phase 6 (Transaksi) → Phase 7 (Print Queue) → Phase 8 (Riwayat) →
Phase 9 (Laporan) → Phase 10 (Hapus Akuntansi) →
Phase 11 (Emil Design) → Phase 12 (Test)
```

## Notes
- Untuk Phase 2 (DB): Tampilkan SQL INSERT table print_queue, tunggu user ketik "LANJUT" sebelum apply via MCP
- Bottom nav berubah jadi 3 tab: [Dashboard] [Riwayat] [Akun] — semua halaman yang ada harus bisa di-navigasi dari sini
- Role detection via AdminSession yang sudah ada — jangan ubah core/auth/
