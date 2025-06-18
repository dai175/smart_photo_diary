// 改善提案データ収集とトラッキング
//
// 分析エンジンが生成した改善提案の効果測定、
// ユーザーフィードバック収集、継続的改善のためのデータ収集
// Phase 2.4.2.4の実装

import 'dart:math';
import '../../models/writing_prompt.dart';
import 'prompt_usage_analytics.dart';
import 'user_behavior_analyzer.dart';

/// 改善提案実装記録
class SuggestionImplementationRecord {
  /// 提案ID
  final String suggestionId;
  
  /// 提案タイプ
  final PersonalizationType suggestionType;
  
  /// 実装日時
  final DateTime implementedAt;
  
  /// 実装前の基準値
  final Map<String, double> baselineMetrics;
  
  /// 実装後の測定値
  final Map<String, double> afterMetrics;
  
  /// ユーザーの満足度（1-5）
  final int? userSatisfaction;
  
  /// ユーザーのフィードバックコメント
  final String? userFeedback;
  
  /// 提案の効果スコア（0-1）
  final double effectivenessScore;
  
  /// データ収集期間（日数）
  final int measurementPeriodDays;

  const SuggestionImplementationRecord({
    required this.suggestionId,
    required this.suggestionType,
    required this.implementedAt,
    required this.baselineMetrics,
    required this.afterMetrics,
    this.userSatisfaction,
    this.userFeedback,
    required this.effectivenessScore,
    required this.measurementPeriodDays,
  });

  /// 改善度を計算
  double getImprovementRate(String metricKey) {
    final baseline = baselineMetrics[metricKey];
    final after = afterMetrics[metricKey];
    
    if (baseline == null || after == null || baseline == 0) {
      return 0.0;
    }
    
    return (after - baseline) / baseline;
  }

  /// 成功と判定されるかどうか
  bool get isSuccessful {
    return effectivenessScore >= 0.6 && 
           (userSatisfaction == null || userSatisfaction! >= 4);
  }

  @override
  String toString() {
    final improvement = getImprovementRate('primaryMetric');
    return 'SuggestionImplementationRecord('
           'type: $suggestionType, '
           'effectiveness: ${(effectivenessScore * 100).toStringAsFixed(1)}%, '
           'improvement: ${(improvement * 100).toStringAsFixed(1)}%, '
           'satisfaction: ${userSatisfaction ?? "未評価"})';
  }
}

/// 提案効果分析結果
class SuggestionEffectivenessAnalysis {
  /// 全体成功率
  final double overallSuccessRate;
  
  /// タイプ別成功率
  final Map<PersonalizationType, double> successRateByType;
  
  /// 平均効果スコア
  final double averageEffectivenessScore;
  
  /// 平均ユーザー満足度
  final double averageUserSatisfaction;
  
  /// 最も効果的な提案タイプ
  final PersonalizationType? mostEffectiveType;
  
  /// 最も効果の低い提案タイプ
  final PersonalizationType? leastEffectiveType;
  
  /// 改善が確認されたメトリクス
  final List<String> improvedMetrics;
  
  /// 実装済み提案数
  final int totalImplementations;
  
  /// 成功事例数
  final int successfulImplementations;

  const SuggestionEffectivenessAnalysis({
    required this.overallSuccessRate,
    required this.successRateByType,
    required this.averageEffectivenessScore,
    required this.averageUserSatisfaction,
    this.mostEffectiveType,
    this.leastEffectiveType,
    required this.improvedMetrics,
    required this.totalImplementations,
    required this.successfulImplementations,
  });

  @override
  String toString() {
    return 'SuggestionEffectivenessAnalysis('
           'successRate: ${(overallSuccessRate * 100).toStringAsFixed(1)}%, '
           'avgEffectiveness: ${(averageEffectivenessScore * 100).toStringAsFixed(1)}%, '
           'avgSatisfaction: ${averageUserSatisfaction.toStringAsFixed(1)}/5, '
           'implementations: $totalImplementations)';
  }
}

/// ユーザーフィードバック分析
class UserFeedbackAnalysis {
  /// フィードバック総数
  final int totalFeedbacks;
  
  /// 満足度分布
  final Map<int, int> satisfactionDistribution;
  
  /// 平均満足度
  final double averageSatisfaction;
  
  /// 最頻満足度
  final int? modeSatisfaction;
  
  /// ポジティブフィードバック率
  final double positiveRate;
  
