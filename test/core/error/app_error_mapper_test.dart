import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/error/app_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppErrorMapper toMessage', () {
    test('23514 obat_etalase_check → pesan spesifik etalase', () {
      // PostgrestException: check constraint violated, constraint name di hint.
      final ex = PostgrestException(
        message: 'new row for relation "obat" violates check constraint '
            '"obat_etalase_check"',
        code: '23514',
        hint: 'Failing row contains (1, Paracetamol, 10, 2, etalase_x, strip).',
      );
      final msg = AppErrorMapper.toMessage(ex);
      expect(msg, contains('Etalase'));
      expect(msg, isNot(contains('Terjadi kendala saat mengakses database.')));
    });

    test('23514 CHECK_STOCK_FAILED → pesan oversell spesifik', () {
      final ex = PostgrestException(
        message: 'oversell: qty melebihi stok tersedia',
        code: '23514',
        hint: 'CHECK_STOCK_FAILED',
      );
      final msg = AppErrorMapper.toMessage(ex);
      expect(msg, contains('Stok tidak mencukupi'));
    });

    test('23514 tanpa nama constraint spesifik → pesan umum check constraint',
        () {
      final ex = PostgrestException(
        message: 'new row violates check constraint "obat_stok_check"',
        code: '23514',
        hint: '',
      );
      final msg = AppErrorMapper.toMessage(ex);
      expect(msg, contains('tidak memenuhi aturan'));
    });

    test('23505 duplicate key → pesan data duplikat', () {
      final ex = PostgrestException(
        message: 'duplicate key value violates unique constraint '
            '"obat_nama_obat_key"',
        code: '23505',
      );
      expect(AppErrorMapper.toMessage(ex), contains('sama sudah tersedia'));
    });

    test('23503 foreign key → pesan relasi data', () {
      final ex = PostgrestException(
        message: 'insert or update on table "obat_masuk" violates '
            'foreign key constraint "obat_masuk_id_obat_fkey"',
        code: '23503',
      );
      expect(
        AppErrorMapper.toMessage(ex),
        contains('terhubung dengan data lain'),
      );
    });

    test('kode tidak dikenal → pesan umum database', () {
      final ex = PostgrestException(
        message: 'internal error',
        code: 'XX000',
      );
      // toMessage() menyertakan debug info saat kDebugMode=true (termasuk di test).
      // Ini behavior yang dirancang: pesan user-facing + detail debug untuk developer.
      expect(
        AppErrorMapper.toMessage(ex),
        'Terjadi kendala saat mengakses database.\n[debug] code=XX000 | pg_code=XX000 | message=internal error',
      );
    });
  });
}
