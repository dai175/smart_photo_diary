// プロンプト使用量分析サービス
// 
// プロンプトの使用パターン、人気度、トレンド分析を提供
// Phase 2.4.2の使用量分析機能実装

import 'dart:math';
import '../../models/writing_prompt.dart';

/// プロンプト使用頻度分析結果
class PromptFrequencyAnalysis {
  /// 分析対象期間（日数）
  final int periodDays;
  
  /// 総使用回数
  final int totalUsage;
  
  /// プロンプト別使用回数
  final Map<String, int> promptUsageCount;
  
  /// 平均使用頻度（回/日）
  final double averageUsagePerDay;
  
  /// 最も使用されたプロンプトID
  final String? mostUsedPromptId;
  
  /// 最高使用回数
  final int maxUsageCount;
  
  /// 使用されたプロンプト数
  final int uniquePromptsUsed;
  
  /// 使用頻度分布（頻度ごとのプロンプト数）
  final Map<int, int> usageDistribution;

  const PromptFrequencyAnalysis({
    required this.periodDays,
    required this.totalUsage,
    required this.promptUsageCount,
    required this.averageUsagePerDay,
    this.mostUsedPromptId,
    required this.maxUsageCount,
    required this.uniquePromptsUsed,
    required this.usageDistribution,
  });

  /// 使用率（総プロンプト数に対する使用されたプロンプトの割合）
  double getUsageRate(int totalPromptCount) {
    if (totalPromptCount == 0) return 0.0;
    return uniquePromptsUsed / totalPromptCount;
  }

  @override
  String toString() {
    return 'PromptFrequencyAnalysis('
           'period: ${periodDays}days, '
           'total: $totalUsage, '
           'unique: $uniquePromptsUsed, '
           'avgPerDay: ${averageUsagePerDay.toStringAsFixed(1)})';
  }
}

/// カテゴリ別人気度分析結果
class CategoryPopularityAnalysis {
  /// カテゴリ別使用回数
  final Map<PromptCategory, int> categoryUsageCount;
  
  /// カテゴリ別使用率（全使用に対する割合）
  final Map<PromptCategory, double> categoryUsageRate;
  
  /// 最も人気のカテゴリ
  final PromptCategory? mostPopularCategory;
  
  /// カテゴリ別平均使用頻度
  final Map<PromptCategory, double> averageUsagePerPrompt;
  
  /// トレンド情報（前期間との比較）
  final Map<PromptCategory, CategoryTrend>? trends;

  const CategoryPopularityAnalysis({
    required this.categoryUsageCount,
    required this.categoryUsageRate,
    this.mostPopularCategory,
    required this.averageUsagePerPrompt,
    this.trends,
  });

  /// 指定カテゴリの使用率を取得
  double getCategoryUsageRate(PromptCategory category) {
    return categoryUsageRate[category] ?? 0.0;
  }

  @override
  String toString() {
    return 'CategoryPopularityAnalysis('
           'categories: ${categoryUsageCount.length}, '
           'mostPopular: ${mostPopularCategory?.displayName})';
  }
}

/// カテゴリトレンド情報
class CategoryTrend {
  /// 前期間からの変化率（%）
  final double changeRate;
  
  /// 使用回数の変化
  final int usageChange;
  
  /// トレンド方向
  final TrendDirection direction;

  const CategoryTrend({
    required this.changeRate,
    required this.usageChange,
    required this.direction,
  });
}

/// トレンド方向
enum TrendDirection {
  /// 上昇傾向
  increasing,
  /// 下降傾向
  decreasing,
  /// 安定
  stable,
}

/// ユーザー行動分析結果
class UserBehaviorAnalysis {
  /// 使用パターン（時間帯別、曜日別など）
  final Map<String, int> usagePatterns;
  
  /// プロンプト選択の多様性指数（0-1）
  final double diversityIndex;
  
  /// 平均セッション間隔（時間）
  final double averageSessionInterval;
  
