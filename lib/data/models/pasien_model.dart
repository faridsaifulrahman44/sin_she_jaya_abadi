import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';

class PasienModel {
  const PasienModel({
    required this.idPasien,
    required this.nomorPasien,
    required this.namaPasien,
    this.alamat,
    required this.usia,
    required this.jenisKelamin,
    this.tanggalJanjian,
    this.createdAt,
    this.updatedAt,
  });

  final int idPasien;
  final String nomorPasien;
  final String namaPasien;
  final String? alamat;
  final int usia;
  final String jenisKelamin;
  final DateTime? tanggalJanjian;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get jenisKelaminLabel =>
      jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan';

  factory PasienModel.fromMap(Map<String, dynamic> map) {
    return PasienModel(
      idPasien: parseInt(map['id_pasien']),
      nomorPasien: parseString(map['nomor_pasien']),
      namaPasien: parseString(map['nama_pasien']),
      alamat: parseNullableString(map['alamat']),
      usia: parseInt(map['usia']),
      jenisKelamin: parseString(map['jenis_kelamin'], fallback: 'L'),
      tanggalJanjian: parseNullableDate(map['tanggal_janjian']),
      createdAt: parseNullableDate(map['created_at']),
      updatedAt: parseNullableDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_pasien': idPasien,
      'nomor_pasien': nomorPasien,
      'nama_pasien': namaPasien,
      'alamat': alamat,
      'usia': usia,
      'jenis_kelamin': jenisKelamin,
      'tanggal_janjian':
          tanggalJanjian == null ? null : formatDateDb(tanggalJanjian!),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
