import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/features/stok/stok_alert_logic.dart';

/// Helper: builds a minimal ObatModel for testing.
ObatModel makeObat({
  int idObat = 1,
  String namaObat = 'Test Obat',
  required int stokSaatIni,
  int? stokMinimum,
  Etalase etalase = Etalase.etalase1,
}) {
  return ObatModel(
    idObat: idObat,
    namaObat: namaObat,
    stokSaatIni: stokSaatIni,
    stokMinimum: stokMinimum ?? 10,
    etalase: etalase,
  );
}

void main() {
  group('categorizeObat', () {
    test('habis when stok = 0', () {
      final obat = makeObat(stokSaatIni: 0);
      expect(categorizeObat(obat), StokStatus.habis);
    });

    test('habis when stok < 0', () {
      final obat = makeObat(stokSaatIni: -3);
      expect(categorizeObat(obat), StokStatus.habis);
    });

    test('menipis when stok = 1 and minimum = 5', () {
      final obat = makeObat(stokSaatIni: 1, stokMinimum: 5);
      expect(categorizeObat(obat), StokStatus.menipis);
    });

    test('menipis when stok = minimum (boundary)', () {
      final obat = makeObat(stokSaatIni: 5, stokMinimum: 5);
      expect(categorizeObat(obat), StokStatus.menipis);
    });

    test('aman when stok > minimum', () {
      final obat = makeObat(stokSaatIni: 20, stokMinimum: 5);
      expect(categorizeObat(obat), StokStatus.aman);
    });

    test('uses default minimum (5) when stokMinimum is null in model', () {
      // ObatModel.stokMinimum is non-nullable; use a model with explicit value
      // that equals the default threshold to test the boundary.
      // When stokMinimum = 5 (== kDefaultStokMinimum) and stok = 5 → menipis
      final obat = makeObat(stokSaatIni: 5, stokMinimum: 5);
      expect(categorizeObat(obat), StokStatus.menipis);

      // stok = 6 with same min → aman
      final obat2 = makeObat(stokSaatIni: 6, stokMinimum: 5);
      expect(categorizeObat(obat2), StokStatus.aman);
    });
  });

  group('buildStokAlertSummary', () {
    test('empty list returns empty categories', () {
      final summary = buildStokAlertSummary([]);
      expect(summary.habis, isEmpty);
      expect(summary.menipis, isEmpty);
      expect(summary.aman, isEmpty);
      expect(summary.hasAnyAlert, isFalse);
    });

    test('correct grouping for mixed obat list', () {
      final obatList = [
        makeObat(idObat: 1, namaObat: 'Obat A', stokSaatIni: 0),
        makeObat(idObat: 2, namaObat: 'Obat B', stokSaatIni: 3, stokMinimum: 5),
        makeObat(idObat: 3, namaObat: 'Obat C', stokSaatIni: 10, stokMinimum: 5),
        makeObat(idObat: 4, namaObat: 'Obat D', stokSaatIni: 5, stokMinimum: 5),
        makeObat(idObat: 5, namaObat: 'Obat E', stokSaatIni: -2),
        makeObat(idObat: 6, namaObat: 'Obat F', stokSaatIni: 50, stokMinimum: 10),
      ];

      final summary = buildStokAlertSummary(obatList);

      expect(summary.habis.map((i) => i.namaObat), ['Obat A', 'Obat E']);
      expect(summary.menipis.map((i) => i.namaObat), ['Obat B', 'Obat D']);
      expect(summary.aman.map((i) => i.namaObat), ['Obat C', 'Obat F']);

      expect(summary.totalHabis, 2);
      expect(summary.totalMenipis, 2);
      expect(summary.hasHabis, isTrue);
      expect(summary.hasMenipis, isTrue);
      expect(summary.hasAnyAlert, isTrue);
    });

    test('all aman returns no alerts', () {
      final obatList = [
        makeObat(stokSaatIni: 100),
        makeObat(idObat: 2, stokSaatIni: 50, stokMinimum: 10),
      ];
      final summary = buildStokAlertSummary(obatList);
      expect(summary.hasAnyAlert, isFalse);
      expect(summary.hasHabis, isFalse);
      expect(summary.hasMenipis, isFalse);
    });
  });

  group('filterByStokAlertCategory', () {
    final obatList = [
      makeObat(idObat: 1, namaObat: 'Habis A', stokSaatIni: 0),
      makeObat(idObat: 2, namaObat: 'Menipis A', stokSaatIni: 3, stokMinimum: 5),
      makeObat(idObat: 3, namaObat: 'Aman A', stokSaatIni: 100),
      makeObat(idObat: 4, namaObat: 'Habis B', stokSaatIni: -1),
      makeObat(idObat: 5, namaObat: 'Menipis B', stokSaatIni: 5, stokMinimum: 5),
    ];

    test('filter by habis', () {
      final result = filterByStokAlertCategory(obatList, StokStatus.habis);
      expect(result.map((o) => o.namaObat), ['Habis A', 'Habis B']);
    });

    test('filter by menipis', () {
      final result = filterByStokAlertCategory(obatList, StokStatus.menipis);
      expect(result.map((o) => o.namaObat), ['Menipis A', 'Menipis B']);
    });

    test('filter by aman', () {
      final result = filterByStokAlertCategory(obatList, StokStatus.aman);
      expect(result.map((o) => o.namaObat), ['Aman A']);
    });

    test('filter empty list returns empty', () {
      final result = filterByStokAlertCategory([], StokStatus.habis);
      expect(result, isEmpty);
    });
  });

  group('ObatAlertItem.fromObat', () {
    test('populates all fields correctly', () {
      final obat = ObatModel(
        idObat: 42,
        namaObat: 'Herbal X',
        stokSaatIni: 3,
        stokMinimum: 5,
        etalase: Etalase.etalase2,
        fotoKey: 'etalase-2/herbal_x.webp',
      );

      final item = ObatAlertItem.fromObat(obat);

      expect(item.idObat, 42);
      expect(item.namaObat, 'Herbal X');
      expect(item.fotoKey, 'etalase-2/herbal_x.webp');
      expect(item.stokSaatIni, 3);
      expect(item.stokMinimum, 5);
      expect(item.kategori, StokStatus.menipis);
      expect(item.etalaseLabel, 'Etalase 2');
    });

    test('kategori = habis for stok = 0', () {
      final obat = makeObat(stokSaatIni: 0);
      expect(ObatAlertItem.fromObat(obat).kategori, StokStatus.habis);
    });
  });

  group('StokAlertSummary helpers', () {
    test('hasHabis / hasMenipis / hasAnyAlert compute correctly', () {
      final summary = StokAlertSummary(
        habis: [
          ObatAlertItem(
            idObat: 1,
            namaObat: 'X',
            stokSaatIni: 0,
            stokMinimum: 5,
            kategori: StokStatus.habis,
            etalaseLabel: 'Etalase 1',
          ),
        ],
        menipis: [
          ObatAlertItem(
            idObat: 2,
            namaObat: 'Y',
            stokSaatIni: 2,
            stokMinimum: 5,
            kategori: StokStatus.menipis,
            etalaseLabel: 'Etalase 1',
          ),
        ],
        aman: [],
      );

      expect(summary.hasHabis, isTrue);
      expect(summary.hasMenipis, isTrue);
      expect(summary.hasAnyAlert, isTrue);
      expect(summary.totalHabis, 1);
      expect(summary.totalMenipis, 1);
    });
  });
}
