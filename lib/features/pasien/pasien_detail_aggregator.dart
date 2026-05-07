import '../../data/models/kehadiran_model.dart';
import '../../data/models/kunjungan_model.dart';
import '../../data/models/pasien_model.dart';
import '../../data/models/transaksi_model.dart';
import 'pasien_detail_summary.dart';

PasienDetailSummary buildPasienDetailSummary({
  required PasienModel pasien,
  required List<KehadiranModel> riwayatKehadiran,
  required List<TransaksiModel> riwayatTransaksi,
  required List<KunjunganModel> riwayatKunjungan,
}) {
  final sortedKehadiran = [...riwayatKehadiran]..sort((a, b) {
      final byDate = b.tanggalHadir.compareTo(a.tanggalHadir);
      if (byDate != 0) return byDate;
      return b.idKehadiran.compareTo(a.idKehadiran);
    });

  final sortedTransaksi = [...riwayatTransaksi]..sort((a, b) {
      final byDate = b.tanggal.compareTo(a.tanggal);
      if (byDate != 0) return byDate;
      return b.idTransaksi.compareTo(a.idTransaksi);
    });

  final totalHadir = sortedKehadiran
      .where((item) => item.statusHadir == StatusHadir.hadir)
      .length;
  final totalTidakHadir = sortedKehadiran
      .where((item) => item.statusHadir == StatusHadir.tidakHadir)
      .length;

  final terakhirHadir = sortedKehadiran
      .where((item) => item.statusHadir == StatusHadir.hadir)
      .map((item) => item.tanggalHadir)
      .cast<DateTime?>()
      .firstWhere((item) => item != null, orElse: () => null);

  final transaksiTerakhir =
      sortedTransaksi.isEmpty ? null : sortedTransaksi.first;

  DateTime? latestTimestamp;
  final candidates = <DateTime?>[
    pasien.createdAt,
    sortedKehadiran.isEmpty ? null : sortedKehadiran.first.tanggalHadir,
    transaksiTerakhir?.tanggal,
  ];
  for (final item in candidates) {
    if (item == null) {
      continue;
    }
    if (latestTimestamp == null || item.isAfter(latestTimestamp)) {
      latestTimestamp = item;
    }
  }

  final totalNominalTransaksi = sortedTransaksi.fold<double>(
    0,
    (sum, item) => sum + item.total,
  );

  // Ambil kunjungan terbaru dan kontrol berikutnya dari kunjungan tersebut.
  final sortedKunjungan = [...riwayatKunjungan]
    ..sort((a, b) => b.tanggalKunjungan.compareTo(a.tanggalKunjungan));
  final terakhirKunjungan =
      sortedKunjungan.isEmpty ? null : sortedKunjungan.first;
  final kontrolBerikutnya = terakhirKunjungan?.tanggalKontrolBerikutnya;

  return PasienDetailSummary(
    pasien: pasien,
    riwayatKehadiran: sortedKehadiran,
    riwayatTransaksi: sortedTransaksi,
    riwayatKunjungan: sortedKunjungan,
    totalKehadiran: sortedKehadiran.length,
    totalHadir: totalHadir,
    totalTidakHadir: totalTidakHadir,
    totalTransaksi: sortedTransaksi.length,
    totalNominalTransaksi: totalNominalTransaksi,
    terakhirHadir: terakhirHadir,
    terakhirTercatat: latestTimestamp,
    transaksiTerakhir: transaksiTerakhir,
    kontrolBerikutnya: kontrolBerikutnya,
    terakhirKunjungan: terakhirKunjungan,
  );
}

String buildTransaksiRingkasan(TransaksiModel transaksi) {
  final base = transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock
      ? 'Pembelian obat'
      : 'Transaksi praktek';

  final extras = <String>[];
  if ((transaksi.durasiHarian ?? 0) > 0) {
    extras.add('Durasi ${transaksi.durasiHarian} hari');
  }
  final note = transaksi.keterangan?.trim();
  if (note != null && note.isNotEmpty) {
    extras.add(note);
  }

  if (extras.isEmpty) {
    return base;
  }

  return '$base • ${extras.join(' • ')}';
}
