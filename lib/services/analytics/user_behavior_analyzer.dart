// ユーザー行動分析基盤
//
// ユーザーのプロンプト使用行動を詳細に分析し、
// パーソナライズ提案やUX改善のためのインサイトを提供
// Phase 2.4.2.3の実装

import 'dart:math';
import '../../models/writing_prompt.dart';
import 'prompt_usage_analytics.dart';

/// 詳細行動分析結果
class DetailedBehaviorAnalysis {
  /// 基本行動分析
  final UserBehaviorAnalysis basicAnalysis;
  
  /// 時間パターン分析
  final TimePatternAnalysis timePattern;
  
  /// 使用傾向分析
  final UsageTrendAnalysis usageTrend;
  
  /// エンゲージメント分析
  final EngagementAnalysis engagement;
  
  /// パーソナライゼーション提案
  final List<PersonalizationSuggestion> personalizationSuggestions;

  const DetailedBehaviorAnalysis({
    required this.basicAnalysis,
    required this.timePattern,
    required this.usageTrend,
    required this.engagement,
    required this.personalizationSuggestions,
  });

  /// 総合スコア（0-1）
  double get overallScore {
    return (basicAnalysis.getHealthScore() + 
            timePattern.consistencyScore + 
            engagement.engagementScore) / 3.0;
  }

  @override
  String toString() {
    return 'DetailedBehaviorAnalysis('
           'overall: ${(overallScore * 100).toStringAsFixed(1)}%, '
           'health: ${(basicAnalysis.getHealthScore() * 100).toStringAsFixed(1)}%, '
           'consistency: ${(timePattern.consistencyScore * 100).toStringAsFixed(1)}%, '
           'engagement: ${(engagement.engagementScore * 100).toStringAsFixed(1)}%)';
  }
}

/// 時間パターン分析
class TimePatternAnalysis {
  /// 時間帯別使用パターン
  final Map<int, int> hourlyPattern;
  
  /// 曜日別使用パターン
  final Map<int, int> weekdayPattern;
  
  /// 最も活発な時間帯
  final int? peakHour;
  
  /// 最も活発な曜日
  final int? peakWeekday;
  
  /// 使用時間の一貫性スコア（0-1）
  final double consistencyScore;
  
  /// 平均セッション長（分）
  final double averageSessionDuration;
  
  /// 連続使用日数の最大値
  final int maxConsecutiveDays;

  const TimePatternAnalysis({
    required this.hourlyPattern,
    required this.weekdayPattern,
    this.peakHour,
    this.peakWeekday,
    required this.consistencyScore,
    required this.averageSessionDuration,
    required this.maxConsecutiveDays,
  });

  /// 時間帯の説明を取得
  String getHourDescription(int hour) {
    if (hour >= 6 && hour < 12) return '朝';
    if (hour >= 12 && hour < 18) return '昼';
    if (hour >= 18 && hour < 22) return '夕方';
    return '夜';
  }

  /// 曜日の説明を取得
  String getWeekdayDescription(int weekday) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    if (weekday >= 1 && weekday <= 7) {
      return weekdays[weekday - 1];
    }
    return '不明';
  }

  @override
  String toString() {
    final peakHourDesc = peakHour != null ? getHourDescription(peakHour!) : '不明';
    final peakWeekdayDesc = peakWeekday != null ? getWeekdayDescription(peakWeekday!) : '不明';
    
    return 'TimePatternAnalysis('
           'peak: $peakHourDesc時間帯、$peakWeekdayDesc曜日, '
           'consistency: ${(consistencyScore * 100).toStringAsFixed(1)}%, '
           'maxConsecutive: $maxConsecutiveDays日)';
  }
}

/// 使用傾向分析
class UsageTrendAnalysis {
  /// 週次使用回数の推移
  final List<WeeklyUsage> weeklyTrends;
  
  /// 使用頻度の変化率（週あたり％）
  final double frequencyChangeRate;
  
  /// 使用の規則性（0-1、1が最も規則的）
  final double regularity;
  
  /// 使用量の季節性指数
  final double seasonalityIndex;
  
  /// トレンド方向
  final UsageTrendDirection direction;

