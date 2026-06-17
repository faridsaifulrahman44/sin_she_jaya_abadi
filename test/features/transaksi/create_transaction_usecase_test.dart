import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/features/stok/services/stock_service.dart';
import 'package:klinik_mobile_app/features/transaksi/usecases/create_transaction_usecase.dart';
import 'package:klinik_mobile_app/test_helpers/mock_repositories.dart';

void main() {
  group('CreateTransactionUseCase validation', () {
    // Inject mock StockService — validation throw di use case
    // sebelum stockService method dipanggil. Tidak butuh Supabase real.
    late CreateTransactionUseCase useCase;

    setUp(() {
      final mocks = MockRepositories();
      final stockService = StockService(
        obatMasukRepository: mocks.obatMasuk,
        obatKeluarRepository: mocks.obatKeluar,
        sinkronisasiStokRepository: mocks.sinkronisasiStok,
        transaksiRepository: mocks.transaksi,
      );
      useCase = CreateTransactionUseCase(stockService: stockService);
    });

    test('rejects admin mismatch', () async {
      final transaksi = TransaksiModel(
        idTransaksi: 0,
        tanggal: DateTime(2026, 5, 9),
        jenisTransaksi: JenisTransaksi.praktekCustom,
        total: 150000,
        metodeBayar: MetodeBayarTransaksi.cash,
        idPasien: 1,
        keterangan: null,
        durasiHarian: null,
        idAdmin: 2,
      );

      expect(
        () => useCase.execute(
          transaksi: transaksi,
          items: const [],
          idAdmin: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects ready-stock total mismatch', () async {
      final transaksi = TransaksiModel(
        idTransaksi: 0,
        tanggal: DateTime(2026, 5, 9),
        jenisTransaksi: JenisTransaksi.obatReadyStock,
        total: 9000,
        metodeBayar: MetodeBayarTransaksi.cash,
        idPasien: null,
        keterangan: null,
        durasiHarian: null,
        idAdmin: 1,
      );

      final items = [
        TransaksiItemModel(
          idItem: 0,
          idTransaksi: 0,
          idObat: 1,
          namaObat: 'A',
          jumlah: 1,
          hargaSatuan: 10000,
          subtotal: 10000,
          idAdmin: 1,
        ),
      ];

      expect(
        () => useCase.execute(
          transaksi: transaksi,
          items: items,
          idAdmin: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
