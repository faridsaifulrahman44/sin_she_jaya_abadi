import '../../core/utils/formatters.dart';
import '../../data/models/obat_etalase.dart';
import '../../core/utils/parsers.dart';
import '../../data/repositories/kehadiran_repository.dart';
import '../../data/repositories/obat_keluar_repository.dart';
import '../../data/repositories/obat_repository.dart';
import '../../data/repositories/pasien_repository.dart';
import '../../features/stok/services/stock_service.dart';

@Deprecated(
    'Gunakan repository typed di lib/data/repositories secara langsung.')
class KlinikRepository {
  KlinikRepository({
    ObatRepository? obatRepository,
    ObatKeluarRepository? obatKeluarRepository,
    PasienRepository? pasienRepository,
    KehadiranRepository? kehadiranRepository,
    StockService? stockService,
  })  : _obatRepository = obatRepository ?? ObatRepository(),
        _obatKeluarRepository = obatKeluarRepository ?? ObatKeluarRepository(),
        _pasienRepository = pasienRepository ?? PasienRepository(),
        _kehadiranRepository = kehadiranRepository ?? KehadiranRepository(),
        _stockService = stockService ?? StockService();

  final ObatRepository _obatRepository;
  final ObatKeluarRepository _obatKeluarRepository;
  final PasienRepository _pasienRepository;
  final KehadiranRepository _kehadiranRepository;
  final StockService _stockService;

  DateTime _parseDateOrNow(String? value) {
    return parseNullableDate(value) ?? DateTime.now();
  }

  Etalase _parseEtalase(String value) => Etalase.fromString(value);

  Future<List<Map<String, dynamic>>> getObat({String? keyword}) async {
    final items = await _obatRepository.getObat(keyword: keyword);
    return items.map((item) => item.toMap()).toList();
  }

  Future<void> insertObat({
    required String namaObat,
    required int stokSaatIni,
    required int stokMinimum,
    required String etalase,
    String? satuan,
    String? keterangan,
  }) async {
    await _obatRepository.insertObat(
      namaObat: namaObat,
      stokSaatIni: stokSaatIni,
      stokMinimum: stokMinimum,
      etalase: _parseEtalase(etalase),
      satuan: satuan,
      keterangan: keterangan,
    );
  }

  Future<void> updateObat({
    required int idObat,
    required String namaObat,
    required int stokMinimum,
    required String etalase,
    String? satuan,
    String? keterangan,
  }) async {
    await _obatRepository.updateObat(
      idObat: idObat,
      namaObat: namaObat,
      stokMinimum: stokMinimum,
      etalase: _parseEtalase(etalase),
      satuan: satuan,
      keterangan: keterangan,
    );
  }

  Future<void> deleteObat(int idObat) => _obatRepository.deleteObat(idObat);

  Future<List<Map<String, dynamic>>> getObatKeluar({String? tanggal}) async {
    final items = await _obatKeluarRepository.getObatKeluar(
      tanggal: tanggal == null || tanggal.trim().isEmpty
          ? null
          : _parseDateOrNow(tanggal),
    );
    return items.map((item) => item.toMap()).toList();
  }

  Future<List<Map<String, dynamic>>> getObatKeluarByRange(
    String startDate,
    String endDate,
  ) async {
    final items = await _obatKeluarRepository.getObatKeluarByRange(
      _parseDateOrNow(startDate),
      _parseDateOrNow(endDate),
    );
    return items.map((item) => item.toMap()).toList();
  }

  Future<void> deleteObatKeluar(int idTerjual) =>
      _stockService.deleteStokKeluar(idTerjual);

  Future<void> deleteObatKeluarByTanggal(String tanggal) =>
      _stockService.deleteStokKeluarByTanggal(_parseDateOrNow(tanggal));

  Future<List<Map<String, dynamic>>> getPasien({String? keyword}) async {
    final items = await _pasienRepository.getPasien(keyword: keyword);
    return items.map((item) => item.toMap()).toList();
  }

  Future<List<Map<String, dynamic>>> getPasienByTanggalJanjian(
      String tanggal) async {
    final items = await _pasienRepository.getPasienByTanggalJanjian(
      _parseDateOrNow(tanggal),
    );
    return items.map((item) => item.toMap()).toList();
  }

  Future<Map<String, dynamic>> insertPasien({
    required String nomorPasien,
    required String namaPasien,
    required String alamat,
    required int usia,
    required String jenisKelamin,
    required String tanggalJanjian,
  }) async {
    final item = await _pasienRepository.insertPasien(
      nomorPasien: nomorPasien,
      namaPasien: namaPasien,
      alamat: alamat,
      usia: usia,
      jenisKelamin: jenisKelamin,
      tanggalJanjian: _parseDateOrNow(tanggalJanjian),
    );
    return item.toMap();
  }

  Future<void> updatePasien({
    required int idPasien,
    required String nomorPasien,
    required String namaPasien,
    required String alamat,
    required int usia,
    required String jenisKelamin,
    required String tanggalJanjian,
  }) async {
    await _pasienRepository.updatePasien(
      idPasien: idPasien,
      nomorPasien: nomorPasien,
      namaPasien: namaPasien,
      alamat: alamat,
      usia: usia,
      jenisKelamin: jenisKelamin,
      tanggalJanjian: _parseDateOrNow(tanggalJanjian),
    );
  }

  Future<List<Map<String, dynamic>>> getTanggalJanjian() async {
    final dates = await _pasienRepository.getTanggalJanjian();
    return dates
        .map((date) => {'tanggal_janjian': formatDateDb(date)})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getKehadiranByTanggal(
      String tanggal) async {
    final items = await _kehadiranRepository.getKehadiranByTanggal(
      _parseDateOrNow(tanggal),
    );
    return items.map((item) => item.toMap()).toList();
  }

  Future<Map<String, dynamic>?> getKehadiranByPasienDanTanggal({
    required int idPasien,
    required String tanggal,
  }) async {
    final item = await _kehadiranRepository.getKehadiranByPasienDanTanggal(
      idPasien: idPasien,
      tanggal: _parseDateOrNow(tanggal),
    );
    return item?.toMap();
  }

  Future<void> insertKehadiran({
    required int idPasien,
    required String tanggalHadir,
    required String statusHadir,
    required int idAdmin,
    String? keterangan,
  }) async {
    await _kehadiranRepository.insertKehadiran(
      idPasien: idPasien,
      tanggalHadir: _parseDateOrNow(tanggalHadir),
      statusHadir: statusHadir,
      idAdmin: idAdmin,
      keterangan: keterangan,
    );
  }

  Future<void> upsertKehadiran({
    required int idPasien,
    required String tanggalHadir,
    required String statusHadir,
    required int idAdmin,
    String? keterangan,
  }) async {
    await _kehadiranRepository.upsertKehadiran(
      idPasien: idPasien,
      tanggalHadir: _parseDateOrNow(tanggalHadir),
      statusHadir: statusHadir,
      idAdmin: idAdmin,
      keterangan: keterangan,
    );
  }

  Future<Map<String, dynamic>> deletePasien(int idPasien) =>
      _pasienRepository.deletePasien(idPasien);

  Future<void> deleteKehadiran(int idKehadiran) =>
      _kehadiranRepository.deleteKehadiran(idKehadiran);
}
