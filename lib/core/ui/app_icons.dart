import 'package:hugeicons/hugeicons.dart';

/// ⚠️ DEPRECATED — Jangan gunakan di kode baru.
/// File ini dipertahankan sebagai backward compatibility untuk kode lama.
/// Semua ikon sudah dimigrasikan ke [AppSymbols] di `app_symbols.dart`.
///
/// Migrasi: ganti `HugeIcon(icon: AppIcons.xxx, ...)` → `Icon(AppSymbols.xxx, ...)`
///
/// HugeIcons tidak implements IconData — selalu gunakan [HugeIcon] widget.
typedef AppHugeIconData = List<List<dynamic>>;

/// Registry ikon Hugeicons (DEPRECATED).
///
/// ⚠️ DEPRECATED — Kode baru HARUS menggunakan [AppSymbols].
///
/// Gunakan dengan widget [HugeIcon]:
/// ```dart
/// HugeIcon(icon: AppIcons.klinik, size: 24, color: Colors.blue)
/// ```
///
/// Untuk migrasi: gunakan [AppSymbols] yang sudah menggunakan
/// [material_symbols_icons](https://pub.dev/packages/material_symbols_icons).
class AppIcons {
  AppIcons._();

  // ─── Login ──────────────────────────────────────────────────────────────────

  /// Branding klinik
  static const AppHugeIconData klinik = HugeIcons.strokeRoundedHospital01;

  /// Email / username
  static const AppHugeIconData mail = HugeIcons.strokeRoundedMail01;

  /// Password / lock
  static const AppHugeIconData lock = HugeIcons.strokeRoundedLock;

  /// Tampilkan password
  static const AppHugeIconData eyeOn = HugeIcons.strokeRoundedEye;

  /// Sembunyikan password (pakai Eye + toggle behavior)
  static const AppHugeIconData eyeOff = HugeIcons.strokeRoundedEye;

  /// Tombol login
  static const AppHugeIconData login = HugeIcons.strokeRoundedLogin01;

  /// Help / bantuan
  static const AppHugeIconData help = HugeIcons.strokeRoundedInformationCircle;

  /// Send / kirim (arrow right — untuk aksi kirim)
  static const AppHugeIconData send = HugeIcons.strokeRoundedArrowRight01;

  /// Waving hand (welcome greeting)
  static const AppHugeIconData wavingHand = HugeIcons.strokeRoundedWavingHand01;

  /// User group (people outline)
  static const AppHugeIconData peopleGroup = HugeIcons.strokeRoundedUserGroup;

  /// Assessment / report (analytics)
  static const AppHugeIconData assessment = HugeIcons.strokeRoundedAnalytics01;

  // ─── Dashboard ───────────────────────────────────────────────────────────────

  /// Toggle light theme (sun)
  static const AppHugeIconData sun = HugeIcons.strokeRoundedSun01;

  /// Toggle dark theme (moon)
  static const AppHugeIconData moon = HugeIcons.strokeRoundedMoon;

  /// Logout
  static const AppHugeIconData logout = HugeIcons.strokeRoundedLogout02;

  // ─── Menu Utama ───────────────────────────────────────────────────────────────

  /// Data Obat — pill/medicine
  static const AppHugeIconData obat = HugeIcons.strokeRoundedHealth;

  /// Data Obat — pills (dedicated pill icon)
  static const AppHugeIconData pills = HugeIcons.strokeRoundedPill;

  /// Obat Masuk (inventory in) — package receive
  static const AppHugeIconData obatMasuk =
      HugeIcons.strokeRoundedPackageReceive;

  /// Obat Keluar (inventory out) — package sent
  static const AppHugeIconData obatKeluar = HugeIcons.strokeRoundedPackageSent;

  /// Data Pasien
  static const AppHugeIconData pasien = HugeIcons.strokeRoundedUser;

  /// Pasien Hub — halaman domain pasien
  static const AppHugeIconData pasienHub = HugeIcons.strokeRoundedUserGroup;

  /// Daftar Hadir Pasien — clipboard
  static const AppHugeIconData daftarHadir = HugeIcons.strokeRoundedClipboard;

