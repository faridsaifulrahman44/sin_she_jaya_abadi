import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/utils/parsers.dart';

void main() {
  group('parseInt', () {
    test('returns fallback for null', () {
      expect(parseInt(null), 0);
    });

    test('returns fallback for null with custom fallback', () {
      expect(parseInt(null, fallback: -1), -1);
    });

    test('returns int as-is', () {
      expect(parseInt(42), 42);
    });

    test('returns num as int (double)', () {
      expect(parseInt(42.9), 42);
    });

    test('returns num as int (int subtype)', () {
      final num n = 7;
      expect(parseInt(n), 7);
    });

    test('parses string integer', () {
      expect(parseInt('100'), 100);
    });

    test('parses string with whitespace', () {
      expect(parseInt('  99  '), 99);
    });

    test('returns fallback for unparseable string', () {
      expect(parseInt('abc'), 0);
    });

    test('returns fallback for empty string', () {
      expect(parseInt(''), 0);
    });
  });

  group('parseNullableInt', () {
    test('returns null for null input', () {
      expect(parseNullableInt(null), isNull);
    });

    test('returns int as-is', () {
      expect(parseNullableInt(42), 42);
    });

    test('returns num as int (double)', () {
      expect(parseNullableInt(42.9), 42);
    });

    test('parses valid integer string', () {
      expect(parseNullableInt(' 100 '), 100);
    });

    test('returns null for invalid string', () {
      expect(parseNullableInt('abc'), isNull);
    });
  });

  group('parseDouble', () {
    test('returns fallback for null', () {
      expect(parseDouble(null), 0.0);
    });

    test('returns fallback for null with custom fallback', () {
      expect(parseDouble(null, fallback: -1.5), -1.5);
    });

    test('returns double as-is', () {
      expect(parseDouble(12.5), 12.5);
    });

    test('returns int as double', () {
      expect(parseDouble(7), 7.0);
    });

    test('returns num as double (double subtype)', () {
      final num n = 3.14;
      expect(parseDouble(n), 3.14);
    });

    test('parses string double', () {
      expect(parseDouble('99.5'), 99.5);
    });

    test('parses string with whitespace', () {
      expect(parseDouble('  7.5  '), 7.5);
    });

    test('returns fallback for unparseable string', () {
      expect(parseDouble('abc'), 0.0);
    });

    test('returns fallback for empty string', () {
      expect(parseDouble(''), 0.0);
    });
  });

  group('parseDate', () {
    test('parses ISO date string YYYY-MM-DD', () {
      expect(parseDate('2026-03-28'), DateTime(2026, 3, 28));
    });

    test('parses ISO datetime string with time component', () {
      final result = parseDate('2026-03-28T14:30:00.000Z');
      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 28);
    });

    test('returns epoch fallback for null', () {
      expect(parseDate(null), DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('returns custom fallback for null', () {
      final fallback = DateTime(2020, 1, 1);
      expect(parseDate(null, fallback: fallback), fallback);
    });

    test('returns DateTime as-is', () {
      final dt = DateTime(2026, 3, 28, 10, 30);
      expect(parseDate(dt), dt);
    });

    test('returns epoch for unparseable string', () {
      expect(parseDate('not-a-date'), DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('parseNullableDate', () {
    test('returns null for null input', () {
      expect(parseNullableDate(null), isNull);
    });

    test('parses ISO date string YYYY-MM-DD', () {
      expect(parseNullableDate('2026-03-28'), DateTime(2026, 3, 28));
    });

    test('parses ISO datetime string with time component', () {
      final result = parseNullableDate('2026-03-28T14:30:00.000Z');
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 28);
    });

    test('returns null for empty string', () {
      expect(parseNullableDate(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parseNullableDate('   '), isNull);
    });

    test('returns DateTime as-is', () {
      final dt = DateTime(2026, 3, 28);
      expect(parseNullableDate(dt), dt);
    });

    test('returns null for unparseable string', () {
      expect(parseNullableDate('hello'), isNull);
    });
  });

  group('parseNullableString', () {
    test('returns null for null input', () {
      expect(parseNullableString(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseNullableString(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parseNullableString('   '), isNull);
    });

    test('returns trimmed string for non-empty input', () {
      expect(parseNullableString('  hello  '), 'hello');
    });

    test('returns string for non-empty input', () {
      expect(parseNullableString('Paracetamol'), 'Paracetamol');
    });

    test('returns "0" string for int zero', () {
      // int 0 converts to "0" string, which is non-empty → returned as-is
      expect(parseNullableString(0), '0');
    });
  });

  group('parseString', () {
    test('returns fallback for null', () {
      expect(parseString(null), '');
    });

    test('returns fallback for empty string', () {
      expect(parseString(''), '');
    });

    test('returns fallback for whitespace-only string', () {
      expect(parseString('   '), '');
    });

    test('returns trimmed string for non-empty', () {
      expect(parseString('  obat  '), 'obat');
    });

    test('returns custom fallback for null', () {
      expect(parseString(null, fallback: 'N/A'), 'N/A');
    });

    test('returns int zero as string', () {
      expect(parseString(0), '0');
    });
  });
}