  const UsageTrendAnalysis({
    required this.weeklyTrends,
    required this.frequencyChangeRate,
    required this.regularity,
    required this.seasonalityIndex,
    required this.direction,
  });

  @override
  String toString() {
    String directionText;
    switch (direction) {
      case UsageTrendDirection.increasing:
        directionText = '増加傾向';
        break;
      case UsageTrendDirection.decreasing:
        directionText = '減少傾向';
        break;
      case UsageTrendDirection.stable:
        directionText = '安定';
        break;
    }
    
    return 'UsageTrendAnalysis('
           'direction: $directionText, '
           'change: ${frequencyChangeRate.toStringAsFixed(1)}%/週, '
           'regularity: ${(regularity * 100).toStringAsFixed(1)}%)';
  }
}

/// 週次使用データ
class WeeklyUsage {
  /// 週の開始日
  final DateTime weekStart;
  
  /// その週の使用回数
  final int usageCount;

  const WeeklyUsage({
    required this.weekStart,
    required this.usageCount,
  });
}

/// 使用トレンド方向
enum UsageTrendDirection {
  increasing,
  decreasing,
  stable,
}

/// エンゲージメント分析
class EngagementAnalysis {
  /// エンゲージメントスコア（0-1）
  final double engagementScore;
  
  /// プロンプト完了率
  final double completionRate;
  
  /// 平均満足度
  final double averageSatisfaction;
  
  /// リピート使用率
  final double repeatUsageRate;
  
  /// 探索度（新しいプロンプトを試す傾向）
  final double explorationRate;
  
  /// ロイヤルティスコア（継続利用の強さ）
  final double loyaltyScore;

  const EngagementAnalysis({
    required this.engagementScore,
    required this.completionRate,
    required this.averageSatisfaction,
    required this.repeatUsageRate,
    required this.explorationRate,
    required this.loyaltyScore,
  });

  /// エンゲージメントレベルの説明
  String get engagementLevel {
    if (engagementScore >= 0.8) return '非常に高い';
    if (engagementScore >= 0.6) return '高い';
    if (engagementScore >= 0.4) return '中程度';
    if (engagementScore >= 0.2) return '低い';
    return '非常に低い';
  }

  @override
  String toString() {
    return 'EngagementAnalysis('
           'level: $engagementLevel, '
           'satisfaction: ${(averageSatisfaction * 100).toStringAsFixed(1)}%, '
           'exploration: ${(explorationRate * 100).toStringAsFixed(1)}%, '
           'loyalty: ${(loyaltyScore * 100).toStringAsFixed(1)}%)';
  }
}

/// パーソナライゼーション提案
class PersonalizationSuggestion {
  /// 提案タイプ
  final PersonalizationType type;
  
  /// 提案内容
  final String suggestion;
  
  /// 優先度（1-5）
  final int priority;
  
  /// 根拠データ
  final Map<String, dynamic> evidence;
  
  /// 期待される効果
  final String expectedImpact;

  const PersonalizationSuggestion({
    required this.type,
    required this.suggestion,
    required this.priority,
    required this.evidence,
    required this.expectedImpact,
  });

  @override
  String toString() {
    return 'PersonalizationSuggestion('
           'type: $type, '
           'priority: $priority, '
           'suggestion: $suggestion)';
  }
}

/// パーソナライゼーションタイプ
enum PersonalizationType {
  /// 時間調整
  timeAdjustment,
  /// カテゴリ推奨
  categoryRecommendation,
  /// 頻度調整
  frequencyAdjustment,
  /// コンテンツ最適化
  contentOptimization,
  /// 通知設定
  notificationSetting,
}

/// ユーザー行動分析器
/// 
/// プロンプト使用履歴から詳細な行動パターンを分析し、
/// パーソナライゼーション提案を生成する
class UserBehaviorAnalyzer {
  