  /// Laporan / analytics — chart
  static const AppHugeIconData laporan = HugeIcons.strokeRoundedChart;

  // ─── Aksi Umum ───────────────────────────────────────────────────────────────

  /// Tambah data
  static const AppHugeIconData tambah = HugeIcons.strokeRoundedAdd01;

  /// Tambah (circle variant)
  static const AppHugeIconData tambahCircle = HugeIcons.strokeRoundedAddCircle;

  /// Edit
  static const AppHugeIconData edit = HugeIcons.strokeRoundedEdit01;

  /// Edit outline (small, untuk inline actions)
  static const AppHugeIconData editOutline = HugeIcons.strokeRoundedEdit02;

  /// Hapus
  static const AppHugeIconData hapus = HugeIcons.strokeRoundedDelete02;

  /// Delete outline (small, untuk inline actions)
  static const AppHugeIconData deleteOutline = HugeIcons.strokeRoundedDelete01;

  /// Hapus sweep (bulk delete)
  static const AppHugeIconData hapusSweep = HugeIcons.strokeRoundedDelete03;

  /// Remove / minus (untuk hapus item di form)
  static const AppHugeIconData removeCircle =
      HugeIcons.strokeRoundedMinusSignCircle;

  /// Simpan — save energy
  static const AppHugeIconData simpan = HugeIcons.strokeRoundedSaveEnergy01;

  /// Cari / search
  static const AppHugeIconData cari = HugeIcons.strokeRoundedSearch01;

  /// Filter
  static const AppHugeIconData filter = HugeIcons.strokeRoundedFilter;

  /// Sort / urutkan
  static const AppHugeIconData sort = HugeIcons.strokeRoundedArrange;

  /// Sort A–Z (tertentu)
  static const AppHugeIconData sortAZ =
      HugeIcons.strokeRoundedArrangeByLettersAZ;

  /// Refresh / reload
  static const AppHugeIconData refresh = HugeIcons.strokeRoundedRefresh;

  /// Kembali / arrow left
  static const AppHugeIconData kembali = HugeIcons.strokeRoundedArrowLeft01;

  /// Arrow left 02
  static const AppHugeIconData arrowBack = HugeIcons.strokeRoundedArrowLeft02;

  /// Arrow right
  static const AppHugeIconData arrowRight = HugeIcons.strokeRoundedArrowRight01;

  /// Arrow down
  static const AppHugeIconData arrowDown = HugeIcons.strokeRoundedArrowDown01;

  /// Arrow up
  static const AppHugeIconData arrowUp = HugeIcons.strokeRoundedArrowUp01;

  /// Lihat detail / eye
  static const AppHugeIconData detail = HugeIcons.strokeRoundedEye;

  /// Visibility / eye
  static const AppHugeIconData visibility = HugeIcons.strokeRoundedEye;

  /// Kalender / tanggal
  static const AppHugeIconData kalender = HugeIcons.strokeRoundedCalendar03;

  /// Calendar today — Hugeicons calendar-03
  static const AppHugeIconData calendarToday =
      HugeIcons.strokeRoundedCalendar03;

  /// Calendar month — Hugeicons calendar-03
  static const AppHugeIconData kalenderMonth =
      HugeIcons.strokeRoundedCalendar03;

  /// Calendar 03 — Hugeicons calendar-03
  static const AppHugeIconData calendar03 = HugeIcons.strokeRoundedCalendar03;

  /// Warning / peringatan
  static const AppHugeIconData warning = HugeIcons.strokeRoundedAlertCircle;

  /// Stok menipis — alert 02
  static const AppHugeIconData stokMenipis = HugeIcons.strokeRoundedAlert02;

  /// Riwayat / clock
  static const AppHugeIconData riwayat = HugeIcons.strokeRoundedTime02;

  // ─── Pasien & Kehadiran ─────────────────────────────────────────────────────

  /// Pasien hadir
  static const AppHugeIconData pasienHadir = HugeIcons.strokeRoundedUserCheck01;

  /// Pasien tidak hadir
  static const AppHugeIconData pasienTidakHadir =
      HugeIcons.strokeRoundedUserRemove01;

