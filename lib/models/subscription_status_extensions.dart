import 'plans/plan.dart';
import 'plans/plan_factory.dart';
import 'subscription_status.dart';

/// SubscriptionStatusの拡張メソッド
/// 新しいPlanクラスとの統合機能を提供します
extension SubscriptionStatusExtensions on SubscriptionStatus {
  /// 現在のプランをPlanクラスとして取得
  Plan get plan => PlanFactory.createPlan(planId);

  /// 現在のプランをPlanクラスとして安全に取得（エラー時はnull）
  Plan? get planOrNull => PlanFactory.tryCreatePlan(planId);

  /// プランが有効かどうかを確認
  bool get hasPlan => PlanFactory.isValidPlanId(planId);

  /// プランの表示名を取得
  String get planDisplayName => plan.displayName;

  /// プランの価格を取得
  int get planPrice => plan.price;

  /// プランの月間AI生成制限を取得
  int get planMonthlyLimit => plan.monthlyAiGenerationLimit;

  /// プランがプレミアムかどうか
  bool get isPremiumPlan => plan.isPremium;

  /// 残りAI生成回数を取得
  int get remainingAiGenerations {
    final limit = plan.monthlyAiGenerationLimit;
    final usage = monthlyUsageCount;
    return (limit - usage).clamp(0, limit);
  }

  /// 使用率を取得（0.0〜1.0）
  double get usageRate {
    final limit = plan.monthlyAiGenerationLimit;
    if (limit <= 0) return 0.0;
    return monthlyUsageCount / limit;
  }

  /// 使用率が高いかどうか（80%以上）
  bool get isHighUsage => usageRate >= 0.8;

  /// 使用制限に達しているかどうか
  bool get hasReachedLimit => remainingAiGenerations <= 0;

  /// プランの機能にアクセスできるかどうかをチェック
  bool canAccessFeature(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'writing_prompts':
      case 'writingprompts':
        return plan.hasWritingPrompts;
      case 'advanced_filters':
      case 'advancedfilters':
        return plan.hasAdvancedFilters;
      case 'advanced_analytics':
      case 'advancedanalytics':
        return plan.hasAdvancedAnalytics;
      case 'priority_support':
      case 'prioritysupport':
        return plan.hasPrioritySupport;
      default:
        return false;
    }
  }

  /// プランのアップグレードが推奨されるかどうか
  bool get shouldRecommendUpgrade {
    // Basicプランで使用率が50%以上の場合
    if (!isPremiumPlan && usageRate >= 0.5) return true;
    // 使用制限に達している場合
    if (hasReachedLimit) return true;
    return false;
  }

  /// 次のリセット日までの日数
  int get daysUntilReset {
    final now = DateTime.now();
    return nextResetDate.difference(now).inDays;
  }

  /// デバッグ用の詳細情報を取得
  Map<String, dynamic> toDebugMap() {
    return {
      'planId': planId,
      'planName': planDisplayName,
      'isPremium': isPremiumPlan,
      'isActive': isActive,
      'monthlyUsage': monthlyUsageCount,
      'monthlyLimit': planMonthlyLimit,
      'remaining': remainingAiGenerations,
      'usageRate': '${(usageRate * 100).toStringAsFixed(1)}%',
      'expiryDate': expiryDate?.toIso8601String(),
      'nextResetDate': nextResetDate.toIso8601String(),
      'autoRenewal': autoRenewal,
    };
  }
}