  /// リピート使用率（同じプロンプトの再使用頻度）
  final double repeatUsageRate;
  
  /// プロンプト満足度平均
  final double averageSatisfaction;

  const UserBehaviorAnalysis({
    required this.usagePatterns,
    required this.diversityIndex,
    required this.averageSessionInterval,
    required this.repeatUsageRate,
    required this.averageSatisfaction,
  });

  /// 使用パターンの健全性スコア（0-1）
  double getHealthScore() {
    // 多様性、満足度、適度な使用頻度を総合評価
    final diversityScore = diversityIndex;
    final satisfactionScore = averageSatisfaction;
    final frequencyScore = _calculateFrequencyScore();
    
    return (diversityScore + satisfactionScore + frequencyScore) / 3.0;
  }

  double _calculateFrequencyScore() {
    // 1日1-3回程度を理想とする（8-72時間間隔）
    if (averageSessionInterval >= 8.0 && averageSessionInterval <= 72.0) {
      return 1.0;
    } else if (averageSessionInterval < 8.0) {
      // 使いすぎ
      return max(0.0, 1.0 - (8.0 - averageSessionInterval) / 8.0);
    } else {
      // 使用頻度が低い
      return max(0.0, 1.0 - (averageSessionInterval - 72.0) / 168.0);
    }
  }

  @override
  String toString() {
    return 'UserBehaviorAnalysis('
           'diversity: ${diversityIndex.toStringAsFixed(3)}, '
           'satisfaction: ${averageSatisfaction.toStringAsFixed(3)}, '
           'health: ${getHealthScore().toStringAsFixed(3)})';
  }
}

/// プロンプト改善提案
class PromptImprovementSuggestion {
  /// 提案タイプ
  final SuggestionType type;
  
  /// 提案対象（カテゴリ、プロンプトIDなど）
  final String target;
  
  /// 提案内容
  final String suggestion;
  
  /// 重要度（1-5）
  final int priority;
  
  /// 根拠データ
  final Map<String, dynamic> evidence;

  const PromptImprovementSuggestion({
    required this.type,
    required this.target,
    required this.suggestion,
    required this.priority,
    required this.evidence,
  });

  @override
  String toString() {
    return 'PromptImprovementSuggestion('
           'type: $type, '
           'target: $target, '
           'priority: $priority)';
  }
}

/// 提案タイプ
enum SuggestionType {
  /// プロンプト追加
  addPrompt,
  /// プロンプト改善
  improvePrompt,
  /// カテゴリ調整
  adjustCategory,
  /// プロンプト削除候補
  removePrompt,
  /// 重み調整
  adjustWeight,
}

/// プロンプト使用量分析サービス
/// 
/// 使用履歴データを分析し、プロンプトの人気度、トレンド、
/// ユーザー行動パターンを分析する
class PromptUsageAnalytics {
  
  /// プロンプト使用頻度を分析
  /// 
  /// [usageData] プロンプトID別使用回数
  /// [periodDays] 分析対象期間（日数）
  /// [allPrompts] 全プロンプトリスト（使用率計算用）
  /// 戻り値: 使用頻度分析結果
  static PromptFrequencyAnalysis analyzePromptFrequency({
    required Map<String, int> usageData,
    required int periodDays,
    List<WritingPrompt>? allPrompts,
  }) {
    if (usageData.isEmpty) {
      return PromptFrequencyAnalysis(
        periodDays: periodDays,
        totalUsage: 0,
        promptUsageCount: {},
        averageUsagePerDay: 0.0,
        maxUsageCount: 0,
        uniquePromptsUsed: 0,
        usageDistribution: {},
      );
    }

    final totalUsage = usageData.values.fold<int>(0, (sum, count) => sum + count);
    final averageUsagePerDay = totalUsage / periodDays;
    final maxUsageCount = usageData.values.reduce(max);
    final mostUsedEntry = usageData.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    // 使用頻度分布を計算
    final usageDistribution = <int, int>{};
    for (final count in usageData.values) {
      usageDistribution[count] = (usageDistribution[count] ?? 0) + 1;
    }

    return PromptFrequencyAnalysis(
      periodDays: periodDays,
      totalUsage: totalUsage,
      promptUsageCount: Map.from(usageData),
      averageUsagePerDay: averageUsagePerDay,
      mostUsedPromptId: mostUsedEntry.key,
      maxUsageCount: maxUsageCount,
      uniquePromptsUsed: usageData.length,
      usageDistribution: usageDistribution,
    );
  }

