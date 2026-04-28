import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/features/obat_keluar/obat_keluar_etalase_sync.dart';
import 'package:klinik_mobile_app/features/obat_keluar/obat_keluar_form_entry.dart';

void main() {
  group('ObatKeluarEtalaseSync', () {
    final obatList = [
      const ObatModel(
        idObat: 1,
        namaObat: 'Paracetamol',
        stokSaatIni: 10,
        stokMinimum: 2,
        etalase: Etalase.etalase1,
      ),
      const ObatModel(
        idObat: 2,
        namaObat: 'Amoxicillin',
        stokSaatIni: 8,
        stokMinimum: 2,
        etalase: Etalase.etalase2,
      ),
    ];

    test('header no_etalase terisi jika semua item etalase sama', () {
      final entries = [
        ObatKeluarFormEntry(idObat: 1, jumlah: 1, hargaSatuan: 1000),
        ObatKeluarFormEntry(idObat: 1, jumlah: 2, hargaSatuan: 1000),
      ];

      final header = ObatKeluarEtalaseSync.resolveHeaderNoEtalase(
        entries: entries,
        obatList: obatList,
      );

      expect(header, 'etalase1');
      expect(
        ObatKeluarEtalaseSync.resolveHeaderDisplayLabel(
          entries: entries,
          obatList: obatList,
        ),
        'Etalase 1',
      );
    });

    test('header no_etalase null jika item beda etalase (campuran)', () {
      final entries = [
        ObatKeluarFormEntry(idObat: 1, jumlah: 1, hargaSatuan: 1000),
        ObatKeluarFormEntry(idObat: 2, jumlah: 1, hargaSatuan: 1500),
      ];

      final header = ObatKeluarEtalaseSync.resolveHeaderNoEtalase(
        entries: entries,
        obatList: obatList,
      );

      expect(header, isNull);
      expect(
        ObatKeluarEtalaseSync.resolveHeaderDisplayLabel(
          entries: entries,
          obatList: obatList,
        ),
        'Campuran',
      );
    });

    test('label etalase item mengikuti obat terpilih', () {
      expect(
        ObatKeluarEtalaseSync.resolveItemEtalaseLabel(
          idObat: 2,
          obatList: obatList,
        ),
        'Etalase 2',
      );
      expect(
        ObatKeluarEtalaseSync.resolveItemEtalaseLabel(
          idObat: null,
          obatList: obatList,
        ),
        '-',
      );
    });
  });
}
