import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Material Symbols wrapper — rounded style.
/// Ganti semua HugeIcons/AppIcons dengan Icon(AppSymbols.xxx).
///
/// Style: Rounded — soft, medical-grade look.
/// Weight: SymbolWeight.w400 (default untuk semua).
///
/// Wrapper ini tidak menggunakan HugeIcon — langsung Icon(...)
/// karena MaterialSymbols adalah IconData native Flutter.
///
/// DEPRECATED: app_icons.dart TIDAK dihapus — tetap ada untuk
/// backward compatibility safety net sampai semua consumer dimigrated.
class AppSymbols {
  AppSymbols._();

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Branding klinik
  static const IconData klinik = Symbols.local_hospital_rounded;

  /// Email / username
  static const IconData mail = Symbols.mail_rounded;

  /// Password / lock
  static const IconData lock = Symbols.lock_rounded;

  /// Tampilkan password
  static const IconData eyeOn = Symbols.visibility_rounded;

  /// Sembunyikan password
  static const IconData eyeOff = Symbols.visibility_off_rounded;

  /// Tombol login
  static const IconData login = Symbols.login_rounded;

  /// Help / bantuan
  static const IconData help = Symbols.info_rounded;

  /// Send / kirim (arrow right)
  static const IconData send = Symbols.arrow_forward_rounded;

  /// Waving hand (welcome greeting)
  static const IconData wavingHand = Symbols.waving_hand_rounded;

  /// User group (people outline)
  static const IconData peopleGroup = Symbols.group_rounded;

  /// Assessment / report (analytics)
  static const IconData assessment = Symbols.analytics_rounded;

  // ─── Dashboard ────────────────────────────────────────────────────────────

  /// Toggle light theme (sun)
  static const IconData sun = Symbols.light_mode_rounded;

  /// Toggle dark theme (moon)
  static const IconData moon = Symbols.dark_mode_rounded;

  /// Logout
  static const IconData logout = Symbols.logout_rounded;

  // ─── Menu Utama ────────────────────────────────────────────────────────────

  /// Data Obat — pill/medicine
  static const IconData obat = Symbols.medication_rounded;

  /// Data Obat — pills (dedicated pill icon)
  static const IconData pills = Symbols.medication_rounded;

  /// Obat Masuk (inventory in) — package receive
  static const IconData obatMasuk = Symbols.download_rounded;

  /// Obat Keluar (inventory out) — package sent
  static const IconData obatKeluar = Symbols.upload_rounded;

  /// Data Pasien
  static const IconData pasien = Symbols.person_rounded;

  /// Pasien Hub — halaman domain pasien
  static const IconData pasienHub = Symbols.group_rounded;

  /// Daftar Hadir Pasien — clipboard
  static const IconData daftarHadir = Symbols.checklist_rounded;

  /// Laporan / analytics — chart
  static const IconData laporan = Symbols.bar_chart_rounded;

  // ─── Aksi Umum ────────────────────────────────────────────────────────────

  /// Tambah data
  static const IconData tambah = Symbols.add_rounded;

  /// Tambah (circle variant)
  static const IconData tambahCircle = Symbols.add_circle_rounded;

  /// Edit
  static const IconData edit = Symbols.edit_rounded;

  /// Edit outline (small, untuk inline actions)
  static const IconData editOutline = Symbols.edit_rounded;

  /// Hapus
  static const IconData hapus = Symbols.delete_rounded;

  /// Delete outline (small, untuk inline actions)
  static const IconData deleteOutline = Symbols.delete_rounded;

  /// Hapus sweep (bulk delete)
  static const IconData hapusSweep = Symbols.delete_sweep_rounded;

  /// Remove / minus (untuk hapus item di form)
  static const IconData removeCircle = Symbols.remove_circle_rounded;

  /// Simpan — save energy
  static const IconData simpan = Symbols.save_rounded;

  /// Cari / search
  static const IconData cari = Symbols.search_rounded;

  /// Filter
  static const IconData filter = Symbols.filter_list_rounded;

  /// Sort / urutkan
  static const IconData sort = Symbols.sort_rounded;

  /// Sort A-Z
  static const IconData sortAZ = Symbols.sort_by_alpha_rounded;

  /// Refresh / reload
  static const IconData refresh = Symbols.refresh_rounded;

  /// Kembali / arrow left
  static const IconData kembali = Symbols.arrow_back_rounded;

  /// Arrow left 02
  static const IconData arrowBack = Symbols.arrow_back_rounded;

  /// Arrow right
  static const IconData arrowRight = Symbols.arrow_forward_rounded;

