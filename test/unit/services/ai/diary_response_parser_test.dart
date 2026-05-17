import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/ai/diary_response_parser.dart';

import '../../helpers/writing_prompt_test_helpers.dart';

void main() {
  late DiaryResponseParser parser;

  setUp(() {
    parser = DiaryResponseParser(logger: NoOpLogger());
  });

  group('DiaryResponseParser.parse', () {
    group('日本語フォーマット', () {
      test('【タイトル】/【本文】形式 → 正しく分割', () {
        final result = parser.parse(
          '【タイトル】\n春の訪れ\n\n【本文】\n暖かい日差しの中で過ごした一日。',
          const Locale('ja'),
        );

        expect(result.title, '春の訪れ');
        expect(result.content, '暖かい日差しの中で過ごした一日。');
      });

      test('前後の空白をトリムする', () {
        final result = parser.parse(
          '【タイトル】\n  タイトル  \n\n【本文】\n  本文  ',
          const Locale('ja'),
        );

        expect(result.title, 'タイトル');
        expect(result.content, '本文');
      });
    });

    group('英語フォーマット', () {
      test('[Title]/[Body]形式 → 正しく分割', () {
        final result = parser.parse(
          '[Title]\nA Warm Day\n\n[Body]\nSpent a lovely day in the sunshine.',
          const Locale('en'),
        );

        expect(result.title, 'A Warm Day');
        expect(result.content, 'Spent a lovely day in the sunshine.');
      });

      test('[title]/[body] (小文字) → 正しく分割', () {
        final result = parser.parse(
          '[title]\nSunny Day\n\n[body]\nA beautiful sunny day.',
          const Locale('en'),
        );

        expect(result.title, 'Sunny Day');
        expect(result.content, 'A beautiful sunny day.');
      });
    });

    group('フォールバック（行分割）', () {
      test('形式不明 → 最初の行がタイトル、残りが本文', () {
        final result = parser.parse(
          'First Line\nSecond Line\nThird Line',
          const Locale('ja'),
        );

        expect(result.title, 'First Line');
        expect(result.content, contains('Second Line'));
      });

      test('1行のみ → タイトルに設定、本文は全体テキスト', () {
        final result = parser.parse('Only one line here', const Locale('ja'));

        expect(result.title, 'Only one line here');
        expect(result.content, 'Only one line here');
      });
    });

    group('デフォルトタイトル（空テキスト）', () {
      test('jaロケール → "今日の日記"', () {
        final result = parser.parse('', const Locale('ja'));

        expect(result.title, '今日の日記');
        expect(result.content, '');
      });

      test('enロケール → "Today\'s Journal"', () {
        final result = parser.parse('', const Locale('en'));

        expect(result.title, "Today's Journal");
        expect(result.content, '');
      });
    });

    group('エラー耐性', () {
      test('空白のみのテキスト → デフォルトタイトルで安全に返す', () {
        final result = parser.parse('   \n\n   ', const Locale('ja'));

        expect(result.title, isNotEmpty);
      });
    });
  });
}
