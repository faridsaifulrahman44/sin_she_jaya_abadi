import '../../core/utils/parsers.dart';

/// Represents clinical notes and practice results for a patient visit.
///
/// Note: This model covers the practice result notes (catatan hasil).
/// Requires `catatan_hasil` table in Supabase.
class CatatanHasilModel {
  const CatatanHasilModel({
    required this.idCatatan,
    required this.idKunjungan,
    required this.idPasien,
    required this.tanggal,
    this.keluhan,
    this.diagnosa,
    this.tindakan,
    this.saranLanjutan,
    this.obatDiresepkan,
    this.nominalTindakan,
    this.idAdmin,
    this.createdAt,
    this.updatedAt,
  });

  final int idCatatan;
  final int idKunjungan;
  final int idPasien;
  final DateTime tanggal;
  final String? keluhan;
  final String? diagnosa;
  final String? tindakan;
  final String? saranLanjutan;
  final String? obatDiresepkan;
  final double? nominalTindakan;
  final int? idAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CatatanHasilModel.fromMap(Map<String, dynamic> map) {
    return CatatanHasilModel(
      idCatatan: parseInt(map['id_catatan']),
      idKunjungan: parseInt(map['id_kunjungan']),
      idPasien: parseInt(map['id_pasien']),
      tanggal: parseDate(map['tanggal']),
      keluhan: parseNullableString(map['keluhan']),
      diagnosa: parseNullableString(map['diagnosa']),
      tindakan: parseNullableString(map['tindakan']),
      saranLanjutan: parseNullableString(map['saran_lanjutan']),
      obatDiresepkan: parseNullableString(map['obat_diresepkan']),
      nominalTindakan: parseDouble(map['nominal_tindakan'], fallback: 0),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
      updatedAt: parseNullableDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_catatan': idCatatan,
      'id_kunjungan': idKunjungan,
      'id_pasien': idPasien,
      'tanggal': tanggal.toIso8601String().split('T').first,
      'keluhan': keluhan,
      'diagnosa': diagnosa,
      'tindakan': tindakan,
      'saran_lanjutan': saranLanjutan,
      'obat_diresepkan': obatDiresepkan,
      'nominal_tindakan': nominalTindakan,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
