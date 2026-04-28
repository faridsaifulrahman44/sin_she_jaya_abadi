import '../../core/utils/parsers.dart';

/// Jenis transaksi di klinik.
enum JenisTransaksi {
  obatReadyStock('obat_ready_stock', 'Obat Ready Stock'),
  praktekCustom('praktek_custom', 'Praktek + Obat Custom');

  const JenisTransaksi(this.value, this.label);
  final String value;
  final String label;

  static JenisTransaksi fromString(String? value) {
    if (value == null) return JenisTransaksi.obatReadyStock;
    return JenisTransaksi.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JenisTransaksi.obatReadyStock,
    );
  }
}

/// Metode pembayaran transaksi.
enum MetodeBayarTransaksi {
  cash('cash', 'Tunai'),
  qris('qris', 'QRIS');

  const MetodeBayarTransaksi(this.value, this.label);
  final String value;
  final String label;

  static MetodeBayarTransaksi fromString(String? value) {
    if (value == null) return MetodeBayarTransaksi.cash;
    return MetodeBayarTransaksi.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MetodeBayarTransaksi.cash,
    );
  }
}

/// Model header transaksi.
class TransaksiModel {
  const TransaksiModel({
    required this.idTransaksi,
    required this.tanggal,
    required this.jenisTransaksi,
    required this.total,
    this.metodeBayar,
    this.idPasien,
    this.keterangan,
    this.durasiHarian,
    required this.idAdmin,
    this.createdAt,
  });

  final int idTransaksi;
  final DateTime tanggal;
  final JenisTransaksi jenisTransaksi;
  final double total;
  final MetodeBayarTransaksi? metodeBayar;
  final int? idPasien;
  final String? keterangan;
  final int? durasiHarian;
  final int idAdmin;
  final DateTime? createdAt;

  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      idTransaksi: parseInt(map['id_transaksi']),
      tanggal: parseDate(map['tanggal']),
      jenisTransaksi:
          JenisTransaksi.fromString(map['jenis_transaksi']?.toString()),
      total: parseDouble(map['total'], fallback: 0),
      metodeBayar:
          MetodeBayarTransaksi.fromString(map['metode_bayar']?.toString()),
      idPasien: parseNullableInt(map['id_pasien']),
      keterangan: parseNullableString(map['keterangan']),
      durasiHarian: parseNullableInt(map['durasi_harian']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_transaksi': idTransaksi,
      'tanggal': tanggal.toIso8601String().split('T').first,
      'jenis_transaksi': jenisTransaksi.value,
      'total': total,
      'metode_bayar': metodeBayar?.value,
      'id_pasien': idPasien,
      'keterangan': keterangan,
      'id_admin': idAdmin,
    };
  }

  /// Untuk insert (tanpa id_transaksi).
  Map<String, dynamic> toInsertMap() {
    return {
      'tanggal': tanggal.toIso8601String().split('T').first,
      'jenis_transaksi': jenisTransaksi.value,
      'total': total,
      'metode_bayar': metodeBayar?.value,
      'id_pasien': idPasien,
      'keterangan': keterangan,
      'durasi_harian': durasiHarian,
      'id_admin': idAdmin,
    };
  }
}

/// Model item transaksi untuk ready stock.
class TransaksiItemModel {
  const TransaksiItemModel({
    required this.idItem,
    required this.idTransaksi,
    required this.idObat,
    this.namaObat,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    required this.idAdmin,
    // ── Ecer Sederhana (FASE 3, 2026-04-27) ──────────────────────
    this.satuanTerjual,
  });

  final int idItem;
  final int idTransaksi;
  final int idObat;
  final String? namaObat;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final int idAdmin;

  // ── Ecer Sederhana (FASE 3, 2026-04-27) ──────────────────────────
  /// Satuan aktual yang dipilih user saat transaksi.
  /// Nullable — legacy transaction sebelum FASE 3 dan transaksi custom tidak punya.
  final String? satuanTerjual;
  // ──────────────────────────────────────────────��─────────────────

  factory TransaksiItemModel.fromMap(Map<String, dynamic> map) {
    return TransaksiItemModel(
      idItem: parseInt(map['id_item']),
      idTransaksi: parseInt(map['id_transaksi']),
      idObat: parseInt(map['id_obat']),
      namaObat: parseNullableString(map['nama_obat']),
      jumlah: parseInt(map['jumlah']),
      hargaSatuan: parseDouble(map['harga_satuan'], fallback: 0),
      subtotal: parseDouble(map['subtotal'], fallback: 0),
      idAdmin: parseInt(map['id_admin']),
      // ── Ecer (FASE 3) ─────────────────────────────────────────────
      satuanTerjual: parseNullableString(map['satuan_terjual']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_item': idItem,
      'id_transaksi': idTransaksi,
      'id_obat': idObat,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
      'satuan_terjual': satuanTerjual,
      'id_admin': idAdmin,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id_transaksi': idTransaksi,
      'id_obat': idObat,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
      'satuan_terjual': satuanTerjual,
      'id_admin': idAdmin,
    };
  }
}
