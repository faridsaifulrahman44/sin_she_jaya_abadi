import '../../core/error/app_exception.dart';
import '../../core/utils/date_range_validator.dart';
import '../models/kehadiran_model.dart';
import '../models/obat_model.dart';
import '../models/pasien_model.dart';
import '../models/transaksi_model.dart';
import 'kehadiran_repository.dart';
import 'obat_repository.dart';
import 'pasien_repository.dart';
import 'transaksi_repository.dart';

/// Bundles all data needed to build laporan bisnis operasional.
///
/// Data difetch paralel supaya halaman laporan tetap responsif.
class LaporanDataBundle {
  const LaporanDataBundle({
    required this.transaksiPeriode,
    required this.transaksiAllTime,
    required this.transaksiItemsAllTime,
    required this.pasienPeriode,
    required this.pasienAllTime,
    required this.kehadiranPeriode,
    required this.obatAllTime,
  });

  final List<TransaksiModel> transaksiPeriode;
  final List<TransaksiModel> transaksiAllTime;
  final List<TransaksiItemModel> transaksiItemsAllTime;
  final List<PasienModel> pasienPeriode;
  final List<PasienModel> pasienAllTime;
  final List<KehadiranModel> kehadiranPeriode;
  final List<ObatModel> obatAllTime;
}

class LaporanRepository {
  LaporanRepository({
    TransaksiRepository? transaksiRepository,
    ObatRepository? obatRepository,
    PasienRepository? pasienRepository,
    KehadiranRepository? kehadiranRepository,
  })  : _transaksiRepository = transaksiRepository ?? TransaksiRepository(),
        _obatRepository = obatRepository ?? ObatRepository(),
        _pasienRepository = pasienRepository ?? PasienRepository(),
        _kehadiranRepository = kehadiranRepository ?? KehadiranRepository();

  final TransaksiRepository _transaksiRepository;
  final ObatRepository _obatRepository;
  final PasienRepository _pasienRepository;
  final KehadiranRepository _kehadiranRepository;

  Future<LaporanDataBundle> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final validation = validateDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    if (!validation.isValid) {
      throw ValidationException(
        validation.message ?? 'Range tanggal tidak valid.',
      );
    }

    final results = await Future.wait<dynamic>([
      _transaksiRepository.getTransaksiByRange(startDate, endDate),
      _transaksiRepository.getAllTransaksi(),
      _transaksiRepository.getAllTransaksiItems(),
      _pasienRepository.getPasienByRange(startDate, endDate),
      _pasienRepository.getPasien(),
      _kehadiranRepository.getKehadiranByRange(startDate, endDate),
      _obatRepository.getObat(),
    ]);

    return LaporanDataBundle(
      transaksiPeriode: results[0] as List<TransaksiModel>,
      transaksiAllTime: results[1] as List<TransaksiModel>,
      transaksiItemsAllTime: results[2] as List<TransaksiItemModel>,
      pasienPeriode: results[3] as List<PasienModel>,
      pasienAllTime: results[4] as List<PasienModel>,
      kehadiranPeriode: results[5] as List<KehadiranModel>,
      obatAllTime: results[6] as List<ObatModel>,
    );
  }
}
