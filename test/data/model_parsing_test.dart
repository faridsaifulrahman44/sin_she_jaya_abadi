import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/kehadiran_model.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_item_model.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_model.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/data/models/pasien_model.dart';

void main() {
  group('model parsing', () {
    test('ObatModel parses new stock fields and etalase correctly', () {
      final model = ObatModel.fromMap({
        'id_obat': '7',
        'nama_obat': 'Paracetamol',
        'stok_saat_ini': 8,
        'stok_minimum': 10,
        'etalase': 'etalase2',
        'satuan': null,
        'keterangan': '',
        'foto_url': 'https://cdn.example.com/obat/7.jpg',
        'updated_at': '2026-03-28T10:00:00.000Z',
      });

      expect(model.idObat, 7);
      expect(model.namaObat, 'Paracetamol');
      expect(model.stokSaatIni, 8);
      expect(model.stokMinimum, 10);
      expect(model.etalase, Etalase.etalase2);
      expect(model.satuan, isNull);
      expect(model.keterangan, isNull);
      expect(model.fotoUrl, 'https://cdn.example.com/obat/7.jpg');
      expect(model.updatedAt, isNotNull);
      expect(model.isLowStock, true);
      expect(model.selisihStok, 2);
    });

    test('ObatModel defaults etalase to etalase1 on unknown value', () {
      final model = ObatModel.fromMap({
        'id_obat': 1,
        'nama_obat': 'Amoxicillin',
        'stok_saat_ini': 50,
        'stok_minimum': 10,
        'etalase': 'unknown',
        'satuan': 'strip',
      });

      expect(model.etalase, Etalase.etalase1);
      expect(model.isLowStock, false);
      expect(model.selisihStok, 0);
    });

    test('ObatKeluarModel parses numeric string values safely', () {
      final model = ObatKeluarModel.fromMap({
        'id_terjual': '3',
        'tanggal_terjual': '2026-03-28',
        'no_etalase': 'A1',
        'jumlah_transaksi': '2',
        'total_nominal': '150000',
        'id_admin': '1',
      });

      expect(model.idTerjual, 3);
      expect(model.tanggalTerjual, DateTime(2026, 3, 28));
      expect(model.jumlahItem, 2);
      expect(model.totalNominal, 150000);
    });

    test('PasienModel parses nullable date and label correctly', () {
      final model = PasienModel.fromMap({
        'id_pasien': 10,
        'nomor_pasien': 'PSN-10',
        'nama_pasien': 'Sinta',
        'alamat': 'Jakarta',
        'usia': '29',
        'jenis_kelamin': 'P',
        'tanggal_janjian': '2026-03-30',
      });

      expect(model.idPasien, 10);
      expect(model.usia, 29);
      expect(model.jenisKelaminLabel, 'Perempuan');
      expect(model.tanggalJanjian, DateTime(2026, 3, 30));
    });

    test('KehadiranModel parses StatusHadir from snake_case DB value correctly',
        () {
      final model = KehadiranModel.fromMap({
        'id_kehadiran': '5',
        'id_pasien': '10',
        'tanggal_hadir': '2026-03-30',
        'status_hadir': 'hadir',
        'keterangan': null,
        'id_admin': '1',
      });

      expect(model.idKehadiran, 5);
      expect(model.idPasien, 10);
      expect(model.statusHadir, StatusHadir.hadir);
      expect(model.statusHadir.toDbString(), 'hadir');
      expect(model.keterangan, isNull);
    });

    test('KehadiranModel parses tidak_hadir from DB correctly', () {
      final model = KehadiranModel.fromMap({
        'id_kehadiran': '5',
        'id_pasien': '10',
        'tanggal_hadir': '2026-03-30',
        'status_hadir': 'tidak_hadir',
        'keterangan': null,
        'id_admin': '1',
      });

      expect(model.statusHadir, StatusHadir.tidakHadir);
      expect(model.statusHadir.toDbString(), 'tidak_hadir');
    });

    test('StatusHadir enum fromDbString parses snake_case DB values correctly',
        () {
      expect(StatusHadir.fromDbString('hadir'), StatusHadir.hadir);
      expect(StatusHadir.fromDbString('tidak_hadir'), StatusHadir.tidakHadir);
    });

    test('StatusHadir enum fromDbString falls back to hadir for unknown values',
        () {
      expect(StatusHadir.fromDbString('invalid'), StatusHadir.hadir);
      expect(StatusHadir.fromDbString(null), StatusHadir.hadir);
    });

    // ── ObatKeluarItemModel ──────────────────────────────────────────────────

    test('ObatKeluarItemModel parses fields correctly', () {
      final item = ObatKeluarItemModel.fromMap({
        'id_item': '10',
        'id_terjual': '3',
        'id_obat': '7',
        'jumlah': '5',
        'harga_satuan': '25000',
        'subtotal': '125000',
        'is_legacy': false,
        'created_at': '2026-04-01T10:00:00.000Z',
      });

      expect(item.idItem, 10);
      expect(item.idTerjual, 3);
      expect(item.idObat, 7);
      expect(item.jumlah, 5);
      expect(item.hargaSatuan, 25000);
      expect(item.subtotal, 125000);
      expect(item.isLegacy, false);
      expect(item.createdAt, isNotNull);
    });

    test('ObatKeluarItemModel marks legacy item correctly', () {
      final item = ObatKeluarItemModel.fromMap({
        'id_item': '1',
        'id_terjual': '99',
        'id_obat': null,
        'jumlah': '1',
        'harga_satuan': '0',
        'subtotal': '0',
        'is_legacy': true,
      });

      expect(item.isLegacy, true);
      expect(item.idObat, 0); // null → 0 (legacy unknown)
    });

    // ── ObatKeluarModel header + items ──────────────────────────────────────

    test('ObatKeluarModel computed totals from items', () {
      final model = ObatKeluarModel(
        idTerjual: 1,
        tanggalTerjual: DateTime(2026, 4, 1),
        idAdmin: 1,
        items: [
          ObatKeluarItemModel(
            idItem: 1,
            idTerjual: 1,
            idObat: 7,
            jumlah: 3,
            hargaSatuan: 10000,
            subtotal: 30000,
            isLegacy: false,
          ),
          ObatKeluarItemModel(
            idItem: 2,
            idTerjual: 1,
            idObat: 8,
            jumlah: 2,
            hargaSatuan: 15000,
            subtotal: 30000,
            isLegacy: false,
          ),
        ],
      );

      expect(model.computedJumlahItem, 2);
      expect(model.computedTotalNominal, 60000);
      expect(model.isLegacyOnly, false);
    });

    test('ObatKeluarModel ignores legacy items in computed totals', () {
      final model = ObatKeluarModel(
        idTerjual: 1,
        tanggalTerjual: DateTime(2026, 4, 1),
        idAdmin: 1,
        items: [
          ObatKeluarItemModel(
            idItem: 1,
            idTerjual: 1,
            idObat: 0,
            jumlah: 1,
            hargaSatuan: 0,
            subtotal: 0,
            isLegacy: true,
          ),
          ObatKeluarItemModel(
            idItem: 2,
            idTerjual: 1,
            idObat: 7,
            jumlah: 3,
            hargaSatuan: 10000,
            subtotal: 30000,
            isLegacy: false,
          ),
        ],
      );

      // Legacy item excluded
      expect(model.computedJumlahItem, 1);
      expect(model.computedTotalNominal, 30000);
      expect(model.isLegacyOnly, false);
    });

    test('ObatKeluarModel isLegacyOnly is true when all items are legacy', () {
      final model = ObatKeluarModel(
        idTerjual: 1,
        tanggalTerjual: DateTime(2026, 4, 1),
        idAdmin: 1,
        items: [
          ObatKeluarItemModel(
            idItem: 1,
            idTerjual: 1,
            idObat: 0,
            jumlah: 1,
            hargaSatuan: 0,
            subtotal: 0,
            isLegacy: true,
          ),
        ],
      );

      expect(model.isLegacyOnly, true);
      expect(model.computedJumlahItem, 0);
    });

    test('ObatKeluarModel parses nullable jumlahItem and totalNominal', () {
      final model = ObatKeluarModel.fromMap({
        'id_terjual': '5',
        'tanggal_terjual': '2026-04-01',
        'id_admin': '1',
        // jumlah_transaksi and total_nominal omitted → null
      });

      expect(model.jumlahItem, isNull);
      expect(model.totalNominal, isNull);
      // computed from empty items
      expect(model.computedJumlahItem, 0);
      expect(model.computedTotalNominal, 0);
    });

    test(
        'ObatKeluarModel display getters fallback ke header saat items belum ter-load',
        () {
      final model = ObatKeluarModel.fromMap({
        'id_terjual': 9,
        'tanggal_terjual': '2026-04-01',
        'id_admin': 1,
        'jumlah_transaksi': 3,
        'total_nominal': 125000,
      });

      expect(model.items, isEmpty);
      expect(model.displayJumlahItem, 3);
      expect(model.displayTotalNominal, 125000);
    });

    test(
        'ObatKeluarModel display getters pakai computed saat items sudah ter-load',
        () {
      final model = ObatKeluarModel(
        idTerjual: 11,
        tanggalTerjual: DateTime(2026, 4, 1),
        idAdmin: 1,
        jumlahItem: 10, // cache header berbeda, harus diabaikan saat items ada
        totalNominal: 999999,
        items: [
          ObatKeluarItemModel(
            idItem: 1,
            idTerjual: 11,
            idObat: 7,
            jumlah: 2,
            hargaSatuan: 10000,
            subtotal: 20000,
            isLegacy: false,
          ),
          ObatKeluarItemModel(
            idItem: 2,
            idTerjual: 11,
            idObat: 0,
            jumlah: 1,
            hargaSatuan: 0,
            subtotal: 0,
            isLegacy: true,
          ),
        ],
      );

      expect(model.displayJumlahItem, 1);
      expect(model.displayTotalNominal, 20000);
    });
  });
}
