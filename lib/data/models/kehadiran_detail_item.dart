import 'kehadiran_model.dart';
import 'pasien_model.dart';

class KehadiranDetailItem {
  const KehadiranDetailItem({
    required this.pasien,
    this.kehadiran,
    this.tanggalKontrolBerikutnya,
  });

  final PasienModel pasien;
  final KehadiranModel? kehadiran;

  /// Tanggal kontrol berikutnya dari kunjungan pasien (nullable).
  final DateTime? tanggalKontrolBerikutnya;

  /// Apakah pasien ini punya jadwal kontrol.
  bool get hasKontrolBerikutnya => tanggalKontrolBerikutnya != null;

  String get statusHadirLabel {
    if (kehadiran == null) return 'Belum Diisi';
    return switch (kehadiran!.statusHadir) {
      StatusHadir.hadir => 'Hadir',
      StatusHadir.tidakHadir => 'Tidak Hadir',
    };
  }

  String? get keteranganKehadiran => kehadiran?.keterangan;
}
