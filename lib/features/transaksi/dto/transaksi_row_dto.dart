import 'package:klinik_mobile_app/core/utils/parsers.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';

class TransaksiRowDto {
  const TransaksiRowDto({
    required this.idTransaksi,
    required this.tanggal,
    required this.jenisTransaksi,
    required this.total,
    required this.metodeBayar,
    required this.idPasien,
    required this.keterangan,
    required this.durasiHarian,
    required this.idAdmin,
    required this.createdAt,
  });

  final int idTransaksi;
  final DateTime tanggal;
  final String? jenisTransaksi;
  final double total;
  final String? metodeBayar;
  final int? idPasien;
  final String? keterangan;
  final int? durasiHarian;
  final int idAdmin;
  final DateTime? createdAt;

  factory TransaksiRowDto.fromMap(Map<String, dynamic> map) {
    return TransaksiRowDto(
      idTransaksi: parseInt(map['id_transaksi']),
      tanggal: parseDate(map['tanggal']),
      jenisTransaksi: parseNullableString(map['jenis_transaksi']),
      total: parseDouble(map['total'], fallback: 0),
      metodeBayar: parseNullableString(map['metode_bayar']),
      idPasien: parseNullableInt(map['id_pasien']),
      keterangan: parseNullableString(map['keterangan']),
      durasiHarian: parseNullableInt(map['durasi_harian']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  TransaksiModel toDomain() {
    return TransaksiModel(
      idTransaksi: idTransaksi,
      tanggal: tanggal,
      jenisTransaksi: JenisTransaksi.fromString(jenisTransaksi),
      total: total,
      metodeBayar: MetodeBayarTransaksi.fromString(metodeBayar),
      idPasien: idPasien,
      keterangan: keterangan,
      durasiHarian: durasiHarian,
      idAdmin: idAdmin,
      createdAt: createdAt,
    );
  }
}
