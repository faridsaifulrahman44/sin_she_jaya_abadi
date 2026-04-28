import '../../core/utils/parsers.dart';

/// Satu baris item dalam transaksi obat keluar.
/// Menyimpan obat spesifik yang keluar beserta jumlah dan harganya.
///
/// Kolom [isLegacy] = true menandai data lama yang di-backfill
/// dari record sebelum redesign domain. Item legacy TIDAK
/// dihitung dalam perhitungan stok.
class ObatKeluarItemModel {
  const ObatKeluarItemModel({
    required this.idItem,
    required this.idTerjual,
    required this.idObat,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.isLegacy = false,
    this.createdAt,
  });

  final int idItem;
  final int idTerjual;
  final int idObat;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final bool isLegacy;
  final DateTime? createdAt;

  factory ObatKeluarItemModel.fromMap(Map<String, dynamic> map) {
    return ObatKeluarItemModel(
      idItem: parseInt(map['id_item']),
      idTerjual: parseInt(map['id_terjual']),
      idObat: parseInt(map['id_obat'] ?? 0),
      jumlah: parseInt(map['jumlah'], fallback: 0),
      hargaSatuan: parseDouble(map['harga_satuan']),
      subtotal: parseDouble(map['subtotal']),
      isLegacy: map['is_legacy'] == true || map['is_legacy'] == 'true',
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idItem > 0) 'id_item': idItem,
      'id_terjual': idTerjual,
      'id_obat': idObat,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
      'is_legacy': isLegacy,
    };
  }

  /// Body untuk INSERT (tanpa id_item yang auto-generated).
  Map<String, dynamic> toInsertMap() {
    return {
      'id_terjual': idTerjual,
      'id_obat': idObat,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'is_legacy': isLegacy,
    };
  }

  ObatKeluarItemModel copyWith({
    int? idItem,
    int? idTerjual,
    int? idObat,
    int? jumlah,
    double? hargaSatuan,
    double? subtotal,
    bool? isLegacy,
    DateTime? createdAt,
  }) {
    return ObatKeluarItemModel(
      idItem: idItem ?? this.idItem,
      idTerjual: idTerjual ?? this.idTerjual,
      idObat: idObat ?? this.idObat,
      jumlah: jumlah ?? this.jumlah,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      subtotal: subtotal ?? this.subtotal,
      isLegacy: isLegacy ?? this.isLegacy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
