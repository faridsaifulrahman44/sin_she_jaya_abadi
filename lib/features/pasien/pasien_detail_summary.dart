import '../../data/models/kehadiran_model.dart';
import '../../data/models/kunjungan_model.dart';
import '../../data/models/pasien_model.dart';
import '../../data/models/transaksi_model.dart';

class PasienDetailSummary {
  const PasienDetailSummary({
    required this.pasien,
    required this.riwayatKehadiran,
    required this.riwayatTransaksi,
    required this.riwayatKunjungan,
    required this.totalKehadiran,
    required this.totalHadir,
    required this.totalTidakHadir,
    required this.totalTransaksi,
    required this.totalNominalTransaksi,
    this.terakhirHadir,
    this.terakhirTercatat,
    this.transaksiTerakhir,
    this.kontrolBerikutnya,
    this.terakhirKunjungan,
  });

  final PasienModel pasien;
  final List<KehadiranModel> riwayatKehadiran;
  final List<TransaksiModel> riwayatTransaksi;
  final List<KunjunganModel> riwayatKunjungan;

  final int totalKehadiran;
  final int totalHadir;
  final int totalTidakHadir;
  final int totalTransaksi;
  final double totalNominalTransaksi;

  final DateTime? terakhirHadir;
  final DateTime? terakhirTercatat;
  final TransaksiModel? transaksiTerakhir;

  /// Tanggal kontrol berikutnya dari kunjungan terbaru yang punya jadwal kontrol.
  final DateTime? kontrolBerikutnya;

  /// Kunjungan terbaru.
  final KunjunganModel? terakhirKunjungan;
}
