import 'plans/plan.dart';
import 'subscription_status.dart';
import 'subscription_info.dart';

/// SubscriptionInfoの拡張メソッド
/// 新しいPlanクラスを使用した機能を提供します
extension SubscriptionInfoExtensions on SubscriptionInfo {
  // 将来的な拡張用のプレースホルダー
}

/// UsageStatisticsの拡張メソッドとファクトリ
extension UsageStatisticsExtensions on UsageStatistics {
  /// Planクラスを使用してUsageStatisticsを作成
  static UsageStatistics fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    final usage = status.monthlyUsageCount;
    final limit = plan.monthlyAiGenerationLimit;
    final remaining = (limit - usage).clamp(0, limit);
    final rate = limit > 0 ? usage / limit : 0.0;

    return UsageStatistics(
      currentMonthUsage: usage,
      monthlyLimit: limit,
      remainingCount: remaining,
      usageRate: rate,
      isNearLimit: rate >= 0.8,
    );
  }
}

/// PlanPeriodInfoの拡張メソッドとファクトリ
extension PlanPeriodInfoExtensions on PlanPeriodInfo {
  /// Planクラスを使用してPlanPeriodInfoを作成
  static PlanPeriodInfo fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    final now = DateTime.now();
    final expiry = status.expiryDate;
    int? daysUntilExpiry;
    bool isExpiryNear = false;

    if (expiry != null) {
      daysUntilExpiry = expiry.difference(now).inDays;
      isExpiryNear = daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
    }

    return PlanPeriodInfo(
      startDate: status.startDate,
      expiryDate: expiry,
      nextRenewalDate: status.autoRenewal ? expiry : null,
      daysUntilExpiry: daysUntilExpiry,
      isExpiryNear: isExpiryNear,
    );
  }
}

/// 新しいPlanクラスを使用したUsageStatistics作成用ヘルパークラス
class UsageStatisticsV2 {
  /// Planクラスを使用してUsageStatisticsを作成
  static UsageStatistics fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    final usage = status.monthlyUsageCount;
    final limit = plan.monthlyAiGenerationLimit;
    final remaining = (limit - usage).clamp(0, limit);
    final rate = limit > 0 ? usage / limit : 0.0;

    return UsageStatistics(
      currentMonthUsage: usage,
      monthlyLimit: limit,
      remainingCount: remaining,
      usageRate: rate,
      isNearLimit: rate >= 0.8,
    );
  }
}

/// 新しいPlanクラスを使用したPlanPeriodInfo作成用ヘルパークラス
class PlanPeriodInfoV2 {
  /// Planクラスを使用してPlanPeriodInfoを作成
  static PlanPeriodInfo fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    final now = DateTime.now();
    final expiry = status.expiryDate;
    int? daysUntilExpiry;
    bool isExpiryNear = false;

    if (expiry != null) {
      daysUntilExpiry = expiry.difference(now).inDays;
      isExpiryNear = daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
    }

    return PlanPeriodInfo(
      startDate: status.startDate,
      expiryDate: expiry,
      nextRenewalDate: status.autoRenewal ? expiry : null,
      daysUntilExpiry: daysUntilExpiry,
      isExpiryNear: isExpiryNear,
    );
  }
}
