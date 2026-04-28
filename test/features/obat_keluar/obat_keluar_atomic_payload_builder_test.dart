import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_item_model.dart';
import 'package:klinik_mobile_app/features/obat_keluar/obat_keluar_atomic_payload_builder.dart';

void main() {
  group('ObatKeluarAtomicPayloadBuilder', () {
    test('build memetakan item non-legacy ke payload RPC', () {
      final items = [
        const ObatKeluarItemModel(
          idItem: 1,
          idTerjual: 10,
          idObat: 7,
          jumlah: 3,
          hargaSatuan: 12000,
          subtotal: 36000,
          isLegacy: false,
        ),
        const ObatKeluarItemModel(
          idItem: 2,
          idTerjual: 10,
          idObat: 0,
          jumlah: 1,
          hargaSatuan: 0,
          subtotal: 0,
          isLegacy: true,
        ),
      ];

      final payload = ObatKeluarAtomicPayloadBuilder.build(items);

      expect(payload, hasLength(1));
      expect(payload.first, {
        'id_obat': 7,
        'jumlah': 3,
        'harga_satuan': 12000.0,
      });
    });

    test('build gagal jika semua item legacy', () {
      final items = [
        const ObatKeluarItemModel(
          idItem: 1,
          idTerjual: 10,
          idObat: 0,
          jumlah: 1,
          hargaSatuan: 0,
          subtotal: 0,
          isLegacy: true,
        ),
      ];

      expect(
        () => ObatKeluarAtomicPayloadBuilder.build(items),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('minimal 1 item obat non-legacy'),
          ),
        ),
      );
    });

    test('build gagal jika id_obat tidak valid', () {
      final items = [
        const ObatKeluarItemModel(
          idItem: 1,
          idTerjual: 10,
          idObat: 0,
          jumlah: 1,
          hargaSatuan: 5000,
          subtotal: 5000,
          isLegacy: false,
        ),
      ];

      expect(
        () => ObatKeluarAtomicPayloadBuilder.build(items),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('id_obat tidak valid'),
          ),
        ),
      );
    });

    test('build gagal jika jumlah <= 0', () {
      final items = [
        const ObatKeluarItemModel(
          idItem: 1,
          idTerjual: 10,
          idObat: 7,
          jumlah: 0,
          hargaSatuan: 5000,
          subtotal: 0,
          isLegacy: false,
        ),
      ];

      expect(
        () => ObatKeluarAtomicPayloadBuilder.build(items),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('jumlah tidak valid'),
          ),
        ),
      );
    });

    test('build gagal jika harga_satuan < 0', () {
      final items = [
        const ObatKeluarItemModel(
          idItem: 1,
          idTerjual: 10,
          idObat: 7,
          jumlah: 1,
          hargaSatuan: -1,
          subtotal: -1,
          isLegacy: false,
        ),
      ];

      expect(
        () => ObatKeluarAtomicPayloadBuilder.build(items),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('harga_satuan tidak valid'),
          ),
        ),
      );
    });
  });
}
