import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_item_model.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_model.dart';
import 'package:klinik_mobile_app/data/models/obat_masuk_model.dart';
import 'package:klinik_mobile_app/data/models/sinkronisasi_stok_model.dart';
import 'package:klinik_mobile_app/data/repositories/obat_keluar_repository.dart';
import 'package:klinik_mobile_app/data/repositories/obat_masuk_repository.dart';
import 'package:klinik_mobile_app/data/repositories/sinkronisasi_stok_repository.dart';

/// Single entry-point untuk mutasi stok operasional.
///
/// Semua mutation utama (masuk/keluar/opname) difasilitasi service ini supaya:
/// - flow konsisten,
/// - validasi terpusat,
/// - mudah diuji,
/// - mencegah update stok langsung dari UI.
class StockService {
  StockService({
    ObatMasukRepository? obatMasukRepository,
    ObatKeluarRepository? obatKeluarRepository,
    SinkronisasiStokRepository? sinkronisasiStokRepository,
  })  : _obatMasukRepository = obatMasukRepository ?? ObatMasukRepository(),
        _obatKeluarRepository = obatKeluarRepository ?? ObatKeluarRepository(),
        _sinkronisasiStokRepository =
            sinkronisasiStokRepository ?? SinkronisasiStokRepository();

  final ObatMasukRepository _obatMasukRepository;
  final ObatKeluarRepository _obatKeluarRepository;
  final SinkronisasiStokRepository _sinkronisasiStokRepository;

  Future<ObatMasukModel> stokMasuk({
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) {
    _requireNonNegative(jumlahMasuk, field: 'jumlahMasuk');
    return _obatMasukRepository.insertObatMasuk(
      idObat: idObat,
      tanggalMasuk: tanggalMasuk,
      jumlahMasuk: jumlahMasuk,
      idAdmin: idAdmin,
      keterangan: keterangan,
    );
  }

  Future<ObatKeluarModel> stokKeluar({
    required DateTime tanggalTerjual,
    required List<ObatKeluarItemModel> items,
    required int idAdmin,
    String? noEtalase,
    String? keterangan,
  }) {
    if (items.isEmpty) {
      throw const ValidationException(
        'Item obat keluar tidak boleh kosong.',
        code: 'stock_keluar_items_empty',
      );
    }
    for (final item in items) {
      _requireNonNegative(item.jumlah, field: 'jumlah');
      _requireNonNegative(item.subtotal.round(), field: 'subtotal');
    }
    return _obatKeluarRepository.insertObatKeluar(
      tanggalTerjual: tanggalTerjual,
      items: items,
      keterangan: keterangan,
      idAdmin: idAdmin,
      noEtalase: noEtalase,
    );
  }

  Future<SinkronisasiStokModel> syncOpname({
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) {
    _requireNonNegative(stokSistem, field: 'stokSistem');
    _requireNonNegative(stokFisik, field: 'stokFisik');
    return _sinkronisasiStokRepository.insertSinkronisasiStok(
      idObat: idObat,
      tanggalOpname: tanggalOpname,
      stokSistem: stokSistem,
      stokFisik: stokFisik,
      idAdmin: idAdmin,
      alasanPenyesuaian: alasanPenyesuaian,
    );
  }

  void _requireNonNegative(int value, {required String field}) {
    if (value < 0) {
      throw ValidationException(
        '$field tidak boleh bernilai negatif.',
        code: 'stock_negative_not_allowed',
      );
    }
  }
}
