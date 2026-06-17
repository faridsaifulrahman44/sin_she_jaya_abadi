import '../../core/utils/parsers.dart';
import 'obat_etalase.dart';

/// Enum status stok untuk display dan filtering.
enum StokStatus {
  /// Stok di atas minimum.
  aman('aman', 'Aman'),

  /// Stok di antara 1 dan minimum (termasuk batas minimum).
  menipis('menipis', 'Menipis'),

  /// Stok = 0 atau kurang.
  habis('habis', 'Habis');

  const StokStatus(this.value, this.label);
  final String value;
  final String label;

  /// Hitung status dari stok saat ini dan minimum.
  static StokStatus fromStok(int stok, int minimum) {
    if (stok <= 0) return StokStatus.habis;
    if (stok <= minimum) return StokStatus.menipis;
    return StokStatus.aman;
  }
}

/// Master data model for medication.
///
/// Stock is derived from the formula:
///   stok_saat_ini = stok_awal + mutasi masuk/keluar + reset stock opname.
/// Nilai akhir di-maintain oleh SQL/RPC database.
class ObatModel {
  const ObatModel({
    required this.idObat,
    required this.namaObat,
    required this.stokSaatIni,
    required this.stokMinimum,
    required this.etalase,
    this.satuan,
    this.keterangan,
    this.fotoKey,
    this.fotoUpdatedAt,
    this.fotoUrl,
    this.createdAt,
    this.updatedAt,
    // ── Harga Source of Truth (FASE 1, 2026-04-27) ────────────────────────
    this.hargaJual,
    this.satuanJual,
    this.bisaEcer = false,
    this.hargaEcer,
    this.satuanEcer,
    this.deskripsi,
  });

  final int idObat;
  final String namaObat;

  /// Current stock snapshot (stored in DB, recomputed by SQL function on mutation).
  final int stokSaatIni;

  /// Minimum stock threshold for low-stock indicator.
  final int stokMinimum;

  /// Fixed storage location.
  final Etalase etalase;

  final String? satuan;
  final String? keterangan;

  /// Storage key di bucket `obat-images` (misal: `ashwagandha_test.webp`).
  final String? fotoKey;

  /// Timestamp update foto terakhir — dipakai untuk cache busting / versioning.
  final DateTime? fotoUpdatedAt;

  /// Legacy field — URL lengkap foto. Kandidat deprecation.
  final String? fotoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Harga Source of Truth (FASE 1, 2026-04-27) ──────────────────────────
  /// Harga utama jual per [satuanJual]. Null jika belum diinput.
  final num? hargaJual;

  /// Satuan default untuk harga utama. Contoh: botol, strip, pcs, paket.
  final String? satuanJual;

  /// Apakah obat ini bisa dijual eceran.
  final bool bisaEcer;

  /// Harga eceran per [satuanEcer]. Null jika belum diinput atau tidak bisa ecer.
  final num? hargaEcer;

  /// Satuan eceran. Contoh: kapsul, tablet, ml.
  final String? satuanEcer;

  /// Deskripsi lengkap obat (manfaat, cara pakai, dosis, peringatan).
  final String? deskripsi;
  // ────────────────────────────────────────────────────────────────────────

  /// Status stok saat ini (aman/menipis/habis).
  StokStatus get statusStok => StokStatus.fromStok(stokSaatIni, stokMinimum);

  /// True when current stock is at or below the minimum threshold.
  bool get isLowStock => stokSaatIni <= stokMinimum;

  /// True when stok saat ini <= 0.
  bool get isStokHabis => stokSaatIni <= 0;

  /// How many units below minimum (0 if not low).
  int get selisihStok => isLowStock ? (stokMinimum - stokSaatIni) : 0;

  /// True if the record has a storage foto available.
  bool get hasFotoKey => fotoKey != null && fotoKey!.trim().isNotEmpty;

  /// True if this obat has a main price populated.
  bool get hasHargaJual => hargaJual != null && hargaJual! > 0;

  /// True if this obat can be sold individually (eceran).
  bool get hasEceran => bisaEcer && hargaEcer != null && hargaEcer! > 0;

  factory ObatModel.fromMap(Map<String, dynamic> map) {
    return ObatModel(
      idObat: parseInt(map['id_obat']),
      namaObat: parseString(map['nama_obat']),
      stokSaatIni: parseInt(map['stok_saat_ini'], fallback: 0),
      stokMinimum: parseInt(map['stok_minimum'], fallback: 10),
      etalase: Etalase.fromString(map['etalase']?.toString()),
      satuan: parseNullableString(map['satuan']),
      keterangan: parseNullableString(map['keterangan']),
      fotoKey: parseNullableString(map['foto_key']),
      fotoUpdatedAt: parseNullableDate(map['foto_updated_at']),
      fotoUrl: parseNullableString(map['foto_url']),
      createdAt: parseNullableDate(map['created_at']),
      updatedAt: parseNullableDate(map['updated_at']),
      // ── Harga Source of Truth (FASE 1, 2026-04-27) ────────────────────
      hargaJual: parseNullableNum(map['harga_jual']),
      satuanJual: parseNullableString(map['satuan_jual']),
      bisaEcer: _parseBool(map['bisa_ecer']),
      hargaEcer: parseNullableNum(map['harga_ecer']),
      satuanEcer: parseNullableString(map['satuan_ecer']),
      deskripsi: parseNullableString(map['deskripsi']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_obat': idObat,
      'nama_obat': namaObat,
      'stok_saat_ini': stokSaatIni,
      'stok_minimum': stokMinimum,
      'etalase': etalase.value,
      'satuan': satuan,
      'keterangan': keterangan,
      'foto_key': fotoKey,
      'foto_updated_at': fotoUpdatedAt?.toIso8601String(),
      'foto_url': fotoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // ── Harga Source of Truth (FASE 1, 2026-04-27) ────────────────────
      'harga_jual': hargaJual,
      'satuan_jual': satuanJual,
      'bisa_ecer': bisaEcer,
      'harga_ecer': hargaEcer,
      'satuan_ecer': satuanEcer,
      'deskripsi': deskripsi,
    };
  }

  /// Creates a copy of this [ObatModel] with the given fields replaced.
  ObatModel copyWith({
    int? idObat,
    String? namaObat,
    int? stokSaatIni,
    int? stokMinimum,
    Etalase? etalase,
    String? satuan,
    String? keterangan,
    String? fotoKey,
    DateTime? fotoUpdatedAt,
    String? fotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    num? hargaJual,
    String? satuanJual,
    bool? bisaEcer,
    num? hargaEcer,
    String? satuanEcer,
    String? deskripsi,
  }) {
    return ObatModel(
      idObat: idObat ?? this.idObat,
      namaObat: namaObat ?? this.namaObat,
      stokSaatIni: stokSaatIni ?? this.stokSaatIni,
      stokMinimum: stokMinimum ?? this.stokMinimum,
      etalase: etalase ?? this.etalase,
      satuan: satuan ?? this.satuan,
      keterangan: keterangan ?? this.keterangan,
      fotoKey: fotoKey ?? this.fotoKey,
      fotoUpdatedAt: fotoUpdatedAt ?? this.fotoUpdatedAt,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hargaJual: hargaJual ?? this.hargaJual,
      satuanJual: satuanJual ?? this.satuanJual,
      bisaEcer: bisaEcer ?? this.bisaEcer,
      hargaEcer: hargaEcer ?? this.hargaEcer,
      satuanEcer: satuanEcer ?? this.satuanEcer,
      deskripsi: deskripsi ?? this.deskripsi,
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
