import 'package:intl/intl.dart';

final NumberFormat _rupiahFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String rupiah(num value) => _rupiahFormatter.format(value);

String asDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

String asMediumDate(DateTime date) =>
    DateFormat('dd MMM yyyy', 'id_ID').format(date);

String asLongDate(DateTime date) =>
    DateFormat('dd MMMM yyyy', 'id_ID').format(date);

String formatDateDb(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String formatNullableDate(
  DateTime? date, {
  String fallback = '-',
}) {
  if (date == null) {
    return fallback;
  }
  return asDate(date);
}

String formatDateRangeLabel(DateTime startDate, DateTime endDate) {
  final isSameDay = startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;
  if (isSameDay) {
    return asDate(startDate);
  }
  return '${asDate(startDate)} - ${asDate(endDate)}';
}

/// Jam besar di dashboard, contoh: "11.14"
String formatClock(DateTime time) => DateFormat('HH.mm').format(time);

/// Tanggal lengkap Bahasa Indonesia, contoh: "Senin, 11 Mei 2026"
String formatDashboardDate(DateTime date) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
