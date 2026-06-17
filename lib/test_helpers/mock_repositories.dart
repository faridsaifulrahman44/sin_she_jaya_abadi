import 'package:klinik_mobile_app/data/models/obat_keluar_item_model.dart';
import 'package:klinik_mobile_app/data/models/obat_keluar_model.dart';
import 'package:klinik_mobile_app/data/models/obat_masuk_model.dart';
import 'package:klinik_mobile_app/data/models/sinkronisasi_stok_model.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/data/repositories/obat_keluar_repository.dart';
import 'package:klinik_mobile_app/data/repositories/obat_masuk_repository.dart';
import 'package:klinik_mobile_app/data/repositories/sinkronisasi_stok_repository.dart';
import 'package:klinik_mobile_app/data/repositories/transaksi_repository.dart';

/// Mock repositories untuk test validation.
///
/// Semua method throw UnimplementedError karena validation test
/// throw SEBELUM repository method dipanggil. Mock ini hanya untuk
/// memenuhi dependency injection agar constructor tidak crash.
class MockRepositories {
  late final ObatMasukRepository obatMasuk;
  late final ObatKeluarRepository obatKeluar;
  late final SinkronisasiStokRepository sinkronisasiStok;
  late final TransaksiRepository transaksi;

  MockRepositories() {
    obatMasuk = _MockObatMasukRepository();
    obatKeluar = _MockObatKeluarRepository();
    sinkronisasiStok = _MockSinkronisasiStokRepository();
    transaksi = _MockTransaksiRepository();
  }
}

class _MockObatMasukRepository implements ObatMasukRepository {
  @override
  Future<ObatMasukModel> insertObatMasuk({
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<ObatMasukModel> updateObatMasuk({
    required int idMasuk,
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<void> deleteObatMasuk(int idMasuk) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<void> deleteObatMasukByTanggal(DateTime tanggal) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Mock method not implemented');
}

class _MockObatKeluarRepository implements ObatKeluarRepository {
  @override
  Future<ObatKeluarModel> insertObatKeluar({
    required DateTime tanggalTerjual,
    required List<ObatKeluarItemModel> items,
    required int idAdmin,
    String? noEtalase,
    String? keterangan,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<ObatKeluarModel> updateObatKeluar({
    required int idTerjual,
    required DateTime tanggalTerjual,
    required List<ObatKeluarItemModel> items,
    required int idAdmin,
    String? noEtalase,
    String? keterangan,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<void> deleteObatKeluar(int idTerjual) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<void> deleteObatKeluarByTanggal(DateTime tanggal) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Mock method not implemented');
}

class _MockSinkronisasiStokRepository
    implements SinkronisasiStokRepository {
  @override
  Future<SinkronisasiStokModel> insertSinkronisasiStok({
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<SinkronisasiStokModel> updateSinkronisasiStok({
    required int idOpname,
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<void> deleteSinkronisasiStok(int idOpname) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<void> deleteSinkronisasiStokByTanggal(DateTime tanggalOpname) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Mock method not implemented');
}

class _MockTransaksiRepository implements TransaksiRepository {
  @override
  Future<TransaksiModel> createTransactionAtomic({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  Future<TransaksiModel> insertTransaksi({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) async {
    throw UnimplementedError('Should not be reached in validation tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Mock method not implemented');
}
