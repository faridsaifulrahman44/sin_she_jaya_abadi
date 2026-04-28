import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import 'obat_keluar_item_model.dart';

/// Model header transaksi obat keluar.
///
/// [jumlahItem] dan [totalNominal] di kolom ini dipertahankan
/// untuk backward-compat dengan data lama. Nilai ini dihitung ulang
/// dari [items] setiap kali transaksi disimpan.
///
/// [items] berisi baris detail yang di-LOAD terpisah (joined/fetched).
///
/// Nota: [jumlahItem] = jumlah baris item (qty unit) per nota,
/// bukan jumlah nota. Satu nota selalu = 1 header.
class ObatKeluarModel {
  const ObatKeluarModel({
    required this.idTerjual,
    required this.tanggalTerjual,
    this.noEtalase,
    this.jumlahItem,
    this.totalNominal,
    this.keterangan,
    required this.idAdmin,
    this.createdAt,
    this.items = const [],
  });

  final int idTerjual;
  final DateTime tanggalTerjual;
  final String? noEtalase;

  /// Jumlah unit/baris item non-legacy. Null untuk data lama.
  /// Alias: [displayJumlahItem].
  final int? jumlahItem;

  /// Total nominal dihitung dari SUM(subtotal) item non-legacy.
  /// Null untuk data lama.
  final double? totalNominal;
  final String? keterangan;
  final int idAdmin;
  final DateTime? createdAt;
  final List<ObatKeluarItemModel> items;

  /// Total nominal dari item non-legacy (calculated).
  double get computedTotalNominal {
    return items
        .where((i) => !i.isLegacy)
        .fold(0.0, (sum, i) => sum + i.subtotal);
  }

  /// Jumlah unit/baris item non-legacy (calculated from loaded [items]).
  int get computedJumlahItem {
    return items.where((i) => !i.isLegacy).length;
  }

  /// Jumlah item yang aman untuk ditampilkan di UI.
  ///
  /// Aturan:
  /// - Jika detail [items] sudah ter-load, gunakan hitungannya.
  /// - Jika [items] belum ter-load (header-only), fallback ke cache header DB.
  int get displayJumlahItem {
    if (items.isNotEmpty) {
      return computedJumlahItem;
    }
    return jumlahItem ?? 0;
  }

  /// Jumlah nota (header) untuk model ini — selalu 1.
  ///
  /// [idTerjual] unik per nota, sehingga satu model header = satu nota.
  int get notaCount => 1;

  /// Total nominal yang aman untuk ditampilkan di UI.
  ///
  /// Aturan:
  /// - Jika detail [items] sudah ter-load, gunakan hitungannya.
  /// - Jika [items] belum ter-load (header-only), fallback ke cache header DB.
  double get displayTotalNominal {
    if (items.isNotEmpty) {
      return computedTotalNominal;
    }
    return totalNominal ?? 0;
  }

  /// Apakah transaksi ini hanya berisi data legacy (belum di-migrate).
  bool get isLegacyOnly => items.isNotEmpty && items.every((i) => i.isLegacy);

  factory ObatKeluarModel.fromMap(Map<String, dynamic> map) {
    return ObatKeluarModel(
      idTerjual: parseInt(map['id_terjual']),
      tanggalTerjual: parseDate(map['tanggal_terjual']),
      noEtalase: parseNullableString(map['no_etalase']),
      jumlahItem: _nullableInt(map['jumlah_transaksi']),
      totalNominal: _nullableDouble(map['total_nominal']),
      keterangan: parseNullableString(map['keterangan']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
      items: const [],
    );
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final parsed = int.tryParse(value.toString().trim());
    return parsed;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().trim());
    return parsed;
  }

  Map<String, dynamic> toMap() {
    return {
      'id_terjual': idTerjual,
      'tanggal_terjual': formatDateDb(tanggalTerjual),
      'no_etalase': noEtalase,
      'keterangan': keterangan,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ObatKeluarModel copyWith({
    int? idTerjual,
    DateTime? tanggalTerjual,
    String? noEtalase,
    int? jumlahItem,
    double? totalNominal,
    String? keterangan,
    int? idAdmin,
    DateTime? createdAt,
    List<ObatKeluarItemModel>? items,
  }) {
    return ObatKeluarModel(
      idTerjual: idTerjual ?? this.idTerjual,
      tanggalTerjual: tanggalTerjual ?? this.tanggalTerjual,
      noEtalase: noEtalase ?? this.noEtalase,
      jumlahItem: jumlahItem ?? this.jumlahItem,
      totalNominal: totalNominal ?? this.totalNominal,
      keterangan: keterangan ?? this.keterangan,
      idAdmin: idAdmin ?? this.idAdmin,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