  /// 詳細行動分析を実行
  /// 
  /// [usageHistory] 使用履歴データ
  /// [availablePrompts] 利用可能プロンプト
  /// 戻り値: 詳細行動分析結果
  static DetailedBehaviorAnalysis analyzeDetailedBehavior({
    required List<PromptUsageHistory> usageHistory,
    required List<WritingPrompt> availablePrompts,
  }) {
    if (usageHistory.isEmpty) {
      return _createEmptyAnalysis();
    }

    // 基本行動分析
    final basicAnalysis = PromptUsageAnalytics.analyzeUserBehavior(
      usageHistory: usageHistory,
    );

    // 時間パターン分析
    final timePattern = _analyzeTimePatterns(usageHistory);

    // 使用傾向分析
    final usageTrend = _analyzeUsageTrends(usageHistory);

    // エンゲージメント分析
    final engagement = _analyzeEngagement(usageHistory, availablePrompts);

    // パーソナライゼーション提案生成
    final personalizationSuggestions = _generatePersonalizationSuggestions(
      basicAnalysis: basicAnalysis,
      timePattern: timePattern,
      usageTrend: usageTrend,
      engagement: engagement,
    );

    return DetailedBehaviorAnalysis(
      basicAnalysis: basicAnalysis,
      timePattern: timePattern,
      usageTrend: usageTrend,
      engagement: engagement,
      personalizationSuggestions: personalizationSuggestions,
    );
  }

  /// 空の分析結果を作成
  static DetailedBehaviorAnalysis _createEmptyAnalysis() {
    return DetailedBehaviorAnalysis(
      basicAnalysis: const UserBehaviorAnalysis(
        usagePatterns: {},
        diversityIndex: 0.0,
        averageSessionInterval: 0.0,
        repeatUsageRate: 0.0,
        averageSatisfaction: 0.0,
      ),
      timePattern: const TimePatternAnalysis(
        hourlyPattern: {},
        weekdayPattern: {},
        consistencyScore: 0.0,
        averageSessionDuration: 0.0,
        maxConsecutiveDays: 0,
      ),
      usageTrend: const UsageTrendAnalysis(
        weeklyTrends: [],
        frequencyChangeRate: 0.0,
        regularity: 0.0,
        seasonalityIndex: 0.0,
        direction: UsageTrendDirection.stable,
      ),
      engagement: const EngagementAnalysis(
        engagementScore: 0.0,
        completionRate: 0.0,
        averageSatisfaction: 0.0,
        repeatUsageRate: 0.0,
        explorationRate: 0.0,
        loyaltyScore: 0.0,
      ),
      personalizationSuggestions: [],
    );
  }

  /// 時間パターンを分析
  static TimePatternAnalysis _analyzeTimePatterns(List<PromptUsageHistory> usageHistory) {
    final hourlyPattern = <int, int>{};
    final weekdayPattern = <int, int>{};
    final usageDates = <DateTime>{};

    for (final history in usageHistory) {
      final hour = history.usedAt.hour;
      final weekday = history.usedAt.weekday;
      final date = DateTime(history.usedAt.year, history.usedAt.month, history.usedAt.day);

      hourlyPattern[hour] = (hourlyPattern[hour] ?? 0) + 1;
      weekdayPattern[weekday] = (weekdayPattern[weekday] ?? 0) + 1;
      usageDates.add(date);
    }

    // ピーク時間とピーク曜日を特定
    int? peakHour;
    int? peakWeekday;
    
    if (hourlyPattern.isNotEmpty) {
      final maxHourEntry = hourlyPattern.entries.reduce((a, b) => a.value > b.value ? a : b);
      peakHour = maxHourEntry.key;
    }
    
    if (weekdayPattern.isNotEmpty) {
      final maxWeekdayEntry = weekdayPattern.entries.reduce((a, b) => a.value > b.value ? a : b);
      peakWeekday = maxWeekdayEntry.key;
    }

    // 一貫性スコアを計算（エントロピーベース）
    final consistencyScore = _calculateConsistencyScore(hourlyPattern, weekdayPattern);

    // 平均セッション長を計算（分単位）
    final averageSessionDuration = _calculateAverageSessionDuration(usageHistory);

    // 連続使用日数を計算
    final maxConsecutiveDays = _calculateMaxConsecutiveDays(usageDates);

    return TimePatternAnalysis(
      hourlyPattern: hourlyPattern,
      weekdayPattern: weekdayPattern,
      peakHour: peakHour,
      peakWeekday: peakWeekday,
      consistencyScore: consistencyScore,
      averageSessionDuration: averageSessionDuration,
      maxConsecutiveDays: maxConsecutiveDays,
    );
  }

