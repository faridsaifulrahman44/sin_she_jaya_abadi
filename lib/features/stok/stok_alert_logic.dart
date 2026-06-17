import 'package:klinik_mobile_app/data/models/obat_model.dart';
import 'package:klinik_mobile_app/data/models/stok_alert_item.dart';

/// Re-export StokStatus for convenience.
/// Alert categories = same as StokStatus (aman/menipis/habis).
export 'package:klinik_mobile_app/data/models/obat_model.dart' show StokStatus;
export 'package:klinik_mobile_app/data/models/stok_alert_item.dart';

/// Determine alert category for a single obat.
/// Uses obat.stokMinimum if not null, otherwise kDefaultStokMinimum.
StokStatus categorizeObat(ObatModel obat) {
  return StokStatus.fromStok(obat.stokSaatIni, obat.stokMinimum);
}

/// Build alert summary from a list of obat.
StokAlertSummary buildStokAlertSummary(List<ObatModel> obatList) {
  final List<ObatAlertItem> habis = [];
  final List<ObatAlertItem> menipis = [];
  final List<ObatAlertItem> aman = [];

  for (final obat in obatList) {
    final item = ObatAlertItem.fromObat(obat);
    switch (item.kategori) {
      case StokStatus.habis:
        habis.add(item);
      case StokStatus.menipis:
        menipis.add(item);
      case StokStatus.aman:
        aman.add(item);
    }
  }

  return StokAlertSummary(habis: habis, menipis: menipis, aman: aman);
}

/// Filter obat list by alert category.
List<ObatModel> filterByStokAlertCategory(
  List<ObatModel> obatList,
  StokStatus category,
) {
  return obatList.where((o) => categorizeObat(o) == category).toList();
}