  /// カテゴリ別人気度を分析
  /// 
  /// [usageData] プロンプトID別使用回数
  /// [allPrompts] 全プロンプトリスト
  /// [previousPeriodData] 前期間のデータ（トレンド計算用）
  /// 戻り値: カテゴリ別人気度分析結果
  static CategoryPopularityAnalysis analyzeCategoryPopularity({
    required Map<String, int> usageData,
    required List<WritingPrompt> allPrompts,
    Map<String, int>? previousPeriodData,
  }) {
    // プロンプトIDからカテゴリマッピングを作成
    final promptToCategory = <String, PromptCategory>{};
    for (final prompt in allPrompts) {
      promptToCategory[prompt.id] = prompt.category;
    }

    // カテゴリ別使用回数を集計
    final categoryUsageCount = <PromptCategory, int>{};
    final totalUsage = usageData.values.fold<int>(0, (sum, count) => sum + count);

    for (final entry in usageData.entries) {
      final category = promptToCategory[entry.key];
      if (category != null) {
        categoryUsageCount[category] = 
            (categoryUsageCount[category] ?? 0) + entry.value;
      }
    }

    // 使用率を計算
    final categoryUsageRate = <PromptCategory, double>{};
    for (final entry in categoryUsageCount.entries) {
      categoryUsageRate[entry.key] = 
          totalUsage > 0 ? entry.value / totalUsage : 0.0;
    }

    // 最も人気のカテゴリを特定
    PromptCategory? mostPopularCategory;
    if (categoryUsageCount.isNotEmpty) {
      final maxEntry = categoryUsageCount.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostPopularCategory = maxEntry.key;
    }

    // カテゴリ別平均使用頻度（プロンプト数で正規化）
    final averageUsagePerPrompt = <PromptCategory, double>{};
    for (final category in PromptCategory.values) {
      final categoryPrompts = allPrompts.where((p) => p.category == category).length;
      final categoryUsage = categoryUsageCount[category] ?? 0;
      averageUsagePerPrompt[category] = 
          categoryPrompts > 0 ? categoryUsage / categoryPrompts : 0.0;
    }

    // トレンド分析（前期間データがある場合）
    Map<PromptCategory, CategoryTrend>? trends;
    if (previousPeriodData != null) {
      trends = _calculateCategoryTrends(
        categoryUsageCount,
        previousPeriodData,
        promptToCategory,
      );
    }

    return CategoryPopularityAnalysis(
      categoryUsageCount: categoryUsageCount,
      categoryUsageRate: categoryUsageRate,
      mostPopularCategory: mostPopularCategory,
      averageUsagePerPrompt: averageUsagePerPrompt,
      trends: trends,
    );
  }

