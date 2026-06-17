import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/pages/transaksi_hub_page.dart';

void main() {
  group('SummaryMetrics', () {
    test('calculates omzet and counts correctly', () {
      final items = [
        TransaksiModel(
          idTransaksi: 1,
          tanggal: DateTime(2026, 5, 7),
          jenisTransaksi: JenisTransaksi.obatReadyStock,
          total: 120000,
          metodeBayar: MetodeBayarTransaksi.cash,
          idAdmin: 1,
        ),
        TransaksiModel(
          idTransaksi: 2,
          tanggal: DateTime(2026, 5, 7),
          jenisTransaksi: JenisTransaksi.praktekCustom,
          total: 80000,
          metodeBayar: MetodeBayarTransaksi.qris,
          idAdmin: 1,
        ),
      ];

      final summary = SummaryMetrics.fromItems(items);
      expect(summary.totalTransaksi, 2);
      expect(summary.totalOmzet, 200000);
      expect(summary.totalObat, 1);
      expect(summary.totalPraktek, 1);
      expect(summary.omzetObat, 120000);
      expect(summary.omzetPraktek, 80000);
    });
  });
}
