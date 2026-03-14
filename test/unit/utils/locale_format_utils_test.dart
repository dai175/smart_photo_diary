import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/utils/locale_format_utils.dart';

void main() {
  group('LocaleFormatUtils', () {
    group('formatCurrency', () {
      test('formats JPY currency for ja locale', () {
        final result = LocaleFormatUtils.formatCurrency(
          300,
          locale: 'ja',
          currencyCode: 'JPY',
        );

        expect(result, contains('300'));
        // JPY should not have decimal places
      });

      test('formats large JPY amount', () {
        final result = LocaleFormatUtils.formatCurrency(
          2800,
          locale: 'ja',
          currencyCode: 'JPY',
        );

        expect(result, contains('2,800'));
      });

      test('formats zero amount', () {
        final result = LocaleFormatUtils.formatCurrency(
          0,
          locale: 'ja',
          currencyCode: 'JPY',
        );

        expect(result, contains('0'));
      });

      test('formats for en locale', () {
        final result = LocaleFormatUtils.formatCurrency(
          2800,
          locale: 'en',
          currencyCode: 'JPY',
        );

        expect(result, isNotEmpty);
      });
    });

    group('formatDecimal', () {
      test('formats integer without decimals', () {
        final result = LocaleFormatUtils.formatDecimal(1234, locale: 'ja');

        expect(result, contains('1,234'));
      });

      test('formats with specified decimal digits', () {
        final result = LocaleFormatUtils.formatDecimal(
          3.14159,
          locale: 'en',
          decimalDigits: 2,
        );

        expect(result, contains('3.14'));
      });

      test('formats zero', () {
        final result = LocaleFormatUtils.formatDecimal(0, locale: 'ja');

        expect(result, '0');
      });
    });
  });
}
