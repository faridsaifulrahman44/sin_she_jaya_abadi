// ─────────────────────────────────────────────────────────────────────────────
// NOTE: JadwalPraktekModel is orphan — the jadwal_praktek table does not exist
// in the current schema. HariPraktek enum lives in jadwal_praktek_helper.dart and
// is the sole source of truth for practice-day logic.
//
// The enum in this file (StatusHadirPraktek) is similarly dead — KehadiranModel
// uses StatusHadir instead, which is the correct enum.
//
// To re-enable this model:
//   1. Create the jadwal_praktek table in Supabase
//   2. Remove this orphan file
//   3. Remove the import from jadwal_praktek_helper.dart
// ─────────────────────────────────────────────────────────────────────────────
library;

import '../../core/utils/jadwal_praktek_helper.dart';
import '../../core/utils/parsers.dart';

// Re-export so existing imports stay valid.
export '../../core/utils/jadwal_praktek_helper.dart' show HariPraktek;

/// Status kehadiran pasien di jadwal practise.
/// @deprecated Use KehadiranModel.StatusHadir instead — this enum is dead code.
enum StatusHadirPraktek {
  dijadwalkan('dijadwalkan', 'Dijadwalkan'),
  hadir('hadir', 'Hadir'),
  batal('batal', 'Batal'),
  tidakHadir('tidak_hadir', 'Tidak Hadir');

  const StatusHadirPraktek(this.value, this.label);
  final String value;
  final String label;

  static StatusHadirPraktek fromString(String? value) {
    if (value == null) return StatusHadirPraktek.dijadwalkan;
    return StatusHadirPraktek.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StatusHadirPraktek.dijadwalkan,
    );
  }
}

/// @deprecated Orphan model — jadwal_praktek table does not exist.
/// KehadiranModel tracks attendance per patient per day in the `kehadiran` table.
class JadwalPraktekModel {
  const JadwalPraktekModel({
    required this.idJadwal,
    required this.idPasien,
    required this.tanggalPraktek,
    required this.hariPraktek,
    required this.statusHadir,
    this.keterangan,
    this.idAdmin,
    this.createdAt,
  });

  final int idJadwal;
  final int idPasien;
  final DateTime tanggalPraktek;
  final HariPraktek hariPraktek;
  final StatusHadirPraktek statusHadir;
  final String? keterangan;
  final int? idAdmin;
  final DateTime? createdAt;

  factory JadwalPraktekModel.fromMap(Map<String, dynamic> map) {
    return JadwalPraktekModel(
      idJadwal: parseInt(map['id_jadwal']),
      idPasien: parseInt(map['id_pasien']),
      tanggalPraktek: parseDate(map['tanggal_praktek']),
      hariPraktek: HariPraktek.fromString(map['hari_praktek']?.toString()) ??
          HariPraktek.senin,
      statusHadir:
          StatusHadirPraktek.fromString(map['status_hadir']?.toString()),
      keterangan: parseNullableString(map['keterangan']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_jadwal': idJadwal,
      'id_pasien': idPasien,
      'tanggal_praktek': tanggalPraktek.toIso8601String().split('T').first,
      'hari_praktek': hariPraktek.value,
      'status_hadir': statusHadir.value,
      'keterangan': keterangan,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
