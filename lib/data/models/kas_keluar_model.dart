import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';

/// Model untuk pengeluaran operasional klinik (owner only).
class KasKeluarModel {
  const KasKeluarModel({
    required this.id,
    required this.tanggal,
    required this.kategori,
    required this.jumlah,
    this.keterangan,
    this.idAdmin,
    this.createdAt,
  });

  final int id;
  final DateTime tanggal;
  final String kategori;
  final double jumlah;
  final String? keterangan;
  final int? idAdmin;
  final DateTime? createdAt;

  factory KasKeluarModel.fromMap(Map<String, dynamic> map) {
    return KasKeluarModel(
      id: parseInt(map['id']),
      tanggal: parseDate(map['tanggal']),
      kategori: parseString(map['kategori'], fallback: ''),
      jumlah: parseDouble(map['jumlah'], fallback: 0),
      keterangan: parseNullableString(map['keterangan']),
      idAdmin: parseNullableInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': formatDateDb(tanggal),
      'kategori': kategori,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'id_admin': idAdmin,
    };
  }

  /// Untuk insert (tanpa id).
  Map<String, dynamic> toInsertMap() {
    return {
      'tanggal': formatDateDb(tanggal),
      'kategori': kategori,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'id_admin': idAdmin,
    };
  }
}
