import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';

/// Model kunjungan pasien.
///
/// Satu baris = satu kunjungan (praktek / kontrol).
/// Tanggal kontrol berikutnya nullable — hanya wajib jika ada jadwal kontrol.
class KunjunganModel {
  const KunjunganModel({
    required this.idKunjungan,
    required this.idPasien,
    required this.tanggalKunjungan,
    this.keluhanSingkat,
    this.catatanHasil,
    this.tindakLanjut,
    this.tanggalKontrolBerikutnya,
    this.idAdmin,
    this.createdAt,
    this.updatedAt,
  });

  final int idKunjungan;
  final int idPasien;
  final DateTime tanggalKunjungan;
  final String? keluhanSingkat;
  final String? catatanHasil;
  final String? tindakLanjut;
  final DateTime? tanggalKontrolBerikutnya;
  final int? idAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Apakah kunjungan ini punya jadwal kontrol berikutnya.
  bool get hasKontrolBerikutnya => tanggalKontrolBerikutnya != null;

  /// Tanggal kontrol sebagai label UI.
  String? get tanggalKontrolLabel {
    final t = tanggalKontrolBerikutnya;
    if (t == null) return null;
    return asMediumDate(t);
  }

  factory KunjunganModel.fromMap(Map<String, dynamic> map) {
    return KunjunganModel(
      idKunjungan: parseInt(map['id_kunjungan']),
      idPasien: parseInt(map['id_pasien']),
      tanggalKunjungan: parseDate(map['tanggal_kunjungan']),
      keluhanSingkat: parseNullableString(map['keluhan_singkat']),
      catatanHasil: parseNullableString(map['catatan_hasil']),
      tindakLanjut: parseNullableString(map['tindak_lanjut']),
      tanggalKontrolBerikutnya:
          parseNullableDate(map['tanggal_kontrol_berikutnya']),
      idAdmin: parseInt(map['id_admin'], fallback: 0) > 0
          ? parseInt(map['id_admin'])
          : null,
      createdAt: parseNullableDate(map['created_at']),
      updatedAt: parseNullableDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_kunjungan': idKunjungan,
      'id_pasien': idPasien,
      'tanggal_kunjungan': formatDateDb(tanggalKunjungan),
      'keluhan_singkat': keluhanSingkat,
      'catatan_hasil': catatanHasil,
      'tindak_lanjut': tindakLanjut,
      'tanggal_kontrol_berikutnya': tanggalKontrolBerikutnya == null
          ? null
          : formatDateDb(tanggalKontrolBerikutnya!),
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Untuk insert (tanpa id server-side).
  Map<String, dynamic> toInsertMap() {
    return {
      'id_pasien': idPasien,
      'tanggal_kunjungan': formatDateDb(tanggalKunjungan),
      'keluhan_singkat': keluhanSingkat,
      'catatan_hasil': catatanHasil,
      'tindak_lanjut': tindakLanjut,
      'tanggal_kontrol_berikutnya': tanggalKontrolBerikutnya == null
          ? null
          : formatDateDb(tanggalKontrolBerikutnya!),
      'id_admin': idAdmin,
    };
  }
}
