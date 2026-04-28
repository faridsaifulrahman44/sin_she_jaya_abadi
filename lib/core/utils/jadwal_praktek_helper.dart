/// Enum hari practise tetap: Senin, Rabu, Jumat.
enum HariPraktek {
  senin('senin', 'Senin', DateTime.monday),
  rabu('rabu', 'Rabu', DateTime.wednesday),
  jumat('jumat', 'Jumat', DateTime.friday);

  const HariPraktek(this.value, this.label, this.weekday);

  /// Nilai DB (lowercase).
  final String value;

  /// Label Indonesia untuk UI.
  final String label;

  /// Nomor weekday (DateTime.monday = 1, dst).
  final int weekday;

  /// Cek apakah [date] jatuh di hari ini.
  bool matchesDate(DateTime date) => date.weekday == weekday;

  /// Convert dari nilai DB string ("senin", "rabu", "jumat").
  static HariPraktek? fromString(String? value) {
    if (value == null) return null;
    for (final h in values) {
      if (h.value == value) return h;
    }
    return null;
  }

  static HariPraktek? fromDate(DateTime date) => fromWeekday(date.weekday);

  static HariPraktek? fromWeekday(int weekday) {
    for (final h in values) {
      if (h.weekday == weekday) return h;
    }
    return null;
  }
}

/// Helper terpusat untuk jadwal practise.
class JadwalPraktekHelper {
  const JadwalPraktekHelper._();

  /// Semua hari practise (statis).
  static const List<HariPraktek> hariPraktek = HariPraktek.values;

  /// Urutan weekday practise: [1, 3, 5] → Senin(1), Rabu(3), Jumat(5).
  static List<int> get weekdays => hariPraktek.map((h) => h.weekday).toList();

  /// Cek apakah [date] adalah hari practise valid.
  static bool isHariPraktek(DateTime date) =>
      HariPraktek.fromDate(date) != null;

  /// Validasi: apakah [date] adalah hari practise valid.
  /// Return null jika valid, return String error jika tidak.
  static String? validateHariPraktek(DateTime date) {
    if (isHariPraktek(date)) return null;
    return 'Tanggal ini bukan hari praktek. '
        'Praktek hanya bisa dijadwalkan hari '
        '${hariPraktek.map((h) => h.label).join(', ')}.';
  }

  /// Cek apakah sebuah DateTime valid untuk dijadwalkan
  /// (tanggal hari ini atau setelah, dan hari practise).
  static bool isValidUntukJadwal(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.compareTo(today) >= 0 && isHariPraktek(d);
  }

  /// Hitung tanggal practise berikutnya dari [from] (inclusive).
  /// Jika [from] sendiri adalah hari practise, return [from].
  static DateTime nextPracticeDay([DateTime? from]) {
    final start = from ?? DateTime.now();
    for (int i = 0; i <= 7; i++) {
      final candidate = start.add(Duration(days: i));
      if (isHariPraktek(candidate)) return candidate;
    }
    // Fallback: Senin depan
    return _nextWeekday(start, DateTime.monday);
  }

  /// Hitung tanggal practise berikutnya setelah [from] (strictly after).
  static DateTime nextPracticeDayAfter(DateTime from) {
    for (int i = 1; i <= 7; i++) {
      final candidate = from.add(Duration(days: i));
      if (isHariPraktek(candidate)) return candidate;
    }
    return _nextWeekday(from, DateTime.monday);
  }

  /// Ambil N opsi tanggal practise terdekat dari [from] (max 3).
  /// Jika [from] sendiri hari practise, opsi pertama = [from].
  static List<DateTime> nextPracticeOptions([DateTime? from, int count = 3]) {
    final result = <DateTime>[];
    final start = from ?? DateTime.now();
    for (int i = 0; i <= 7 && result.length < count; i++) {
      final candidate = start.add(Duration(days: i));
      if (isHariPraktek(candidate)) result.add(candidate);
    }
    return result;
  }

  /// Format label human-readable: "Senin, 21 Apr 2026".
  static String formatPracticeDateLabel(DateTime date) {
    final hari = HariPraktek.fromDate(date);
    return '${hari?.label ?? 'Tanggal'}, '
        '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  static String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month];
  }

  static DateTime _nextWeekday(DateTime from, int targetWeekday) {
    int diff = targetWeekday - from.weekday;
    if (diff <= 0) diff += 7;
    return from.add(Duration(days: diff));
  }
}
