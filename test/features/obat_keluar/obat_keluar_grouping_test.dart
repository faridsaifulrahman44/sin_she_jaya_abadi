import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_model.dart';
import 'package:klinik_mobile_app/features/obat_keluar/obat_keluar_grouping.dart';

void main() {
  test('groupObatKeluarByTanggal groups and sorts transactions by date', () {
    final result = groupObatKeluarByTanggal([
      ObatKeluarModel(
        idTerjual: 1,
        tanggalTerjual: DateTime(2026, 3, 28),
        noEtalase: '1',
        jumlahItem: 2,
        totalNominal: 150000,
        idAdmin: 1,
      ),
      ObatKeluarModel(
        idTerjual: 2,
        tanggalTerjual: DateTime(2026, 3, 28),
        noEtalase: '2',
        jumlahItem: 1,
        totalNominal: 50000,
        idAdmin: 1,
      ),
      ObatKeluarModel(
        idTerjual: 3,
        tanggalTerjual: DateTime(2026, 3, 27),
        noEtalase: '1',
        jumlahItem: 1,
        totalNominal: 25000,
        idAdmin: 1,
      ),
    ]);

    expect(result.length, 2);
    expect(result.first.tanggal, DateTime(2026, 3, 28));
    // Total item rows: 2 + 1 = 3
    expect(result.first.jumlahItem, 3);
    expect(result.first.totalNominal, 200000);
    // Total nota (header): 1 + 1 = 2
    expect(result.first.jumlahNota, 2);
  });

  test('groupObatKeluarByTanggal sorts by tanggal descending', () {
    final result = groupObatKeluarByTanggal([
      ObatKeluarModel(
        idTerjual: 1,
        tanggalTerjual: DateTime(2026, 3, 27),
        noEtalase: '1',
        jumlahItem: 1,
        totalNominal: 25000,
        idAdmin: 1,
      ),
      ObatKeluarModel(
        idTerjual: 2,
        tanggalTerjual: DateTime(2026, 3, 28),
        noEtalase: '1',
        jumlahItem: 2,
        totalNominal: 150000,
        idAdmin: 1,
      ),
    ]);

    expect(result.first.tanggal, DateTime(2026, 3, 28));
    expect(result.last.tanggal, DateTime(2026, 3, 27));
  });
}
