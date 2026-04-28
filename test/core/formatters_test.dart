import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';

void main() {
  group('formatters', () {
    test('rupiah formats integer to IDR string', () {
      expect(rupiah(12000), 'Rp 12.000');
    });

    test('asDate formats date using dd/MM/yyyy', () {
      expect(asDate(DateTime(2026, 3, 28)), '28/03/2026');
    });

    test('formatDateRangeLabel returns single date when same day', () {
      expect(
        formatDateRangeLabel(DateTime(2026, 3, 28), DateTime(2026, 3, 28)),
        '28/03/2026',
      );
    });

    test('formatDateRangeLabel returns range when different dates', () {
      expect(
        formatDateRangeLabel(DateTime(2026, 3, 1), DateTime(2026, 3, 7)),
        '01/03/2026 - 07/03/2026',
      );
    });
  });
}
