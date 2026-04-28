class ObatUsageInfo {
  const ObatUsageInfo({
    required this.usedInObatMasuk,
    required this.usedInObatKeluarItem,
    required this.usedInSinkronisasiStok,
  });

  final bool usedInObatMasuk;
  final bool usedInObatKeluarItem;
  final bool usedInSinkronisasiStok;

  bool get isUsed =>
      usedInObatMasuk || usedInObatKeluarItem || usedInSinkronisasiStok;

  List<String> get usedSources {
    final sources = <String>[];
    if (usedInObatMasuk) {
      sources.add('obat_masuk');
    }
    if (usedInObatKeluarItem) {
      sources.add('obat_keluar_item');
    }
    if (usedInSinkronisasiStok) {
      sources.add('sinkronisasi_stok');
    }
    return sources;
  }

  String toDeleteBlockedMessage({String? namaObat}) {
    final target =
        (namaObat ?? '').trim().isEmpty ? 'Obat ini' : 'Obat "$namaObat"';
    if (!isUsed) {
      return '$target belum dipakai pada histori dan dapat dihapus.';
    }

    final refs = usedSources.join(', ');
    return '$target tidak bisa dihapus karena sudah dipakai pada: $refs.';
  }

  factory ObatUsageInfo.fromMap(Map<String, dynamic> map) {
    // Kolom database baru: sinkronisasi_stok. Fallback ke nama lama
    // jika view/function belum dimigrasikan.
    final inSinkronisasiStok = _parseBool(
        map['used_in_sinkronisasi_stok'] ??
        map['used_in_stock_opname'] ??
        map['is_used_sinkronisasi_stok'] ??
        map['is_used_stock_opname']);

    return ObatUsageInfo(
      usedInObatMasuk:
          _parseBool(map['used_in_obat_masuk'] ?? map['is_used_obat_masuk']),
      usedInObatKeluarItem: _parseBool(
          map['used_in_obat_keluar_item'] ?? map['is_used_obat_keluar_item']),
      usedInSinkronisasiStok: inSinkronisasiStok,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return false;

    final raw = value.toString().trim().toLowerCase();
    return raw == 'true' || raw == '1' || raw == 't' || raw == 'yes';
  }
}
