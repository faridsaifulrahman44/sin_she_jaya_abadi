import 'package:klinik_mobile_app/data/models/obat_model.dart';

/// Default minimum stock if obat.stokMinimum is null.
const kDefaultStokMinimum = 5;

/// Item alert untuk satu obat.
/// Re-exported via stok_alert_logic.dart.
class ObatAlertItem {
  const ObatAlertItem({
    required this.idObat,
    required this.namaObat,
    this.fotoKey,
    required this.stokSaatIni,
    required this.stokMinimum,
    required this.kategori,
    required this.etalaseLabel,
  });

  final int idObat;
  final String namaObat;
  final String? fotoKey;
  final int stokSaatIni;
  final int stokMinimum;
  final StokStatus kategori;
  final String etalaseLabel;

  /// Build from ObatModel.
  factory ObatAlertItem.fromObat(ObatModel obat) {
    final effectiveMin = obat.stokMinimum;
    return ObatAlertItem(
      idObat: obat.idObat,
      namaObat: obat.namaObat,
      fotoKey: obat.fotoKey,
      stokSaatIni: obat.stokSaatIni,
      stokMinimum: effectiveMin,
      kategori: StokStatus.fromStok(obat.stokSaatIni, effectiveMin),
      etalaseLabel: obat.etalase.label,
    );
  }
}

/// Summary聚合 all obat into 3 categories.
class StokAlertSummary {
  const StokAlertSummary({
    required this.habis,
    required this.menipis,
    required this.aman,
  });

  final List<ObatAlertItem> habis;
  final List<ObatAlertItem> menipis;
  final List<ObatAlertItem> aman;

  int get totalHabis => habis.length;
  int get totalMenipis => menipis.length;
  bool get hasHabis => totalHabis > 0;
  bool get hasMenipis => totalMenipis > 0;
  bool get hasAnyAlert => hasHabis || hasMenipis;
}
