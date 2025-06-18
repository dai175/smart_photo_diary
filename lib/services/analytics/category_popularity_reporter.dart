// カテゴリ別人気度レポーター
// 
// カテゴリ分析結果の可視化とレポート生成
// Phase 2.4.2.2の実装

import '../../models/writing_prompt.dart';
import 'prompt_usage_analytics.dart';

/// カテゴリ人気度レポート
class CategoryPopularityReport {
  /// レポート生成日時
  final DateTime generatedAt;
  
  /// 分析対象期間
  final int periodDays;
  
  /// 分析結果
  final CategoryPopularityAnalysis analysis;
  
  /// レポートサマリー
  final CategoryReportSummary summary;
  
  /// 詳細データ
  final List<CategoryDetail> categoryDetails;
  
  /// トレンド要約
  final TrendSummary? trendSummary;

  const CategoryPopularityReport({
    required this.generatedAt,
    required this.periodDays,
    required this.analysis,
    required this.summary,
    required this.categoryDetails,
    this.trendSummary,
  });

  /// レポートを文字列形式で出力
  String toFormattedString() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== カテゴリ別人気度レポート ===');
    buffer.writeln('生成日時: ${_formatDateTime(generatedAt)}');
    buffer.writeln('分析期間: $periodDays日間');
    buffer.writeln();
    
    buffer.writeln('== サマリー ==');
    buffer.writeln(summary.toString());
    buffer.writeln();
    
    buffer.writeln('== カテゴリ詳細 ==');
    for (final detail in categoryDetails) {
      buffer.writeln(detail.toString());
    }
    
    if (trendSummary != null) {
      buffer.writeln();
      buffer.writeln('== トレンド分析 ==');
      buffer.writeln(trendSummary.toString());
    }
    
    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// カテゴリレポートサマリー
class CategoryReportSummary {
  /// 総使用回数
  final int totalUsage;
  
  /// アクティブカテゴリ数
  final int activeCategories;
  
  /// 最も人気のカテゴリ
  final PromptCategory? mostPopularCategory;
  
  /// 最も人気のカテゴリの使用率
  final double mostPopularUsageRate;
  
  /// 使用率の偏り度（ジニ係数風）
  final double inequalityIndex;
  
  /// 平均カテゴリ使用率
  final double averageCategoryUsage;

  const CategoryReportSummary({
    required this.totalUsage,
    required this.activeCategories,
    this.mostPopularCategory,
    required this.mostPopularUsageRate,
    required this.inequalityIndex,
    required this.averageCategoryUsage,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('総使用回数: $totalUsage回');
    buffer.writeln('アクティブカテゴリ数: $activeCategories/${PromptCategory.values.length}');
    
    if (mostPopularCategory != null) {
      buffer.writeln('最人気カテゴリ: ${mostPopularCategory!.displayName} '
                    '(${(mostPopularUsageRate * 100).toStringAsFixed(1)}%)');
    }
    
    buffer.writeln('平均カテゴリ使用率: ${(averageCategoryUsage * 100).toStringAsFixed(1)}%');
    buffer.writeln('使用率の偏り度: ${(inequalityIndex * 100).toStringAsFixed(1)}%');
    
    return buffer.toString();
  }
}

/// カテゴリ詳細情報
class CategoryDetail {
  /// カテゴリ
  final PromptCategory category;
  
  /// 使用回数
  final int usageCount;
  
  /// 使用率
  final double usageRate;
  
  /// ランキング（1位、2位など）
  final int rank;
  
  /// プロンプト数あたりの平均使用回数
  final double averageUsagePerPrompt;
  
  /// トレンド情報
  final CategoryTrend? trend;

  const CategoryDetail({
    required this.category,
    required this.usageCount,
    required this.usageRate,
    required this.rank,
    required this.averageUsagePerPrompt,
    this.trend,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$rank位. ${category.displayName}: ');
    buffer.write('$usageCount回 (${(usageRate * 100).toStringAsFixed(1)}%)');
    buffer.write(' [平均${averageUsagePerPrompt.toStringAsFixed(1)}回/プロンプト]');
    
    if (trend != null) {
      final trendIcon = _getTrendIcon(trend!.direction);
      final changeText = trend!.changeRate >= 0 
          ? '+${trend!.changeRate.toStringAsFixed(1)}%'
          : '${trend!.changeRate.toStringAsFixed(1)}%';
      buffer.write(' $trendIcon$changeText');
    }
    
    return buffer.toString();
  }

  String _getTrendIcon(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.increasing:
        return '↗️';
      case TrendDirection.decreasing:
        return '↘️';
      case TrendDirection.stable:
        return '→';
    }
  }
}

/// トレンド要約
class TrendSummary {
  /// 成長中のカテゴリ数
  final int growingCategories;
  
