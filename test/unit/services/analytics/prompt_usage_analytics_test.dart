// プロンプト使用量分析サービステスト
//
// PromptUsageAnalyticsクラスの分析機能を包括的にテスト
// Phase 2.4.2.1の実装検証

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/analytics/prompt_usage_analytics.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
  group('PromptUsageAnalytics', () {
    late List<WritingPrompt> testPrompts;
    late Map<String, int> testUsageData;
    late List<PromptUsageHistory> testUsageHistory;

    setUp(() {
      // テスト用プロンプトデータ
      testPrompts = [
        WritingPrompt(
          id: 'emotion_001',
          text: '今日の気持ちを教えてください',
          category: PromptCategory.emotion,
          isPremiumOnly: false,
          priority: 90,
        ),
        WritingPrompt(
          id: 'emotion_depth_001',
          text: 'その感情の背景は何ですか？',
          category: PromptCategory.emotionDepth,
          isPremiumOnly: true,
          priority: 85,
        ),
        WritingPrompt(
          id: 'sensory_001',
          text: 'その時の音やにおいを覚えていますか？',
          category: PromptCategory.sensoryEmotion,
          isPremiumOnly: true,
          priority: 80,
        ),
        WritingPrompt(
          id: 'unused_001',
          text: '未使用のプロンプト',
          category: PromptCategory.emotionHealing,
          isPremiumOnly: true,
          priority: 75,
        ),
      ];

      // テスト用使用データ
      testUsageData = {
        'emotion_001': 15,      // 最も使用頻度が高い
        'emotion_depth_001': 8,  // 中程度
        'sensory_001': 3,       // 低頻度
        // 'unused_001'は使用なし
      };

      // テスト用使用履歴
      final now = DateTime.now();
      testUsageHistory = [
        PromptUsageHistory(
          promptId: 'emotion_001',
          usedAt: now.subtract(const Duration(hours: 2)),
          wasHelpful: true,
        ),
        PromptUsageHistory(
          promptId: 'emotion_001',
          usedAt: now.subtract(const Duration(hours: 5)),
          wasHelpful: true,
        ),
        PromptUsageHistory(
          promptId: 'emotion_depth_001',
          usedAt: now.subtract(const Duration(hours: 8)),
          wasHelpful: false,
        ),
        PromptUsageHistory(
          promptId: 'sensory_001',
          usedAt: now.subtract(const Duration(days: 1)),
          wasHelpful: true,
        ),
        PromptUsageHistory(
          promptId: 'emotion_001',
          usedAt: now.subtract(const Duration(days: 2)),
          wasHelpful: true,
        ),
      ];
    });

    group('analyzePromptFrequency', () {
      test('基本的な使用頻度分析が正常に動作する', () {
        final analysis = PromptUsageAnalytics.analyzePromptFrequency(
          usageData: testUsageData,
          periodDays: 30,
          allPrompts: testPrompts,
        );

        expect(analysis.periodDays, 30);
        expect(analysis.totalUsage, 26); // 15 + 8 + 3
        expect(analysis.averageUsagePerDay, closeTo(0.87, 0.01)); // 26/30
        expect(analysis.mostUsedPromptId, 'emotion_001');
        expect(analysis.maxUsageCount, 15);
        expect(analysis.uniquePromptsUsed, 3);
        expect(analysis.getUsageRate(4), 0.75); // 3/4のプロンプトが使用された
      });

      test('空のデータでも正常に処理される', () {
        final analysis = PromptUsageAnalytics.analyzePromptFrequency(
          usageData: {},
          periodDays: 30,
        );

        expect(analysis.totalUsage, 0);
        expect(analysis.averageUsagePerDay, 0.0);
        expect(analysis.mostUsedPromptId, isNull);
        expect(analysis.maxUsageCount, 0);
        expect(analysis.uniquePromptsUsed, 0);
      });

      test('使用頻度分布が正しく計算される', () {
        final analysis = PromptUsageAnalytics.analyzePromptFrequency(
          usageData: testUsageData,
          periodDays: 30,
          allPrompts: testPrompts,
        );

        expect(analysis.usageDistribution[15], 1); // 15回使用: 1プロンプト
        expect(analysis.usageDistribution[8], 1);  // 8回使用: 1プロンプト
        expect(analysis.usageDistribution[3], 1);  // 3回使用: 1プロンプト
      });
    });

    group('analyzeCategoryPopularity', () {
      test('カテゴリ別人気度分析が正常に動作する', () {
        final analysis = PromptUsageAnalytics.analyzeCategoryPopularity(
          usageData: testUsageData,
          allPrompts: testPrompts,
        );

        expect(analysis.categoryUsageCount[PromptCategory.emotion], 15);
        expect(analysis.categoryUsageCount[PromptCategory.emotionDepth], 8);
        expect(analysis.categoryUsageCount[PromptCategory.sensoryEmotion], 3);
        expect(analysis.categoryUsageCount[PromptCategory.emotionHealing], isNull);

        expect(analysis.mostPopularCategory, PromptCategory.emotion);
      });

      test('カテゴリ使用率が正しく計算される', () {
        final analysis = PromptUsageAnalytics.analyzeCategoryPopularity(
          usageData: testUsageData,
          allPrompts: testPrompts,
        );

        final totalUsage = 26;
        expect(analysis.getCategoryUsageRate(PromptCategory.emotion), 
               closeTo(15 / totalUsage, 0.01));
        expect(analysis.getCategoryUsageRate(PromptCategory.emotionDepth), 
               closeTo(8 / totalUsage, 0.01));
        expect(analysis.getCategoryUsageRate(PromptCategory.sensoryEmotion), 
               closeTo(3 / totalUsage, 0.01));
      });

      test('前期間データとの比較でトレンドが計算される', () {
        final previousData = {
          'emotion_001': 10,      // 15から10へ: +50%増加
          'emotion_depth_001': 12, // 8から12へ: -33%減少
          'sensory_001': 3,       // 変化なし
        };

        final analysis = PromptUsageAnalytics.analyzeCategoryPopularity(
          usageData: testUsageData,
          allPrompts: testPrompts,
          previousPeriodData: previousData,
        );

        expect(analysis.trends, isNotNull);
        expect(analysis.trends![PromptCategory.emotion]!.direction, 
               TrendDirection.increasing);
        expect(analysis.trends![PromptCategory.emotionDepth]!.direction, 
               TrendDirection.decreasing);
      });
    });

    group('analyzeUserBehavior', () {
      test('ユーザー行動分析が正常に動作する', () {
        final analysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: testUsageHistory,
        );

        expect(analysis.usagePatterns, isNotEmpty);
        expect(analysis.diversityIndex, greaterThan(0.0));
        expect(analysis.averageSessionInterval, greaterThan(0.0));
        expect(analysis.averageSatisfaction, closeTo(0.8, 0.1)); // 4/5が役に立った
      });

      test('時間帯別使用パターンが正しく集計される', () {
        final analysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: testUsageHistory,
        );

        // 使用履歴から計算される時間帯パターンをチェック
        expect(analysis.usagePatterns, isMap);
        expect(analysis.usagePatterns.keys.any((key) => key.startsWith('hour_')), isTrue);
      });

      test('空の履歴でも正常に処理される', () {
        final analysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: [],
        );

        expect(analysis.diversityIndex, 0.0);
        expect(analysis.averageSessionInterval, 0.0);
        expect(analysis.repeatUsageRate, 0.0);
        expect(analysis.averageSatisfaction, 0.0);
      });

      test('ヘルススコアが適切に計算される', () {
        final analysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: testUsageHistory,
        );

        final healthScore = analysis.getHealthScore();
        expect(healthScore, greaterThanOrEqualTo(0.0));
        expect(healthScore, lessThanOrEqualTo(1.0));
      });
    });

    group('generateImprovementSuggestions', () {
      test('改善提案が生成される', () {
        final frequencyAnalysis = PromptUsageAnalytics.analyzePromptFrequency(
          usageData: testUsageData,
          periodDays: 30,
          allPrompts: testPrompts,
        );

        final categoryAnalysis = PromptUsageAnalytics.analyzeCategoryPopularity(
          usageData: testUsageData,
          allPrompts: testPrompts,
        );

        final behaviorAnalysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: testUsageHistory,
        );

        final suggestions = PromptUsageAnalytics.generateImprovementSuggestions(
          frequencyAnalysis: frequencyAnalysis,
          categoryAnalysis: categoryAnalysis,
          behaviorAnalysis: behaviorAnalysis,
          allPrompts: testPrompts,
        );

        expect(suggestions, isNotEmpty);
        expect(suggestions.first.priority, greaterThanOrEqualTo(1));
        expect(suggestions.first.priority, lessThanOrEqualTo(5));
      });

      test('未使用プロンプトの提案が含まれる', () {
        final frequencyAnalysis = PromptUsageAnalytics.analyzePromptFrequency(
          usageData: testUsageData,
          periodDays: 30,
          allPrompts: testPrompts,
        );

        final categoryAnalysis = PromptUsageAnalytics.analyzeCategoryPopularity(
          usageData: testUsageData,
          allPrompts: testPrompts,
        );

        final behaviorAnalysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: testUsageHistory,
        );

        final suggestions = PromptUsageAnalytics.generateImprovementSuggestions(
          frequencyAnalysis: frequencyAnalysis,
          categoryAnalysis: categoryAnalysis,
          behaviorAnalysis: behaviorAnalysis,
          allPrompts: testPrompts,
        );

        final unusedSuggestion = suggestions.firstWhere(
          (s) => s.type == SuggestionType.improvePrompt && s.target == 'unused_prompts',
          orElse: () => throw StateError('未使用プロンプト提案が見つからない'),
        );

        expect(unusedSuggestion.evidence['unusedCount'], 1);
        expect(unusedSuggestion.evidence['unusedIds'], contains('unused_001'));
      });

      test('提案が優先度順にソートされる', () {
        final frequencyAnalysis = PromptUsageAnalytics.analyzePromptFrequency(
          usageData: testUsageData,
          periodDays: 30,
          allPrompts: testPrompts,
        );

        final categoryAnalysis = PromptUsageAnalytics.analyzeCategoryPopularity(
          usageData: testUsageData,
          allPrompts: testPrompts,
        );

        final behaviorAnalysis = PromptUsageAnalytics.analyzeUserBehavior(
          usageHistory: testUsageHistory,
        );

        final suggestions = PromptUsageAnalytics.generateImprovementSuggestions(
          frequencyAnalysis: frequencyAnalysis,
          categoryAnalysis: categoryAnalysis,
          behaviorAnalysis: behaviorAnalysis,
          allPrompts: testPrompts,
        );

        if (suggestions.length > 1) {
          for (int i = 0; i < suggestions.length - 1; i++) {
            expect(suggestions[i].priority, 
                   greaterThanOrEqualTo(suggestions[i + 1].priority));
          }
        }
      });
    });

    group('PromptFrequencyAnalysis', () {
      test('toString()が適切な形式で出力される', () {
        final analysis = PromptFrequencyAnalysis(
          periodDays: 30,
          totalUsage: 100,
          promptUsageCount: {'test': 50},
          averageUsagePerDay: 3.33,
          mostUsedPromptId: 'test',
          maxUsageCount: 50,
          uniquePromptsUsed: 1,
          usageDistribution: {50: 1},
        );

        final str = analysis.toString();
        expect(str, contains('30days'));
        expect(str, contains('total: 100'));
        expect(str, contains('unique: 1'));
        expect(str, contains('avgPerDay: 3.3'));
      });
    });

    group('UserBehaviorAnalysis', () {
      test('健全性スコアが適切に計算される', () {
        final analysis = UserBehaviorAnalysis(
          usagePatterns: {'hour_10': 3, 'hour_14': 2},
          diversityIndex: 0.8,
          averageSessionInterval: 24.0, // 1日1回（理想的）
          repeatUsageRate: 0.3,
          averageSatisfaction: 0.9,
        );

        final healthScore = analysis.getHealthScore();
        expect(healthScore, greaterThan(0.8)); // 高スコア期待
      });

      test('使用頻度過多でスコアが下がる', () {
        final analysis = UserBehaviorAnalysis(
          usagePatterns: {},
          diversityIndex: 0.8,
          averageSessionInterval: 2.0, // 2時間間隔（使いすぎ）
          repeatUsageRate: 0.3,
          averageSatisfaction: 0.9,
        );

        final healthScore = analysis.getHealthScore();
        expect(healthScore, lessThan(0.9)); // スコアが下がる
      });
    });
  });
}