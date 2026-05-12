import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';

/// Represents a medication stock-in/restock entry.
class ObatMasukModel {
  const ObatMasukModel({
    required this.idMasuk,
    required this.idObat,
    this.namaObat,
    this.fotoKey,
    this.fotoUpdatedAt,
    this.fotoUrl,
    required this.tanggalMasuk,
    required this.jumlahMasuk,
    this.keterangan,
    required this.idAdmin,
    this.createdAt,
  });

  final int idMasuk;
  final int idObat;
  final String? namaObat;

  /// Storage key di bucket `obat-images` — prioritas 1 untuk foto.
  final String? fotoKey;

  /// Timestamp update foto terakhir — untuk cache busting.
  final DateTime? fotoUpdatedAt;

  /// Legacy field. Prioritas 2.
  final String? fotoUrl;
  final DateTime tanggalMasuk;
  final int jumlahMasuk;
  final String? keterangan;
  final int idAdmin;
  final DateTime? createdAt;

  factory ObatMasukModel.fromMap(Map<String, dynamic> map) {
    return ObatMasukModel(
      idMasuk: parseInt(map['id_masuk']),
      idObat: parseInt(map['id_obat']),
      namaObat: _parseNamaObat(map),
      fotoKey: _parseFotoKey(map),
      fotoUpdatedAt: _parseFotoUpdatedAt(map),
      fotoUrl: _parseFotoUrl(map),
      tanggalMasuk: parseDate(map['tanggal_masuk']),
      jumlahMasuk: parseInt(map['jumlah_masuk'], fallback: 0),
      keterangan: parseNullableString(map['keterangan']),
      idAdmin: parseInt(map['id_admin']),
      createdAt: parseNullableDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_masuk': idMasuk,
      'id_obat': idObat,
      'tanggal_masuk': formatDateDb(tanggalMasuk),
      'jumlah_masuk': jumlahMasuk,
      'keterangan': keterangan,
      'id_admin': idAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static String? _parseNamaObat(Map<String, dynamic> map) {
    final direct = parseNullableString(map['nama_obat']);
    if (direct != null) return direct;

    final obat = map['obat'];
    if (obat is Map<String, dynamic>) {
      return parseNullableString(obat['nama_obat']);
    }
    if (obat is Map) {
      return parseNullableString(obat['nama_obat']);
    }
    if (obat is List && obat.isNotEmpty) {
      final first = obat.first;
      if (first is Map<String, dynamic>) {
        return parseNullableString(first['nama_obat']);
      }
      if (first is Map) {
        return parseNullableString(first['nama_obat']);
      }
    }

    return null;
  }

  static String? _parseFotoUrl(Map<String, dynamic> map) {
    final direct = parseNullableString(map['foto_url']);
    if (direct != null) return direct;

    final obat = map['obat'];
    if (obat is Map<String, dynamic>) {
      return parseNullableString(obat['foto_url']);
    }
    if (obat is Map) {
      return parseNullableString(obat['foto_url']);
    }
    if (obat is List && obat.isNotEmpty) {
      final first = obat.first;
      if (first is Map<String, dynamic>) {
        return parseNullableString(first['foto_url']);
      }
      if (first is Map) {
        return parseNullableString(first['foto_url']);
      }
    }

    return null;
  }

  static String? _parseFotoKey(Map<String, dynamic> map) {
    final direct = parseNullableString(map['foto_key']);
    if (direct != null) return direct;

    final obat = map['obat'];
    if (obat is Map<String, dynamic>) {
      return parseNullableString(obat['foto_key']);
    }
    if (obat is Map) {
      return parseNullableString(obat['foto_key']);
    }
    if (obat is List && obat.isNotEmpty) {
      final first = obat.first;
      if (first is Map<String, dynamic>) {
        return parseNullableString(first['foto_key']);
      }
      if (first is Map) {
        return parseNullableString(first['foto_key']);
      }
    }

    return null;
  }

  static DateTime? _parseFotoUpdatedAt(Map<String, dynamic> map) {
    final direct = parseNullableDate(map['foto_updated_at']);
    if (direct != null) return direct;

    final obat = map['obat'];
    if (obat is Map<String, dynamic>) {
      return parseNullableDate(obat['foto_updated_at']);
    }
    if (obat is Map) {
      return parseNullableDate(obat['foto_updated_at']);
    }
    if (obat is List && obat.isNotEmpty) {
      final first = obat.first;
      if (first is Map<String, dynamic>) {
        return parseNullableDate(first['foto_updated_at']);
      }
      if (first is Map) {
        return parseNullableDate(first['foto_updated_at']);
      }
    }

    return null;
  }
}