  /// 衰退中のカテゴリ数
  final int decliningCategories;
  
  /// 安定カテゴリ数
  final int stableCategories;
  
  /// 最も成長したカテゴリ
  final PromptCategory? fastestGrowingCategory;
  
  /// 最も成長率
  final double maxGrowthRate;
  
  /// 最も衰退したカテゴリ
  final PromptCategory? fastestDecliningCategory;
  
  /// 最も衰退率
  final double maxDeclineRate;

  const TrendSummary({
    required this.growingCategories,
    required this.decliningCategories,
    required this.stableCategories,
    this.fastestGrowingCategory,
    required this.maxGrowthRate,
    this.fastestDecliningCategory,
    required this.maxDeclineRate,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('成長中: $growingCategoriesカテゴリ');
    buffer.writeln('衰退中: $decliningCategoriesカテゴリ');
    buffer.writeln('安定: $stableCategoriesカテゴリ');
    
    if (fastestGrowingCategory != null && maxGrowthRate > 0) {
      buffer.writeln('最高成長: ${fastestGrowingCategory!.displayName} '
                    '(+${maxGrowthRate.toStringAsFixed(1)}%)');
    }
    
    if (fastestDecliningCategory != null && maxDeclineRate < 0) {
      buffer.writeln('最大衰退: ${fastestDecliningCategory!.displayName} '
                    '(${maxDeclineRate.toStringAsFixed(1)}%)');
    }
    
    return buffer.toString();
  }
}

/// カテゴリ人気度レポーター
/// 
/// CategoryPopularityAnalysisからレポートを生成
class CategoryPopularityReporter {
  
  /// 詳細レポートを生成
  /// 
  /// [analysis] カテゴリ分析結果
  /// [periodDays] 分析期間
  /// 戻り値: 詳細レポート
  static CategoryPopularityReport generateDetailedReport({
    required CategoryPopularityAnalysis analysis,
    required int periodDays,
  }) {
    final generatedAt = DateTime.now();
    
    // サマリーを生成
    final summary = _generateSummary(analysis);
    
    // カテゴリ詳細を生成
    final categoryDetails = _generateCategoryDetails(analysis);
    
    // トレンド要約を生成
    final trendSummary = analysis.trends != null 
        ? _generateTrendSummary(analysis.trends!)
        : null;
    
    return CategoryPopularityReport(
      generatedAt: generatedAt,
      periodDays: periodDays,
      analysis: analysis,
      summary: summary,
      categoryDetails: categoryDetails,
      trendSummary: trendSummary,
    );
  }

  /// サマリーを生成
  static CategoryReportSummary _generateSummary(CategoryPopularityAnalysis analysis) {
    final totalUsage = analysis.categoryUsageCount.values
        .fold<int>(0, (sum, count) => sum + count);
    
    final activeCategories = analysis.categoryUsageCount.values
        .where((count) => count > 0).length;
    
    final mostPopularUsageRate = analysis.mostPopularCategory != null
        ? analysis.getCategoryUsageRate(analysis.mostPopularCategory!)
        : 0.0;
    
    // 使用率の偏りを計算（ジニ係数風）
    final usageRates = analysis.categoryUsageRate.values.toList()..sort();
    final inequalityIndex = _calculateInequalityIndex(usageRates);
    
    // 平均カテゴリ使用率
    final averageCategoryUsage = analysis.categoryUsageRate.values.isNotEmpty
        ? analysis.categoryUsageRate.values.reduce((a, b) => a + b) / 
          analysis.categoryUsageRate.values.length
        : 0.0;
    
    return CategoryReportSummary(
      totalUsage: totalUsage,
      activeCategories: activeCategories,
      mostPopularCategory: analysis.mostPopularCategory,
      mostPopularUsageRate: mostPopularUsageRate,
      inequalityIndex: inequalityIndex,
      averageCategoryUsage: averageCategoryUsage,
    );
  }

  /// カテゴリ詳細を生成
  static List<CategoryDetail> _generateCategoryDetails(CategoryPopularityAnalysis analysis) {
    final details = <CategoryDetail>[];
    
    // 使用回数でソートしてランキングを作成
    final sortedEntries = analysis.categoryUsageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final category = entry.key;
      final usageCount = entry.value;
      
      if (usageCount == 0) continue; // 使用なしのカテゴリはスキップ
      
      final usageRate = analysis.getCategoryUsageRate(category);
      final averageUsagePerPrompt = analysis.averageUsagePerPrompt[category] ?? 0.0;
      final trend = analysis.trends?[category];
      
      details.add(CategoryDetail(
        category: category,
        usageCount: usageCount,
        usageRate: usageRate,
        rank: i + 1,
        averageUsagePerPrompt: averageUsagePerPrompt,
        trend: trend,
      ));
    }
    
    return details;
  }

