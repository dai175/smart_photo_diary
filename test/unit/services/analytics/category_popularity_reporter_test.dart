// カテゴリ人気度レポーターテスト
//
// CategoryPopularityReporterクラスのレポート生成機能を包括的にテスト
// Phase 2.4.2.2の実装検証

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/analytics/category_popularity_reporter.dart';
import 'package:smart_photo_diary/services/analytics/prompt_usage_analytics.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
  group('CategoryPopularityReporter', () {
    late CategoryPopularityAnalysis testAnalysis;
    late Map<PromptCategory, CategoryTrend> testTrends;

    setUp(() {
      // テスト用のカテゴリ使用データ
      final categoryUsageCount = {
        PromptCategory.emotion: 20,
        PromptCategory.emotionDepth: 15,
        PromptCategory.sensoryEmotion: 10,
        PromptCategory.emotionGrowth: 5,
        PromptCategory.emotionConnection: 0, // 未使用
      };

      final categoryUsageRate = {
        PromptCategory.emotion: 0.4, // 40%
        PromptCategory.emotionDepth: 0.3, // 30%
        PromptCategory.sensoryEmotion: 0.2, // 20%
        PromptCategory.emotionGrowth: 0.1, // 10%
        PromptCategory.emotionConnection: 0.0, // 0%
      };

      final averageUsagePerPrompt = {
        PromptCategory.emotion: 4.0,
        PromptCategory.emotionDepth: 7.5,
        PromptCategory.sensoryEmotion: 5.0,
        PromptCategory.emotionGrowth: 2.5,
        PromptCategory.emotionConnection: 0.0,
      };

      // テスト用トレンドデータ
      testTrends = {
        PromptCategory.emotion: const CategoryTrend(
          changeRate: 25.0,
          usageChange: 4,
          direction: TrendDirection.increasing,
        ),
        PromptCategory.emotionDepth: const CategoryTrend(
          changeRate: -10.0,
          usageChange: -2,
          direction: TrendDirection.decreasing,
        ),
        PromptCategory.sensoryEmotion: const CategoryTrend(
          changeRate: 5.0,
          usageChange: 1,
          direction: TrendDirection.stable,
        ),
        PromptCategory.emotionGrowth: const CategoryTrend(
          changeRate: 100.0,
          usageChange: 3,
          direction: TrendDirection.increasing,
        ),
      };

      testAnalysis = CategoryPopularityAnalysis(
        categoryUsageCount: categoryUsageCount,
        categoryUsageRate: categoryUsageRate,
        mostPopularCategory: PromptCategory.emotion,
        averageUsagePerPrompt: averageUsagePerPrompt,
        trends: testTrends,
      );
    });

    group('generateDetailedReport', () {
      test('詳細レポートが正常に生成される', () {
        final report = CategoryPopularityReporter.generateDetailedReport(
          analysis: testAnalysis,
          periodDays: 30,
        );

        expect(report.periodDays, 30);
        expect(report.analysis, testAnalysis);
        expect(report.generatedAt, isA<DateTime>());
        expect(report.summary, isA<CategoryReportSummary>());
        expect(report.categoryDetails, isNotEmpty);
        expect(report.trendSummary, isNotNull);
      });

      test('サマリー情報が正しく計算される', () {
        final report = CategoryPopularityReporter.generateDetailedReport(
          analysis: testAnalysis,
          periodDays: 30,
        );

        expect(report.summary.totalUsage, 50); // 20+15+10+5+0
        expect(report.summary.activeCategories, 4); // 使用回数 > 0
        expect(report.summary.mostPopularCategory, PromptCategory.emotion);
        expect(report.summary.mostPopularUsageRate, 0.4);
      });

      test('カテゴリ詳細がランキング順にソートされる', () {
        final report = CategoryPopularityReporter.generateDetailedReport(
          analysis: testAnalysis,
          periodDays: 30,
        );

        final details = report.categoryDetails;
        expect(details.length, 4); // 使用されたカテゴリのみ

        // ランキング順チェック
        expect(details[0].rank, 1);
        expect(details[0].category, PromptCategory.emotion);
        expect(details[0].usageCount, 20);

        expect(details[1].rank, 2);
        expect(details[1].category, PromptCategory.emotionDepth);
        expect(details[1].usageCount, 15);

        expect(details[2].rank, 3);
        expect(details[2].category, PromptCategory.sensoryEmotion);
        expect(details[2].usageCount, 10);

        expect(details[3].rank, 4);
        expect(details[3].category, PromptCategory.emotionGrowth);
        expect(details[3].usageCount, 5);
      });

      test('トレンド要約が正しく生成される', () {
        final report = CategoryPopularityReporter.generateDetailedReport(
          analysis: testAnalysis,
          periodDays: 30,
        );

        final trendSummary = report.trendSummary!;
        expect(trendSummary.growingCategories, 2); // emotion, emotionGrowth
        expect(trendSummary.decliningCategories, 1); // emotionDepth
        expect(trendSummary.stableCategories, 1); // sensoryEmotion

        expect(
          trendSummary.fastestGrowingCategory,
          PromptCategory.emotionGrowth,
        );
        expect(trendSummary.maxGrowthRate, 100.0);

        expect(
          trendSummary.fastestDecliningCategory,
          PromptCategory.emotionDepth,
        );
        expect(trendSummary.maxDeclineRate, -10.0);
      });
    });

    group('generateQuickSummary', () {
      test('使用履歴なしでメッセージが返される', () {
        final emptyAnalysis = CategoryPopularityAnalysis(
          categoryUsageCount: const {},
          categoryUsageRate: const {},
          mostPopularCategory: null,
          averageUsagePerPrompt: const {},
        );

        final summary = CategoryPopularityReporter.generateQuickSummary(
          emptyAnalysis,
        );
        expect(summary, 'まだプロンプトの使用履歴がありません。');
      });

      test('使用履歴ありで適切なサマリーが生成される', () {
        final summary = CategoryPopularityReporter.generateQuickSummary(
          testAnalysis,
        );

        expect(summary, contains('50回'));
        expect(summary, contains('4カテゴリ'));
        expect(summary, contains('感情'));
        expect(summary, contains('40%'));
      });
    });

    group('getCategoryRanking', () {
      test('指定された上位N位のランキングが返される', () {
        final ranking = CategoryPopularityReporter.getCategoryRanking(
          analysis: testAnalysis,
          topN: 3,
        );

        expect(ranking.length, 3);

        expect(ranking[0].rank, 1);
        expect(ranking[0].category, PromptCategory.emotion);
        expect(ranking[0].usageCount, 20);
        expect(ranking[0].usageRate, 0.4);

        expect(ranking[1].rank, 2);
        expect(ranking[1].category, PromptCategory.emotionDepth);
        expect(ranking[1].usageCount, 15);

        expect(ranking[2].rank, 3);
        expect(ranking[2].category, PromptCategory.sensoryEmotion);
        expect(ranking[2].usageCount, 10);
      });

      test('使用回数0のカテゴリは除外される', () {
        final ranking = CategoryPopularityReporter.getCategoryRanking(
          analysis: testAnalysis,
          topN: 10,
        );

        // emotionConnectionは使用回数0なので除外される
        expect(ranking.length, 4);
        expect(
          ranking.any(
            (item) => item.category == PromptCategory.emotionConnection,
          ),
          false,
        );
      });

      test('利用可能カテゴリ数より多いtopNを指定しても正常動作', () {
        final ranking = CategoryPopularityReporter.getCategoryRanking(
          analysis: testAnalysis,
          topN: 100,
        );

        expect(ranking.length, 4); // 実際の使用カテゴリ数
      });
    });

    group('CategoryDetail', () {
      test('toString()でトレンド情報が含まれる', () {
        final detail = CategoryDetail(
          category: PromptCategory.emotion,
          usageCount: 20,
          usageRate: 0.4,
          rank: 1,
          averageUsagePerPrompt: 4.0,
          trend: const CategoryTrend(
            changeRate: 25.0,
            usageChange: 4,
            direction: TrendDirection.increasing,
          ),
        );

        final str = detail.toString();
        expect(str, contains('1位'));
        expect(str, contains('感情'));
        expect(str, contains('20回'));
        expect(str, contains('40.0%'));
        expect(str, contains('4.0回/プロンプト'));
        expect(str, contains('+25.0%'));
        expect(str, contains('↗️'));
      });

      test('トレンド方向に応じたアイコンが表示される', () {
        final increasingDetail = CategoryDetail(
          category: PromptCategory.emotion,
          usageCount: 20,
          usageRate: 0.4,
          rank: 1,
          averageUsagePerPrompt: 4.0,
          trend: const CategoryTrend(
            changeRate: 25.0,
            usageChange: 4,
            direction: TrendDirection.increasing,
          ),
        );

        final decreasingDetail = CategoryDetail(
          category: PromptCategory.emotionDepth,
          usageCount: 15,
          usageRate: 0.3,
          rank: 2,
          averageUsagePerPrompt: 7.5,
          trend: const CategoryTrend(
            changeRate: -10.0,
            usageChange: -2,
            direction: TrendDirection.decreasing,
          ),
        );

        final stableDetail = CategoryDetail(
          category: PromptCategory.sensoryEmotion,
          usageCount: 10,
          usageRate: 0.2,
          rank: 3,
          averageUsagePerPrompt: 5.0,
          trend: const CategoryTrend(
            changeRate: 5.0,
            usageChange: 1,
            direction: TrendDirection.stable,
          ),
        );

        expect(increasingDetail.toString(), contains('↗️'));
        expect(decreasingDetail.toString(), contains('↘️'));
        expect(stableDetail.toString(), contains('→'));
      });
    });

    group('CategoryPopularityReport', () {
      test('toFormattedString()で完全なレポートが出力される', () {
        final report = CategoryPopularityReporter.generateDetailedReport(
          analysis: testAnalysis,
          periodDays: 30,
        );

        final formatted = report.toFormattedString();

        expect(formatted, contains('=== カテゴリ別人気度レポート ==='));
        expect(formatted, contains('生成日時:'));
        expect(formatted, contains('分析期間: 30日間'));
        expect(formatted, contains('== サマリー =='));
        expect(formatted, contains('== カテゴリ詳細 =='));
        expect(formatted, contains('== トレンド分析 =='));
        expect(formatted, contains('総使用回数: 50回'));
        expect(formatted, contains('アクティブカテゴリ数: 4'));
      });
    });

    group('CategoryRankingItem', () {
      test('toString()で適切な形式が出力される', () {
        final item = CategoryRankingItem(
          rank: 1,
          category: PromptCategory.emotion,
          usageCount: 20,
          usageRate: 0.4,
          averageUsagePerPrompt: 4.0,
        );

        final str = item.toString();
        expect(str, contains('1位'));
        expect(str, contains('感情'));
        expect(str, contains('20回'));
        expect(str, contains('40.0%'));
      });
    });

    group('TrendSummary', () {
      test('toString()でトレンド情報が適切に出力される', () {
        final trendSummary = TrendSummary(
          growingCategories: 2,
          decliningCategories: 1,
          stableCategories: 1,
          fastestGrowingCategory: PromptCategory.emotionGrowth,
          maxGrowthRate: 100.0,
          fastestDecliningCategory: PromptCategory.emotionDepth,
          maxDeclineRate: -10.0,
        );

        final str = trendSummary.toString();
        expect(str, contains('成長中: 2カテゴリ'));
        expect(str, contains('衰退中: 1カテゴリ'));
        expect(str, contains('安定: 1カテゴリ'));
        expect(str, contains('最高成長: 感情成長 (+100.0%)'));
        expect(str, contains('最大衰退: 感情深掘り (-10.0%)'));
      });
    });
  });
}