  /// ネガティブフィードバック率
  final double negativeRate;
  
  /// 頻出キーワード
  final Map<String, int> keywordFrequency;
  
  /// 改善要望が多いエリア
  final List<PersonalizationType> improvementAreas;

  const UserFeedbackAnalysis({
    required this.totalFeedbacks,
    required this.satisfactionDistribution,
    required this.averageSatisfaction,
    this.modeSatisfaction,
    required this.positiveRate,
    required this.negativeRate,
    required this.keywordFrequency,
    required this.improvementAreas,
  });

  @override
  String toString() {
    return 'UserFeedbackAnalysis('
           'feedbacks: $totalFeedbacks, '
           'avgSatisfaction: ${averageSatisfaction.toStringAsFixed(1)}/5, '
           'positiveRate: ${(positiveRate * 100).toStringAsFixed(1)}%, '
           'topKeywords: ${keywordFrequency.keys.take(3).join(", ")})';
  }
}

/// 継続的改善のための学習データ
class ContinuousImprovementData {
  /// パターン認識結果
  final Map<String, double> patternScores;
  
  /// 成功要因
  final List<String> successFactors;
  
  /// 失敗要因
  final List<String> failureFactors;
  
  /// 推奨アクション
  final List<String> recommendedActions;
  
  /// 次回提案への学習ポイント
  final Map<PersonalizationType, List<String>> learningPoints;
  
  /// データ信頼度スコア
  final double confidenceScore;

  const ContinuousImprovementData({
    required this.patternScores,
    required this.successFactors,
    required this.failureFactors,
    required this.recommendedActions,
    required this.learningPoints,
    required this.confidenceScore,
  });

  @override
  String toString() {
    return 'ContinuousImprovementData('
           'confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%, '
           'successFactors: ${successFactors.length}, '
           'learningPoints: ${learningPoints.length} types)';
  }
}

/// 改善提案データ収集とトラッキングサービス
/// 
/// 分析エンジンが生成した改善提案の効果測定、
/// ユーザーフィードバック収集、継続的改善のためのデータ分析を提供
class ImprovementSuggestionTracker {

  /// 提案効果分析を実行
  /// 
  /// [implementations] 実装記録リスト
  /// 戻り値: 提案効果分析結果
  static SuggestionEffectivenessAnalysis analyzeEffectiveness({
    required List<SuggestionImplementationRecord> implementations,
  }) {
    if (implementations.isEmpty) {
      return const SuggestionEffectivenessAnalysis(
        overallSuccessRate: 0.0,
        successRateByType: {},
        averageEffectivenessScore: 0.0,
        averageUserSatisfaction: 0.0,
        improvedMetrics: [],
        totalImplementations: 0,
        successfulImplementations: 0,
      );
    }

    final successfulCount = implementations.where((impl) => impl.isSuccessful).length;
    final overallSuccessRate = successfulCount / implementations.length;

    // タイプ別成功率を計算
    final successRateByType = <PersonalizationType, double>{};
    final typeGroups = <PersonalizationType, List<SuggestionImplementationRecord>>{};
    
    for (final impl in implementations) {
      typeGroups[impl.suggestionType] ??= [];
      typeGroups[impl.suggestionType]!.add(impl);
    }
    
    for (final entry in typeGroups.entries) {
      final typeSuccessCount = entry.value.where((impl) => impl.isSuccessful).length;
      successRateByType[entry.key] = typeSuccessCount / entry.value.length;
    }

    // 平均効果スコア
    final averageEffectivenessScore = implementations
        .map((impl) => impl.effectivenessScore)
        .reduce((a, b) => a + b) / implementations.length;

    // 平均満足度
    final satisfactionScores = implementations
        .where((impl) => impl.userSatisfaction != null)
        .map((impl) => impl.userSatisfaction!.toDouble())
        .toList();
    
    final averageUserSatisfaction = satisfactionScores.isNotEmpty
        ? satisfactionScores.reduce((a, b) => a + b) / satisfactionScores.length
        : 0.0;

    // 最も効果的なタイプ
    PersonalizationType? mostEffectiveType;
    PersonalizationType? leastEffectiveType;
    
    if (successRateByType.isNotEmpty) {
      final sortedBySuccess = successRateByType.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      mostEffectiveType = sortedBySuccess.first.key;
      leastEffectiveType = sortedBySuccess.last.key;
    }

    // 改善されたメトリクス
    final improvedMetrics = _analyzeImprovedMetrics(implementations);

    return SuggestionEffectivenessAnalysis(
      overallSuccessRate: overallSuccessRate,
      successRateByType: successRateByType,
      averageEffectivenessScore: averageEffectivenessScore,
      averageUserSatisfaction: averageUserSatisfaction,
      mostEffectiveType: mostEffectiveType,
      leastEffectiveType: leastEffectiveType,
      improvedMetrics: improvedMetrics,
      totalImplementations: implementations.length,
      successfulImplementations: successfulCount,
    );
  }

