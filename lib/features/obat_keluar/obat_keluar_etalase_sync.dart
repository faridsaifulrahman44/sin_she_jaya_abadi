import '../../data/models/obat_model.dart';
import 'obat_keluar_form_entry.dart';

/// Helper sinkronisasi etalase untuk form transaksi obat keluar.
///
/// Aturan:
/// - Etalase item selalu mengikuti etalase dari obat yang dipilih.
/// - Header no_etalase diisi hanya jika semua item berada pada etalase yang sama.
/// - Jika campuran etalase, header no_etalase dikosongkan (null).
class ObatKeluarEtalaseSync {
  const ObatKeluarEtalaseSync._();

  static String? resolveHeaderNoEtalase({
    required List<ObatKeluarFormEntry> entries,
    required List<ObatModel> obatList,
  }) {
    final etalaseValues = _collectSelectedEtalaseValues(
      entries: entries,
      obatList: obatList,
    );

    if (etalaseValues.isEmpty) return null;
    if (etalaseValues.length == 1) return etalaseValues.first;
    return null;
  }

  static String resolveHeaderDisplayLabel({
    required List<ObatKeluarFormEntry> entries,
    required List<ObatModel> obatList,
  }) {
    final etalaseValues = _collectSelectedEtalaseValues(
      entries: entries,
      obatList: obatList,
    );

    if (etalaseValues.isEmpty) return '-';
    if (etalaseValues.length > 1) return 'Campuran';

    final value = etalaseValues.first;
    final obat = obatList.where((item) => item.etalase.value == value).toList();
    if (obat.isEmpty) return value;

    return obat.first.etalase.label;
  }

  static String resolveItemEtalaseLabel({
    required int? idObat,
    required List<ObatModel> obatList,
  }) {
    final selected = _findObat(idObat, obatList);
    if (selected == null) return '-';
    return selected.etalase.label;
  }

  static Set<String> _collectSelectedEtalaseValues({
    required List<ObatKeluarFormEntry> entries,
    required List<ObatModel> obatList,
  }) {
    final values = <String>{};
    for (final entry in entries) {
      final selected = _findObat(entry.idObat, obatList);
      if (selected != null) {
        values.add(selected.etalase.value);
      }
    }
    return values;
  }

  static ObatModel? _findObat(int? idObat, List<ObatModel> obatList) {
    if (idObat == null || idObat <= 0) return null;
    for (final obat in obatList) {
      if (obat.idObat == idObat) {
        return obat;
      }
    }
    return null;
  }
}
