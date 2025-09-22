import 'package:intl/intl.dart';

/// ロケールに応じた通貨・数値フォーマットを提供するユーティリティ
class LocaleFormatUtils {
  LocaleFormatUtils._();

  static String formatCurrency(
    num amount, {
    required String locale,
    String currencyCode = 'JPY',
  }) {
    try {
      final formatter = NumberFormat.simpleCurrency(
        locale: locale,
        name: currencyCode,
      );
      return formatter.format(amount);
    } catch (e) {
      // フォールバック: 標準的な通貨フォーマット
      final formatter = NumberFormat.currency(
        locale: locale,
        name: currencyCode,
      );
      return formatter.format(amount);
    }
  }

  static String formatDecimal(
    num value, {
    required String locale,
    int decimalDigits = 0,
  }) {
    final formatter = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = decimalDigits
      ..minimumFractionDigits = decimalDigits;
    return formatter.format(value);
  }
}