  /// ユーザーフィードバック分析
  /// 
  /// [implementations] フィードバック付き実装記録
  /// 戻り値: フィードバック分析結果
  static UserFeedbackAnalysis analyzeFeedback({
    required List<SuggestionImplementationRecord> implementations,
  }) {
    final feedbackImplementations = implementations
        .where((impl) => impl.userSatisfaction != null)
        .toList();

    if (feedbackImplementations.isEmpty) {
      return const UserFeedbackAnalysis(
        totalFeedbacks: 0,
        satisfactionDistribution: {},
        averageSatisfaction: 0.0,
        positiveRate: 0.0,
        negativeRate: 0.0,
        keywordFrequency: {},
        improvementAreas: [],
      );
    }

    // 満足度分布
    final satisfactionDistribution = <int, int>{};
    for (final impl in feedbackImplementations) {
      final satisfaction = impl.userSatisfaction!;
      satisfactionDistribution[satisfaction] = 
          (satisfactionDistribution[satisfaction] ?? 0) + 1;
    }

    // 平均満足度
    final averageSatisfaction = feedbackImplementations
        .map((impl) => impl.userSatisfaction!.toDouble())
        .reduce((a, b) => a + b) / feedbackImplementations.length;

    // 最頻満足度
    int? modeSatisfaction;
    if (satisfactionDistribution.isNotEmpty) {
      final maxEntry = satisfactionDistribution.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      modeSatisfaction = maxEntry.key;
    }

    // ポジティブ/ネガティブ率
    final positiveCount = feedbackImplementations
        .where((impl) => impl.userSatisfaction! >= 4)
        .length;
    final negativeCount = feedbackImplementations
        .where((impl) => impl.userSatisfaction! <= 2)
        .length;
    
    final positiveRate = positiveCount / feedbackImplementations.length;
    final negativeRate = negativeCount / feedbackImplementations.length;

    // キーワード頻度分析
    final keywordFrequency = _analyzeKeywords(feedbackImplementations);

    // 改善要望エリア
    final improvementAreas = _identifyImprovementAreas(feedbackImplementations);

    return UserFeedbackAnalysis(
      totalFeedbacks: feedbackImplementations.length,
      satisfactionDistribution: satisfactionDistribution,
      averageSatisfaction: averageSatisfaction,
      modeSatisfaction: modeSatisfaction,
      positiveRate: positiveRate,
      negativeRate: negativeRate,
      keywordFrequency: keywordFrequency,
      improvementAreas: improvementAreas,
    );
  }

  /// 継続的改善データを生成
  /// 
  /// [effectivenessAnalysis] 効果分析結果
  /// [feedbackAnalysis] フィードバック分析結果
  /// [implementations] 実装記録
  /// 戻り値: 継続的改善データ
  static ContinuousImprovementData generateContinuousImprovementData({
    required SuggestionEffectivenessAnalysis effectivenessAnalysis,
    required UserFeedbackAnalysis feedbackAnalysis,
    required List<SuggestionImplementationRecord> implementations,
  }) {
    // パターン認識スコア
    final patternScores = _calculatePatternScores(
      effectivenessAnalysis,
      feedbackAnalysis,
    );

    // 成功要因分析
    final successFactors = _identifySuccessFactors(
      implementations.where((impl) => impl.isSuccessful).toList(),
    );

    // 失敗要因分析
    final failureFactors = _identifyFailureFactors(
      implementations.where((impl) => !impl.isSuccessful).toList(),
    );

    // 推奨アクション
    final recommendedActions = _generateRecommendedActions(
      effectivenessAnalysis,
      feedbackAnalysis,
    );

    // 学習ポイント
    final learningPoints = _extractLearningPoints(implementations);

    // 信頼度スコア
    final confidenceScore = _calculateConfidenceScore(
      implementations.length,
      feedbackAnalysis.totalFeedbacks,
      effectivenessAnalysis.overallSuccessRate,
    );

    return ContinuousImprovementData(
      patternScores: patternScores,
      successFactors: successFactors,
      failureFactors: failureFactors,
      recommendedActions: recommendedActions,
      learningPoints: learningPoints,
      confidenceScore: confidenceScore,
    );
  }