  /// Person (generic)
  static const AppHugeIconData person = HugeIcons.strokeRoundedUser;

  /// Event attendance — calendar check-in
  static const AppHugeIconData event = HugeIcons.strokeRoundedCalendarCheckIn01;

  // ─── Laporan / Chart ─────────────────────────────────────────────────────────

  /// Receipt / nota — invoice
  static const AppHugeIconData receipt = HugeIcons.strokeRoundedInvoice;

  /// Analytics summary
  static const AppHugeIconData analytics = HugeIcons.strokeRoundedAnalytics01;

  /// Chart trending up
  static const AppHugeIconData trendingUp = HugeIcons.strokeRoundedChartUp;

  /// Chart trending down
  static const AppHugeIconData trendingDown = HugeIcons.strokeRoundedChartDown;

  /// Bar chart
  static const AppHugeIconData chartBar = HugeIcons.strokeRoundedChartAverage;

  /// Star / terbaik
  static const AppHugeIconData star = HugeIcons.strokeRoundedStar;

  /// Etalase / storefront
  static const AppHugeIconData etalase = HugeIcons.strokeRoundedStore01;

  /// Add box / unit masuk
  static const AppHugeIconData addBox = HugeIcons.strokeRoundedAddSquare;

  // ─── Obat Detail ─────────────────────────────────────────────────────────────

  /// Medication / pill — health
  static const AppHugeIconData medication = HugeIcons.strokeRoundedHealth;

  /// Input / masuk
  static const AppHugeIconData input = HugeIcons.strokeRoundedArrowDown01;

  /// Output / keluar
  static const AppHugeIconData output = HugeIcons.strokeRoundedArrowUp01;

  /// Inventory
  static const AppHugeIconData inventory = HugeIcons.strokeRoundedPackage;

  // ─── UI Umum ─────────────────────────────────────────────────────────────────

  /// Success / check
  static const AppHugeIconData success =
      HugeIcons.strokeRoundedCheckmarkCircle01;

  /// Error / gagal
  static const AppHugeIconData error = HugeIcons.strokeRoundedDanger;

  /// Close — ClosedCaption
  static const AppHugeIconData close = HugeIcons.strokeRoundedClosedCaption;

  /// Empty / inbox
  static const AppHugeIconData empty = HugeIcons.strokeRoundedInbox;

  /// More horizontal
  static const AppHugeIconData more = HugeIcons.strokeRoundedMoreHorizontal;

  /// Medical services
  static const AppHugeIconData medical = HugeIcons.strokeRoundedHealth;

  /// Description / catatan
  static const AppHugeIconData description =
      HugeIcons.strokeRoundedLegalDocument01;

  /// Payment / tagihan
  static const AppHugeIconData payment = HugeIcons.strokeRoundedWallet01;

  /// Tunai / cash payment
  static const AppHugeIconData tunai = HugeIcons.strokeRoundedMoney02;

  /// QRIS / QR code payment
  static const AppHugeIconData qris = HugeIcons.strokeRoundedQrCode;

  /// Computer / system
  static const AppHugeIconData computer = HugeIcons.strokeRoundedComputer;

  /// Compare / selisih
  static const AppHugeIconData compare = HugeIcons.strokeRoundedGitCompare;

  // ─── Dashboard Summary ─────────────────────────────────────────────────────

  /// Wallet / omzet — untuk ringkasan omzet hari ini
  static const AppHugeIconData wallet = HugeIcons.strokeRoundedWallet01;

  /// Calendar / jadwal — untuk ringkasan jadwal hari ini
  static const AppHugeIconData jadwalSummary = HugeIcons.strokeRoundedCalendar03;

  /// Receipt / transaksi — untuk ringkasan transaksi hari ini
  static const AppHugeIconData receiptSummary = HugeIcons.strokeRoundedInvoice;

  /// User check / hadir — untuk ringkasan hadir hari ini
  static const AppHugeIconData hadirSummary = HugeIcons.strokeRoundedUserCheck01;

  /// Check circle
  static const AppHugeIconData checkCircle =
      HugeIcons.strokeRoundedCheckmarkCircle01;
}