  /// ユーザー行動を分析
  /// 
  /// [usageHistory] 使用履歴データ
  /// 戻り値: ユーザー行動分析結果
  static UserBehaviorAnalysis analyzeUserBehavior({
    required List<PromptUsageHistory> usageHistory,
  }) {
    if (usageHistory.isEmpty) {
      return const UserBehaviorAnalysis(
        usagePatterns: {},
        diversityIndex: 0.0,
        averageSessionInterval: 0.0,
        repeatUsageRate: 0.0,
        averageSatisfaction: 0.0,
      );
    }

    // 時間帯別使用パターンを分析
    final hourlyUsage = <int, int>{};
    final promptIdCounts = <String, int>{};
    final satisfactionScores = <bool>[];
    final usageTimes = <DateTime>[];

    for (final history in usageHistory) {
      // 時間帯
      final hour = history.usedAt.hour;
      hourlyUsage[hour] = (hourlyUsage[hour] ?? 0) + 1;

      // プロンプトID別カウント
      promptIdCounts[history.promptId] = 
          (promptIdCounts[history.promptId] ?? 0) + 1;

      // 満足度
      satisfactionScores.add(history.wasHelpful);

      // 使用時刻
      usageTimes.add(history.usedAt);
    }

    // 使用パターン
    final usagePatterns = hourlyUsage.map(
      (hour, count) => MapEntry('hour_$hour', count),
    );

    // 多様性指数（シャノンエントロピー）
    final diversityIndex = _calculateShannonEntropy(promptIdCounts.values.toList());

    // 平均セッション間隔
    final averageSessionInterval = _calculateAverageInterval(usageTimes);

    // リピート使用率
    final totalUsage = usageHistory.length;
    final repeatUsage = promptIdCounts.values.where((count) => count > 1).length;
    final repeatUsageRate = totalUsage > 0 ? repeatUsage / totalUsage : 0.0;

    // 平均満足度
    final satisfactionSum = satisfactionScores.where((s) => s).length;
    final averageSatisfaction = 
        satisfactionScores.isNotEmpty ? satisfactionSum / satisfactionScores.length : 0.0;

    return UserBehaviorAnalysis(
      usagePatterns: usagePatterns,
      diversityIndex: diversityIndex,
      averageSessionInterval: averageSessionInterval,
      repeatUsageRate: repeatUsageRate,
      averageSatisfaction: averageSatisfaction,
    );
  }