  /// 使用傾向を分析
  static UsageTrendAnalysis _analyzeUsageTrends(List<PromptUsageHistory> usageHistory) {
    if (usageHistory.length < 2) {
      return const UsageTrendAnalysis(
        weeklyTrends: [],
        frequencyChangeRate: 0.0,
        regularity: 0.0,
        seasonalityIndex: 0.0,
        direction: UsageTrendDirection.stable,
      );
    }

    // 週次データを作成
    final weeklyTrends = _generateWeeklyTrends(usageHistory);

    // 変化率を計算
    final frequencyChangeRate = _calculateFrequencyChangeRate(weeklyTrends);

    // 規則性を計算
    final regularity = _calculateRegularity(usageHistory);

    // 季節性指数を計算
    final seasonalityIndex = _calculateSeasonalityIndex(usageHistory);

    // トレンド方向を決定
    UsageTrendDirection direction;
    if (frequencyChangeRate > 5.0) {
      direction = UsageTrendDirection.increasing;
    } else if (frequencyChangeRate < -5.0) {
      direction = UsageTrendDirection.decreasing;
    } else {
      direction = UsageTrendDirection.stable;
    }

    return UsageTrendAnalysis(
      weeklyTrends: weeklyTrends,
      frequencyChangeRate: frequencyChangeRate,
      regularity: regularity,
      seasonalityIndex: seasonalityIndex,
      direction: direction,
    );
  }

  /// エンゲージメントを分析
  static EngagementAnalysis _analyzeEngagement(
    List<PromptUsageHistory> usageHistory,
    List<WritingPrompt> availablePrompts,
  ) {
    if (usageHistory.isEmpty) {
      return const EngagementAnalysis(
        engagementScore: 0.0,
        completionRate: 0.0,
        averageSatisfaction: 0.0,
        repeatUsageRate: 0.0,
        explorationRate: 0.0,
        loyaltyScore: 0.0,
      );
    }

    // 満足度計算
    final satisfactionSum = usageHistory.where((h) => h.wasHelpful).length;
    final averageSatisfaction = satisfactionSum / usageHistory.length;

    // リピート使用率
    final promptCounts = <String, int>{};
    for (final history in usageHistory) {
      promptCounts[history.promptId] = (promptCounts[history.promptId] ?? 0) + 1;
    }
    final repeatUsage = promptCounts.values.where((count) => count > 1).length;
    final repeatUsageRate = promptCounts.isNotEmpty ? repeatUsage / promptCounts.length : 0.0;

    // 探索度計算
    final uniquePromptsUsed = promptCounts.length;
    final totalPromptsAvailable = availablePrompts.length;
    final explorationRate = totalPromptsAvailable > 0 ? uniquePromptsUsed / totalPromptsAvailable : 0.0;

    // ロイヤルティスコア（継続性と頻度の組み合わせ）
    final daySpan = _calculateDaySpan(usageHistory);
    final averageFrequency = daySpan > 0 ? usageHistory.length / daySpan : 0.0;
    final loyaltyScore = min(1.0, (averageFrequency / 3.0) * averageSatisfaction); // 1日3回を最大として正規化

    // 完了率（簡易的に満足度と同じとする）
    final completionRate = averageSatisfaction;

    // 総合エンゲージメントスコア
    final engagementScore = (averageSatisfaction * 0.3 + 
                           explorationRate * 0.3 + 
                           loyaltyScore * 0.4);

    return EngagementAnalysis(
      engagementScore: engagementScore,
      completionRate: completionRate,
      averageSatisfaction: averageSatisfaction,
      repeatUsageRate: repeatUsageRate,
      explorationRate: explorationRate,
      loyaltyScore: loyaltyScore,
    );
  }

