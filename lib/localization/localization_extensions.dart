import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../constants/subscription_constants.dart';
import '../utils/locale_format_utils.dart';

extension LocalizationBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocalizationFormattingX on AppLocalizations {
  /// 例: 2025年9月20日 / September 20, 2025
  String formatFullDate(DateTime date) =>
      DateFormat.yMMMMd(localeName).format(date);

  /// 例: 2025年9月20日 14:30 / September 20, 2025 2:30 PM (locale依存)
  String formatFullDateTime(DateTime dateTime) =>
      DateFormat.yMMMMd(localeName).add_Hm().format(dateTime);

  /// 例: 9/20 / 20/9 (locale依存)
  String formatMonthDay(DateTime date) =>
      DateFormat.Md(localeName).format(date);

  /// 例: 9月20日 / September 20
  String formatMonthDayLong(DateTime date) =>
      DateFormat.MMMMd(localeName).format(date);

  /// 例: 2025年9月 / September 2025
  String formatMonth(DateTime month) =>
      DateFormat.yMMMM(localeName).format(month);

  /// 例: 14:05 / 2:05 PM (locale依存)
  String formatTime(DateTime dateTime) =>
      DateFormat.Hm(localeName).format(dateTime);

  /// 例: 無料 / Free
  String formatCurrency(
    num amount, {
    String currencyCode = SubscriptionConstants.defaultCurrencyCode,
    bool showFreeLabel = true,
    int decimalDigits = 0,
  }) {
    if (amount == 0 && showFreeLabel) {
      return pricingFree;
    }

    return LocaleFormatUtils.formatCurrency(
      amount,
      locale: localeName,
      currencyCode: currencyCode,
    );
  }

  /// 汎用的な数値フォーマット
  String formatNumber(num value, {int decimalDigits = 0}) =>
      LocaleFormatUtils.formatDecimal(
        value,
        locale: localeName,
        decimalDigits: decimalDigits,
      );
}
