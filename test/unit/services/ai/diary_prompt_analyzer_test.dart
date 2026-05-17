import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/services/ai/diary_prompt_analyzer.dart';

void main() {
  group('analyzePromptType', () {
    test('null → "emotion"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType(null), 'emotion');
    });

    test('空文字 → "emotion"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType(''), 'emotion');
    });

    test('スペースのみ → "emotion"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('   '), 'emotion');
    });

    test('"感情"を含む → "emotion"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('今日の感情を書いて'), 'emotion');
    });

    test('"feeling"を含む → "emotion"', () {
      expect(
        DiaryPromptAnalyzer.analyzePromptType('Write about my feeling'),
        'emotion',
      );
    });

    test('"heart"を含む → "emotion"', () {
      expect(
        DiaryPromptAnalyzer.analyzePromptType('Open your heart'),
        'emotion',
      );
    });

    test('"成長"を含む → "growth"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('成長を記録する'), 'growth');
    });

    test('"change"を含む → "growth"', () {
      expect(
        DiaryPromptAnalyzer.analyzePromptType('How I change today'),
        'growth',
      );
    });

    test('"discovery"を含む → "growth"', () {
      expect(
        DiaryPromptAnalyzer.analyzePromptType('A new discovery'),
        'growth',
      );
    });

    test('"つながり"を含む → "connection"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('人とのつながり'), 'connection');
    });

    test('"relationship"を含む → "connection"', () {
      expect(
        DiaryPromptAnalyzer.analyzePromptType('My relationship'),
        'connection',
      );
    });

    test('"community"を含む → "connection"', () {
      expect(
        DiaryPromptAnalyzer.analyzePromptType('My community'),
        'connection',
      );
    });

    test('"癒し"を含む → "healing"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('癒しの時間'), 'healing');
    });

    test('"peace"を含む → "healing"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('Inner peace'), 'healing');
    });

    test('"calm"を含む → "healing"', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('Stay calm'), 'healing');
    });

    test('未知のキーワード → "emotion"（デフォルト）', () {
      expect(DiaryPromptAnalyzer.analyzePromptType('ランチを食べた'), 'emotion');
    });
  });

  group('getOptimizationParams', () {
    test('emotion + ja → maxTokens=300', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'emotion',
        const Locale('ja'),
      );
      expect(params.maxTokens, 300);
      expect(params.emphasis, isA<String>());
    });

    test('emotion + en → maxTokens=360', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'emotion',
        const Locale('en'),
      );
      expect(params.maxTokens, 360);
    });

    test('growth + ja → maxTokens=320', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'growth',
        const Locale('ja'),
      );
      expect(params.maxTokens, 320);
    });

    test('growth + en → maxTokens=380', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'growth',
        const Locale('en'),
      );
      expect(params.maxTokens, 380);
    });

    test('connection + ja → maxTokens=310', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'connection',
        const Locale('ja'),
      );
      expect(params.maxTokens, 310);
    });

    test('connection + en → maxTokens=370', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'connection',
        const Locale('en'),
      );
      expect(params.maxTokens, 370);
    });

    test('healing + ja → maxTokens=290', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'healing',
        const Locale('ja'),
      );
      expect(params.maxTokens, 290);
    });

    test('healing + en → maxTokens=360', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'healing',
        const Locale('en'),
      );
      expect(params.maxTokens, 360);
    });

    test('未知type → emotionと同じ', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'unknown',
        const Locale('ja'),
      );
      expect(params.maxTokens, 300);
    });
  });

  group('getOptimizationParams (DiaryLength)', () {
    test('short + emotion + ja → reduced maxTokens', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'emotion',
        const Locale('ja'),
        diaryLength: DiaryLength.short,
      );
      expect(params.maxTokens, DiaryPromptAnalyzer.emotionTokensJaShort);
    });

    test('short + emotion + en → reduced maxTokens', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'emotion',
        const Locale('en'),
        diaryLength: DiaryLength.short,
      );
      expect(params.maxTokens, DiaryPromptAnalyzer.emotionTokensEnShort);
    });

    test('short + growth + ja → reduced maxTokens', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'growth',
        const Locale('ja'),
        diaryLength: DiaryLength.short,
      );
      expect(params.maxTokens, DiaryPromptAnalyzer.growthTokensJaShort);
    });

    test('short + connection + en → reduced maxTokens', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'connection',
        const Locale('en'),
        diaryLength: DiaryLength.short,
      );
      expect(params.maxTokens, DiaryPromptAnalyzer.connectionTokensEnShort);
    });

    test('short + healing + ja → reduced maxTokens', () {
      final params = DiaryPromptAnalyzer.getOptimizationParams(
        'healing',
        const Locale('ja'),
        diaryLength: DiaryLength.short,
      );
      expect(params.maxTokens, DiaryPromptAnalyzer.healingTokensJaShort);
    });

    test('standard maxTokens > short maxTokens for all types', () {
      for (final type in ['emotion', 'growth', 'connection', 'healing']) {
        for (final locale in [const Locale('ja'), const Locale('en')]) {
          final standard = DiaryPromptAnalyzer.getOptimizationParams(
            type,
            locale,
            diaryLength: DiaryLength.standard,
          );
          final short = DiaryPromptAnalyzer.getOptimizationParams(
            type,
            locale,
            diaryLength: DiaryLength.short,
          );
          expect(
            standard.maxTokens,
            greaterThan(short.maxTokens),
            reason: '$type/$locale: standard should > short',
          );
        }
      }
    });
  });
}
