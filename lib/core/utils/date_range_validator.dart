class DateRangeValidationResult {
  const DateRangeValidationResult({
    required this.isValid,
    this.message,
  });

  final bool isValid;
  final String? message;
}

DateRangeValidationResult validateDateRange({
  required DateTime startDate,
  required DateTime endDate,
}) {
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);

  if (end.isBefore(start)) {
    return const DateRangeValidationResult(
      isValid: false,
      message: 'Tanggal akhir tidak boleh sebelum tanggal mulai.',
    );
  }

  return const DateRangeValidationResult(isValid: true);
}
