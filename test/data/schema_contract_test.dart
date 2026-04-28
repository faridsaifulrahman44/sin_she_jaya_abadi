import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schema contract', () {
    late String schemaSql;

    setUpAll(() {
      schemaSql = File('supabase/schema.sql').readAsStringSync();
    });

    test('memiliki tabel inti domain klinik', () {
      const tables = [
        'public.admin',
        'public.obat',
        'public.obat_masuk',
        'public.obat_keluar',
        'public.obat_keluar_item',
        'public.stock_opname',
        'public.pasien',
        'public.kehadiran_pasien',
      ];

      for (final table in tables) {
        expect(
          schemaSql,
          contains('CREATE TABLE IF NOT EXISTS $table'),
          reason: 'Missing table contract: $table',
        );
      }
    });

    test('relasi kehadiran_pasien ke pasien menggunakan ON DELETE CASCADE', () {
      expect(
        schemaSql,
        contains(
          'id_pasien bigint NOT NULL REFERENCES public.pasien(id_pasien) ON DELETE CASCADE',
        ),
      );
    });

    test('tabel obat memiliki kolom foto_url', () {
      expect(schemaSql, contains('foto_url text,'));
    });

    test('memiliki fungsi RPC atomic transaksi obat keluar/masuk/opname', () {
      const functions = [
        'public.fn_recalculate_obat_stok_single',
        'public.fn_recalculate_obat_stok_bulk',
        'public.fn_obat_keluar_refresh_totals',
        'public.fn_obat_keluar_insert_atomic',
        'public.fn_obat_keluar_update_atomic',
        'public.fn_obat_keluar_delete_atomic',
        'public.fn_obat_keluar_delete_by_tanggal_atomic',
        'public.fn_obat_masuk_insert_atomic',
        'public.fn_obat_masuk_update_atomic',
        'public.fn_obat_masuk_delete_atomic',
        'public.fn_obat_masuk_delete_by_tanggal_atomic',
        'public.fn_stock_opname_insert_atomic',
        'public.fn_stock_opname_update_atomic',
        'public.fn_stock_opname_delete_atomic',
        'public.fn_stock_opname_delete_by_tanggal_atomic',
        'public.fn_obat_delete_if_unused',
        'public.fn_pasien_delete_and_renumber',
      ];

      for (final fn in functions) {
        expect(
          schemaSql,
          contains('CREATE OR REPLACE FUNCTION $fn'),
          reason: 'Missing RPC contract: $fn',
        );
      }
    });

    test('grant execute tersedia untuk fungsi atomic utama', () {
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_insert_atomic(date, text, text, bigint, jsonb) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_update_atomic(bigint, date, text, text, bigint, jsonb) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_atomic(bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_insert_atomic(bigint, date, integer, text, bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_update_atomic(bigint, bigint, date, integer, text, bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_atomic(bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_by_tanggal_atomic(date) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_stock_opname_insert_atomic(bigint, date, integer, integer, text, bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_stock_opname_update_atomic(bigint, bigint, date, integer, integer, text, bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_atomic(bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(date) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_delete_if_unused(bigint) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_and_renumber(bigint) TO authenticated;',
        ),
      );
    });

    test('kontrak delete pasien final tidak ambigu', () {
      expect(
        schemaSql,
        contains(
            'DROP FUNCTION IF EXISTS public.fn_pasien_delete_if_unused(bigint);'),
      );
      expect(
        schemaSql,
        isNot(contains(
            'CREATE OR REPLACE FUNCTION public.fn_pasien_delete_if_unused')),
      );
    });

    test('storage foto obat tersedia dan policy explicit', () {
      expect(
        schemaSql,
        contains(
            'INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)'),
      );
      expect(schemaSql, contains("'obat-images'"));
      expect(
        schemaSql,
        contains('CREATE POLICY "public read obat-images"'),
      );
      expect(
        schemaSql,
        contains('CREATE POLICY "authenticated upload obat-images"'),
      );
      expect(
        schemaSql,
        contains('CREATE POLICY "authenticated update obat-images"'),
      );
      expect(
        schemaSql,
        contains('CREATE POLICY "authenticated delete obat-images"'),
      );
    });
  });
}
