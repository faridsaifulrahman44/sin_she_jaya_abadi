import '../../core/utils/parsers.dart';

/// Model untuk fitur Sinkronisasi Stok Obat.
///
/// Tabel Supabase: `sinkronisasi_stok`.
class SinkronisasiStokModel {
  const SinkronisasiStokModel({
    required this.idOpname,
    required this.idObat,
    required this.tanggalOpname,
    required this.stokSistem,
    required this.stokFisik,
    required this.selisih,
    this.alasanPenyesuaian,
    required this.idAdmin,
    this.createdAt,
  });

  /// Nama tabel Supabase.
  static const tableName = 'sinkronisasi_stok';

  final int idOpname;
  final int idObat;
  final DateTime tanggalOpname;
  final int stokSistem;
  final int stokFisik;
  final int selisih;
  final String? alasanPenyesuaian;
  final int idAdmin;
  final DateTime? createdAt;

  bool get isBalanced => selisih == 0;
  bool get isOverStock => selisih > 0;
  bool get isUnderStock => selisih < 0;

  factory SinkronisasiStokModel.fromMap(Map<String, dynamic> map) {
    return SinkronisasiStokModel(
      idOpname: parseInt(map['id_opname']),
      idObat: parseInt(map['id_obat']),
      tanggalOpname: parseDate(map['tanggal_opname']),
      stokSistem: parseInt(map['stok_sistem'], fallback: 0),
      stokFisik: parseInt(map['stok_fisik'], fallback: 0),
      selisih: parseInt(map['selisih'], fallback: 0),
      alasanPenyesuaian: parseNullableString(map['alasan_penyesuaian']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_opname': idOpname,
      'id_obat': idObat,
      'tanggal_opname': tanggalOpname.toIso8601String().split('T').first,
      'stok_sistem': stokSistem,
      'stok_fisik': stokFisik,
      'selisih': selisih,
      'alasan_penyesuaian': alasanPenyesuaian,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
