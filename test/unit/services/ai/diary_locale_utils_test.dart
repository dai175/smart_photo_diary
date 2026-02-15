import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_photo_diary/services/ai/diary_locale_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
    await initializeDateFormatting('en');
  });

  group('isJapanese', () {
    test('ja → true', () {
      expect(DiaryLocaleUtils.isJapanese(const Locale('ja')), isTrue);
    });

    test('en → false', () {
      expect(DiaryLocaleUtils.isJapanese(const Locale('en')), isFalse);
    });

    test('JA(大文字languageCode) → true', () {
      // Locale normalizes to lowercase internally
      expect(DiaryLocaleUtils.isJapanese(const Locale('ja', 'JP')), isTrue);
    });
  });

  group('toLocaleTag', () {
    test('Locale("ja") → "ja"', () {
      expect(DiaryLocaleUtils.toLocaleTag(const Locale('ja')), 'ja');
    });

    test('Locale("en", "US") → "en-US"', () {
      expect(DiaryLocaleUtils.toLocaleTag(const Locale('en', 'US')), 'en-US');
    });

    test('Locale("ja", "JP") → "ja-JP"', () {
      expect(DiaryLocaleUtils.toLocaleTag(const Locale('ja', 'JP')), 'ja-JP');
    });
  });

  group('formatDate', () {
    final date = DateTime(2025, 3, 15);

    test('日本語ロケール → 年月日形式', () {
      final result = DiaryLocaleUtils.formatDate(date, const Locale('ja'));
      expect(result, contains('2025'));
      expect(result, contains('3'));
      expect(result, contains('15'));
    });

    test('英語ロケール → Month Day, Year形式', () {
      final result = DiaryLocaleUtils.formatDate(date, const Locale('en'));
      expect(result, contains('March'));
      expect(result, contains('15'));
      expect(result, contains('2025'));
    });
  });

  group('formatTime', () {
    final date = DateTime(2025, 3, 15, 14, 30);

    test('日本語ロケール → 24時間形式(Hm)', () {
      final result = DiaryLocaleUtils.formatTime(date, const Locale('ja'));
      expect(result, contains('14'));
      expect(result, contains('30'));
    });

    test('英語ロケール → 12時間形式(jm)', () {
      final result = DiaryLocaleUtils.formatTime(date, const Locale('en'));
      expect(result, contains('2'));
      expect(result, contains('30'));
      expect(result, contains('PM'));
    });
  });

  group('locationLine', () {
    test('null → 空文字', () {
      expect(DiaryLocaleUtils.locationLine(null, const Locale('ja')), isEmpty);
    });

    test('空文字列 → 空文字', () {
      expect(DiaryLocaleUtils.locationLine('', const Locale('ja')), isEmpty);
    });

    test('スペースのみ → 空文字', () {
      expect(DiaryLocaleUtils.locationLine('   ', const Locale('ja')), isEmpty);
    });

    test('日本語ロケール → "場所: XXX\\n"', () {
      expect(
        DiaryLocaleUtils.locationLine('東京', const Locale('ja')),
        '場所: 東京\n',
      );
    });

    test('英語ロケール → "Location: XXX\\n"', () {
      expect(
        DiaryLocaleUtils.locationLine('Tokyo', const Locale('en')),
        'Location: Tokyo\n',
      );
    });
  });

  group('analysisFailureMessage', () {
    test('日本語 → "画像分析に失敗しました"', () {
      expect(
        DiaryLocaleUtils.analysisFailureMessage(const Locale('ja')),
        '画像分析に失敗しました',
      );
    });

    test('英語 → "Image analysis failed"', () {
      expect(
        DiaryLocaleUtils.analysisFailureMessage(const Locale('en')),
        'Image analysis failed',
      );
    });
  });
}
