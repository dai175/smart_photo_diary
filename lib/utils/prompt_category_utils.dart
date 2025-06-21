// プロンプトカテゴリユーティリティクラス
//
// カテゴリ仕様に基づいたプロンプト管理、フィルタリング、
// 統計分析等の機能を提供します。

import 'package:flutter/material.dart';
import '../models/writing_prompt.dart';
import '../ui/design_system/app_colors.dart';

/// プロンプトカテゴリユーティリティ
class PromptCategoryUtils {
  /// プラン別に利用可能なカテゴリを取得（感情深掘り型対応）
  ///
  /// [isPremium] Premium プランかどうか
  /// 戻り値: 利用可能なカテゴリリスト
  static List<PromptCategory> getAvailableCategories({
    required bool isPremium,
  }) {
    if (isPremium) {
      // Premiumは全感情深掘り型カテゴリ利用可能
      return [
        PromptCategory.emotion, // 基本感情（Basic用）
        PromptCategory.emotionDepth, // 感情深掘り
        PromptCategory.sensoryEmotion, // 感情五感
        PromptCategory.emotionGrowth, // 感情成長
        PromptCategory.emotionConnection, // 感情つながり
        PromptCategory.emotionDiscovery, // 感情発見
        PromptCategory.emotionFantasy, // 感情幻想
        PromptCategory.emotionHealing, // 感情癒し
        PromptCategory.emotionEnergy, // 感情エネルギー
      ];
    } else {
      // Basicは基本感情カテゴリのみ
      return [
        PromptCategory.emotion, // 基本感情
      ];
    }
  }

  /// カテゴリがBasicプランで利用可能かチェック（感情深掘り型対応）
  ///
  /// [category] チェック対象のカテゴリ
  /// 戻り値: Basicプランで利用可能かどうか
  static bool isBasicAvailable(PromptCategory category) {
    switch (category) {
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return true; // 基本感情はBasic利用可能
      case PromptCategory.emotionDepth:
      case PromptCategory.sensoryEmotion:
      case PromptCategory.emotionGrowth:
      case PromptCategory.emotionConnection:
      case PromptCategory.emotionDiscovery:
      case PromptCategory.emotionFantasy:
      case PromptCategory.emotionHealing:
      case PromptCategory.emotionEnergy:
        return false; // Premium感情カテゴリはBasic利用不可
    }
  }

  /// カテゴリの基本プロンプト数を取得
  ///
  /// [category] 対象カテゴリ
  /// 戻り値: Basicプラン用プロンプト数
  static int getBasicPromptCount(PromptCategory category) {
    switch (category) {
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return 5; // Basic感情カテゴリ
      case PromptCategory.emotionDepth:
      case PromptCategory.sensoryEmotion:
      case PromptCategory.emotionGrowth:
      case PromptCategory.emotionConnection:
      case PromptCategory.emotionDiscovery:
      case PromptCategory.emotionFantasy:
      case PromptCategory.emotionHealing:
      case PromptCategory.emotionEnergy:
        return 0; // Premium専用カテゴリ
    }
  }

  /// カテゴリのPremiumプロンプト数を取得
  ///
  /// [category] 対象カテゴリ
  /// 戻り値: Premium追加プロンプト数
  static int getPremiumPromptCount(PromptCategory category) {
    switch (category) {
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return 0; // Basic専用カテゴリ
      case PromptCategory.emotionDepth:
      case PromptCategory.sensoryEmotion:
      case PromptCategory.emotionGrowth:
      case PromptCategory.emotionConnection:
      case PromptCategory.emotionDiscovery:
      case PromptCategory.emotionHealing:
      case PromptCategory.emotionEnergy:
        return 2; // 各2個のPremiumプロンプト
      case PromptCategory.emotionFantasy:
        return 1; // 1個のPremiumプロンプト
    }
  }

