import 'package:klinik_mobile_app/core/error/app_exception.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/features/stok/services/stock_service.dart';

class CreateTransactionUseCase {
  CreateTransactionUseCase({StockService? stockService})
      : _stockService = stockService ?? StockService();

  final StockService _stockService;

  Future<TransaksiModel> execute({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) async {
    if (transaksi.idAdmin != idAdmin) {
      throw const ValidationException(
        'Session admin tidak sesuai. Silakan muat ulang halaman.',
        code: 'transaksi_admin_mismatch',
      );
    }

    if (transaksi.total <= 0) {
      throw const ValidationException(
        'Total transaksi harus lebih dari 0.',
        code: 'transaksi_total_invalid',
      );
    }

    if (transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock) {
      if (items.isEmpty) {
        throw const ValidationException(
          'Transaksi obat wajib memiliki item.',
          code: 'transaksi_ready_stock_items_empty',
        );
      }

      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );
      final diff = (subtotal - transaksi.total).abs();
      if (diff > 0.01) {
        throw const ValidationException(
          'Total transaksi tidak sesuai dengan subtotal item.',
          code: 'transaksi_total_mismatch',
        );
      }
    }

    return _stockService.createTransaksiAtomic(
      transaksi: transaksi,
      items: items,
      idAdmin: idAdmin,
    );
  }
}
