# Penyempurnaan Aplikasi SinShe Jaya Abadi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul navigasi, transaksi, laporan, branding, dan struktur menu sesuai spec v2026-05-29 — tanpa mengubah logika stok/database yang ada.

**Architecture:** Multi-page incremental refactor. Setiap fase berdiri sendiri, testable, dan bisa dicommit secara independen. Bottom nav 3-tab sebagai shell, pages di dalam dengan TabBar/stacked navigation.

**Tech Stack:** Flutter + Dart, go_router, Riverpod (existing), Supabase Flutter, thermal printing (existing)

---

## Fase 0 — Preparation (Asset + Konfigurasi)

### Task 0.1: Asset Logo SinShe

**Files:**
- Create: `assets/logo/logo_sinshe.png` (copy dari mockup screenshot)
- Modify: `pubspec.yaml` → tambah path asset

**Steps:**

- [ ] **Step 1: Copy logo dari mockup screenshot ke assets/logo/**

```bash
cp "mockup/screenshot/logo_sinshe.png" "assets/logo/logo_sinshe.png"
```

Jika file tidak ada, check `mockup/screenshot/` — user akan berikan path yang benar.

- [ ] **Step 2: Update pubspec.yaml — tambah assets/logo**

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/obat/
    - assets/logo/         # <-- TAMBAH
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "feat(assets): add SinShe logo to assets/logo/"
```

### Task 0.2: App Name & Branding — Rename Global

**Files:**
- Modify: `pubspec.yaml` → name, flutter.app.title
- Modify: `android/app/src/main/AndroidManifest.xml` → app label
- Modify: `android/app/src/main/res/values/strings.xml` → app name
- Modify: `android/app/build.gradle` → applicationId (optional)

**Steps:**

- [ ] **Step 1: Update pubspec.yaml**

```yaml
name: sinshe_jaya_abadi
version: 1.0.0+1
publish_to: 'none'
```

- [ ] **Step 2: Update AndroidManifest.xml — app label**

```xml
<application
    android:label="SinShe Jaya Abadi"
    ...>
```

- [ ] **Step 3: Update strings.xml**

```xml
<resources>
    <string name="app_name">SinShe Jaya Abadi</string>
</resources>
```

- [ ] **Step 4: Update build.gradle — applicationIdSuffix (optional, untuk debug builds)**

```groovy
android {
    namespace "com.sinshe.jayaabadi"
    ...
}
```

- [ ] **Step 5: Search & replace semua teks statis "Klinik" → "SinShe Jaya Abadi" di Dart files**

```bash
# Preview dulu — jangan langsung replace
grep -rn "Klinik" lib/ --include="*.dart" | grep -v "Klinik Sin She Jaya Abadi"
```

Lakukan replace manual per file yang user-facing (bukan nama class/variable).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml android/ pubspec.lock
git commit -m "feat(branding): rename app to SinShe Jaya Abadi"
```

---

## Fase 1 — Bottom Navigation Shell (3 Tab)

### Task 1.1: Buat AppBottomNavWidget

**Files:**
- Create: `lib/widgets/app_bottom_nav.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/riwayat-transaksi');
            break;
          case 2:
            context.go('/akun');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Riwayat Transaksi',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_circle_outlined),
          selectedIcon: Icon(Icons.account_circle),
          label: 'Akun',
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Add routes baru ke app_router.dart**

```dart
// Tambah import
import '../../pages/riwayat_transaksi_page.dart';
import '../../pages/akun_page.dart';

// Tambah route
GoRoute(
  path: RiwayatTransaksiPage.routeName,
  name: 'riwayat-transaksi',
  builder: (context, state) => const RiwayatTransaksiPage(),
),
GoRoute(
  path: AkunPage.routeName,
  name: 'akun',
  builder: (context, state) => const AkunPage(),
),
```

- [ ] **Step 3: Add placeholder pages**

Create placeholder files untuk `riwayat_transaksi_page.dart` dan `akun_page.dart` (kosong, placeholder dulu).

- [ ] **Step 4: Wrap DashboardPage dengan AppBottomNav**

Di `dashboard_page.dart`, tambahkan `Scaffold` body dengan `Column` → `[Expanded(body)] + [AppBottomNav]`.

```dart
Scaffold(
  body: Column(
    children: [
      Expanded(child: ExistingDashboardContent()),
      const AppBottomNav(currentIndex: 0),
    ],
  ),
)
```

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/app_bottom_nav.dart lib/core/routing/app_router.dart
git commit -m "feat(nav): add 3-tab bottom navigation shell"
```

---

## Fase 2 — Dashboard Redesign (Home Base + Shortcut Cards + Quick Action)

### Task 2.1: Redesain DashboardPage

**Files:**
- Modify: `lib/pages/dashboard_page.dart` — redesign total

Struktur dashboard:

```
Scaffold
└── Column
    ├── Card Biru Header (role: owner)
    │   ├── Row: [Greeting + Nama Klinik] | [Jam + Tanggal]
    │   ├── "Penjualan Hari Ini: Rp xxx.xxx"
    │   └── (dark mode & logout → di halaman Akun)
    ├── Menu Grid Cards (2 kolom)
    │   ├── [💊 Obat]       → goto /obat
    │   ├── [👥 Pasien]     → goto /pasien
    │   ├── [📊 Laporan]    → goto /laporan (Owner only)
    │   ├── [📅 Jadwal]     → goto /kehadiran
    │   └── [📦 Stok]      → goto /stok
    ├── ⚡ Quick Action (row, 2 tombol besar)
    │   ├── [💊 Jual Obat]  → goto /transaksi-hub?jenis=obat
    │   └── [🏥 Praktek]    → goto /transaksi-hub?jenis=praktek
    ├── Notif Bar (Owner only)
    │   └── "Struk Pending — X" → goto /print-queue
    └── AppBottomNav(currentIndex: 0)
```

**Logic:**
- Card biru header → hanya Owner (`AdminSession.role == 'owner'`)
- Menu "Laporan" → hanya Owner, Admin tidak melihat kartu ini
- Quick Action "Praktek" → hanya Owner
- Quick Action "Jual Obat" → Owner + Admin
- Notif Bar "Struk Pending" → hanya Owner (query count dari print_queue WHERE status = 'pending')

- [ ] **Step 1: Write the failing test** (tambahkan di `test/pages/dashboard_page_test.dart` jika ada)

```dart
// Tidak ada unit test spesifik untuk UI widget — skip test-driven UI refactor
// Verifikasi manual saat implementasi
```

- [ ] **Step 2: Implementasi — refactor dashboard_page.dart**

Ambil existing dashboard_page.dart, extract content ke dalam `Column`, tambahkan `AppBottomNav` di bottom, redesign header card biru, tambah menu grid, tambah quick action buttons.

- [ ] **Step 3: Update bottom nav index**

```dart
const AppBottomNav(currentIndex: 0)
```

- [ ] **Step 4: Test manual — verifikasi:**
- Owner: lihat card biru + semua menu + quick action
- Admin: tanpa card biru + tanpa Laporan + tanpa Praktek

- [ ] **Step 5: Commit**

```bash
git add lib/pages/dashboard_page.dart
git commit -m "feat(dashboard): redesign home base dengan shortcut cards + quick action"
```

---

## Fase 3 — Halaman Akun (Profile + Dark Mode + Logout)

### Task 3.1: Buat AkunPage

**Files:**
- Create: `lib/pages/akun_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/admin_session.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});
  static const routeName = '/akun';

  @override
  Widget build(BuildContext context) {
    final session = AdminSession.current;
    final isOwner = session.role == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + Nama
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session.nama ?? 'Pengguna',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  isOwner ? 'Owner' : 'Admin / Petugas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Dark Mode Toggle
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode Gelap'),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                // Panggil theme service / setState untuk toggle
                // Jika app menggunakan Riverpod, update ThemeNotifier
              },
            ),
          ),
          const Divider(),
          // Logout
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Yakin keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Clear session → goto /login
                await AdminSession.clear();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update app_router.dart — tambah route `/akun`**

- [ ] **Step 3: Wrap dengan AppBottomNav**

```dart
Scaffold(
  body: Column(
    children: [
      Expanded(child: AkunPageContent()),  // content di atas
      const AppBottomNav(currentIndex: 2),
    ],
  ),
)
```

- [ ] **Step 4: Commit**

```bash
git add lib/pages/akun_page.dart lib/core/routing/app_router.dart
git commit -m "feat(akun): add akun page dengan profile + dark mode + logout"
```

---

## Fase 4 — Riwayat Transaksi (2 Tab: Transaksi + Riwayat Stok)

### Task 4.1: Buat RiwayatTransaksiPage

**Files:**
- Create: `lib/pages/riwayat_transaksi_page.dart`

Tab 1 — Transaksi: query `transaksi` table, format per item sesuai spec.

Tab 2 — Riwayat Stok: query `obat_masuk` + `obat_keluar`, filter chips: Semua | Restock | Obat Keluar.

Filter chips Tab 1: Semua | Praktek | Obat | Pending Print (Owner only).

```dart
class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});
  static const routeName = '/riwayat-transaksi';

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transaksi'),
            Tab(text: 'Riwayat Stok'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TransaksiTab(),
          _RiwayatStokTab(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wrap dengan AppBottomNav (currentIndex: 1)**

```dart
body: Column(
  children: [
    Expanded(child: TabBarView(...)),
    const AppBottomNav(currentIndex: 1),
  ],
)
```

- [ ] **Step 3: Query Supabase untuk Tab 1 — Transaksi**

```dart
// Di _TransaksiTab
final session = AdminSession.current;
final isOwner = session.role == 'owner';

final trans = await Supabase.instance.client
    .from('transaksi')
    .select('*, transaksi_item(*), pasien(nama)')
    .order('created_at', ascending: false)
    .limit(50);
```

Filter chips:
- `Semua` → tanpa filter
- `Praktek` → `.eq('jenis', 'praktekCustom')`
- `Obat` → `.eq('jenis', 'obatReadyStock')`
- `Pending Print` → `.eq('status', 'pending_print')` (Owner only)

- [ ] **Step 4: Query Supabase untuk Tab 2 — Riwayat Stok**

Gabungkan `obat_masuk` + `obat_keluar` dalam satu list, sort by date. Filter chips: Semua | Restock | Obat Keluar.

```dart
// Gabungan via Future.wait
final masuk = await Supabase.instance.client
    .from('obat_masuk').select('*, obat(nama_obat, etalase)')
    .order('created_at', ascending: false);
final keluar = await Supabase.instance.client
    .from('obat_keluar').select('*, obat(nama_obat, etalase)')
    .order('created_at', ascending: false);
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/riwayat_transaksi_page.dart
git commit -m "feat(riwayat): add riwayat transaksi page dengan 2 tab"
```

---

## Fase 5 — Halaman Obat dengan Tab Strip (5 Tab)

### Task 5.1: Refactor ObatPage — Tambah TabBar

**Files:**
- Modify: `lib/pages/obat_page.dart` — ubah jadi tab strip

Tab strip di bawah AppBar:

```
[Obat] [Obat Masuk] [Obat Keluar] [Keterangan Stok] [Sinkronisasi]
```

- [ ] **Step 1: Refactor obat_page.dart — tambah TabController + 5 tabs**

Ekstrak existing konten ke tab `Obat`. Tambahkan 4 tab baru:

- **Tab 2 — Obat Masuk:** widget `ObatMasukTanggalContent` (reuse existing `obat_masuk_tanggal_form_page.dart` logic)
- **Tab 3 — Obat Keluar:** widget `ObatKeluarTanggalContent` (reuse existing)
- **Tab 4 — Keterangan Stok:** rename dari `StokAlertPage`, tampilkan obat habis & menipis (reuse `stok_alert_page.dart` content)
- **Tab 5 — Sinkronisasi:** reuse existing `sinkronisasi_stok_page.dart` logic

- [ ] **Step 2: Handle Etalase 3 visibility**

Admin → tab Obat Masuk/Keluar hanya eta 1 & 2
Owner → semua eta

Di dalam tab Obat Masuk & Obat Keluar, filter default berdasarkan role.

- [ ] **Step 3: Update route — `/stok-alert` di-remove**

Hapus route `StokAlertPage` dari `app_router.dart`. Stok Alert hanya accessible lewat tab.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/obat_page.dart lib/core/routing/app_router.dart
git commit -m "feat(obat): convert obat page ke tab strip dengan 5 tab"
```

---

## Fase 6 — Login Page (Desain dari screenshot)

### Task 6.1: Refactor LoginPage

**Files:**
- Modify: `lib/pages/login_page.dart` — update desain sesuai screenshot

Ambil reference dari `mockup/screenshot/login_app.jpeg` — implementasi persis layout, warna, spacing.

Perubahan kunci:
- Logo di atas: gunakan `assets/logo/logo_sinshe.png`
- Hapus/hide elemen yang tidak ada di screenshot
- Posisi form centered
- Warna sesuai screenshot

- [ ] **Step 1: Baca screenshot lagi + bandingkan dengan existing login_page.dart**

- [ ] **Step 2: Update login_page.dart — desain baru**

Sesuaikan dengan screenshot. Umumnya layout login yang bagus:

```
Center
└── SingleChildScrollView
    └── Padding
        └── Column
            ├── [Logo SinShe - besar, centered]
            ├── [App Name: "SinShe Jaya Abadi"]
            ├── [Email TextField]
            ├── [Password TextField]
            ├── [Login Button]
            └── [Forgot Password link]
```

- [ ] **Step 3: Test manual — verifikasi desain match screenshot**

- [ ] **Step 4: Commit**

```bash
git add lib/pages/login_page.dart
git commit -m "feat(login): update desain sesuai screenshot dengan logo SinShe"
```

---

## Fase 7 — Preview Cetak Struk (Hitam Putih)

### Task 7.1: Refactor PreviewCetakPage

**Files:**
- Modify: `lib/pages/preview_cetak_page.dart` (jika ada)
- Modify: `lib/core/services/receipt_printer_service.dart`

- [ ] **Step 1: Cek existing preview_cetak_page.dart**

```bash
find lib/ -name "*preview*cetak*" -o -name "*cetak*" -o -name "*print*page*" 2>/dev/null
```

- [ ] **Step 2: Update desain struk ke hitam putih**

Struk thermal hitam putih:

```
================================
     SIN SHE JAYA ABADI
================================
Tanggal : 29 Mei 2026 | 14.25
No.     : TXN-20260529-001
--------------------------------
ITEM              QTY    HARGA
--------------------------------
Paracetamol 500mg   2   Rp 15.000
OBAT123           x2   Rp 10.000
--------------------------------
Subtotal                 Rp 25.000
Pajak (0%)               Rp 0
TOTAL                    Rp 25.000
--------------------------------
Metode Bayar : Tunai
================================
       TERIMA KASIH
================================
```

- Font: monospace (Courier / Android monospace)
- Border: karakter `=` `-` `|`
- Tidak ada warna RGB sama sekali

- [ ] **Step 3: Update receipt_printer_service.dart — satu desain**

Satukan desain preview dan print menjadi satu — tidak ada beda visual.

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/receipt_printer_service.dart
git commit -m "feat(receipt): unify receipt design ke hitam putih"
```

---

## Fase 8 — Laporan Owner (Harian/Bulanan/Tahunan)

### Task 8.1: Buat/Sempurnakan LaporanPage

**Files:**
- Modify: `lib/pages/laporan_page.dart`
- Modify: `lib/features/laporan/` (struktur existing)

- [ ] **Step 1: Cek existing laporan_page.dart + features/laporan/**

```bash
ls lib/pages/laporan_page.dart lib/features/laporan/
```

- [ ] **Step 2: Add TabBar Harian / Bulanan / Tahunan**

Struktur per tab mengikuti spec section 9:

**Tab Harian:**
- Statistik: total transaksi + nominal, comparison vs kemarin
- Breakdown: Obat vs Praktek
- Grafik: penjualan per jam (fl_chart bar chart, 06:00–21:00)
- Daftar: Top 10 Obat Terjual
- Operasional: obat masuk/keluar count, pasien hadir count
- Action: Export CSV, Cetak Thermal

**Tab Bulanan:**
- Statistik: total + rata-rata/hari, comparison vs bulan lalu
- Grafik: tren harian sepanjang bulan
- Daftar: Top 10 Obat Terjual, breakdown %
- Operasional: total masuk/keluar, pasien hadir

**Tab Tahunan:**
- Statistik: total tahun ini
- Grafik: tren bulanan (12 bulan)
- Daftar: Top 10 Obat Terjual
- Ringkasan stok: total item, obat habis, obat menipis

- [ ] **Step 3: Role check — Owner only**

```dart
if (AdminSession.current.role != 'owner') {
  return const SizedBox.shrink();  // Admin tidak bisa akses
}
```

- [ ] **Step 4: Query data dari Supabase per tab**

Harian: query `transaksi` WHERE DATE(created_at) = today, GROUP BY HOUR
Bulanan: query GROUP BY DATE for the month
Tahunan: query GROUP BY MONTH for the year

- [ ] **Step 5: Export CSV button**

```dart
// Generate CSV dari data, share via share_plus atau file save
```

- [ ] **Step 6: Commit**

```bash
git add lib/pages/laporan_page.dart
git commit -m "feat(laporan): overhaul laporan dengan tab harian/bulanan/tahunan"
```

---

## Fase 9 — Print Queue (Tabel Database + UI)

### Task 9.1: Buat Tabel print_queue + UI PrintQueuePage

**Files:**
- Modify: perlu SQL migration (display only, TIDAK execute — tunggu konfirmasi user)
- Create: `lib/pages/print_queue_page.dart`
- Modify: `lib/pages/transaksi_form_page.dart` — add print queue creation

**Steps:**

- [ ] **Step 1: Display SQL — CREATE TABLE print_queue (DONT EXECUTE)**

```sql
CREATE TABLE print_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaksi_id UUID NOT NULL REFERENCES public.transaksi(id),
  created_by UUID NOT NULL REFERENCES public.admin(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'printed', 'canceled')),
  printed_by UUID REFERENCES public.admin(id),
  printed_at TIMESTAMPTZ,
  locked_by UUID REFERENCES public.admin(id),
  locked_at TIMESTAMPTZ
);

CREATE INDEX idx_print_queue_status ON print_queue(status);
CREATE INDEX idx_print_queue_created_at ON print_queue(created_at DESC);
```

- [ ] **Step 2: Buat PrintQueuePage**

Halaman untuk melihat transaksi pending print:

```dart
// Kirim notifikasi ke admin saat Owner input transaksi praktek
// Admin lihat list pending → klik → preview → cetak → status = printed
```

- [ ] **Step 3: Update TransaksiFormPage — create queue entry after save**

```dart
// Setelah transaksi saved:
await Supabase.instance.client.from('print_queue').insert({
  'transaksi_id': savedTransaksi.id,
  'created_by': AdminSession.current.adminId,
  'status': 'pending',
});
```

- [ ] **Step 4: Commit SQL proposal + code**

---

## Fase 10 — Transaksi Flow (Etalase Filter + Validation)

### Task 10.1: Update TransaksiFormPage

**Files:**
- Modify: `lib/pages/transaksi_form_page.dart`

- [ ] **Step 1: Tambah filter etalase di form**

Saat pilih "Jual Obat" → hanya tampilkan obat eta 1 & 2
Saat pilih "Praktek" → hanya tampilkan obat eta 3

Validasi saat input:
- "Jual Obat" tapi pilih obat eta 3 → showDialog: "Obat etalase 3 hanya untuk transaksi Praktek."
- "Praktek" tapi belum pilih pasien → showDialog: "Silakan pilih pasien terlebih dahulu."

- [ ] **Step 2: Handle biaya konsultasi untuk Praktek**

Di form Praktek, tambah field `biaya_konsultasi` (number input, bisa 0).

- [ ] **Step 3: Commit**

```bash
git add lib/pages/transaksi_form_page.dart
git commit -m "feat(transaksi): filter etalase per jenis transaksi + validasi"
```

---

## Fase 11 — Navigation Integration (Semua Page → Bottom Nav)

### Task 11.1: Wrap Semua Page dengan Bottom Nav

**Files:**
- Modify: `lib/pages/obat_page.dart`
- Modify: `lib/pages/pasien_page.dart`
- Modify: `lib/pages/laporan_page.dart`
- Modify: `lib/pages/kehadiran_page.dart`
- Modify: `lib/pages/transaksi_hub_page.dart`

- [ ] **Step 1: Wrap setiap page dengan pattern**

```dart
Scaffold(
  body: Column(
    children: [
      Expanded(child: PageContent()),
      const AppBottomNav(currentIndex: 0),  // sesuai tab
    ],
  ),
)
```

- [ ] **Step 2: Commit per file**

```bash
git add lib/pages/obat_page.dart lib/pages/pasien_page.dart
git commit -m "feat(nav): integrate bottom nav ke halaman utama"
```

---

## Fase 12 — Emil Design Token + Polish

### Task 12.1: Buat Design Token

**Files:**
- Create: `lib/core/design_system/emil_design.dart`

```dart
import 'package:flutter/material.dart';

class EmilDesign {
  // ── Durations ──
  static const fast    = Duration(milliseconds: 150);
  static const normal  = Duration(milliseconds: 300);
  static const slow    = Duration(milliseconds: 500);

  // ── Curves ──
  static const enter    = Curves.easeOutCubic;
  static const exit     = Curves.easeInCubic;
  static const gesture  = Curves.easeOutCubic;
  static const toggle   = Curves.easeInOutCubic;

  // ── Scale ──
  static const pressScale  = 0.97;
  static const hoverScale  = 1.04;

  // ── Reduced Motion ──
  static Duration adaptiveDuration(BuildContext context, Duration normalDuration) {
    return MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : normalDuration;
  }
}
```

- [ ] **Step 2: Apply ke halaman baru (dashboard, login, akun, riwayat)**

```dart
// Contoh: AnimatedPageRoute
PageRouteBuilder(
  transitionDuration: EmilDesign.normal,
  pageBuilder: (_, __, ___) => NewPage(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(opacity: animation, child: child);
  },
)
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/design_system/emil_design.dart
git commit -m "feat(design): add EmilDesign motion token system"
```

---

## Scope Check

| Spec Section | Task | Status |
|---|---|---|
| Bottom Nav 3 tab | Task 1.1 | ✅ |
| Dashboard redesign | Task 2.1 | ✅ |
| Hapus Akuntansi | Tidak ada task — menu tidak dibuat, tidak perlu dihapus | ✅ |
| Transaksi ke Dashboard | Task 10.1 | ✅ |
| Riwayat Transaksi 2 tab | Task 4.1 | ✅ |
| Print Queue | Task 9.1 | ✅ |
| Owner→Admin notifikasi | Task 9.1 + 10.1 | ✅ |
| Etalase filter di transaksi | Task 10.1 | ✅ |
| Login desain screenshot | Task 6.1 | ✅ |
| Logo SinShe integration | Task 0.1 | ✅ |
| Struk hitam putih | Task 7.1 | ✅ |
| Rename "Klinik" → "SinShe" | Task 0.2 | ✅ |
| Laporan Harian/Bulanan/Tahunan | Task 8.1 | ✅ |
| Admin tanpa Laporan | Task 8.1 | ✅ |
| Etalase 3 hanya Owner | Task 5.1 | ✅ |
| Pasien non-praktek tidak dicatat | Default existing behavior | ✅ |
| Manajemen Stok tab strip | Task 5.1 | ✅ |
| Rename "Stok Alert" → "Keterangan Stok" | Task 5.1 | ✅ |

**Spec gap:** Tidak ada. Semua 22 perubahan dari spec tercakup.

---

## Plan complete and saved to `docs/superpowers/plans/YYYY-MM-DD-penyempurnaan-mockup.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. Gunakan skill `superpowers:subagent-driven-development`.

**2. Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints. Batch per fase.

**Which approach?**