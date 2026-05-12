import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/data/models/sinkronisasi_stok_model.dart';
import 'package:klinik_mobile_app/features/stok/services/stock_service.dart';

class SyncStockUseCase {
  SyncStockUseCase({StockService? stockService})
      : _stockService = stockService ?? StockService();

  final StockService _stockService;

  Future<SinkronisasiStokModel> execute({
    int? idOpname,
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) {
    if (idObat <= 0) {
      throw const ValidationException(
        'Obat belum dipilih.',
        code: 'sync_stock_obat_invalid',
      );
    }

    if (stokSistem < 0 || stokFisik < 0) {
      throw const ValidationException(
        'Stok tidak boleh negatif.',
        code: 'sync_stock_negative',
      );
    }

    if (idOpname == null) {
      return _stockService.syncOpname(
        idObat: idObat,
        tanggalOpname: tanggalOpname,
        stokSistem: stokSistem,
        stokFisik: stokFisik,
        idAdmin: idAdmin,
        alasanPenyesuaian: alasanPenyesuaian,
      );
    }

    return _stockService.updateSyncOpname(
      idOpname: idOpname,
      idObat: idObat,
      tanggalOpname: tanggalOpname,
      stokSistem: stokSistem,
      stokFisik: stokFisik,
      idAdmin: idAdmin,
      alasanPenyesuaian: alasanPenyesuaian,
    );
  }
}
