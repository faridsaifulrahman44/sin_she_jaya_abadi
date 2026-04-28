import '../../data/models/obat_model.dart';
import 'daily_income_point.dart';

class LaporanSummary {
  const LaporanSummary({
    required this.totalPendapatanKeseluruhan,
    required this.pendapatanPeriodeAktif,
    required this.pendapatanReadyStock,
    required this.pendapatanPraktekCustomBundled,
    required this.pendapatanEtalase1,
    required this.pendapatanEtalase2,
    required this.pendapatanEtalase3Custom,
    required this.selisihPendapatanBelumTerpetakan,
    required this.jumlahTransaksi,
    required this.jumlahTransaksiReadyStock,
    required this.jumlahTransaksiPraktekCustom,
    required this.jumlahTransaksiCash,
    required this.jumlahTransaksiQris,
    required this.nominalCash,
    required this.nominalQris,
    required this.jumlahPasienTerdaftar,
    required this.jumlahPasienTerjadwalPeriode,
    required this.jumlahHadir,
    required this.jumlahTidakHadir,
    required this.jumlahStokMenipis,
    required this.jumlahStokHabis,
    required this.stokKritis,
    required this.chartPoints,
  });

  final double totalPendapatanKeseluruhan;
  final double pendapatanPeriodeAktif;
  final double pendapatanReadyStock;
  final double pendapatanPraktekCustomBundled;

  /// Breakdown etalase:
  /// - etalase1/etalase2 dari item ready stock
  /// - etalase3 custom = item etalase3 + transaksi praktek_custom (bundled)
  final double pendapatanEtalase1;
  final double pendapatanEtalase2;
  final double pendapatanEtalase3Custom;

  /// Selisih jika total pendapatan periode belum seluruhnya
  /// bisa dipetakan ke breakdown etalase.
  final double selisihPendapatanBelumTerpetakan;

  final int jumlahTransaksi;
  final int jumlahTransaksiReadyStock;
  final int jumlahTransaksiPraktekCustom;

  final int jumlahTransaksiCash;
  final int jumlahTransaksiQris;
  final double nominalCash;
  final double nominalQris;

  final int jumlahPasienTerdaftar;
  final int jumlahPasienTerjadwalPeriode;
  final int jumlahHadir;
  final int jumlahTidakHadir;

  final int jumlahStokMenipis;
  final int jumlahStokHabis;
  final List<ObatModel> stokKritis;

  final List<DailyIncomePoint> chartPoints;

  int get jumlahKehadiran => jumlahHadir + jumlahTidakHadir;
  int get jumlahStokKritis => jumlahStokMenipis + jumlahStokHabis;

  bool get hasSelisihEtalase =>
      selisihPendapatanBelumTerpetakan.abs() >= 1; // ignore tiny rounding noise
}
