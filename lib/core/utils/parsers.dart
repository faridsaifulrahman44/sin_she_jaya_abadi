String parseString(
  dynamic value, {
  String fallback = '',
}) {
  if (value == null) {
    return fallback;
  }

  final parsed = value.toString().trim();
  return parsed.isEmpty ? fallback : parsed;
}

String? parseNullableString(dynamic value) {
  final parsed = parseString(value);
  return parsed.isEmpty ? null : parsed;
}

int parseInt(
  dynamic value, {
  int fallback = 0,
}) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim()) ?? fallback;
}

int? parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim());
}

double parseDouble(
  dynamic value, {
  double fallback = 0,
}) {
  if (value == null) {
    return fallback;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().trim()) ?? fallback;
}

num? parseNullableNum(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  // Coba int dulu, lalu double
  return int.tryParse(raw) ?? double.tryParse(raw);
}

DateTime parseDate(
  dynamic value, {
  DateTime? fallback,
}) {
  return parseNullableDate(value) ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}
