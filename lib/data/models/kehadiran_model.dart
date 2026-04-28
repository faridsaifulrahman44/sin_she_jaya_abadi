import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';

enum StatusHadir {
  hadir._('hadir'),
  tidakHadir._('tidak_hadir');

  const StatusHadir._(this.dbValue);
  final String dbValue;

  /// Serialisasi ke nilai API/DB (snake_case).
  String toDbString() => dbValue;

  /// Parsing dari nilai DB (snake_case) ke enum.
  static StatusHadir fromDbString(String? value) {
    return StatusHadir.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => StatusHadir.hadir,
    );
  }
}

class KehadiranModel {
  const KehadiranModel({
    required this.idKehadiran,
    required this.idPasien,
    required this.tanggalHadir,
    required this.statusHadir,
    this.keterangan,
    required this.idAdmin,
    this.createdAt,
  });

  final int idKehadiran;
  final int idPasien;
  final DateTime tanggalHadir;
  final StatusHadir statusHadir;
  final String? keterangan;
  final int idAdmin;
  final DateTime? createdAt;

  factory KehadiranModel.fromMap(Map<String, dynamic> map) {
    return KehadiranModel(
      idKehadiran: parseInt(map['id_kehadiran']),
      idPasien: parseInt(map['id_pasien']),
      tanggalHadir: parseDate(map['tanggal_hadir']),
      statusHadir: StatusHadir.fromDbString(
        parseString(map['status_hadir'], fallback: 'hadir'),
      ),
      keterangan: parseNullableString(map['keterangan']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_kehadiran': idKehadiran,
      'id_pasien': idPasien,
      'tanggal_hadir': formatDateDb(tanggalHadir),
      'status_hadir': statusHadir.toDbString(),
      'keterangan': keterangan,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