  /// 提案実装のベースライン測定
  /// 
  /// [usageHistory] プロンプト使用履歴
  /// [suggestionType] 提案タイプ
  /// 戻り値: ベースラインメトリクス
  static Map<String, double> measureBaseline({
    required List<PromptUsageHistory> usageHistory,
    required PersonalizationType suggestionType,
  }) {
    if (usageHistory.isEmpty) {
      return {
        'primaryMetric': 0.0,
        'usageFrequency': 0.0,
        'satisfaction': 0.0,
        'diversity': 0.0,
      };
    }

    final behaviorAnalysis = PromptUsageAnalytics.analyzeUserBehavior(
      usageHistory: usageHistory,
    );

    switch (suggestionType) {
      case PersonalizationType.timeAdjustment:
        return {
          'primaryMetric': _calculateTimeConsistency(usageHistory),
          'usageFrequency': _calculateWeeklyFrequency(usageHistory),
          'satisfaction': behaviorAnalysis.averageSatisfaction,
          'diversity': behaviorAnalysis.diversityIndex,
        };
        
      case PersonalizationType.frequencyAdjustment:
        return {
          'primaryMetric': _calculateWeeklyFrequency(usageHistory),
          'usageFrequency': _calculateWeeklyFrequency(usageHistory),
          'satisfaction': behaviorAnalysis.averageSatisfaction,
          'diversity': behaviorAnalysis.diversityIndex,
        };
        
      case PersonalizationType.categoryRecommendation:
        return {
          'primaryMetric': behaviorAnalysis.diversityIndex,
          'usageFrequency': _calculateWeeklyFrequency(usageHistory),
          'satisfaction': behaviorAnalysis.averageSatisfaction,
          'diversity': behaviorAnalysis.diversityIndex,
        };
        
      case PersonalizationType.contentOptimization:
        return {
          'primaryMetric': behaviorAnalysis.averageSatisfaction,
          'usageFrequency': _calculateWeeklyFrequency(usageHistory),
          'satisfaction': behaviorAnalysis.averageSatisfaction,
          'diversity': behaviorAnalysis.diversityIndex,
        };
        
      case PersonalizationType.notificationSetting:
        return {
          'primaryMetric': _calculateWeeklyFrequency(usageHistory),
          'usageFrequency': _calculateWeeklyFrequency(usageHistory),
          'satisfaction': behaviorAnalysis.averageSatisfaction,
          'diversity': behaviorAnalysis.diversityIndex,
        };
    }
  }

  /// 改善されたメトリクスを分析
  static List<String> _analyzeImprovedMetrics(
    List<SuggestionImplementationRecord> implementations,
  ) {
    final improvedMetrics = <String>[];
    final metricImprovements = <String, List<double>>{};

    for (final impl in implementations) {
      for (final metricKey in impl.baselineMetrics.keys) {
        final improvement = impl.getImprovementRate(metricKey);
        metricImprovements[metricKey] ??= [];
        metricImprovements[metricKey]!.add(improvement);
      }
    }

    for (final entry in metricImprovements.entries) {
      final averageImprovement = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (averageImprovement > 0.05) { // 5%以上の改善
        improvedMetrics.add(entry.key);
      }
    }

    return improvedMetrics;
  }

