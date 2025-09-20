import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:smart_photo_diary/localization/localization_extensions.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations_en.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations_ja.dart';

void main() {
  group('LocalizationFormattingX', () {
    setUp(() {
      Intl.defaultLocale = 'ja';
    });

    test('日本語ロケールで日付と通貨が正しくフォーマットされる', () async {
      await initializeDateFormatting('ja');
      final l10n = AppLocalizationsJa();
      final sampleDate = DateTime(2025, 9, 20, 14, 30);

      expect(l10n.formatFullDate(sampleDate), '2025年9月20日');
      expect(l10n.formatMonthDayLong(sampleDate), '9月20日');
      expect(l10n.formatCurrency(0), '無料');
      expect(l10n.formatCurrency(2800), '¥2,800');
    });

    test('英語ロケールで日付と通貨が正しくフォーマットされる', () async {
      await initializeDateFormatting('en');
      Intl.defaultLocale = 'en';
      final l10n = AppLocalizationsEn();
      final sampleDate = DateTime(2025, 9, 20, 14, 30);

      expect(l10n.formatFullDate(sampleDate), 'September 20, 2025');
      expect(l10n.formatMonthDayLong(sampleDate), 'September 20');
      expect(l10n.formatCurrency(0), 'Free');
      expect(l10n.formatCurrency(2800), '¥2,800');
    });
  });
}
