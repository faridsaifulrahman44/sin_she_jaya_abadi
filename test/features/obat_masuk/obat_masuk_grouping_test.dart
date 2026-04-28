import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_masuk_model.dart';
import 'package:klinik_mobile_app/features/obat_masuk/obat_masuk_grouping.dart';

void main() {
  group('groupObatMasukByTanggal', () {
    test('returns empty list for empty input', () {
      final result = groupObatMasukByTanggal([]);
      expect(result, isEmpty);
    });

    test('groups single item correctly', () {
      final items = [
        ObatMasukModel(
          idMasuk: 1,
          idObat: 10,
          tanggalMasuk: DateTime(2026, 3, 28),
          jumlahMasuk: 5,
          idAdmin: 1,
        ),
      ];

      final result = groupObatMasukByTanggal(items);
      expect(result.length, 1);
      expect(result[0].tanggal, DateTime(2026, 3, 28));
      expect(result[0].jumlahItem, 1);
      expect(result[0].totalJumlahMasuk, 5);
    });

    test('groups multiple items on same date correctly', () {
      final items = [
        ObatMasukModel(
          idMasuk: 1,
          idObat: 10,
          tanggalMasuk: DateTime(2026, 3, 28),
          jumlahMasuk: 5,
          idAdmin: 1,
        ),
        ObatMasukModel(
          idMasuk: 2,
          idObat: 11,
          tanggalMasuk: DateTime(2026, 3, 28),
          jumlahMasuk: 3,
          idAdmin: 1,
        ),
        ObatMasukModel(
          idMasuk: 3,
          idObat: 12,
          tanggalMasuk: DateTime(2026, 3, 28),
          jumlahMasuk: 10,
          idAdmin: 1,
        ),
      ];

      final result = groupObatMasukByTanggal(items);
      expect(result.length, 1);
      expect(result[0].jumlahItem, 3);
      expect(result[0].totalJumlahMasuk, 18);
    });

    test('groups items across multiple dates correctly', () {
      final items = [
        ObatMasukModel(
          idMasuk: 1,
          idObat: 10,
          tanggalMasuk: DateTime(2026, 3, 28),
          jumlahMasuk: 5,
          idAdmin: 1,
        ),
        ObatMasukModel(
          idMasuk: 2,
          idObat: 11,
          tanggalMasuk: DateTime(2026, 3, 30),
          jumlahMasuk: 3,
          idAdmin: 1,
        ),
        ObatMasukModel(
          idMasuk: 3,
          idObat: 12,
          tanggalMasuk: DateTime(2026, 3, 28),
          jumlahMasuk: 2,
          idAdmin: 1,
        ),
      ];

      final result = groupObatMasukByTanggal(items);
      expect(result.length, 2);

      // Sorted descending by date — newest first
      expect(result[0].tanggal, DateTime(2026, 3, 30));
      expect(result[0].jumlahItem, 1);
      expect(result[0].totalJumlahMasuk, 3);

      expect(result[1].tanggal, DateTime(2026, 3, 28));
      expect(result[1].jumlahItem, 2);
      expect(result[1].totalJumlahMasuk, 7);
    });

    test('ignores time component, groups by calendar date only', () {
      final items = [
        ObatMasukModel(
          idMasuk: 1,
          idObat: 10,
          tanggalMasuk: DateTime(2026, 3, 28, 8, 0),
          jumlahMasuk: 5,
          idAdmin: 1,
        ),
        ObatMasukModel(
          idMasuk: 2,
          idObat: 11,
          tanggalMasuk: DateTime(2026, 3, 28, 20, 30),
          jumlahMasuk: 3,
          idAdmin: 1,
        ),
      ];

      final result = groupObatMasukByTanggal(items);
      expect(result.length, 1);
      expect(result[0].jumlahItem, 2);
      expect(result[0].totalJumlahMasuk, 8);
    });
  });
}
