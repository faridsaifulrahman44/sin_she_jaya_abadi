import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/features/obat_keluar/obat_keluar_form_entry.dart';

void main() {
  group('ObatKeluarFormEntry', () {
    test('subtotal dihitung dari jumlah x harga', () {
      final entry = ObatKeluarFormEntry(
        idObat: 7,
        jumlah: 3,
        hargaSatuan: 12500,
      );

      expect(entry.subtotal, 37500);
    });

    test('validate gagal jika idObat kosong', () {
      final entry = ObatKeluarFormEntry(
        jumlah: 1,
        hargaSatuan: 1000,
      );

      expect(entry.validate(), 'Pilih obat');
    });

    test('validate gagal jika jumlah <= 0', () {
      final entry = ObatKeluarFormEntry(
        idObat: 7,
        jumlah: 0,
        hargaSatuan: 1000,
      );

      expect(entry.validate(), 'Qty harus > 0');
    });

    test('validate gagal jika harga negatif', () {
      final entry = ObatKeluarFormEntry(
        idObat: 7,
        jumlah: 1,
        hargaSatuan: -1000,
      );

      expect(entry.validate(), 'Harga harus >= 0');
    });

    test('validate lolos untuk item valid', () {
      final entry = ObatKeluarFormEntry(
        idObat: 7,
        jumlah: 2,
        hargaSatuan: 5000,
      );

      expect(entry.validate(), isNull);
    });

    // ── Oversell validation ───────────────────────────────────

    ObatModel obat5Stok() => const ObatModel(
          idObat: 1,
          namaObat: 'Paracetamol',
          stokSaatIni: 5,
          stokMinimum: 2,
          etalase: Etalase.etalase1,
        );

    test('validateStock lolos: qty <= stok', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: 5, hargaSatuan: 1000);
      expect(entry.validateStock(obat5Stok()), isNull);
    });

    test('validateStock lolos: qty < stok', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: 3, hargaSatuan: 1000);
      expect(entry.validateStock(obat5Stok()), isNull);
    });

    test('validateStock gagal: qty > stok (oversell)', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: 10, hargaSatuan: 1000);
      final err = entry.validateStock(obat5Stok());
      expect(err, contains('Stok tidak cukup'));
      expect(err, contains('5')); // stok tersedia
    });

    test('validateStock gagal: qty == stok + 1', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: 6, hargaSatuan: 1000);
      final err = entry.validateStock(obat5Stok());
      expect(err, isNotNull);
      expect(err, contains('Stok tidak cukup'));
    });

    test('validateStock lolos: qty == stok (exact)', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: 5, hargaSatuan: 1000);
      expect(entry.validateStock(obat5Stok()), isNull);
    });

    test('validateStock diskip: idObat null', () {
      final entry =
          ObatKeluarFormEntry(idObat: null, jumlah: 100, hargaSatuan: 1000);
      expect(entry.validateStock(obat5Stok()), isNull);
    });

    test('validateStock diskip: selectedObat null', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: 100, hargaSatuan: 1000);
      expect(entry.validateStock(null), isNull);
    });

    test('validateStock diskip: selectedObat.idObat tidak match', () {
      final entry =
          ObatKeluarFormEntry(idObat: 99, jumlah: 100, hargaSatuan: 1000);
      expect(entry.validateStock(obat5Stok()), isNull);
    });

    test('validateStock diskip: jumlah null', () {
      final entry =
          ObatKeluarFormEntry(idObat: 1, jumlah: null, hargaSatuan: 1000);
      expect(entry.validateStock(obat5Stok()), isNull);
    });

    test('multi-item: item 1 OK, item 2 oversell terdeteksi', () {
      final entries = [
        ObatKeluarFormEntry(idObat: 1, jumlah: 3, hargaSatuan: 1000),
        ObatKeluarFormEntry(idObat: 2, jumlah: 20, hargaSatuan: 1500),
      ];
      final stokMap = {
        1: const ObatModel(
            idObat: 1,
            namaObat: 'A',
            stokSaatIni: 5,
            stokMinimum: 1,
            etalase: Etalase.etalase1),
        2: const ObatModel(
            idObat: 2,
            namaObat: 'B',
            stokSaatIni: 8,
            stokMinimum: 1,
            etalase: Etalase.etalase1),
      };

      // Item 1 passes
      expect(entries[0].validateStock(stokMap[1]), isNull);
      // Item 2 fails (oversell)
      final err = entries[1].validateStock(stokMap[2]);
      expect(err, isNotNull);
      expect(err, contains('Stok tidak cukup'));
    });
  });
}
