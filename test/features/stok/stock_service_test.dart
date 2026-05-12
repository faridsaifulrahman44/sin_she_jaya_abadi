import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
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

    test('stokKeluar rejects empty items', () async {
      expect(
        () => service.stokKeluar(
          tanggalTerjual: DateTime(2026, 5, 7),
          items: const [],
          idAdmin: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createTransaksiAtomic rejects ready-stock transaction without item',
        () async {
      final transaksi = TransaksiModel(
        idTransaksi: 0,
        tanggal: DateTime(2026, 5, 7),
        jenisTransaksi: JenisTransaksi.obatReadyStock,
        total: 10000,
        metodeBayar: MetodeBayarTransaksi.cash,
        idPasien: null,
        keterangan: null,
        durasiHarian: null,
        idAdmin: 1,
      );
      expect(
        () => service.createTransaksiAtomic(
          transaksi: transaksi,
          items: const [],
          idAdmin: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
