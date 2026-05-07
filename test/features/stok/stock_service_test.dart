import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/features/stok/services/stock_service.dart';

void main() {
  group('StockService validation', () {
    final service = StockService();

    test('stokMasuk rejects negative quantity', () async {
      expect(
        () => service.stokMasuk(
          idObat: 1,
          tanggalMasuk: DateTime(2026, 5, 7),
          jumlahMasuk: -1,
          idAdmin: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('syncOpname rejects negative stock values', () async {
      expect(
        () => service.syncOpname(
          idObat: 1,
          tanggalOpname: DateTime(2026, 5, 7),
          stokSistem: -1,
          stokFisik: 10,
          idAdmin: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
