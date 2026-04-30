import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:klinik_mobile_app/core/services/receipt_printer_service.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('ReceiptPrinterService', () {
    test('buildReceiptText formats 58mm receipt text safely', () {
      final service = ReceiptPrinterService();
      final transaksi = TransaksiModel(
        idTransaksi: 12,
        tanggal: DateTime(2026, 4, 30),
        jenisTransaksi: JenisTransaksi.obatReadyStock,
        total: 45000,
        metodeBayar: MetodeBayarTransaksi.cash,
        idPasien: 3,
        idAdmin: 7,
        createdAt: DateTime(2026, 4, 30, 9, 5),
      );
      final items = [
        const TransaksiItemModel(
          idItem: 1,
          idTransaksi: 12,
          idObat: 99,
          namaObat: 'Ramuan Herbal Sin She Sangat Panjang',
          jumlah: 2,
          hargaSatuan: 15000,
          subtotal: 30000,
          idAdmin: 7,
          satuanTerjual: 'Botol',
        ),
        const TransaksiItemModel(
          idItem: 2,
          idTransaksi: 12,
          idObat: 100,
          namaObat: 'Minyak',
          jumlah: 1,
          hargaSatuan: 15000,
          subtotal: 15000,
          idAdmin: 7,
        ),
      ];

      final text = service.buildReceiptText(
        transaksi: transaksi,
        items: items,
        namaPasien: 'Budi',
        namaAdmin: 'Admin Satu',
      );

      expect(text, contains('SIN SHE JAYA ABADI'));
      expect(text, contains('Struk Pembayaran'));
      expect(text, contains('No                           #12'));
      expect(text, contains('Pasien                      Budi'));
      expect(text, contains('Petugas               Admin Satu'));
      expect(text, contains('2 Botol x Rp 15.000    Rp 30.000'));
      expect(text, contains('TOTAL                  Rp 45.000'));
      expect(text, contains('Metode                     Tunai'));

      for (final line in text.split('\n')) {
        expect(line.length, lessThanOrEqualTo(32));
      }
    });
  });
}
