import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/sinkronisasi_stok_model.dart';

void main() {
  group('SinkronisasiStokModel getters', () {
    test('isBalanced returns true when selisih is zero', () {
      final model = SinkronisasiStokModel(
        idOpname: 1,
        idObat: 10,
        tanggalOpname: DateTime(2026, 3, 28),
        stokSistem: 20,
        stokFisik: 20,
        selisih: 0,
        idAdmin: 1,
      );

      expect(model.isBalanced, true);
      expect(model.isOverStock, false);
      expect(model.isUnderStock, false);
    });

    test('isOverStock returns true when stokFisik > stokSistem', () {
      final model = SinkronisasiStokModel(
        idOpname: 2,
        idObat: 11,
        tanggalOpname: DateTime(2026, 3, 28),
        stokSistem: 15,
        stokFisik: 20,
        selisih: 5,
        idAdmin: 1,
      );

      expect(model.isBalanced, false);
      expect(model.isOverStock, true);
      expect(model.isUnderStock, false);
    });

    test('isUnderStock returns true when stokFisik < stokSistem', () {
      final model = SinkronisasiStokModel(
        idOpname: 3,
        idObat: 12,
        tanggalOpname: DateTime(2026, 3, 28),
        stokSistem: 25,
        stokFisik: 18,
        selisih: -7,
        idAdmin: 1,
      );

      expect(model.isBalanced, false);
      expect(model.isOverStock, false);
      expect(model.isUnderStock, true);
    });
  });

  group('SinkronisasiStokModel.fromMap', () {
    test('parses map with all fields correctly', () {
      final model = SinkronisasiStokModel.fromMap({
        'id_opname': '5',
        'id_obat': '10',
        'tanggal_opname': '2026-03-28',
        'stok_sistem': '20',
        'stok_fisik': '18',
        'selisih': '-2',
        'alasan_penyesuaian': 'Barang rusak',
        'id_admin': '1',
        'created_at': '2026-03-28T10:00:00.000Z',
      });

      expect(model.idOpname, 5);
      expect(model.idObat, 10);
      expect(model.tanggalOpname, DateTime(2026, 3, 28));
      expect(model.stokSistem, 20);
      expect(model.stokFisik, 18);
      expect(model.selisih, -2);
      expect(model.alasanPenyesuaian, 'Barang rusak');
      expect(model.idAdmin, 1);
      expect(model.createdAt, isNotNull);
    });

    test('handles null optional fields gracefully', () {
      final model = SinkronisasiStokModel.fromMap({
        'id_opname': '1',
        'id_obat': '2',
        'tanggal_opname': '2026-03-28',
        'stok_sistem': null,
        'stok_fisik': null,
        'selisih': null,
        'alasan_penyesuaian': null,
        'id_admin': '1',
        'created_at': null,
      });

      expect(model.stokSistem, 0);
      expect(model.stokFisik, 0);
      expect(model.selisih, 0);
      expect(model.alasanPenyesuaian, isNull);
      expect(model.createdAt, isNull);
    });
  });

  group('SinkronisasiStokModel.toMap', () {
    test('serializes all fields correctly', () {
      final model = SinkronisasiStokModel(
        idOpname: 1,
        idObat: 10,
        tanggalOpname: DateTime(2026, 3, 28),
        stokSistem: 20,
        stokFisik: 18,
        selisih: -2,
        alasanPenyesuaian: 'Barang jatuh',
        idAdmin: 1,
        createdAt: null,
      );

      final map = model.toMap();

      expect(map['id_opname'], 1);
      expect(map['id_obat'], 10);
      expect(map['tanggal_opname'], '2026-03-28');
      expect(map['stok_sistem'], 20);
      expect(map['stok_fisik'], 18);
      expect(map['selisih'], -2);
      expect(map['alasan_penyesuaian'], 'Barang jatuh');
      expect(map['id_admin'], 1);
      expect(map['created_at'], isNull);
    });

    test('serializes createdAt as ISO string when present', () {
      final model = SinkronisasiStokModel(
        idOpname: 1,
        idObat: 10,
        tanggalOpname: DateTime(2026, 3, 28),
        stokSistem: 20,
        stokFisik: 20,
        selisih: 0,
        idAdmin: 1,
        createdAt: DateTime(2026, 3, 28, 14, 30),
      );

      final map = model.toMap();
      expect(map['created_at'], contains('2026-03-28'));
    });
  });
}
