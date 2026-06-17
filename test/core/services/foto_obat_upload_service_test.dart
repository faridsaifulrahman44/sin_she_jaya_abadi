import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/services/foto_obat_upload_service.dart';

void main() {
  group('FotoObatUploadService.buildFotoKey', () {
    final service = FotoObatUploadService();

    test('normalisasi etalase1 → etalase-1', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase1',
        namaObat: 'Die Da Tay Ping Yao Jing',
      );
      expect(key, equals('etalase-1/die_da_tay_ping_yao_jing.webp'));
    });

    test('normalisasi etalase2 → etalase-2', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase2',
        namaObat: 'Sanjin Tablets',
      );
      expect(key, equals('etalase-2/sanjin_tablets.webp'));
    });

    test('normalisasi etalase3 → etalase-3', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase3',
        namaObat: 'Layanan Praktek',
      );
      expect(key, equals('etalase-3/layanan_praktek.webp'));
    });

    test('nama dengan spasi dan dash → underscore', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase1',
        namaObat: 'Four-Season Medicated Oil',
      );
      expect(key, equals('etalase-1/four_season_medicated_oil.webp'));
    });

    test('nama dengan karakter non-alphanumeric di-strip', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase2',
        namaObat: 'Obat A+ (Eceran) #1',
      );
      // hanya a-z, 0-9, underscore yang diizinkan
      expect(key, equals('etalase-2/obat_a_eceran_1.webp'));
    });

    test('awalan/akhiran underscore di-trim', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase1',
        namaObat: '  --Test--  ',
      );
      expect(key, equals('etalase-1/test.webp'));
    });

    test('etalase label uppercase di-lowercase', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'ETALASE2',
        namaObat: 'Sanjin',
      );
      expect(key, equals('etalase-2/sanjin.webp'));
    });

    test('etalase label dalam format dengan dash sudah benar', () {
      // Jika user/admin terlanjur pakai format dash, harus tetap valid
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase-1',
        namaObat: 'Ashwagandha',
      );
      expect(key, equals('etalase-1/ashwagandha.webp'));
    });

    test('path tanpa leading slash atau prefix bucket', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase1',
        namaObat: 'Test',
      );
      expect(key.startsWith('/'), isFalse);
      expect(key.startsWith('obat-images/'), isFalse);
    });

    test('nama kosong → path dengan slug kosong (tidak error)', () {
      final key = service.buildFotoKey(
        etalaseLabel: 'etalase1',
        namaObat: '',
      );
      // slug dari string kosong adalah string kosong
      expect(key, equals('etalase-1/.webp'));
    });
  });

  group('FotoObatUploadService.uploadFoto validation', () {
    final service = FotoObatUploadService();

    test('bytes kosong → throw ValidationException', () async {
      expect(
        () => service.uploadFoto(
          bytes: Uint8List(0),
          fileName: 'test.jpg',
          etalaseLabel: 'etalase1',
          namaObat: 'Test',
        ),
        throwsA(isA<dynamic>().having(
          (e) => e.toString(),
          'toString',
          contains('gambar kosong'),
        )),
      );
    });

    test('bytes > 5 MB → throw ValidationException', () async {
      // 5 MB + 1 byte — terlalu besar
      final bigBytes = Uint8List(5 * 1024 * 1024 + 1);
      expect(
        () => service.uploadFoto(
          bytes: bigBytes,
          fileName: 'test.jpg',
          etalaseLabel: 'etalase1',
          namaObat: 'Test',
        ),
        throwsA(isA<dynamic>().having(
          (e) => e.toString(),
          'toString',
          contains('5 MB'),
        )),
      );
    });

    test('bytes persis 5 MB → tidak throw karena <= 5 MB', () async {
      // Boundary: persis 5 MB tidak boleh ditolak
      // Tapi karena tidak ada Supabase, akan throw lain di step upload.
      // Kita hanya cek bahwa validation awal LULUS, bukan error size.
      try {
        await service.uploadFoto(
          bytes: Uint8List(5 * 1024 * 1024),
          fileName: 'test.jpg',
          etalaseLabel: 'etalase1',
          namaObat: 'Test',
        );
      } catch (e) {
        // Boleh error di step upload (Supabase unavailable di test),
        // tapi TIDAK boleh error "5 MB"
        expect(e.toString(), isNot(contains('Ukuran foto maksimal 5 MB')));
      }
    });
  });
}
