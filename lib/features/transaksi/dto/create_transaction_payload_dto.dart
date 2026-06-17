import 'package:klinik_mobile_app/data/models/transaksi_model.dart';

class CreateTransactionItemDto {
  const CreateTransactionItemDto({
    required this.idObat,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.satuanTerjual,
  });

  final int idObat;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final String? satuanTerjual;

  factory CreateTransactionItemDto.fromDomain(TransaksiItemModel model) {
    return CreateTransactionItemDto(
      idObat: model.idObat,
      jumlah: model.jumlah,
      hargaSatuan: model.hargaSatuan,
      subtotal: model.subtotal,
      satuanTerjual: model.satuanTerjual,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_obat': idObat,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
      'satuan_terjual': satuanTerjual,
    };
  }
}
