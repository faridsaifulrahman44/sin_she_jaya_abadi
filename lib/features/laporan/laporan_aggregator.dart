import '../../data/models/kehadiran_model.dart';
import '../../data/models/obat_etalase.dart';
import '../../data/models/obat_model.dart';
import '../../data/models/pasien_model.dart';
import '../../data/models/transaksi_model.dart';
import 'daily_income_point.dart';
import 'laporan_summary.dart';

DateTime _dateKey(DateTime value) =>
    DateTime(value.year, value.month, value.day);

Map<DateTime, double> aggregateDailyIncome(List<TransaksiModel> transaksi) {
  final grouped = <DateTime, double>{};
  for (final item in transaksi) {
    final key = _dateKey(item.tanggal);
    grouped[key] = (grouped[key] ?? 0) + item.total;
  }
  return grouped;
}

List<DailyIncomePoint> buildDailyIncomePoints({
  required List<TransaksiModel> items,
  required DateTime endDate,
  int days = 7,
}) {
  final grouped = aggregateDailyIncome(items);
  final end = _dateKey(endDate);
  final safeDays = days <= 0 ? 1 : days;

  return List<DailyIncomePoint>.generate(safeDays, (index) {
    final offset = safeDays - index - 1;
    final day = end.subtract(Duration(days: offset));
    return DailyIncomePoint(
      date: day,
      totalNominal: grouped[day] ?? 0,
    );
  });
}

double _sumTotal(Iterable<TransaksiModel> items) {
  return items.fold<double>(0, (sum, item) => sum + item.total);
}

LaporanSummary buildLaporanSummary({
  required DateTime startDate,
  required DateTime endDate,
  required List<TransaksiModel> transaksiPeriode,
  required List<TransaksiModel> transaksiAllTime,
  required List<TransaksiItemModel> transaksiItemsAllTime,
  required List<PasienModel> pasienPeriode,
  required List<PasienModel> pasienAllTime,
  required List<KehadiranModel> kehadiranPeriode,
  required List<ObatModel> obatAllTime,
}) {
  final totalPendapatanKeseluruhan = _sumTotal(transaksiAllTime);
  final pendapatanPeriodeAktif = _sumTotal(transaksiPeriode);

  final transaksiReadyStock = transaksiPeriode
      .where((t) => t.jenisTransaksi == JenisTransaksi.obatReadyStock)
      .toList(growable: false);
  final transaksiPraktekCustom = transaksiPeriode
      .where((t) => t.jenisTransaksi == JenisTransaksi.praktekCustom)
      .toList(growable: false);

  final pendapatanReadyStock = _sumTotal(transaksiReadyStock);
  final pendapatanPraktekCustomBundled = _sumTotal(transaksiPraktekCustom);

  final readyStockIds = transaksiReadyStock.map((t) => t.idTransaksi).toSet();
  final obatById = {for (final item in obatAllTime) item.idObat: item};

  double pendapatanEtalase1 = 0;
  double pendapatanEtalase2 = 0;
  double pendapatanEtalase3FromReady = 0;

  for (final item in transaksiItemsAllTime) {
    if (!readyStockIds.contains(item.idTransaksi)) {
      continue;
    }

    final etalase = obatById[item.idObat]?.etalase;
    switch (etalase) {
      case Etalase.etalase1:
        pendapatanEtalase1 += item.subtotal;
        break;
      case Etalase.etalase2:
        pendapatanEtalase2 += item.subtotal;
        break;
      case Etalase.etalase3:
        pendapatanEtalase3FromReady += item.subtotal;
        break;
      case null:
        break;
    }
  }

  final pendapatanEtalase3Custom =
      pendapatanEtalase3FromReady + pendapatanPraktekCustomBundled;
  final pendapatanMappedEtalase =
      pendapatanEtalase1 + pendapatanEtalase2 + pendapatanEtalase3Custom;
  final selisihPendapatanBelumTerpetakan =
      pendapatanPeriodeAktif - pendapatanMappedEtalase;

  final transaksiCash = transaksiPeriode
      .where((t) => t.metodeBayar == MetodeBayarTransaksi.cash)
      .toList(growable: false);
  final transaksiQris = transaksiPeriode
      .where((t) => t.metodeBayar == MetodeBayarTransaksi.qris)
      .toList(growable: false);

  final jumlahHadir =
      kehadiranPeriode.where((k) => k.statusHadir == StatusHadir.hadir).length;
  final jumlahTidakHadir = kehadiranPeriode
      .where((k) => k.statusHadir == StatusHadir.tidakHadir)
      .length;

  final stokMenipis = obatAllTime
      .where((o) => o.statusStok == StokStatus.menipis)
      .toList(growable: false);
  final stokHabis = obatAllTime
      .where((o) => o.statusStok == StokStatus.habis)
      .toList(growable: false);

  final stokKritis = obatAllTime
      .where(
        (o) =>
            o.statusStok == StokStatus.menipis ||
            o.statusStok == StokStatus.habis,
      )
      .toList()
    ..sort((a, b) {
      final statusRankA = a.statusStok == StokStatus.habis ? 0 : 1;
      final statusRankB = b.statusStok == StokStatus.habis ? 0 : 1;
      final byStatus = statusRankA.compareTo(statusRankB);
      if (byStatus != 0) return byStatus;

      final byStock = a.stokSaatIni.compareTo(b.stokSaatIni);
      if (byStock != 0) return byStock;

      return b.selisihStok.compareTo(a.selisihStok);
    });

  final totalDays = endDate.difference(startDate).inDays + 1;
  final chartDays = totalDays <= 0 ? 1 : (totalDays < 7 ? totalDays : 7);

  return LaporanSummary(
    totalPendapatanKeseluruhan: totalPendapatanKeseluruhan,
    pendapatanPeriodeAktif: pendapatanPeriodeAktif,
    pendapatanReadyStock: pendapatanReadyStock,
    pendapatanPraktekCustomBundled: pendapatanPraktekCustomBundled,
    pendapatanEtalase1: pendapatanEtalase1,
    pendapatanEtalase2: pendapatanEtalase2,
    pendapatanEtalase3Custom: pendapatanEtalase3Custom,
    selisihPendapatanBelumTerpetakan: selisihPendapatanBelumTerpetakan,
    jumlahTransaksi: transaksiPeriode.length,
    jumlahTransaksiReadyStock: transaksiReadyStock.length,
    jumlahTransaksiPraktekCustom: transaksiPraktekCustom.length,
    jumlahTransaksiCash: transaksiCash.length,
    jumlahTransaksiQris: transaksiQris.length,
    nominalCash: _sumTotal(transaksiCash),
    nominalQris: _sumTotal(transaksiQris),
    jumlahPasienTerdaftar: pasienAllTime.length,
    jumlahPasienTerjadwalPeriode: pasienPeriode.length,
    jumlahHadir: jumlahHadir,
    jumlahTidakHadir: jumlahTidakHadir,
    jumlahStokMenipis: stokMenipis.length,
    jumlahStokHabis: stokHabis.length,
    stokKritis: stokKritis.take(10).toList(growable: false),
    chartPoints: buildDailyIncomePoints(
      items: transaksiPeriode,
      endDate: endDate,
      days: chartDays,
    ),
  );
}
