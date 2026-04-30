import '../../core/error/app_exception.dart';
import '../models/kehadiran_model.dart';
import '../models/kunjungan_model.dart';
import '../models/pasien_model.dart';
import '../models/transaksi_model.dart';
import 'kehadiran_repository.dart';
import 'kunjungan_repository.dart';
import 'pasien_repository.dart';
import 'transaksi_repository.dart';

class PasienDetailDataBundle {
  const PasienDetailDataBundle({
    required this.pasien,
    required this.riwayatKehadiran,
    required this.riwayatTransaksi,
    required this.riwayatKunjungan,
  });

  final PasienModel pasien;
  final List<KehadiranModel> riwayatKehadiran;
  final List<TransaksiModel> riwayatTransaksi;
  final List<KunjunganModel> riwayatKunjungan;
}

class PasienDetailRepository {
  PasienDetailRepository({
    PasienRepository? pasienRepository,
    KehadiranRepository? kehadiranRepository,
    TransaksiRepository? transaksiRepository,
    KunjunganRepository? kunjunganRepository,
  })  : _pasienRepository = pasienRepository ?? PasienRepository(),
        _kehadiranRepository = kehadiranRepository ?? KehadiranRepository(),
        _transaksiRepository = transaksiRepository ?? TransaksiRepository(),
        _kunjunganRepository = kunjunganRepository ?? KunjunganRepository();

  final PasienRepository _pasienRepository;
  final KehadiranRepository _kehadiranRepository;
  final TransaksiRepository _transaksiRepository;
  final KunjunganRepository _kunjunganRepository;

  Future<PasienDetailDataBundle> getDetail(
    int idPasien, {
    bool includeRiwayatTransaksi = true,
  }) async {
    if (idPasien <= 0) {
      throw const ValidationException('Data pasien tidak valid.');
    }

    final results = await Future.wait<dynamic>([
      _pasienRepository.getPasienById(idPasien),
      _kehadiranRepository.getKehadiranByPasien(idPasien),
      includeRiwayatTransaksi
          ? _transaksiRepository.getTransaksiByPasien(idPasien)
          : Future<List<TransaksiModel>>.value(const []),
      _kunjunganRepository.getKunjunganByPasien(idPasien),
    ]);

    final pasien = results[0] as PasienModel?;
    if (pasien == null) {
      throw const ValidationException('Data pasien tidak ditemukan.');
    }

    return PasienDetailDataBundle(
      pasien: pasien,
      riwayatKehadiran: results[1] as List<KehadiranModel>,
      riwayatTransaksi: results[2] as List<TransaksiModel>,
      riwayatKunjungan: results[3] as List<KunjunganModel>,
    );
  }
}
