import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/features/sinkronisasi_stok/sinkronisasi_stok_calc.dart';

void main() {
  group('sinkronisasiStokSelisihLabel', () {
    test('mengembalikan "Sesuai" untuk selisih 0', () {
      expect(sinkronisasiStokSelisihLabel(0), 'Sesuai');
    });

    test('menambahkan tanda plus untuk selisih positif', () {
      expect(sinkronisasiStokSelisihLabel(4), '+4');
    });

    test('menampilkan angka negatif apa adanya untuk selisih negatif', () {
      expect(sinkronisasiStokSelisihLabel(-3), '-3');
    });
  });
}
