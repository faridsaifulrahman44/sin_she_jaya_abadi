import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/kas_keluar_model.dart';

void main() {
  group('KasKeluarModel', () {
    test('fromMap parses all fields correctly', () {
      final map = {
        'id': 5,
        'tanggal': '2026-05-19',
        'kategori': 'Pembelian Obat',
        'jumlah': 150000.0,
        'keterangan': 'Stok vitamin',
        'id_admin': 1,
        'created_at': '2026-05-19T10:00:00Z',
      };

      final model = KasKeluarModel.fromMap(map);

      expect(model.id, 5);
      expect(model.tanggal.year, 2026);
      expect(model.tanggal.month, 5);
      expect(model.tanggal.day, 19);
      expect(model.kategori, 'Pembelian Obat');
      expect(model.jumlah, 150000.0);
      expect(model.keterangan, 'Stok vitamin');
      expect(model.idAdmin, 1);
      expect(model.createdAt, isNotNull);
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'id': 1,
        'tanggal': '2026-05-01',
        'kategori': 'Listrik',
        'jumlah': 500000.0,
        'keterangan': null,
        'id_admin': null,
        'created_at': null,
      };

      final model = KasKeluarModel.fromMap(map);

      expect(model.id, 1);
      expect(model.kategori, 'Listrik');
      expect(model.keterangan, isNull);
      expect(model.idAdmin, isNull);
      expect(model.createdAt, isNull);
    });

    test('fromMap defaults jumlah to 0 for invalid value', () {
      final map = {
        'id': 2,
        'tanggal': '2026-05-01',
        'kategori': 'Gaji',
        'jumlah': 'invalid',
        'id_admin': 1,
      };

      final model = KasKeluarModel.fromMap(map);
      expect(model.jumlah, 0.0);
    });

    test('toMap serializes all fields correctly', () {
      final model = KasKeluarModel(
        id: 3,
        tanggal: DateTime(2026, 5, 15),
        kategori: 'ATK',
        jumlah: 75000.0,
        keterangan: 'Pulpen & kertas',
        idAdmin: 1,
        createdAt: DateTime(2026, 5, 15, 9, 30),
      );

      final map = model.toMap();

      expect(map['id'], 3);
      expect(map['tanggal'], '2026-05-15');
      expect(map['kategori'], 'ATK');
      expect(map['jumlah'], 75000.0);
      expect(map['keterangan'], 'Pulpen & kertas');
      expect(map['id_admin'], 1);
    });

    test('toInsertMap omits id field', () {
      final model = KasKeluarModel(
        id: 99,
        tanggal: DateTime(2026, 5, 20),
        kategori: 'Transport',
        jumlah: 50000.0,
        idAdmin: 1,
      );

      final map = model.toInsertMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['kategori'], 'Transport');
      expect(map['jumlah'], 50000.0);
    });
  });
}