  /// トレンド要約を生成
  static TrendSummary _generateTrendSummary(Map<PromptCategory, CategoryTrend> trends) {
    int growingCategories = 0;
    int decliningCategories = 0;
    int stableCategories = 0;
    
    PromptCategory? fastestGrowingCategory;
    double maxGrowthRate = 0.0;
    PromptCategory? fastestDecliningCategory;
    double maxDeclineRate = 0.0;
    
    for (final entry in trends.entries) {
      final category = entry.key;
      final trend = entry.value;
      
      switch (trend.direction) {
        case TrendDirection.increasing:
          growingCategories++;
          if (trend.changeRate > maxGrowthRate) {
            maxGrowthRate = trend.changeRate;
            fastestGrowingCategory = category;
          }
          break;
        case TrendDirection.decreasing:
          decliningCategories++;
          if (trend.changeRate < maxDeclineRate) {
            maxDeclineRate = trend.changeRate;
            fastestDecliningCategory = category;
          }
          break;
        case TrendDirection.stable:
          stableCategories++;
          break;
      }
    }
    
    return TrendSummary(
      growingCategories: growingCategories,
      decliningCategories: decliningCategories,
      stableCategories: stableCategories,
      fastestGrowingCategory: fastestGrowingCategory,
      maxGrowthRate: maxGrowthRate,
      fastestDecliningCategory: fastestDecliningCategory,
      maxDeclineRate: maxDeclineRate,
    );
  }

  /// 不平等指数を計算（ジニ係数風）
  static double _calculateInequalityIndex(List<double> sortedValues) {
    if (sortedValues.isEmpty) return 0.0;
    
    final n = sortedValues.length;
    double sum = 0.0;
    
    for (int i = 0; i < n; i++) {
      sum += (2 * (i + 1) - n - 1) * sortedValues[i];
    }
    
    final totalSum = sortedValues.fold<double>(0.0, (a, b) => a + b);
    if (totalSum == 0.0) return 0.0;
    
    return sum / (n * totalSum);
  }

  /// 簡易サマリーテキストを生成
  /// 
  /// [analysis] 分析結果
  /// 戻り値: 簡易サマリー文字列
  static String generateQuickSummary(CategoryPopularityAnalysis analysis) {
    final totalUsage = analysis.categoryUsageCount.values
        .fold<int>(0, (sum, count) => sum + count);
    
    if (totalUsage == 0) {
      return 'まだプロンプトの使用履歴がありません。';
    }
    
    final activeCategories = analysis.categoryUsageCount.values
        .where((count) => count > 0).length;
    
    String summary = '$totalUsage回のプロンプト使用で$activeCategoriesカテゴリが活用されています。';
    
    if (analysis.mostPopularCategory != null) {
      final popularCategory = analysis.mostPopularCategory!;
      final usageRate = analysis.getCategoryUsageRate(popularCategory);
      summary += '最も人気は「${popularCategory.displayName}」で${(usageRate * 100).toStringAsFixed(0)}%の使用率です。';
    }
    
    return summary;
  }

  /// カテゴリの使用状況をランキング形式で取得
  /// 
  /// [analysis] 分析結果
  /// [topN] 上位何位まで取得するか（デフォルト: 5）
  /// 戻り値: ランキングリスト
  static List<CategoryRankingItem> getCategoryRanking({
    required CategoryPopularityAnalysis analysis,
    int topN = 5,
  }) {
    final sortedEntries = analysis.categoryUsageCount.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final ranking = <CategoryRankingItem>[];
    final takeCount = topN < sortedEntries.length ? topN : sortedEntries.length;
    
    for (int i = 0; i < takeCount; i++) {
      final entry = sortedEntries[i];
      final usageRate = analysis.getCategoryUsageRate(entry.key);
      final averageUsage = analysis.averageUsagePerPrompt[entry.key] ?? 0.0;
      
      ranking.add(CategoryRankingItem(
        rank: i + 1,
        category: entry.key,
        usageCount: entry.value,
        usageRate: usageRate,
        averageUsagePerPrompt: averageUsage,
      ));
    }
    
    return ranking;
  }
}

/// カテゴリランキング項目
class CategoryRankingItem {
  /// ランキング順位
  final int rank;
  
  /// カテゴリ
  final PromptCategory category;
  
  /// 使用回数
  final int usageCount;
  
  /// 使用率
  final double usageRate;
  
  /// プロンプトあたり平均使用回数
  final double averageUsagePerPrompt;

  const CategoryRankingItem({
    required this.rank,
    required this.category,
    required this.usageCount,
    required this.usageRate,
    required this.averageUsagePerPrompt,
  });

  @override
  String toString() {
    return '$rank位: ${category.displayName} - $usageCount回 '
           '(${(usageRate * 100).toStringAsFixed(1)}%)';
  }
}