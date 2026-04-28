import '../../data/models/obat_model.dart';

class ObatKeluarFormEntry {
  ObatKeluarFormEntry({
    this.idItem = 0,
    this.idObat,
    this.jumlah,
    this.hargaSatuan,
    // ── Ecer Sederhana (FASE 3, 2026-04-27) ──────────────────────
    this.satuanTerjual,
  });

  int idItem;
  int? idObat;
  int? jumlah;
  double? hargaSatuan;

  // ── Ecer (FASE 3) ─────────────────────────────────────────────
  /// Satuan aktual yang dipilih user saat transaksi (nullable).
  /// Null untuk legacy transaksi atau transaksi tanpa informasi satuan.
  String? satuanTerjual;
  // ─────────────────────────────────────────────────────────────

  double get subtotal => (jumlah ?? 0) * (hargaSatuan ?? 0);

  String? validate() {
    if (idObat == null) return 'Pilih obat';
    if (jumlah == null || jumlah! <= 0) return 'Qty harus > 0';
    if (hargaSatuan == null || hargaSatuan! < 0) return 'Harga harus >= 0';
    return null;
  }

  /// Validasi oversell: qty tidak boleh melebihi stok tersedia.
  ///
  /// [selectedObat] adalah ObatModel yang sesuai dengan [idObat] saat ini.
  /// Jika [selectedObat] null atau idObat tidak match, validasi diskip.
  /// [isEcer] = true mengskip validasi stok (eceran tidak track per-unit stock).
  String? validateStock(ObatModel? selectedObat, {bool isEcer = false}) {
    if (idObat == null || jumlah == null) return null;
    if (isEcer) return null;
    if (selectedObat == null || selectedObat.idObat != idObat) return null;
    if (jumlah! > selectedObat.stokSaatIni) {
      return 'Stok tidak cukup (tersedia: ${selectedObat.stokSaatIni})';
    }
    return null;
  }
}
