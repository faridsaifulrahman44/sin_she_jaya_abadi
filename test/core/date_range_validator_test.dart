import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/utils/date_range_validator.dart';

void main() {
  group('validateDateRange', () {
    test('accepts same day range', () {
      final result = validateDateRange(
        startDate: DateTime(2026, 3, 28),
        endDate: DateTime(2026, 3, 28),
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('rejects end date before start date', () {
      final result = validateDateRange(
        startDate: DateTime(2026, 3, 29),
        endDate: DateTime(2026, 3, 28),
      );

      expect(result.isValid, isFalse);
      expect(result.message, isNotNull);
    });
  });
}
