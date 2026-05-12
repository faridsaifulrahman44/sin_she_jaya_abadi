import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_item_model.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_model.dart';
import 'package:klinik_mobile_app/data/models/obat_masuk_model.dart';
import 'package:klinik_mobile_app/data/models/sinkronisasi_stok_model.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/data/repositories/obat_keluar_repository.dart';
import 'package:klinik_mobile_app/data/repositories/obat_masuk_repository.dart';
import 'package:klinik_mobile_app/data/repositories/sinkronisasi_stok_repository.dart';
import 'package:klinik_mobile_app/data/repositories/transaksi_repository.dart';

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
    TransaksiRepository? transaksiRepository,
  })  : _obatMasukRepository = obatMasukRepository ?? ObatMasukRepository(),
        _obatKeluarRepository = obatKeluarRepository ?? ObatKeluarRepository(),
        _sinkronisasiStokRepository =
            sinkronisasiStokRepository ?? SinkronisasiStokRepository(),
        _transaksiRepository = transaksiRepository ?? TransaksiRepository();

  final ObatMasukRepository _obatMasukRepository;
  final ObatKeluarRepository _obatKeluarRepository;
  final SinkronisasiStokRepository _sinkronisasiStokRepository;
  final TransaksiRepository _transaksiRepository;

  Future<ObatMasukModel> stokMasuk({
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) {
    _requirePositive(jumlahMasuk, field: 'jumlahMasuk');
    return _obatMasukRepository.insertObatMasuk(
      idObat: idObat,
      tanggalMasuk: tanggalMasuk,
      jumlahMasuk: jumlahMasuk,
      idAdmin: idAdmin,
      keterangan: keterangan,
    );
  }

  Future<ObatMasukModel> updateStokMasuk({
    required int idMasuk,
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) {
    _requirePositive(jumlahMasuk, field: 'jumlahMasuk');
    return _obatMasukRepository.updateObatMasuk(
      idMasuk: idMasuk,
      idObat: idObat,
      tanggalMasuk: tanggalMasuk,
      jumlahMasuk: jumlahMasuk,
      idAdmin: idAdmin,
      keterangan: keterangan,
    );
  }

  Future<void> deleteStokMasuk(int idMasuk) {
    return _obatMasukRepository.deleteObatMasuk(idMasuk);
  }

  Future<void> deleteStokMasukByTanggal(DateTime tanggalMasuk) {
    return _obatMasukRepository.deleteObatMasukByTanggal(tanggalMasuk);
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
      _requirePositive(item.jumlah, field: 'jumlah');
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

  Future<ObatKeluarModel> updateStokKeluar({
    required int idTerjual,
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
      _requirePositive(item.jumlah, field: 'jumlah');
      _requireNonNegative(item.subtotal.round(), field: 'subtotal');
    }
    return _obatKeluarRepository.updateObatKeluar(
      idTerjual: idTerjual,
      tanggalTerjual: tanggalTerjual,
      items: items,
      keterangan: keterangan,
      idAdmin: idAdmin,
      noEtalase: noEtalase,
    );
  }

  Future<void> deleteStokKeluar(int idTerjual) {
    return _obatKeluarRepository.deleteObatKeluar(idTerjual);
  }

  Future<void> deleteStokKeluarByTanggal(DateTime tanggalTerjual) {
    return _obatKeluarRepository.deleteObatKeluarByTanggal(tanggalTerjual);
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

  Future<SinkronisasiStokModel> updateSyncOpname({
    required int idOpname,
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) {
    _requireNonNegative(stokSistem, field: 'stokSistem');
    _requireNonNegative(stokFisik, field: 'stokFisik');
    return _sinkronisasiStokRepository.updateSinkronisasiStok(
      idOpname: idOpname,
      idObat: idObat,
      tanggalOpname: tanggalOpname,
      stokSistem: stokSistem,
      stokFisik: stokFisik,
      idAdmin: idAdmin,
      alasanPenyesuaian: alasanPenyesuaian,
    );
  }

  Future<void> deleteSyncOpname(int idOpname) {
    return _sinkronisasiStokRepository.deleteSinkronisasiStok(idOpname);
  }

  Future<void> deleteSyncOpnameByTanggal(DateTime tanggalOpname) {
    return _sinkronisasiStokRepository.deleteSinkronisasiStokByTanggal(
      tanggalOpname,
    );
  }

  /// Transaksi ready-stock/custom via single atomic RPC.
  /// Stock movement, header, item, dan update stok dilakukan terpusat di DB.
  Future<TransaksiModel> createTransaksiAtomic({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) {
    if (transaksi.total <= 0) {
      throw const ValidationException(
        'Total transaksi harus lebih dari 0.',
        code: 'transaksi_total_invalid',
      );
    }
    if (transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock &&
        items.isEmpty) {
      throw const ValidationException(
        'Transaksi obat wajib memiliki item.',
        code: 'transaksi_ready_stock_items_empty',
      );
    }
    for (final item in items) {
      _requirePositive(item.jumlah, field: 'jumlah');
      _requireNonNegative(item.subtotal.round(), field: 'subtotal');
    }
    return _transaksiRepository.createTransactionAtomic(
      transaksi: transaksi,
      items: items,
      idAdmin: idAdmin,
    );
  }

  void _requirePositive(int value, {required String field}) {
    if (value <= 0) {
      throw ValidationException(
        '$field harus lebih dari 0.',
        code: 'stock_positive_required',
      );
    }
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