  /// 改善提案を生成
  /// 
  /// [frequencyAnalysis] 使用頻度分析結果
  /// [categoryAnalysis] カテゴリ分析結果
  /// [behaviorAnalysis] 行動分析結果
  /// [allPrompts] 全プロンプトリスト
  /// 戻り値: 改善提案リスト
  static List<PromptImprovementSuggestion> generateImprovementSuggestions({
    required PromptFrequencyAnalysis frequencyAnalysis,
    required CategoryPopularityAnalysis categoryAnalysis,
    required UserBehaviorAnalysis behaviorAnalysis,
    required List<WritingPrompt> allPrompts,
  }) {
    final suggestions = <PromptImprovementSuggestion>[];

    // 1. 未使用プロンプトの検出
    final usedPromptIds = frequencyAnalysis.promptUsageCount.keys.toSet();
    final allPromptIds = allPrompts.map((p) => p.id).toSet();
    final unusedPromptIds = allPromptIds.difference(usedPromptIds);

    if (unusedPromptIds.isNotEmpty) {
      suggestions.add(PromptImprovementSuggestion(
        type: SuggestionType.improvePrompt,
        target: 'unused_prompts',
        suggestion: '${unusedPromptIds.length}個の未使用プロンプトがあります。内容の見直しまたは削除を検討してください。',
        priority: 3,
        evidence: {'unusedCount': unusedPromptIds.length, 'unusedIds': unusedPromptIds.toList()},
      ));
    }

    // 2. 低満足度の改善提案
    if (behaviorAnalysis.averageSatisfaction < 0.7) {
      suggestions.add(PromptImprovementSuggestion(
        type: SuggestionType.improvePrompt,
        target: 'satisfaction',
        suggestion: 'ユーザー満足度が低めです（${(behaviorAnalysis.averageSatisfaction * 100).toStringAsFixed(1)}%）。プロンプト内容の改善を検討してください。',
        priority: 4,
        evidence: {'satisfaction': behaviorAnalysis.averageSatisfaction},
      ));
    }

    // 3. 人気カテゴリの拡充提案
    if (categoryAnalysis.mostPopularCategory != null) {
      final popularCategory = categoryAnalysis.mostPopularCategory!;
      final usageRate = categoryAnalysis.getCategoryUsageRate(popularCategory);
      
      if (usageRate > 0.4) {
        suggestions.add(PromptImprovementSuggestion(
          type: SuggestionType.addPrompt,
          target: popularCategory.id,
          suggestion: '${popularCategory.displayName}カテゴリが人気です（使用率${(usageRate * 100).toStringAsFixed(1)}%）。このカテゴリのプロンプト追加を検討してください。',
          priority: 5,
          evidence: {'category': popularCategory.id, 'usageRate': usageRate},
        ));
      }
    }

    // 4. 多様性の改善提案
    if (behaviorAnalysis.diversityIndex < 0.5) {
      suggestions.add(PromptImprovementSuggestion(
        type: SuggestionType.adjustCategory,
        target: 'diversity',
        suggestion: 'プロンプト選択の多様性が低いです。ランダム選択機能の改善や新しいカテゴリの追加を検討してください。',
        priority: 3,
        evidence: {'diversityIndex': behaviorAnalysis.diversityIndex},
      ));
    }

    return suggestions..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// カテゴリトレンドを計算
  static Map<PromptCategory, CategoryTrend> _calculateCategoryTrends(
    Map<PromptCategory, int> currentData,
    Map<String, int> previousData,
    Map<String, PromptCategory> promptToCategory,
  ) {
    // 前期間のカテゴリ別データを集計
    final previousCategoryData = <PromptCategory, int>{};
    for (final entry in previousData.entries) {
      final category = promptToCategory[entry.key];
      if (category != null) {
        previousCategoryData[category] = 
            (previousCategoryData[category] ?? 0) + entry.value;
      }
    }

    final trends = <PromptCategory, CategoryTrend>{};
    for (final category in PromptCategory.values) {
      final currentUsage = currentData[category] ?? 0;
      final previousUsage = previousCategoryData[category] ?? 0;
      
      final usageChange = currentUsage - previousUsage;
      final changeRate = previousUsage > 0 
          ? (usageChange / previousUsage) * 100
          : (currentUsage > 0 ? 100.0 : 0.0);

      TrendDirection direction;
      if (changeRate > 10) {
        direction = TrendDirection.increasing;
      } else if (changeRate < -10) {
        direction = TrendDirection.decreasing;
      } else {
        direction = TrendDirection.stable;
      }

      trends[category] = CategoryTrend(
        changeRate: changeRate,
        usageChange: usageChange,
        direction: direction,
      );
    }

    return trends;
  }

  /// シャノンエントロピーを計算（多様性指数）
  static double _calculateShannonEntropy(List<int> counts) {
    if (counts.isEmpty) return 0.0;

    final total = counts.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return 0.0;

    double entropy = 0.0;
    for (final count in counts) {
      if (count > 0) {
        final probability = count / total;
        entropy -= probability * (log(probability) / ln2);
      }
    }

    // 0-1に正規化（最大エントロピーで割る）
    final maxEntropy = log(counts.length) / ln2;
    return maxEntropy > 0 ? entropy / maxEntropy : 0.0;
  }

  /// 平均セッション間隔を計算（時間単位）
  static double _calculateAverageInterval(List<DateTime> usageTimes) {
    if (usageTimes.length < 2) return 0.0;

    // 時系列順にソート
    final sortedTimes = List<DateTime>.from(usageTimes)..sort();
    
    final intervals = <double>[];
    for (int i = 1; i < sortedTimes.length; i++) {
      final interval = sortedTimes[i].difference(sortedTimes[i - 1]).inHours.toDouble();
      intervals.add(interval);
    }

    return intervals.isEmpty ? 0.0 : intervals.reduce((a, b) => a + b) / intervals.length;
  }
}