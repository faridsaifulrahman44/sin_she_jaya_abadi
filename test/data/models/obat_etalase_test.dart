import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';

void main() {
  group('Etalase enum', () {
    test('value getter mengembalikan string plain (sesuai schema DB)', () {
      // Schema final: CHECK (etalase IN ('etalase1','etalase2','etalase3'))
      // Enum.name di Dart 3 mengembalikan identifier, bukan 'Etalase.etalase1'.
      expect(Etalase.etalase1.value, 'etalase1');
      expect(Etalase.etalase2.value, 'etalase2');
      expect(Etalase.etalase3.value, 'etalase3');
    });

    test('label getter mengembalikan label yang readable', () {
      expect(Etalase.etalase1.label, 'Etalase 1');
      expect(Etalase.etalase2.label, 'Etalase 2');
      expect(Etalase.etalase3.label, 'Etalase 3');
    });

    test('fromString memetakan nilai DB → enum dengan benar', () {
      expect(Etalase.fromString('etalase1'), Etalase.etalase1);
      expect(Etalase.fromString('etalase2'), Etalase.etalase2);
      expect(Etalase.fromString('etalase3'), Etalase.etalase3);
    });

    test('fromString fallback ke etalase1 untuk nilai invalid', () {
      expect(Etalase.fromString('invalid'), Etalase.etalase1);
      expect(Etalase.fromString(''), Etalase.etalase1);
      expect(Etalase.fromString(null), Etalase.etalase1);
      expect(Etalase.fromString('Etalase 1'),
          Etalase.etalase1); // label tidak dipakai utk parsing
    });

    test('ObatModel.fromMap parsing etalase dari DB', () {
      final model = ObatModel.fromMap({
        'id_obat': 1,
        'nama_obat': 'Paracetamol',
        'stok_saat_ini': 10,
        'stok_minimum': 5,
        'etalase': 'etalase2',
        'satuan': 'strip',
        'keterangan': null,
        'id_admin': 1,
        'created_at': null,
        'updated_at': null,
      });
      expect(model.etalase, Etalase.etalase2);
      expect(model.etalase.label, 'Etalase 2');
    });

    test('ObatModel.fromMap fallback etalase1 untuk nilai null/invalid', () {
      final model = ObatModel.fromMap({
        'id_obat': 1,
        'nama_obat': 'Paracetamol',
        'stok_saat_ini': 10,
        'stok_minimum': 5,
        'etalase': null,
        'satuan': null,
        'keterangan': null,
        'id_admin': 1,
        'created_at': null,
        'updated_at': null,
      });
      expect(model.etalase, Etalase.etalase1);
    });
  });
}