  /// カテゴリの総プロンプト数を取得
  ///
  /// [category] 対象カテゴリ
  /// [isPremium] Premiumプランかどうか
  /// 戻り値: プラン別総プロンプト数
  static int getTotalPromptCount(
    PromptCategory category, {
    required bool isPremium,
  }) {
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
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return '基本的な感情や気持ちを探るプロンプト';
      case PromptCategory.emotionDepth:
        return '感情の奥深くを掘り下げるプロンプト';
      case PromptCategory.sensoryEmotion:
        return '五感を通じて感情を表現するプロンプト';
      case PromptCategory.emotionGrowth:
        return '感情的成長を促すプロンプト';
      case PromptCategory.emotionConnection:
        return '人とのつながりを感じるプロンプト';
      case PromptCategory.emotionDiscovery:
        return '新しい感情を発見するプロンプト';
      case PromptCategory.emotionFantasy:
        return '想像力を使った感情表現プロンプト';
      case PromptCategory.emotionHealing:
        return '心の癒しを求めるプロンプト';
      case PromptCategory.emotionEnergy:
        return 'エネルギーや活力を感じるプロンプト';
    }
  }

  /// カテゴリの推奨タグを取得
  ///
  /// [category] 対象カテゴリ
  /// 戻り値: 推奨タグリスト
  static List<String> getRecommendedTags(PromptCategory category) {
    switch (category) {
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return ['感情', '気持ち', '心', '印象'];
      case PromptCategory.emotionDepth:
        return ['感情深掘り', '深掘り', '背景', '変化'];
      case PromptCategory.sensoryEmotion:
        return ['感情五感', '五感', '音', 'におい', '空気感'];
      case PromptCategory.emotionGrowth:
        return ['感情成長', '成長', '発展', '進歩'];
      case PromptCategory.emotionConnection:
        return ['感情つながり', 'つながり', '絆', '関係'];
      case PromptCategory.emotionDiscovery:
        return ['感情発見', '発見', '気づき', '新しい視点'];
      case PromptCategory.emotionFantasy:
        return ['感情幻想', '想像', '創造', 'ファンタジー'];
      case PromptCategory.emotionHealing:
        return ['感情癒し', '癒し', '平安', '安らぎ'];
      case PromptCategory.emotionEnergy:
        return ['感情エネルギー', 'エネルギー', '活力', '生命力'];
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
      final categoryPrompts = prompts
          .where((p) => p.category == category)
          .toList();
      final basicPrompts = categoryPrompts
          .where((p) => !p.isPremiumOnly)
          .length;
      final premiumPrompts = categoryPrompts
          .where((p) => p.isPremiumOnly)
          .length;

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
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return ['感情の認識向上', '自己理解の深化', '心の整理'];
      case PromptCategory.emotionDepth:
        return ['感情の深い洞察', '内面の成長', '心の平穏'];
      case PromptCategory.sensoryEmotion:
        return ['五感の鋭敏化', '感覚的記憶の向上', '豊かな表現力'];
      case PromptCategory.emotionGrowth:
        return ['精神的成長', 'ストレス解消', '前向きな思考'];
      case PromptCategory.emotionConnection:
        return ['人間関係の改善', '共感力の向上', '絆の深化'];
      case PromptCategory.emotionDiscovery:
        return ['新しい視点の獲得', '創造性の向上', '自己発見'];
      case PromptCategory.emotionFantasy:
        return ['想像力の発達', '創造的思考', '心の解放'];
      case PromptCategory.emotionHealing:
        return ['心の癒し', 'リラクゼーション', '内面の平和'];
      case PromptCategory.emotionEnergy:
        return ['活力の向上', 'モチベーション増加', 'ポジティブ思考'];
    }
  }

  /// カテゴリの表示名を取得
  ///
  /// [category] 対象カテゴリ
  /// 戻り値: カテゴリの日本語表示名
  static String getCategoryDisplayName(PromptCategory category) {
    return category.displayName;
  }

  /// カテゴリの色を取得
  ///
  /// [category] 対象カテゴリ
  /// 戻り値: カテゴリに対応する色
  static Color getCategoryColor(PromptCategory category) {
    switch (category) {
      // 感情深掘り型カテゴリ
      case PromptCategory.emotion:
        return AppColors.primary;
      case PromptCategory.emotionDepth:
        return const Color(0xFF673AB7); // Deep Purple
      case PromptCategory.sensoryEmotion:
        return const Color(0xFF009688); // Teal
      case PromptCategory.emotionGrowth:
        return const Color(0xFF4CAF50); // Green
      case PromptCategory.emotionConnection:
        return const Color(0xFFE91E63); // Pink
      case PromptCategory.emotionDiscovery:
        return const Color(0xFF2196F3); // Blue
      case PromptCategory.emotionFantasy:
        return const Color(0xFF9C27B0); // Purple
      case PromptCategory.emotionHealing:
        return const Color(0xFF00BCD4); // Cyan
      case PromptCategory.emotionEnergy:
        return const Color(0xFFFF9800); // Orange
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
    // 感情深掘り型カテゴリ
    PromptCategory.emotion: 1.0, // 基本感情（最も頻繁）
    PromptCategory.emotionDepth: 0.8, // 感情深掘り（高頻度）
    PromptCategory.sensoryEmotion: 0.7, // 感情五感（やや高頻度）
    PromptCategory.emotionGrowth: 0.6, // 感情成長（中頻度）
    PromptCategory.emotionConnection: 0.6, // 感情つながり（中頻度）
    PromptCategory.emotionDiscovery: 0.5, // 感情発見（中低頻度）
    PromptCategory.emotionFantasy: 0.3, // 感情幻想（低頻度）
    PromptCategory.emotionHealing: 0.7, // 感情癒し（やや高頻度）
    PromptCategory.emotionEnergy: 0.6, // 感情エネルギー（中頻度）
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
    if (daysInceLastUse <= 3) return 0.5; // 3日以内
    if (daysInceLastUse <= 7) return 0.8; // 1週間以内
    return 1.0; // 1週間以上
  }
}
