import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schema contract', () {
    late String schemaSql;
    late String rlsP1Sql;

    setUpAll(() {
      schemaSql = File('supabase/schema.sql').readAsStringSync();
      rlsP1Sql = File('supabase/migration_fase20_rls_owner_admin_harden.sql')
          .readAsStringSync();
    });

    test('memiliki tabel inti domain klinik', () {
      const tables = [
        'public.admin',
        'public.obat',
        'public.obat_masuk',
        'public.obat_keluar',
        'public.obat_keluar_item',
        'public.sinkronisasi_stok',
        'public.pasien',
        'public.kehadiran_pasien',
        'public.transaksi',
        'public.transaksi_item',
        'public.kunjungan_pasien',
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

    test('tabel obat memiliki kolom foto aktif', () {
      expect(schemaSql, contains('foto_url text,'));
      expect(schemaSql, contains('foto_key text,'));
      expect(schemaSql, contains('foto_updated_at timestamptz,'));
    });

    test('tabel transaksi_item memiliki kolom satuan_terjual', () {
      expect(schemaSql, contains('satuan_terjual varchar(30),'));
    });

    test('memiliki fungsi RPC atomic transaksi obat keluar/masuk/opname', () {
      const functions = [
        'public.fn_recalculate_obat_stok_single',
        'public.fn_recalculate_obat_stok_bulk',
        'public.fn_transaksi_insert',
        'public.fn_obat_kurangi_stok',
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
        'public.current_admin_id',
        'public.current_admin_role',
        'public.is_owner',
        'public.is_petugas',
        'public.is_clinic_staff',
        'public.can_view_laporan',
        'public.require_clinic_staff',
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
          'GRANT EXECUTE ON FUNCTION public.fn_transaksi_insert(date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb) TO authenticated;',
        ),
      );
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
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.fn_obat_kurangi_stok(int, int) TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.current_admin_id() TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.current_admin_role() TO authenticated;',
        ),
      );
      expect(
        schemaSql,
        contains(
          'GRANT EXECUTE ON FUNCTION public.require_clinic_staff(bigint) TO authenticated;',
        ),
      );
    });

    test('RLS P1 memakai role admin, bukan sekadar authenticated', () {
      expect(
        schemaSql,
        isNot(contains('auth.uid() IS NOT NULL')),
        reason: 'Final schema policy tidak boleh cuma cek authenticated.',
      );
      expect(
        rlsP1Sql,
        isNot(contains('auth.uid() IS NOT NULL')),
        reason: 'Migration P1 policy tidak boleh cuma cek authenticated.',
      );
      expect(schemaSql, contains('USING (public.is_clinic_staff())'));
      expect(schemaSql,
          contains('WITH CHECK (public.current_admin_id() = id_admin)'));
      expect(schemaSql, contains('WITH CHECK (public.is_owner())'));
      expect(rlsP1Sql, contains('CREATE POLICY "clinic staff can read admin"'));
      expect(rlsP1Sql, contains('CREATE POLICY "owner can update admin"'));
      expect(
          rlsP1Sql,
          contains(
              'CREATE POLICY "authenticated can delete kehadiran_pasien"'));
    });

    test('RPC SECURITY DEFINER memvalidasi admin login', () {
      const guardedFunctions = [
        'public.fn_transaksi_insert',
        'public.fn_obat_kurangi_stok',
        'public.fn_obat_keluar_update_atomic',
        'public.fn_obat_keluar_delete_atomic',
        'public.fn_obat_masuk_delete_atomic',
        'public.fn_stock_opname_delete_atomic',
        'public.fn_obat_delete_if_unused',
        'public.fn_pasien_delete_and_renumber',
      ];

      for (final fn in guardedFunctions) {
        final start = schemaSql.indexOf('CREATE OR REPLACE FUNCTION $fn');
        expect(start, isNonNegative, reason: 'Missing guarded RPC: $fn');

        final next =
            schemaSql.indexOf('CREATE OR REPLACE FUNCTION public.', start + 1);
        final block =
            schemaSql.substring(start, next == -1 ? schemaSql.length : next);

        expect(block, contains('SECURITY DEFINER'), reason: fn);
        expect(block, contains('public.require_clinic_staff'), reason: fn);
      }
    });

    test('SQL aktif tidak mereferensikan public.stock_opname', () {
      final activeRefs = <String>[];
      final sqlFiles = Directory('supabase')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'));

      for (final file in sqlFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i += 1) {
          final line = lines[i];
          if (line.trimLeft().startsWith('--')) continue;
          if (line.contains('public.stock_opname')) {
            activeRefs.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(activeRefs, isEmpty, reason: activeRefs.join('\n'));
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
