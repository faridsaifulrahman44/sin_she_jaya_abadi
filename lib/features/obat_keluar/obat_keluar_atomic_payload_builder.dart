import '../../data/models/obat_keluar_item_model.dart';

class ObatKeluarAtomicPayloadBuilder {
  const ObatKeluarAtomicPayloadBuilder._();

  static List<Map<String, dynamic>> build(List<ObatKeluarItemModel> items) {
    final nonLegacyItems = items.where((item) => !item.isLegacy).toList();
    if (nonLegacyItems.isEmpty) {
      throw Exception(
          'Transaksi harus memiliki minimal 1 item obat non-legacy.');
    }

    final payload = <Map<String, dynamic>>[];
    for (final item in nonLegacyItems) {
      if (item.idObat <= 0) {
        throw Exception('Item obat keluar memiliki id_obat tidak valid.');
      }
      if (item.jumlah <= 0) {
        throw Exception('Item obat keluar memiliki jumlah tidak valid.');
      }
      if (item.hargaSatuan < 0) {
        throw Exception('Item obat keluar memiliki harga_satuan tidak valid.');
      }

      payload.add({
        'id_obat': item.idObat,
        'jumlah': item.jumlah,
        'harga_satuan': item.hargaSatuan,
      });
    }

    return payload;
  }
}