  /// Arrow down
  static const IconData arrowDown = Symbols.keyboard_arrow_down_rounded;

  /// Arrow up
  static const IconData arrowUp = Symbols.keyboard_arrow_up_rounded;

  /// Lihat detail / eye
  static const IconData detail = Symbols.visibility_rounded;

  /// Visibility / eye
  static const IconData visibility = Symbols.visibility_rounded;

  /// Kalender / tanggal
  static const IconData kalender = Symbols.calendar_today_rounded;

  /// Calendar today
  static const IconData calendarToday = Symbols.calendar_today_rounded;

  /// Calendar month
  static const IconData kalenderMonth = Symbols.calendar_month_rounded;

  /// Calendar 03
  static const IconData calendar03 = Symbols.calendar_today_rounded;

  /// Warning / peringatan
  static const IconData warning = Symbols.warning_rounded;

  /// Stok menipis — alert 02
  static const IconData stokMenipis = Symbols.error_rounded;

  /// Riwayat / clock
  static const IconData riwayat = Symbols.history_rounded;

  // ─── Pasien & Kehadiran ───────────────────────────────────────────────────

  /// Pasien hadir
  static const IconData pasienHadir = Symbols.check_circle_rounded;

  /// Pasien tidak hadir
  static const IconData pasienTidakHadir = Symbols.cancel_rounded;

  /// Person (generic)
  static const IconData person = Symbols.person_rounded;

  /// Event attendance — calendar check-in
  static const IconData event = Symbols.event_available_rounded;

  // ─── Laporan / Chart ──────────────────────────────────────────────────────

  /// Receipt / nota — invoice
  static const IconData receipt = Symbols.receipt_rounded;

  /// Analytics summary
  static const IconData analytics = Symbols.analytics_rounded;

  /// Chart trending up
  static const IconData trendingUp = Symbols.trending_up_rounded;

  /// Chart trending down
  static const IconData trendingDown = Symbols.trending_down_rounded;

  /// Bar chart
  static const IconData chartBar = Symbols.bar_chart_rounded;

  /// Star / terbaik
  static const IconData star = Symbols.star_rounded;

  /// Etalase / storefront
  static const IconData etalase = Symbols.storefront_rounded;

  /// Add box / unit masuk
  static const IconData addBox = Symbols.add_box_rounded;

  // ─── Obat Detail ──────────────────────────────────────────────────────────

  /// Medication / pill — health
  static const IconData medication = Symbols.medication_rounded;

  /// Input / masuk
  static const IconData input = Symbols.download_rounded;

  /// Output / keluar
  static const IconData output = Symbols.upload_rounded;

  /// Inventory
  static const IconData inventory = Symbols.inventory_2_rounded;

  // ─── UI Umum ───────────────────────────────────────────────────────────────

  /// Success / check
  static const IconData success = Symbols.check_circle_rounded;

  /// Error / gagal
  static const IconData error = Symbols.error_rounded;

  /// Close
  static const IconData close = Symbols.close_rounded;

  /// Empty / inbox
  static const IconData empty = Symbols.inbox_rounded;

  /// More horizontal
  static const IconData more = Symbols.more_horiz_rounded;

  /// Medical services
  static const IconData medical = Symbols.medical_services_rounded;

  /// Description / catatan
  static const IconData description = Symbols.description_rounded;

  /// Payment / tagihan
  static const IconData payment = Symbols.payments_rounded;

  /// Tunai / cash payment
  static const IconData tunai = Symbols.payments_rounded;

  /// QRIS / QR code payment
  static const IconData qris = Symbols.qr_code_rounded;

  /// Computer / system
  static const IconData computer = Symbols.computer_rounded;

  /// Compare / selisih
  static const IconData compare = Symbols.compare_rounded;

  // ─── Dashboard Summary ────────────────────────────────────────────────────

  /// Wallet / omzet — untuk ringkasan omzet hari ini
  static const IconData wallet = Symbols.account_balance_wallet_rounded;

  /// Calendar / jadwal — untuk ringkasan jadwal hari ini
  static const IconData jadwalSummary = Symbols.calendar_today_rounded;

  /// Receipt / transaksi — untuk ringkasan transaksi hari ini
  static const IconData receiptSummary = Symbols.receipt_long_rounded;

  /// User check / hadir — untuk ringkasan hadir hari ini
  static const IconData hadirSummary = Symbols.check_circle_rounded;

  /// Check circle
  static const IconData checkCircle = Symbols.check_circle_rounded;
}
