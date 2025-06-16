// プロンプトカテゴリユーティリティクラス
// 
// カテゴリ仕様に基づいたプロンプト管理、フィルタリング、
// 統計分析等の機能を提供します。

import '../models/writing_prompt.dart';
import '../constants/prompt_categories.dart';

/// プロンプトカテゴリユーティリティ
class PromptCategoryUtils {
  /// プラン別に利用可能なカテゴリを取得
  /// 
  /// [isPremium] Premium プランかどうか
  /// 戻り値: 利用可能なカテゴリリスト
  static List<PromptCategory> getAvailableCategories({required bool isPremium}) {
    if (isPremium) {
      // Premiumは全カテゴリ利用可能
      return PromptCategory.values;
    } else {
      // Basicは限定カテゴリのみ
      return [
        PromptCategory.daily,     // 日常（基本）
        PromptCategory.gratitude, // 感謝（一部）
      ];
    }
  }
  
  /// カテゴリがBasicプランで利用可能かチェック
  /// 
  /// [category] チェック対象のカテゴリ
  /// 戻り値: Basicプランで利用可能かどうか
  static bool isBasicAvailable(PromptCategory category) {
    switch (category) {
      case PromptCategory.daily:
        return PromptCategorySpecs.dailyCategory.isBasicAvailable;
      case PromptCategory.gratitude:
        return PromptCategorySpecs.gratitudeCategory.isBasicAvailable;
      case PromptCategory.travel:
        return PromptCategorySpecs.travelCategory.isBasicAvailable;
      case PromptCategory.work:
        return PromptCategorySpecs.workCategory.isBasicAvailable;
      case PromptCategory.reflection:
        return PromptCategorySpecs.reflectionCategory.isBasicAvailable;
      case PromptCategory.creative:
        return PromptCategorySpecs.creativeCategory.isBasicAvailable;
      case PromptCategory.wellness:
        return PromptCategorySpecs.wellnessCategory.isBasicAvailable;
      case PromptCategory.relationships:
        return PromptCategorySpecs.relationshipsCategory.isBasicAvailable;
    }
  }
  
  /// カテゴリの基本プロンプト数を取得
  /// 
  /// [category] 対象カテゴリ
  /// 戻り値: Basicプラン用プロンプト数
  static int getBasicPromptCount(PromptCategory category) {
    switch (category) {
      case PromptCategory.daily:
        return PromptCategorySpecs.dailyCategory.basicPromptCount;
      case PromptCategory.gratitude:
        return PromptCategorySpecs.gratitudeCategory.basicPromptCount;
      case PromptCategory.travel:
        return PromptCategorySpecs.travelCategory.basicPromptCount;
      case PromptCategory.work:
        return PromptCategorySpecs.workCategory.basicPromptCount;
      case PromptCategory.reflection:
        return PromptCategorySpecs.reflectionCategory.basicPromptCount;
      case PromptCategory.creative:
        return PromptCategorySpecs.creativeCategory.basicPromptCount;
      case PromptCategory.wellness:
        return PromptCategorySpecs.wellnessCategory.basicPromptCount;
      case PromptCategory.relationships:
        return PromptCategorySpecs.relationshipsCategory.basicPromptCount;
    }
  }
  
  /// カテゴリのPremiumプロンプト数を取得
  /// 
  /// [category] 対象カテゴリ
  /// 戻り値: Premium追加プロンプト数
  static int getPremiumPromptCount(PromptCategory category) {
    switch (category) {
      case PromptCategory.daily:
        return PromptCategorySpecs.dailyCategory.premiumPromptCount;
      case PromptCategory.gratitude:
        return PromptCategorySpecs.gratitudeCategory.premiumPromptCount;
      case PromptCategory.travel:
        return PromptCategorySpecs.travelCategory.premiumPromptCount;
      case PromptCategory.work:
        return PromptCategorySpecs.workCategory.premiumPromptCount;
      case PromptCategory.reflection:
        return PromptCategorySpecs.reflectionCategory.premiumPromptCount;
      case PromptCategory.creative:
        return PromptCategorySpecs.creativeCategory.premiumPromptCount;
      case PromptCategory.wellness:
        return PromptCategorySpecs.wellnessCategory.premiumPromptCount;
      case PromptCategory.relationships:
        return PromptCategorySpecs.relationshipsCategory.premiumPromptCount;
    }
  }
  
