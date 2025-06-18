// 改善提案データ収集とトラッキングテスト
//
// ImprovementSuggestionTrackerクラスの効果測定、
// フィードバック分析、継続的改善機能を包括的にテスト
// Phase 2.4.2.4の実装検証

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/analytics/improvement_suggestion_tracker.dart';
import 'package:smart_photo_diary/services/analytics/user_behavior_analyzer.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
  group('ImprovementSuggestionTracker', () {
    late List<SuggestionImplementationRecord> testImplementations;
    late List<PromptUsageHistory> testUsageHistory;

    setUp(() {
      // テスト用実装記録を作成
      testImplementations = [
        // 成功事例
        SuggestionImplementationRecord(
          suggestionId: 'time_adjust_001',
          suggestionType: PersonalizationType.timeAdjustment,
          implementedAt: DateTime.now().subtract(Duration(days: 30)),
          baselineMetrics: {
            'primaryMetric': 0.3,
            'usageFrequency': 2.0,
            'satisfaction': 0.6,
            'diversity': 0.4,
          },
          afterMetrics: {
            'primaryMetric': 0.7,
            'usageFrequency': 3.5,
            'satisfaction': 0.8,
            'diversity': 0.5,
          },
          userSatisfaction: 5,
          userFeedback: 'とても役に立ちました。時間を意識するようになりました。',
          effectivenessScore: 0.85,
          measurementPeriodDays: 14,
        ),
        SuggestionImplementationRecord(
          suggestionId: 'freq_adjust_001',
          suggestionType: PersonalizationType.frequencyAdjustment,
          implementedAt: DateTime.now().subtract(Duration(days: 25)),
          baselineMetrics: {
            'primaryMetric': 1.5,
            'usageFrequency': 1.5,
            'satisfaction': 0.7,
            'diversity': 0.6,
          },
          afterMetrics: {
            'primaryMetric': 2.8,
            'usageFrequency': 2.8,
            'satisfaction': 0.85,
            'diversity': 0.7,
          },
          userSatisfaction: 4,
          userFeedback: '習慣化に役立ちました。',
          effectivenessScore: 0.75,
          measurementPeriodDays: 21,
        ),
        
        // 失敗事例
        SuggestionImplementationRecord(
          suggestionId: 'content_opt_001',
          suggestionType: PersonalizationType.contentOptimization,
          implementedAt: DateTime.now().subtract(Duration(days: 20)),
          baselineMetrics: {
            'primaryMetric': 0.8,
            'usageFrequency': 3.0,
            'satisfaction': 0.8,
            'diversity': 0.3,
          },
          afterMetrics: {
            'primaryMetric': 0.7,
            'usageFrequency': 2.5,
            'satisfaction': 0.6,
            'diversity': 0.25,
          },
          userSatisfaction: 2,
          userFeedback: 'あまり効果を感じませんでした。',
          effectivenessScore: 0.2,
          measurementPeriodDays: 10,
        ),
        
        // 中程度の事例
        SuggestionImplementationRecord(
          suggestionId: 'category_rec_001',
          suggestionType: PersonalizationType.categoryRecommendation,
          implementedAt: DateTime.now().subtract(Duration(days: 15)),
          baselineMetrics: {
            'primaryMetric': 0.4,
            'usageFrequency': 2.2,
            'satisfaction': 0.65,
            'diversity': 0.4,
          },
          afterMetrics: {
            'primaryMetric': 0.6,
            'usageFrequency': 2.5,
            'satisfaction': 0.75,
            'diversity': 0.6,
          },
          userSatisfaction: 3,
          userFeedback: '普通でした。',
          effectivenessScore: 0.55,
          measurementPeriodDays: 12,
        ),
        
        // フィードバックなし事例
        SuggestionImplementationRecord(
          suggestionId: 'notification_001',
          suggestionType: PersonalizationType.notificationSetting,
          implementedAt: DateTime.now().subtract(Duration(days: 10)),
          baselineMetrics: {
            'primaryMetric': 1.8,
            'usageFrequency': 1.8,
            'satisfaction': 0.5,
            'diversity': 0.3,
          },
          afterMetrics: {
            'primaryMetric': 2.5,
            'usageFrequency': 2.5,
            'satisfaction': 0.7,
            'diversity': 0.4,
          },
          effectivenessScore: 0.7,
          measurementPeriodDays: 7,
        ),
      ];

      // テスト用使用履歴
      testUsageHistory = [
        PromptUsageHistory(
          promptId: 'prompt_001',
          usedAt: DateTime.now().subtract(Duration(days: 1, hours: 9)),
          wasHelpful: true,
        ),
        PromptUsageHistory(
          promptId: 'prompt_002',
          usedAt: DateTime.now().subtract(Duration(days: 2, hours: 10)),
          wasHelpful: true,
        ),
        PromptUsageHistory(
          promptId: 'prompt_001',
          usedAt: DateTime.now().subtract(Duration(days: 3, hours: 9)),
          wasHelpful: false,
        ),
        PromptUsageHistory(
          promptId: 'prompt_003',
          usedAt: DateTime.now().subtract(Duration(days: 4, hours: 20)),
          wasHelpful: true,
        ),
      ];
    });

    group('analyzeEffectiveness', () {
      test('効果分析が正常に実行される', () {
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );

        expect(analysis.totalImplementations, 5);
        expect(analysis.successfulImplementations, 3); // 効果スコア0.6以上かつ満足度4以上またはnull
        expect(analysis.overallSuccessRate, 0.6); // 3/5
        expect(analysis.averageEffectivenessScore, isA<double>());
        expect(analysis.averageUserSatisfaction, isA<double>());
      });

      test('タイプ別成功率が正しく計算される', () {
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );

        expect(analysis.successRateByType, isNotEmpty);
        expect(analysis.successRateByType[PersonalizationType.timeAdjustment], 1.0);
        expect(analysis.successRateByType[PersonalizationType.contentOptimization], 0.0);
      });

      test('最も効果的なタイプが特定される', () {
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );

        expect(analysis.mostEffectiveType, isNotNull);
        expect(analysis.leastEffectiveType, isNotNull);
      });

      test('改善されたメトリクスが特定される', () {
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );

        expect(analysis.improvedMetrics, isNotEmpty);
        expect(analysis.improvedMetrics, contains('primaryMetric'));
      });

      test('空の実装リストでエラーが発生しない', () {
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: [],
        );

        expect(analysis.totalImplementations, 0);
        expect(analysis.successfulImplementations, 0);
        expect(analysis.overallSuccessRate, 0.0);
        expect(analysis.averageEffectivenessScore, 0.0);
        expect(analysis.averageUserSatisfaction, 0.0);
      });
    });

    group('analyzeFeedback', () {
      test('フィードバック分析が正常に実行される', () {
        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        expect(analysis.totalFeedbacks, 4); // フィードバック付きは4件
        expect(analysis.satisfactionDistribution, isNotEmpty);
        expect(analysis.averageSatisfaction, isA<double>());
        expect(analysis.modeSatisfaction, isNotNull);
      });

      test('満足度分布が正しく計算される', () {
        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        expect(analysis.satisfactionDistribution[5], 1);
        expect(analysis.satisfactionDistribution[4], 1);
        expect(analysis.satisfactionDistribution[3], 1);
        expect(analysis.satisfactionDistribution[2], 1);
      });

      test('ポジティブ/ネガティブ率が正しく計算される', () {
        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        expect(analysis.positiveRate, 0.5); // 満足度4以上が2件/4件
        expect(analysis.negativeRate, 0.25); // 満足度2以下が1件/4件
      });

      test('キーワード頻度が抽出される', () {
        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        expect(analysis.keywordFrequency, isNotEmpty);
        expect(analysis.keywordFrequency.keys, anyOf([contains('役に立ちました'), contains('とても')]));
      });

      test('改善要望エリアが特定される', () {
        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        expect(analysis.improvementAreas, contains(PersonalizationType.contentOptimization));
      });

      test('フィードバックなしでエラーが発生しない', () {
        final noFeedbackImplementations = [
          SuggestionImplementationRecord(
            suggestionId: 'test',
            suggestionType: PersonalizationType.timeAdjustment,
            implementedAt: DateTime.now(),
            baselineMetrics: {'test': 0.0},
            afterMetrics: {'test': 0.0},
            effectivenessScore: 0.5,
            measurementPeriodDays: 7,
          ),
        ];

        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: noFeedbackImplementations,
        );

        expect(analysis.totalFeedbacks, 0);
        expect(analysis.averageSatisfaction, 0.0);
        expect(analysis.positiveRate, 0.0);
        expect(analysis.negativeRate, 0.0);
      });
    });

    group('generateContinuousImprovementData', () {
      test('継続的改善データが生成される', () {
        final effectivenessAnalysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );
        final feedbackAnalysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        final improvementData = ImprovementSuggestionTracker.generateContinuousImprovementData(
          effectivenessAnalysis: effectivenessAnalysis,
          feedbackAnalysis: feedbackAnalysis,
          implementations: testImplementations,
        );

        expect(improvementData.patternScores, isNotEmpty);
        expect(improvementData.successFactors, isNotEmpty);
        expect(improvementData.failureFactors, isNotEmpty);
        expect(improvementData.recommendedActions, isNotEmpty);
        expect(improvementData.learningPoints, isNotEmpty);
        expect(improvementData.confidenceScore, isA<double>());
        expect(improvementData.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(improvementData.confidenceScore, lessThanOrEqualTo(1.0));
      });

      test('パターンスコアが適切に計算される', () {
        final effectivenessAnalysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );
        final feedbackAnalysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        final improvementData = ImprovementSuggestionTracker.generateContinuousImprovementData(
          effectivenessAnalysis: effectivenessAnalysis,
          feedbackAnalysis: feedbackAnalysis,
          implementations: testImplementations,
        );

        expect(improvementData.patternScores['effectivenessPattern'], isA<double>());
        expect(improvementData.patternScores['satisfactionPattern'], isA<double>());
        expect(improvementData.patternScores['feedbackVolumePattern'], isA<double>());
        expect(improvementData.patternScores['diversityPattern'], isA<double>());
      });

      test('成功要因が特定される', () {
        final effectivenessAnalysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );
        final feedbackAnalysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        final improvementData = ImprovementSuggestionTracker.generateContinuousImprovementData(
          effectivenessAnalysis: effectivenessAnalysis,
          feedbackAnalysis: feedbackAnalysis,
          implementations: testImplementations,
        );

        expect(improvementData.successFactors, isNotEmpty);
        expect(improvementData.successFactors.any((factor) => factor.contains('効果スコア') || factor.contains('測定期間')), true);
      });

      test('推奨アクションが生成される', () {
        final effectivenessAnalysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );
        final feedbackAnalysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        final improvementData = ImprovementSuggestionTracker.generateContinuousImprovementData(
          effectivenessAnalysis: effectivenessAnalysis,
          feedbackAnalysis: feedbackAnalysis,
          implementations: testImplementations,
        );

        expect(improvementData.recommendedActions, isNotEmpty);
      });
    });

    group('measureBaseline', () {
      test('時間調整提案のベースライン測定', () {
        final baseline = ImprovementSuggestionTracker.measureBaseline(
          usageHistory: testUsageHistory,
          suggestionType: PersonalizationType.timeAdjustment,
        );

        expect(baseline['primaryMetric'], isA<double>());
        expect(baseline['usageFrequency'], isA<double>());
        expect(baseline['satisfaction'], isA<double>());
        expect(baseline['diversity'], isA<double>());
      });

      test('頻度調整提案のベースライン測定', () {
        final baseline = ImprovementSuggestionTracker.measureBaseline(
          usageHistory: testUsageHistory,
          suggestionType: PersonalizationType.frequencyAdjustment,
        );

        expect(baseline['primaryMetric'], isA<double>());
        expect(baseline['usageFrequency'], isA<double>());
      });

      test('カテゴリ推奨提案のベースライン測定', () {
        final baseline = ImprovementSuggestionTracker.measureBaseline(
          usageHistory: testUsageHistory,
          suggestionType: PersonalizationType.categoryRecommendation,
        );

        expect(baseline['primaryMetric'], isA<double>());
        expect(baseline['diversity'], isA<double>());
      });

      test('コンテンツ最適化提案のベースライン測定', () {
        final baseline = ImprovementSuggestionTracker.measureBaseline(
          usageHistory: testUsageHistory,
          suggestionType: PersonalizationType.contentOptimization,
        );

        expect(baseline['primaryMetric'], isA<double>());
        expect(baseline['satisfaction'], isA<double>());
      });

      test('通知設定提案のベースライン測定', () {
        final baseline = ImprovementSuggestionTracker.measureBaseline(
          usageHistory: testUsageHistory,
          suggestionType: PersonalizationType.notificationSetting,
        );

        expect(baseline['primaryMetric'], isA<double>());
        expect(baseline['usageFrequency'], isA<double>());
      });

      test('空の履歴でエラーが発生しない', () {
        final baseline = ImprovementSuggestionTracker.measureBaseline(
          usageHistory: [],
          suggestionType: PersonalizationType.timeAdjustment,
        );

        expect(baseline['primaryMetric'], 0.0);
        expect(baseline['usageFrequency'], 0.0);
        expect(baseline['satisfaction'], 0.0);
        expect(baseline['diversity'], 0.0);
      });
    });

    group('SuggestionImplementationRecord', () {
      test('改善度計算が正常に動作', () {
        final record = testImplementations.first;
        final improvement = record.getImprovementRate('primaryMetric');
        
        expect(improvement, isA<double>());
        expect(improvement, greaterThan(0)); // 0.3 -> 0.7なので改善
      });

      test('成功判定が正常に動作', () {
        final successfulRecord = testImplementations.first;
        expect(successfulRecord.isSuccessful, true);
        
        final failedRecord = testImplementations[2];
        expect(failedRecord.isSuccessful, false);
      });

      test('toString()が適切な形式で出力される', () {
        final record = testImplementations.first;
        final str = record.toString();
        
        expect(str, contains('SuggestionImplementationRecord'));
        expect(str, contains('timeAdjustment'));
        expect(str, contains('85.0%'));
      });
    });

    group('SuggestionEffectivenessAnalysis', () {
      test('toString()が適切な形式で出力される', () {
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );
        
        final str = analysis.toString();
        expect(str, contains('SuggestionEffectivenessAnalysis'));
        expect(str, contains('60.0%')); // 成功率
        expect(str, contains('implementations: 5'));
      });
    });

    group('UserFeedbackAnalysis', () {
      test('toString()が適切な形式で出力される', () {
        final analysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );
        
        final str = analysis.toString();
        expect(str, contains('UserFeedbackAnalysis'));
        expect(str, contains('feedbacks: 4'));
      });
    });

    group('ContinuousImprovementData', () {
      test('toString()が適切な形式で出力される', () {
        final effectivenessAnalysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: testImplementations,
        );
        final feedbackAnalysis = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: testImplementations,
        );

        final improvementData = ImprovementSuggestionTracker.generateContinuousImprovementData(
          effectivenessAnalysis: effectivenessAnalysis,
          feedbackAnalysis: feedbackAnalysis,
          implementations: testImplementations,
        );
        
        final str = improvementData.toString();
        expect(str, contains('ContinuousImprovementData'));
        expect(str, contains('confidence:'));
        expect(str, contains('successFactors:'));
      });
    });

    group('Edge Cases', () {
      test('単一実装での分析', () {
        final singleImplementation = [testImplementations.first];
        
        final effectiveness = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: singleImplementation,
        );
        final feedback = ImprovementSuggestionTracker.analyzeFeedback(
          implementations: singleImplementation,
        );
        
        expect(effectiveness.totalImplementations, 1);
        expect(feedback.totalFeedbacks, 1);
      });

      test('全て同じタイプの実装での分析', () {
        final sameTypeImplementations = testImplementations
            .map((impl) => SuggestionImplementationRecord(
                  suggestionId: impl.suggestionId,
                  suggestionType: PersonalizationType.timeAdjustment,
                  implementedAt: impl.implementedAt,
                  baselineMetrics: impl.baselineMetrics,
                  afterMetrics: impl.afterMetrics,
                  userSatisfaction: impl.userSatisfaction,
                  userFeedback: impl.userFeedback,
                  effectivenessScore: impl.effectivenessScore,
                  measurementPeriodDays: impl.measurementPeriodDays,
                ))
            .toList();
        
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: sameTypeImplementations,
        );
        
        expect(analysis.successRateByType.keys.length, 1);
        expect(analysis.successRateByType.containsKey(PersonalizationType.timeAdjustment), true);
      });

      test('極端な値での信頼性', () {
        final extremeImplementations = [
          SuggestionImplementationRecord(
            suggestionId: 'extreme_success',
            suggestionType: PersonalizationType.timeAdjustment,
            implementedAt: DateTime.now(),
            baselineMetrics: {'primaryMetric': 0.0},
            afterMetrics: {'primaryMetric': 1.0},
            userSatisfaction: 5,
            userFeedback: 'Perfect!',
            effectivenessScore: 1.0,
            measurementPeriodDays: 30,
          ),
          SuggestionImplementationRecord(
            suggestionId: 'extreme_failure',
            suggestionType: PersonalizationType.contentOptimization,
            implementedAt: DateTime.now(),
            baselineMetrics: {'primaryMetric': 1.0},
            afterMetrics: {'primaryMetric': 0.0},
            userSatisfaction: 1,
            userFeedback: 'Terrible!',
            effectivenessScore: 0.0,
            measurementPeriodDays: 3,
          ),
        ];
        
        final analysis = ImprovementSuggestionTracker.analyzeEffectiveness(
          implementations: extremeImplementations,
        );
        
        expect(analysis.overallSuccessRate, 0.5);
        expect(analysis.averageEffectivenessScore, 0.5);
      });
    });
  });
}