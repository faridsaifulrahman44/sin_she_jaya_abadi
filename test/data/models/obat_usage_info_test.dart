import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_usage_info.dart';

void main() {
  group('ObatUsageInfo', () {
    test('fromMap parses usage flags from rpc payload', () {
      final usage = ObatUsageInfo.fromMap({
        'deleted': false,
        'used_in_obat_masuk': true,
        'used_in_obat_keluar_item': 0,
        'used_in_sinkronisasi_stok': 'true',
      });

      expect(usage.usedInObatMasuk, true);
      expect(usage.usedInObatKeluarItem, false);
      expect(usage.usedInSinkronisasiStok, true);
      expect(usage.isUsed, true);
      expect(usage.usedSources, ['obat_masuk', 'sinkronisasi_stok']);
    });

    test('toDeleteBlockedMessage lists referenced tables clearly', () {
      const usage = ObatUsageInfo(
        usedInObatMasuk: false,
        usedInObatKeluarItem: true,
        usedInSinkronisasiStok: true,
      );

      final message = usage.toDeleteBlockedMessage(namaObat: 'Paracetamol');
      expect(
        message,
        'Obat "Paracetamol" tidak bisa dihapus karena sudah dipakai pada: obat_keluar_item, sinkronisasi_stok.',
      );
    });

    test('toDeleteBlockedMessage returns deletable hint when unused', () {
      const usage = ObatUsageInfo(
        usedInObatMasuk: false,
        usedInObatKeluarItem: false,
        usedInSinkronisasiStok: false,
      );

      final message = usage.toDeleteBlockedMessage(namaObat: 'Amoxicillin');
      expect(
        message,
        'Obat "Amoxicillin" belum dipakai pada histori dan dapat dihapus.',
      );
    });
  });
}