  /// カテゴリの総プロンプト数を取得
  /// 
  /// [category] 対象カテゴリ
  /// [isPremium] Premiumプランかどうか
  /// 戻り値: プラン別総プロンプト数
  static int getTotalPromptCount(PromptCategory category, {required bool isPremium}) {
    final basicCount = getBasicPromptCount(category);
    if (!isPremium) {
      return basicCount;
    }
    return basicCount + getPremiumPromptCount(category);
  }
  
  /// カテゴリの説明を取得
  /// 
  /// [category] 対象カテゴリ
  /// 戻り値: カテゴリの説明文
  static String getCategoryDescription(PromptCategory category) {
    switch (category) {
      case PromptCategory.daily:
        return PromptCategorySpecs.dailyCategory.description;
      case PromptCategory.travel:
        return PromptCategorySpecs.travelCategory.description;
      case PromptCategory.work:
        return PromptCategorySpecs.workCategory.description;
      case PromptCategory.gratitude:
        return PromptCategorySpecs.gratitudeCategory.description;
      case PromptCategory.reflection:
        return PromptCategorySpecs.reflectionCategory.description;
      case PromptCategory.creative:
        return PromptCategorySpecs.creativeCategory.description;
      case PromptCategory.wellness:
        return PromptCategorySpecs.wellnessCategory.description;
      case PromptCategory.relationships:
        return PromptCategorySpecs.relationshipsCategory.description;
    }
  }
  
  /// カテゴリの推奨タグを取得
  /// 
  /// [category] 対象カテゴリ
  /// 戻り値: 推奨タグリスト
  static List<String> getRecommendedTags(PromptCategory category) {
    switch (category) {
      case PromptCategory.daily:
        return PromptCategorySpecs.dailyCategory.recommendedTags;
      case PromptCategory.travel:
        return PromptCategorySpecs.travelCategory.recommendedTags;
      case PromptCategory.work:
        return PromptCategorySpecs.workCategory.recommendedTags;
      case PromptCategory.gratitude:
        return PromptCategorySpecs.gratitudeCategory.recommendedTags;
      case PromptCategory.reflection:
        return PromptCategorySpecs.reflectionCategory.recommendedTags;
      case PromptCategory.creative:
        return PromptCategorySpecs.creativeCategory.recommendedTags;
      case PromptCategory.wellness:
        return PromptCategorySpecs.wellnessCategory.recommendedTags;
      case PromptCategory.relationships:
        return PromptCategorySpecs.relationshipsCategory.recommendedTags;
    }
  }
  
  /// プロンプトリストをプラン別にフィルタリング
  /// 
  /// [prompts] 元のプロンプトリスト
  /// [isPremium] Premiumプランかどうか
  /// 戻り値: フィルタリング済みプロンプトリスト
  static List<WritingPrompt> filterPromptsByPlan(
    List<WritingPrompt> prompts, {
    required bool isPremium,
  }) {
    return prompts.where((prompt) {
      // 非アクティブなプロンプトを除外
      if (!prompt.isActive) return false;
      
      // カテゴリがプランで利用可能かチェック
      if (!isPremium && !isBasicAvailable(prompt.category)) {
        return false;
      }
      
      // プロンプト自体がプラン制限に適合するかチェック
      return prompt.isAvailableForPlan(isPremium: isPremium);
    }).toList();
  }
  
  /// カテゴリ別プロンプト統計を取得
  /// 
  /// [prompts] プロンプトリスト
  /// 戻り値: カテゴリ別統計情報
  static Map<PromptCategory, CategoryStats> getCategoryStats(
    List<WritingPrompt> prompts,
  ) {
    final stats = <PromptCategory, CategoryStats>{};
    
    for (final category in PromptCategory.values) {
      final categoryPrompts = prompts.where((p) => p.category == category).toList();
      final basicPrompts = categoryPrompts.where((p) => !p.isPremiumOnly).length;
      final premiumPrompts = categoryPrompts.where((p) => p.isPremiumOnly).length;
      
      stats[category] = CategoryStats(
        category: category,
        totalPrompts: categoryPrompts.length,
        basicPrompts: basicPrompts,
        premiumPrompts: premiumPrompts,
        isBasicAvailable: isBasicAvailable(category),
      );
    }
    
    return stats;
  }
  
