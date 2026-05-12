import 'package:klinik_mobile_app/data/models/kehadiran_model.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/data/models/pasien_model.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/features/laporan/laporan_aggregator.dart';
import 'package:klinik_mobile_app/features/laporan/laporan_summary.dart';

class GenerateReportUseCase {
  const GenerateReportUseCase();

  LaporanSummary execute({
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
    return buildLaporanSummary(
      startDate: startDate,
      endDate: endDate,
      transaksiPeriode: transaksiPeriode,
      transaksiAllTime: transaksiAllTime,
      transaksiItemsAllTime: transaksiItemsAllTime,
      pasienPeriode: pasienPeriode,
      pasienAllTime: pasienAllTime,
      kehadiranPeriode: kehadiranPeriode,
      obatAllTime: obatAllTime,
    );
  }
}