  /// キーワード頻度分析
  static Map<String, int> _analyzeKeywords(
    List<SuggestionImplementationRecord> implementations,
  ) {
    final keywords = <String, int>{};
    
    for (final impl in implementations) {
      if (impl.userFeedback != null) {
        // 日本語のキーワード抽出のためのシンプルな分割
        final feedback = impl.userFeedback!;
        final phrases = [
          '役に立ちました',
          'とても',
          '習慣化',
          '効果',
          '役立ち',
          '意識',
          '時間',
          '普通',
          'あまり',
        ];
        
        for (final phrase in phrases) {
          if (feedback.contains(phrase)) {
            keywords[phrase] = (keywords[phrase] ?? 0) + 1;
          }
        }
        
        // 基本的な単語分割
        final words = feedback
            .replaceAll(RegExp(r'[。、！？]'), ' ')
            .split(RegExp(r'\s+'))
            .where((word) => word.length > 1)
            .toList();
        
        for (final word in words) {
          if (word.length >= 2) {
            keywords[word] = (keywords[word] ?? 0) + 1;
          }
        }
      }
    }
    
    return Map.fromEntries(
      keywords.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10)
    );
  }

  /// 改善要望エリアを特定
  static List<PersonalizationType> _identifyImprovementAreas(
    List<SuggestionImplementationRecord> implementations,
  ) {
    final typePerformance = <PersonalizationType, double>{};
    final typeCounts = <PersonalizationType, int>{};

    for (final impl in implementations) {
      if (impl.userSatisfaction != null) {
        typePerformance[impl.suggestionType] = 
            (typePerformance[impl.suggestionType] ?? 0.0) + impl.userSatisfaction!;
        typeCounts[impl.suggestionType] = 
            (typeCounts[impl.suggestionType] ?? 0) + 1;
      }
    }

    final averageByType = <PersonalizationType, double>{};
    for (final type in typePerformance.keys) {
      averageByType[type] = typePerformance[type]! / typeCounts[type]!;
    }

    return averageByType.entries
        .where((entry) => entry.value < 3.5) // 満足度3.5未満
        .map((entry) => entry.key)
        .toList();
  }

  /// パターン認識スコアを計算
  static Map<String, double> _calculatePatternScores(
    SuggestionEffectivenessAnalysis effectivenessAnalysis,
    UserFeedbackAnalysis feedbackAnalysis,
  ) {
    return {
      'effectivenessPattern': effectivenessAnalysis.overallSuccessRate,
      'satisfactionPattern': feedbackAnalysis.averageSatisfaction / 5.0,
      'feedbackVolumePattern': min(1.0, feedbackAnalysis.totalFeedbacks / 50.0),
      'diversityPattern': effectivenessAnalysis.successRateByType.length / 5.0,
    };
  }

  /// 成功要因を特定
  static List<String> _identifySuccessFactors(
    List<SuggestionImplementationRecord> successfulImplementations,
  ) {
    final factors = <String>[];
    
    if (successfulImplementations.isEmpty) return factors;

    // 成功事例の共通パターンを分析
    final avgEffectiveness = successfulImplementations
        .map((impl) => impl.effectivenessScore)
        .reduce((a, b) => a + b) / successfulImplementations.length;
    
    if (avgEffectiveness > 0.7) {
      factors.add('高い効果スコア（${(avgEffectiveness * 100).toStringAsFixed(1)}%）');
    }

    final satisfactionScores = successfulImplementations
        .where((impl) => impl.userSatisfaction != null)
        .map((impl) => impl.userSatisfaction!.toDouble())
        .toList();
    
    if (satisfactionScores.isNotEmpty) {
      final avgSatisfaction = satisfactionScores.reduce((a, b) => a + b) / satisfactionScores.length;
      if (avgSatisfaction >= 4.0) {
        factors.add('高いユーザー満足度（${avgSatisfaction.toStringAsFixed(1)}/5）');
      }
    }

    // 測定期間の分析
    final avgMeasurementPeriod = successfulImplementations
        .map((impl) => impl.measurementPeriodDays)
        .reduce((a, b) => a + b) / successfulImplementations.length;
    
    if (avgMeasurementPeriod >= 14) {
      factors.add('十分な測定期間（平均${avgMeasurementPeriod.toStringAsFixed(1)}日）');
    }

    return factors;
  }

  /// 失敗要因を特定
  static List<String> _identifyFailureFactors(
    List<SuggestionImplementationRecord> failedImplementations,
  ) {
    final factors = <String>[];
    
    if (failedImplementations.isEmpty) return factors;

    final avgEffectiveness = failedImplementations
        .map((impl) => impl.effectivenessScore)
        .reduce((a, b) => a + b) / failedImplementations.length;
    
    if (avgEffectiveness < 0.3) {
      factors.add('低い効果スコア（${(avgEffectiveness * 100).toStringAsFixed(1)}%）');
    }

    final lowSatisfactionCount = failedImplementations
        .where((impl) => impl.userSatisfaction != null && impl.userSatisfaction! <= 2)
        .length;
    
    if (lowSatisfactionCount / failedImplementations.length > 0.5) {
      factors.add('低いユーザー満足度（${(lowSatisfactionCount / failedImplementations.length * 100).toStringAsFixed(1)}%が満足度2以下）');
    }

    // 最低限の失敗要因を確保
    if (factors.isEmpty && failedImplementations.isNotEmpty) {
      factors.add('実装が期待された成果を達成できませんでした');
    }

    return factors;
  }

  /// 推奨アクションを生成
  static List<String> _generateRecommendedActions(
    SuggestionEffectivenessAnalysis effectivenessAnalysis,
    UserFeedbackAnalysis feedbackAnalysis,
  ) {
    final actions = <String>[];

    if (effectivenessAnalysis.overallSuccessRate < 0.6) {
      actions.add('提案アルゴリズムの見直しと改善');
    }

    if (feedbackAnalysis.averageSatisfaction < 3.5) {
      actions.add('ユーザーエクスペリエンスの向上');
    }

    if (feedbackAnalysis.totalFeedbacks < 10) {
      actions.add('フィードバック収集機能の強化');
    }

    if (effectivenessAnalysis.mostEffectiveType != null) {
      actions.add('${effectivenessAnalysis.mostEffectiveType}タイプの提案を重点的に展開');
    }

    return actions;
  }

  /// 学習ポイントを抽出
  static Map<PersonalizationType, List<String>> _extractLearningPoints(
    List<SuggestionImplementationRecord> implementations,
  ) {
    final learningPoints = <PersonalizationType, List<String>>{};

    for (final type in PersonalizationType.values) {
      final typeImplementations = implementations
          .where((impl) => impl.suggestionType == type)
          .toList();
      
      if (typeImplementations.isNotEmpty) {
        final points = <String>[];
        
        final successRate = typeImplementations
            .where((impl) => impl.isSuccessful)
            .length / typeImplementations.length;
        
        if (successRate > 0.8) {
          points.add('高い成功率（${(successRate * 100).toStringAsFixed(1)}%）を維持');
        } else if (successRate < 0.4) {
          points.add('成功率改善が必要（現在${(successRate * 100).toStringAsFixed(1)}%）');
        }

        final avgEffectiveness = typeImplementations
            .map((impl) => impl.effectivenessScore)
            .reduce((a, b) => a + b) / typeImplementations.length;
        
        if (avgEffectiveness < 0.5) {
          points.add('効果スコア向上が必要');
        }

        // 最低限の学習ポイントを確保
        if (points.isEmpty) {
          points.add('実装数が少ないため、継続的な評価が必要');
        }

        learningPoints[type] = points;
      }
    }

    // 少なくとも1つの学習ポイントを確保
    if (learningPoints.isEmpty) {
      learningPoints[PersonalizationType.timeAdjustment] = ['データ収集を開始して分析を継続'];
    }

    return learningPoints;
  }

  /// 信頼度スコアを計算
  static double _calculateConfidenceScore(
    int totalImplementations,
    int totalFeedbacks,
    double successRate,
  ) {
    // 実装数の信頼度（0-0.4）
    final implementationConfidence = min(0.4, totalImplementations / 50.0);
    
    // フィードバック数の信頼度（0-0.3）
    final feedbackConfidence = min(0.3, totalFeedbacks / 30.0);
    
    // 成功率の信頼度（0-0.3）
    final successConfidence = successRate * 0.3;
    
    return implementationConfidence + feedbackConfidence + successConfidence;
  }

  /// 時間一貫性を計算
  static double _calculateTimeConsistency(List<PromptUsageHistory> usageHistory) {
    if (usageHistory.length < 2) return 0.0;
    
    final hourCounts = <int, int>{};
    for (final history in usageHistory) {
      final hour = history.usedAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    // エントロピーベースの一貫性計算
    final total = usageHistory.length;
    double entropy = 0.0;
    
    for (final count in hourCounts.values) {
      final probability = count / total;
      entropy -= probability * (log(probability) / ln2);
    }
    
    final maxEntropy = log(24) / ln2;
    return 1.0 - (entropy / maxEntropy);
  }

  /// 週次頻度を計算
  static double _calculateWeeklyFrequency(List<PromptUsageHistory> usageHistory) {
    if (usageHistory.isEmpty) return 0.0;
    
    final sortedHistory = usageHistory.toList()
      ..sort((a, b) => a.usedAt.compareTo(b.usedAt));
    
    final daySpan = sortedHistory.last.usedAt
        .difference(sortedHistory.first.usedAt)
        .inDays + 1;
    
    final weekSpan = daySpan / 7.0;
    return weekSpan > 0 ? usageHistory.length / weekSpan : 0.0;
  }
}