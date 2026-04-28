import '../../core/utils/parsers.dart';

/// Status pembayaran tagihan.
enum StatusBayar {
  lunas('lunas', 'Lunas'),
  belumLunas('belum_lunas', 'Belum Lunas'),
  dicicil('dicicil', 'Dicicil'),
  dibatalkan('dibatalkan', 'Dibatalkan');

  const StatusBayar(this.value, this.label);
  final String value;
  final String label;

  static StatusBayar fromString(String? value) {
    if (value == null) return StatusBayar.belumLunas;
    return StatusBayar.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StatusBayar.belumLunas,
    );
  }
}

/// Metode pembayaran.
enum MetodeBayar {
  cash('cash', 'Tunai'),
  debit('debit', 'Debit'),
  transfer('transfer', 'Transfer'),
  qr('qr', 'QRIS'),
  lainnya('lainnya', 'Lainnya');

  const MetodeBayar(this.value, this.label);
  final String value;
  final String label;

  static MetodeBayar fromString(String? value) {
    if (value == null) return MetodeBayar.cash;
    return MetodeBayar.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MetodeBayar.cash,
    );
  }
}

/// Represents a billing/payment record for a patient visit.
///
/// Note: Requires `tagihan` table in Supabase.
class TagihanModel {
  const TagihanModel({
    required this.idTagihan,
    required this.idKunjungan,
    required this.idPasien,
    required this.tanggal,
    this.rincianObat,
    this.rincianBiayaPraktek,
    required this.totalObat,
    required this.totalBiayaPraktek,
    required this.totalBayar,
    required this.statusBayar,
    this.metodeBayar,
    this.nominalDibayar,
    this.idAdmin,
    this.createdAt,
    this.updatedAt,
  });

  final int idTagihan;
  final int idKunjungan;
  final int idPasien;
  final DateTime tanggal;
  final String? rincianObat;
  final String? rincianBiayaPraktek;
  final double totalObat;
  final double totalBiayaPraktek;
  final double totalBayar;
  final StatusBayar statusBayar;
  final MetodeBayar? metodeBayar;
  final double? nominalDibayar;
  final int? idAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get sisaBayar => totalBayar - (nominalDibayar ?? 0);

  factory TagihanModel.fromMap(Map<String, dynamic> map) {
    return TagihanModel(
      idTagihan: parseInt(map['id_tagihan']),
      idKunjungan: parseInt(map['id_kunjungan']),
      idPasien: parseInt(map['id_pasien']),
      tanggal: parseDate(map['tanggal']),
      rincianObat: parseNullableString(map['rincian_obat']),
      rincianBiayaPraktek: parseNullableString(map['rincian_biaya_praktek']),
      totalObat: parseDouble(map['total_obat'], fallback: 0),
      totalBiayaPraktek: parseDouble(map['total_biaya_praktek'], fallback: 0),
      totalBayar: parseDouble(map['total_bayar'], fallback: 0),
      statusBayar: StatusBayar.fromString(map['status_bayar']?.toString()),
      metodeBayar: MetodeBayar.fromString(map['metode_bayar']?.toString()),
      nominalDibayar: parseDouble(map['nominal_dibayar']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
      updatedAt: parseNullableDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_tagihan': idTagihan,
      'id_kunjungan': idKunjungan,
      'id_pasien': idPasien,
      'tanggal': tanggal.toIso8601String().split('T').first,
      'rincian_obat': rincianObat,
      'rincian_biaya_praktek': rincianBiayaPraktek,
      'total_obat': totalObat,
      'total_biaya_praktek': totalBiayaPraktek,
      'total_bayar': totalBayar,
      'status_bayar': statusBayar.value,
      'metode_bayar': metodeBayar?.value,
      'nominal_dibayar': nominalDibayar,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