  /// パーソナライゼーション提案を生成
  static List<PersonalizationSuggestion> _generatePersonalizationSuggestions({
    required UserBehaviorAnalysis basicAnalysis,
    required TimePatternAnalysis timePattern,
    required UsageTrendAnalysis usageTrend,
    required EngagementAnalysis engagement,
  }) {
    final suggestions = <PersonalizationSuggestion>[];

    // 時間最適化提案
    if (timePattern.peakHour != null && timePattern.consistencyScore < 0.6) {
      suggestions.add(PersonalizationSuggestion(
        type: PersonalizationType.timeAdjustment,
        suggestion: '${timePattern.getHourDescription(timePattern.peakHour!)}時間帯（${timePattern.peakHour}時頃）に通知を設定することで、より一貫した使用習慣を作ることができます。',
        priority: 4,
        evidence: {
          'peakHour': timePattern.peakHour!,
          'consistencyScore': timePattern.consistencyScore,
        },
        expectedImpact: '使用の一貫性向上',
      ));
    }

    // 頻度調整提案
    if (usageTrend.direction == UsageTrendDirection.decreasing) {
      suggestions.add(PersonalizationSuggestion(
        type: PersonalizationType.frequencyAdjustment,
        suggestion: '使用頻度が減少傾向にあります。週2-3回のリマインダー設定で、習慣を維持することをお勧めします。',
        priority: 5,
        evidence: {
          'direction': usageTrend.direction.toString(),
          'changeRate': usageTrend.frequencyChangeRate,
        },
        expectedImpact: '継続的な利用促進',
      ));
    }

    // エンゲージメント向上提案
    if (engagement.explorationRate < 0.3) {
      suggestions.add(PersonalizationSuggestion(
        type: PersonalizationType.contentOptimization,
        suggestion: '新しいプロンプトの探索率が低いです。お気に入りカテゴリ以外からのランダム選択を時々試してみませんか？',
        priority: 3,
        evidence: {
          'explorationRate': engagement.explorationRate,
        },
        expectedImpact: 'プロンプト多様性の向上',
      ));
    }

    // 満足度改善提案
    if (engagement.averageSatisfaction < 0.7) {
      suggestions.add(PersonalizationSuggestion(
        type: PersonalizationType.categoryRecommendation,
        suggestion: '満足度を向上させるため、より具体的で感情に深く関わるプロンプトカテゴリを試してみることをお勧めします。',
        priority: 4,
        evidence: {
          'satisfaction': engagement.averageSatisfaction,
        },
        expectedImpact: 'ユーザー満足度の向上',
      ));
    }

    return suggestions..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 一貫性スコアを計算
  static double _calculateConsistencyScore(
    Map<int, int> hourlyPattern,
    Map<int, int> weekdayPattern,
  ) {
    if (hourlyPattern.isEmpty && weekdayPattern.isEmpty) return 0.0;

    double hourlyConsistency = 0.0;
    double weekdayConsistency = 0.0;

    // 時間帯の一貫性（エントロピーの逆数）
    if (hourlyPattern.isNotEmpty) {
      final totalHourly = hourlyPattern.values.fold<int>(0, (sum, count) => sum + count);
      double entropy = 0.0;
      for (final count in hourlyPattern.values) {
        final probability = count / totalHourly;
        entropy -= probability * (log(probability) / ln2);
      }
      final maxEntropy = log(24) / ln2; // 24時間の最大エントロピー
      hourlyConsistency = 1.0 - (entropy / maxEntropy);
    }

    // 曜日の一貫性
    if (weekdayPattern.isNotEmpty) {
      final totalWeekday = weekdayPattern.values.fold<int>(0, (sum, count) => sum + count);
      double entropy = 0.0;
      for (final count in weekdayPattern.values) {
        final probability = count / totalWeekday;
        entropy -= probability * (log(probability) / ln2);
      }
      final maxEntropy = log(7) / ln2; // 7曜日の最大エントロピー
      weekdayConsistency = 1.0 - (entropy / maxEntropy);
    }

    return (hourlyConsistency + weekdayConsistency) / 2.0;
  }

  /// 平均セッション長を計算（分単位）
  static double _calculateAverageSessionDuration(List<PromptUsageHistory> usageHistory) {
    // 簡易的に同じ日の使用を1セッションとして計算
    final dailySessions = <String, List<DateTime>>{};
    
    for (final history in usageHistory) {
      final dateKey = '${history.usedAt.year}-${history.usedAt.month}-${history.usedAt.day}';
      dailySessions[dateKey] ??= [];
      dailySessions[dateKey]!.add(history.usedAt);
    }

    if (dailySessions.isEmpty) return 0.0;

    double totalDuration = 0.0;
    int sessionCount = 0;

    for (final times in dailySessions.values) {
      if (times.length > 1) {
        times.sort();
        final duration = times.last.difference(times.first).inMinutes.toDouble();
        totalDuration += duration;
      } else {
        totalDuration += 5.0; // 単発使用は5分と仮定
      }
      sessionCount++;
    }

    return sessionCount > 0 ? totalDuration / sessionCount : 0.0;
  }

  /// 最大連続使用日数を計算
  static int _calculateMaxConsecutiveDays(Set<DateTime> usageDates) {
    if (usageDates.isEmpty) return 0;

    final sortedDates = usageDates.toList()..sort();
    int maxConsecutive = 1;
    int currentConsecutive = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final dayDiff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (dayDiff == 1) {
        currentConsecutive++;
        maxConsecutive = max(maxConsecutive, currentConsecutive);
      } else {
        currentConsecutive = 1;
      }
    }

    return maxConsecutive;
  }