  /// Premium限定カテゴリの一覧を取得
  /// 
  /// 戻り値: Premium限定カテゴリのリスト
  static List<PromptCategory> getPremiumOnlyCategories() {
    return PromptCategory.values
        .where((category) => !isBasicAvailable(category))
        .toList();
  }
  
  /// カテゴリの期待効果を取得
  /// 
  /// [category] 対象カテゴリ
  /// 戻り値: 期待効果のリスト
  static List<String> getExpectedBenefits(PromptCategory category) {
    switch (category) {
      case PromptCategory.daily:
        return PromptCategorySpecs.dailyCategory.expectedBenefits;
      case PromptCategory.travel:
        return PromptCategorySpecs.travelCategory.expectedBenefits;
      case PromptCategory.work:
        return PromptCategorySpecs.workCategory.expectedBenefits;
      case PromptCategory.gratitude:
        return PromptCategorySpecs.gratitudeCategory.expectedBenefits;
      case PromptCategory.reflection:
        return PromptCategorySpecs.reflectionCategory.expectedBenefits;
      case PromptCategory.creative:
        return PromptCategorySpecs.creativeCategory.expectedBenefits;
      case PromptCategory.wellness:
        return PromptCategorySpecs.wellnessCategory.expectedBenefits;
      case PromptCategory.relationships:
        return PromptCategorySpecs.relationshipsCategory.expectedBenefits;
    }
  }
}

/// カテゴリ別統計情報
class CategoryStats {
  final PromptCategory category;
  final int totalPrompts;
  final int basicPrompts;
  final int premiumPrompts;
  final bool isBasicAvailable;
  
  const CategoryStats({
    required this.category,
    required this.totalPrompts,
    required this.basicPrompts,
    required this.premiumPrompts,
    required this.isBasicAvailable,
  });
  
  /// カテゴリ名を取得
  String get categoryName => category.displayName;
  
  /// Premium専用プロンプトの割合
  double get premiumRatio {
    if (totalPrompts == 0) return 0.0;
    return premiumPrompts / totalPrompts;
  }
  
  /// Basicプランでの利用可能率
  double get basicAvailability {
    if (totalPrompts == 0) return 0.0;
    return basicPrompts / totalPrompts;
  }
  
  @override
  String toString() {
    return 'CategoryStats(category: $categoryName, total: $totalPrompts, '
           'basic: $basicPrompts, premium: $premiumPrompts, '
           'basicAvailable: $isBasicAvailable)';
  }
}

/// プロンプト選択の重み付け設定
class PromptWeightConfig {
  /// カテゴリ別の基本重み（デフォルト選択確率）
  static const Map<PromptCategory, double> categoryWeights = {
    PromptCategory.daily: 1.0,        // 標準（最も頻繁に使用される）
    PromptCategory.gratitude: 0.8,    // やや高頻度
    PromptCategory.reflection: 0.6,   // 中頻度
    PromptCategory.travel: 0.4,       // 低頻度（旅行時のみ）
    PromptCategory.work: 0.5,         // 中低頻度（平日中心）
    PromptCategory.creative: 0.3,     // 低頻度（特別な時）
    PromptCategory.wellness: 0.7,     // やや高頻度（健康意識向上）
    PromptCategory.relationships: 0.6, // 中頻度（人間関係重視）
  };
  
  /// プロンプト優先度による重み調整
  static double getPriorityWeight(int priority) {
    if (priority >= 80) return 1.2; // 高優先度
    if (priority >= 50) return 1.0; // 標準優先度
    return 0.8; // 低優先度
  }
  
  /// 最近の使用履歴による重み調整（使用頻度を下げる）
  static double getRecencyWeight(int daysInceLastUse) {
    if (daysInceLastUse == 0) return 0.1; // 今日使用済み
    if (daysInceLastUse <= 3) return 0.5;  // 3日以内
    if (daysInceLastUse <= 7) return 0.8;  // 1週間以内
    return 1.0; // 1週間以上
  }
}