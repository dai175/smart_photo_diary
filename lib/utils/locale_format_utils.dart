import 'package:intl/intl.dart';

/// ロケールに応じた通貨・数値フォーマットを提供するユーティリティ
class LocaleFormatUtils {
  LocaleFormatUtils._();

  static const Map<String, String> _currencySymbolOverrides = {'JPY': '¥'};

  static String formatCurrency(
    num amount, {
    required String locale,
    String currencyCode = 'JPY',
    int decimalDigits = 0,
    String? fallbackSymbol,
  }) {
    final symbol =
        _currencySymbolOverrides[currencyCode] ??
        fallbackSymbol ??
        NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;

    final formatter = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );

    return formatter.format(amount);
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