  /// 週次トレンドを生成
  static List<WeeklyUsage> _generateWeeklyTrends(List<PromptUsageHistory> usageHistory) {
    final weeklyData = <DateTime, int>{};

    for (final history in usageHistory) {
      // 週の開始を月曜日として計算
      final weekday = history.usedAt.weekday;
      final daysToMonday = weekday - 1;
      final weekStart = DateTime(
        history.usedAt.year,
        history.usedAt.month,
        history.usedAt.day - daysToMonday,
      );

      weeklyData[weekStart] = (weeklyData[weekStart] ?? 0) + 1;
    }

    return weeklyData.entries
        .map((entry) => WeeklyUsage(weekStart: entry.key, usageCount: entry.value))
        .toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  /// 頻度変化率を計算
  static double _calculateFrequencyChangeRate(List<WeeklyUsage> weeklyTrends) {
    if (weeklyTrends.length < 2) return 0.0;

    final firstHalf = weeklyTrends.take(weeklyTrends.length ~/ 2).toList();
    final secondHalf = weeklyTrends.skip(weeklyTrends.length ~/ 2).toList();

    final firstHalfAvg = firstHalf.fold<int>(0, (sum, w) => sum + w.usageCount) / firstHalf.length;
    final secondHalfAvg = secondHalf.fold<int>(0, (sum, w) => sum + w.usageCount) / secondHalf.length;

    if (firstHalfAvg == 0) return 0.0;

    return ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;
  }

  /// 規則性を計算
  static double _calculateRegularity(List<PromptUsageHistory> usageHistory) {
    if (usageHistory.length < 3) return 0.0;

    final sortedHistory = usageHistory.toList()
      ..sort((a, b) => a.usedAt.compareTo(b.usedAt));

    final intervals = <double>[];
    for (int i = 1; i < sortedHistory.length; i++) {
      final interval = sortedHistory[i].usedAt.difference(sortedHistory[i - 1].usedAt).inHours.toDouble();
      intervals.add(interval);
    }

    if (intervals.isEmpty) return 0.0;

    // 標準偏差の逆数で規則性を測定
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / intervals.length;
    final stdDev = sqrt(variance);

    return stdDev > 0 ? 1.0 / (1.0 + stdDev / mean) : 1.0;
  }

  /// 季節性指数を計算
  static double _calculateSeasonalityIndex(List<PromptUsageHistory> usageHistory) {
    // 簡易的な季節性分析（月別変動）
    final monthlyUsage = <int, int>{};
    
    for (final history in usageHistory) {
      final month = history.usedAt.month;
      monthlyUsage[month] = (monthlyUsage[month] ?? 0) + 1;
    }

    if (monthlyUsage.length < 3) return 0.0;

    final values = monthlyUsage.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;

    return sqrt(variance) / mean; // 変動係数
  }

  /// 日数スパンを計算
  static double _calculateDaySpan(List<PromptUsageHistory> usageHistory) {
    if (usageHistory.length < 2) return 1.0;

    final sortedHistory = usageHistory.toList()
      ..sort((a, b) => a.usedAt.compareTo(b.usedAt));

    return sortedHistory.last.usedAt.difference(sortedHistory.first.usedAt).inDays.toDouble() + 1;
  }
}