import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/utils/date_utils.dart';

void main() {
  group('DateFormatExtension', () {
    group('toYearMonth', () {
      test('formats standard date correctly', () {
        final date = DateTime(2026, 3, 14);
        expect(date.toYearMonth(), '2026-03');
      });

      test('pads single-digit month with zero', () {
        final date = DateTime(2025, 1, 1);
        expect(date.toYearMonth(), '2025-01');
      });

      test('handles December correctly', () {
        final date = DateTime(2025, 12, 31);
        expect(date.toYearMonth(), '2025-12');
      });

      test('pads year with zeros for early years', () {
        final date = DateTime(5, 6, 1);
        expect(date.toYearMonth(), '0005-06');
      });
    });
  });
}
