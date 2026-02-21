import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/services/ai/diary_prompt_builder.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
    await initializeDateFormatting('en');
  });

  group('analyzePromptType', () {
    test('null → "emotion"', () {
      expect(DiaryPromptBuilder.analyzePromptType(null), 'emotion');
    });

    test('空文字 → "emotion"', () {
      expect(DiaryPromptBuilder.analyzePromptType(''), 'emotion');
    });

    test('スペースのみ → "emotion"', () {
      expect(DiaryPromptBuilder.analyzePromptType('   '), 'emotion');
    });

    test('"感情"を含む → "emotion"', () {
      expect(DiaryPromptBuilder.analyzePromptType('今日の感情を書いて'), 'emotion');
    });

    test('"feeling"を含む → "emotion"', () {
      expect(
        DiaryPromptBuilder.analyzePromptType('Write about my feeling'),
        'emotion',
      );
    });

    test('"heart"を含む → "emotion"', () {
      expect(
        DiaryPromptBuilder.analyzePromptType('Open your heart'),
        'emotion',
      );
    });

    test('"成長"を含む → "growth"', () {
      expect(DiaryPromptBuilder.analyzePromptType('成長を記録する'), 'growth');
    });

    test('"change"を含む → "growth"', () {
      expect(
        DiaryPromptBuilder.analyzePromptType('How I change today'),
        'growth',
      );
    });

    test('"discovery"を含む → "growth"', () {
      expect(DiaryPromptBuilder.analyzePromptType('A new discovery'), 'growth');
    });

    test('"つながり"を含む → "connection"', () {
      expect(DiaryPromptBuilder.analyzePromptType('人とのつながり'), 'connection');
    });

    test('"relationship"を含む → "connection"', () {
      expect(
        DiaryPromptBuilder.analyzePromptType('My relationship'),
        'connection',
      );
    });

    test('"community"を含む → "connection"', () {
      expect(
        DiaryPromptBuilder.analyzePromptType('My community'),
        'connection',
      );
    });

    test('"癒し"を含む → "healing"', () {
      expect(DiaryPromptBuilder.analyzePromptType('癒しの時間'), 'healing');
    });

    test('"peace"を含む → "healing"', () {
      expect(DiaryPromptBuilder.analyzePromptType('Inner peace'), 'healing');
    });

    test('"calm"を含む → "healing"', () {
      expect(DiaryPromptBuilder.analyzePromptType('Stay calm'), 'healing');
    });

    test('未知のキーワード → "emotion"（デフォルト）', () {
      expect(DiaryPromptBuilder.analyzePromptType('ランチを食べた'), 'emotion');
    });
  });

  group('getOptimizationParams', () {
    test('emotion + ja → maxTokens=300', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'emotion',
        const Locale('ja'),
      );
      expect(params['maxTokens'], 300);
      expect(params['emphasis'], isA<String>());
    });

    test('emotion + en → maxTokens=360', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'emotion',
        const Locale('en'),
      );
      expect(params['maxTokens'], 360);
    });

    test('growth + ja → maxTokens=320', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'growth',
        const Locale('ja'),
      );
      expect(params['maxTokens'], 320);
    });

    test('growth + en → maxTokens=380', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'growth',
        const Locale('en'),
      );
      expect(params['maxTokens'], 380);
    });

    test('connection + ja → maxTokens=310', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'connection',
        const Locale('ja'),
      );
      expect(params['maxTokens'], 310);
    });

    test('connection + en → maxTokens=370', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'connection',
        const Locale('en'),
      );
      expect(params['maxTokens'], 370);
    });

    test('healing + ja → maxTokens=290', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'healing',
        const Locale('ja'),
      );
      expect(params['maxTokens'], 290);
    });

    test('healing + en → maxTokens=360', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'healing',
        const Locale('en'),
      );
      expect(params['maxTokens'], 360);
    });

    test('未知type → emotionと同じ', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'unknown',
        const Locale('ja'),
      );
      expect(params['maxTokens'], 300);
    });
  });

  group('buildSingleImagePrompt', () {
    test('日本語 + customPromptなし → 日本語基本プロンプト', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('【タイトル】'));
      expect(result, contains('【本文】'));
      expect(result, contains('日記'));
    });

    test('英語 + customPromptなし → 英語基本プロンプト', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: 'captures emotional depth',
      );
      expect(result, contains('[Title]'));
      expect(result, contains('[Body]'));
      expect(result, contains('diary'));
    });

    test('日本語 + customPromptあり → プロンプト統合版', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        customPrompt: '成長について',
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('成長について'));
      expect(result, contains('ライティングプロンプト'));
    });

    test('英語 + customPromptあり → プロンプト統合版', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        customPrompt: 'About growth',
        emphasis: 'captures emotional depth',
      );
      expect(result, contains('About growth'));
      expect(result, contains('writing prompt'));
    });

    test('複数photoTimes(ja) → 時系列描写指示が含まれる', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10), DateTime(2025, 1, 1, 14)],
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('時系列'));
    });

    test('複数photoTimes(en) → multi photo hint含む', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10), DateTime(2025, 1, 1, 14)],
        emphasis: 'captures emotional depth',
      );
      expect(result, contains('feelings shift'));
    });

    test('locationあり → locationLineが含まれる', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        location: '東京',
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('場所: 東京'));
    });
  });

  group('buildMultiImagePrompt', () {
    test('日本語 + customPromptなし → 基本プロンプト', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析結果1', '分析結果2'],
        photoTimes: [DateTime(2025, 3, 15, 8), DateTime(2025, 3, 15, 14)],
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('【タイトル】'));
      expect(result, contains('【本文】'));
      expect(result, contains('分析結果1'));
      expect(result, contains('分析結果2'));
    });

    test('英語 + customPromptなし → 基本プロンプト', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('en'),
        analyses: ['Analysis 1'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: 'captures emotional depth',
      );
      expect(result, contains('[Title]'));
      expect(result, contains('[Body]'));
      expect(result, contains('Analysis 1'));
    });

    test('日本語 + customPromptあり → プロンプト統合版', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        customPrompt: '友人との時間',
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('友人との時間'));
      expect(result, contains('ライティングプロンプト'));
    });

    test('英語 + customPromptあり → プロンプト統合版', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('en'),
        analyses: ['Analysis'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        customPrompt: 'Time with friends',
        emphasis: 'captures emotional depth',
      );
      expect(result, contains('Time with friends'));
      expect(result, contains('writing prompt'));
    });

    test('dateLabel/timeRangeが含まれる', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析'],
        photoTimes: [DateTime(2025, 3, 15, 8), DateTime(2025, 3, 15, 14)],
        emphasis: '感情の深みを大切にして',
      );
      expect(result, contains('2025'));
      expect(result, contains('朝から昼にかけて'));
    });

    test('locationあり → locationLineが含まれる', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('en'),
        analyses: ['Analysis'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        location: 'Tokyo',
        emphasis: 'captures emotional depth',
      );
      expect(result, contains('Location: Tokyo'));
    });
  });

  group('getOptimizationParams (DiaryLength)', () {
    test('short + emotion + ja → reduced maxTokens', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'emotion',
        const Locale('ja'),
        diaryLength: DiaryLength.short,
      );
      expect(params['maxTokens'], DiaryPromptBuilder.emotionTokensJaShort);
    });

    test('short + emotion + en → reduced maxTokens', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'emotion',
        const Locale('en'),
        diaryLength: DiaryLength.short,
      );
      expect(params['maxTokens'], DiaryPromptBuilder.emotionTokensEnShort);
    });

    test('short + growth + ja → reduced maxTokens', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'growth',
        const Locale('ja'),
        diaryLength: DiaryLength.short,
      );
      expect(params['maxTokens'], DiaryPromptBuilder.growthTokensJaShort);
    });

    test('short + connection + en → reduced maxTokens', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'connection',
        const Locale('en'),
        diaryLength: DiaryLength.short,
      );
      expect(params['maxTokens'], DiaryPromptBuilder.connectionTokensEnShort);
    });

    test('short + healing + ja → reduced maxTokens', () {
      final params = DiaryPromptBuilder.getOptimizationParams(
        'healing',
        const Locale('ja'),
        diaryLength: DiaryLength.short,
      );
      expect(params['maxTokens'], DiaryPromptBuilder.healingTokensJaShort);
    });

    test('standard maxTokens > short maxTokens for all types', () {
      for (final type in ['emotion', 'growth', 'connection', 'healing']) {
        for (final locale in [const Locale('ja'), const Locale('en')]) {
          final standard = DiaryPromptBuilder.getOptimizationParams(
            type,
            locale,
            diaryLength: DiaryLength.standard,
          );
          final short = DiaryPromptBuilder.getOptimizationParams(
            type,
            locale,
            diaryLength: DiaryLength.short,
          );
          expect(
            standard['maxTokens'] as int,
            greaterThan(short['maxTokens'] as int),
            reason: '$type/$locale: standard should > short',
          );
        }
      }
    });
  });

  group('buildSingleImagePrompt (DiaryLength)', () {
    test('short + ja → shorter body instruction', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: '感情の深みを大切にして',
        diaryLength: DiaryLength.short,
      );
      expect(result, contains('40-70文字程度'));
      expect(result, contains('3-6文字程度'));
    });

    test('standard + ja → standard body instruction', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: '感情の深みを大切にして',
        diaryLength: DiaryLength.standard,
      );
      expect(result, contains('150-200文字程度'));
      expect(result, contains('5-10文字程度'));
    });

    test('short + en → shorter word count instruction', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: 'captures emotional depth',
        diaryLength: DiaryLength.short,
      );
      expect(result, contains('15-25 words'));
      expect(result, contains('2-3 word'));
    });

    test('standard + en → standard word count instruction', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: 'captures emotional depth',
        diaryLength: DiaryLength.standard,
      );
      expect(result, contains('70-90 words'));
      expect(result, contains('3-6 word'));
    });
  });

  group('buildMultiImagePrompt (DiaryLength)', () {
    test('short + ja → shorter body instruction', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析結果'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: '感情の深みを大切にして',
        diaryLength: DiaryLength.short,
      );
      expect(result, contains('50-80文字程度'));
      expect(result, contains('3-6文字程度'));
    });

    test('standard + ja → standard body instruction', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析結果'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: '感情の深みを大切にして',
        diaryLength: DiaryLength.standard,
      );
      expect(result, contains('150-220文字程度'));
      expect(result, contains('5-10文字程度'));
    });

    test('short + en → shorter word count instruction', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('en'),
        analyses: ['Analysis'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: 'captures emotional depth',
        diaryLength: DiaryLength.short,
      );
      expect(result, contains('20-30 words'));
      expect(result, contains('2-3 word'));
    });

    test('standard + en → standard word count instruction', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('en'),
        analyses: ['Analysis'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: 'captures emotional depth',
        diaryLength: DiaryLength.standard,
      );
      expect(result, contains('80-100 words'));
      expect(result, contains('3-6 word'));
    });
  });

  group('buildSingleImagePrompt (contextText)', () {
    test('contextText=null → 状況・背景ブロックを含まない', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: '感情の深みを大切にして',
        contextText: null,
      );
      expect(result, isNot(contains('状況・背景')));
    });

    test('ja + contextTextのみ → 状況・背景ブロックを含む', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: '感情の深みを大切にして',
        contextText: '友達と花見に行った',
      );
      expect(result, contains('状況・背景'));
      expect(result, contains('友達と花見に行った'));
    });

    test('ja + contextText + customPrompt → 両方含む', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        customPrompt: '感情を書いて',
        emphasis: '感情の深みを大切にして',
        contextText: '友達と花見に行った',
      );
      expect(result, contains('状況・背景'));
      expect(result, contains('友達と花見に行った'));
      expect(result, contains('「感情を書いて」'));
    });

    test('en + contextTextのみ → Context ブロックを含む', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: 'captures emotional depth',
        contextText: 'Cherry blossom viewing with friends',
      );
      expect(result, contains('Context:'));
      expect(result, contains('Cherry blossom viewing with friends'));
    });

    test('en + contextText + customPrompt → 両方含む', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('en'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        customPrompt: 'About growth',
        emphasis: 'captures emotional depth',
        contextText: 'Cherry blossom viewing with friends',
      );
      expect(result, contains('Context:'));
      expect(result, contains('Cherry blossom viewing with friends'));
      expect(result, contains('"About growth"'));
    });

    test('空文字のcontextText → 状況・背景ブロックを含まない', () {
      final result = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: const Locale('ja'),
        photoTimes: [DateTime(2025, 1, 1, 10)],
        emphasis: '感情の深みを大切にして',
        contextText: '   ',
      );
      expect(result, isNot(contains('状況・背景')));
    });
  });

  group('buildMultiImagePrompt (contextText)', () {
    test('contextText=null → 状況・背景ブロックを含まない', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析結果'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: '感情の深みを大切にして',
        contextText: null,
      );
      expect(result, isNot(contains('状況・背景')));
    });

    test('ja + contextTextのみ → 状況・背景ブロックを含む', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('ja'),
        analyses: ['分析結果'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        emphasis: '感情の深みを大切にして',
        contextText: '子どもの運動会',
      );
      expect(result, contains('状況・背景'));
      expect(result, contains('子どもの運動会'));
    });

    test('en + contextText + customPrompt → 両方含む', () {
      final result = DiaryPromptBuilder.buildMultiImagePrompt(
        locale: const Locale('en'),
        analyses: ['Analysis'],
        photoTimes: [DateTime(2025, 3, 15, 8)],
        customPrompt: 'Time with friends',
        emphasis: 'captures emotional depth',
        contextText: 'School sports day',
      );
      expect(result, contains('Context:'));
      expect(result, contains('School sports day'));
      expect(result, contains('"Time with friends"'));
    });
  });
}
