import 'plans/plan.dart';
import 'plans/plan_factory.dart';
import 'subscription_plan.dart';
import 'subscription_status.dart';
import 'subscription_info.dart';

/// サブスクリプション情報を統合的に管理するデータモデル（新Planクラス版）
/// 設定画面や状態表示で使用するための包括的な情報を提供します
///
/// 既存のSubscriptionInfoとの互換性を保ちながら、
/// 新しいPlanクラスを使用した実装を提供します。
class SubscriptionInfoV2 {
  /// 現在のプラン（新Planクラス）
  final Plan currentPlan;

  /// サブスクリプション状態
  final SubscriptionStatus status;

  /// 使用量統計
  final UsageStatistics usageStats;

  /// プラン期限情報
  final PlanPeriodInfo periodInfo;

  /// 自動更新情報
  final AutoRenewalInfo autoRenewalInfo;

  const SubscriptionInfoV2({
    required this.currentPlan,
    required this.status,
    required this.usageStats,
    required this.periodInfo,
    required this.autoRenewalInfo,
  });

  /// ファクトリコンストラクタ - SubscriptionStatusから構築
  factory SubscriptionInfoV2.fromStatus(SubscriptionStatus status) {
    final plan = PlanFactory.createPlan(status.planId);
    // 互換性のため、一時的にSubscriptionPlanに変換
    final subscriptionPlan = SubscriptionPlan.fromId(status.planId);

    return SubscriptionInfoV2(
      currentPlan: plan,
      status: status,
      usageStats: UsageStatistics.fromStatus(status, subscriptionPlan),
      periodInfo: PlanPeriodInfo.fromStatus(status, subscriptionPlan),
      autoRenewalInfo: AutoRenewalInfo.fromStatus(status),
    );
  }

  /// SubscriptionStatusとPlanから構築
  factory SubscriptionInfoV2.fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    // 互換性のため、一時的にSubscriptionPlanに変換
    final subscriptionPlan = SubscriptionPlan.fromId(plan.id);

    return SubscriptionInfoV2(
      currentPlan: plan,
      status: status,
      usageStats: UsageStatistics.fromStatus(status, subscriptionPlan),
      periodInfo: PlanPeriodInfo.fromStatus(status, subscriptionPlan),
      autoRenewalInfo: AutoRenewalInfo.fromStatus(status),
    );
  }

  /// 既存のSubscriptionInfoから変換
  factory SubscriptionInfoV2.fromLegacy(SubscriptionInfo info) {
    final plan = PlanFactory.createPlan(info.currentPlan.id);

    return SubscriptionInfoV2(
      currentPlan: plan,
      status: info.status,
      usageStats: info.usageStats,
      periodInfo: info.periodInfo,
      autoRenewalInfo: info.autoRenewalInfo,
    );
  }

  /// 現在のプランがアクティブかどうか
  bool get isActive => status.isActive;

  /// Premiumプランかどうか
  bool get isPremium => currentPlan.isPremium;

  /// プランの表示名
  String get planDisplayName => currentPlan.displayName;

  /// プランの機能一覧
  List<String> get planFeatures => currentPlan.features;

  // ============================================================================
  // Phase 1.8.2.4: UI用データフォーマット実装
  // ============================================================================

  /// 設定画面用のプラン状態表示文字列（問題がある場合のみ表示）
  String? get planStatusDisplay {
    if (!isActive) return '無効';
    if (isPremium && periodInfo.isExpiryNear) return '期限間近';
    return null; // 正常な状態では何も表示しない
  }

  /// 設定画面用の期限表示文字列
  String? get expiryDisplayText {
    if (periodInfo.expiryDate == null) return null;

    final expiry = periodInfo.expiryDate!;
    final daysUntil = periodInfo.daysUntilExpiry ?? 0;
    final now = DateTime.now();

    if (daysUntil <= 0) return '期限切れ';
    if (daysUntil <= 7) return '${expiry.month}/${expiry.day} (あと$daysUntil日)';

    // 年が異なる場合は年も表示
    if (expiry.year != now.year) {
      return '${expiry.year}/${expiry.month}/${expiry.day}';
    }

    return '${expiry.month}/${expiry.day}';
  }

  /// 設定画面用の自動更新状態表示
  String get autoRenewalDisplayText {
    if (!isPremium) return '対象外';
    return autoRenewalInfo.isAutoRenewalEnabled ? '有効' : '無効';
  }

  /// 設定画面用の使用量警告メッセージ
  String? get usageWarningMessage {
    if (usageStats.isNearLimit) {
      final remaining = usageStats.remainingCount;
      if (remaining == 0) return 'AI生成の制限に達しました';
      return 'AI生成の残り回数が$remaining回です';
    }
    return null;
  }

  /// 設定画面用のプラン推奨メッセージ
  String? get planRecommendationMessage {
    if (isPremium) return null;

    final usageRate = usageStats.usageRate;
    if (usageRate >= 0.8) {
      return 'Premiumプランにアップグレードすると月間${currentPlan.monthlyAiGenerationLimit}回まで利用できます';
    }
    if (usageRate >= 0.5) {
      return 'より多くAI生成を利用される場合はPremiumプランがおすすめです';
    }
    return null;
  }

  /// 設定画面用のリセット日表示
  String get resetDateDisplayText {
    final resetDate = status.nextResetDate;
    final today = DateTime.now();
    final daysUntilReset = resetDate.difference(today).inDays;

    if (daysUntilReset <= 0) return '今日';
    if (daysUntilReset == 1) return '明日';
    if (daysUntilReset <= 7) {
      return '${resetDate.month}/${resetDate.day} (あと$daysUntilReset日)';
    }
    return '${resetDate.month}/${resetDate.day}';
  }

  /// 設定画面表示用の統合データ
  SubscriptionDisplayData get displayData => SubscriptionDisplayData(
    planName: planDisplayName,
    planStatus: planStatusDisplay,
    usageText: usageStats.usageDisplay,
    remainingText: '${usageStats.remainingCount}回',
    resetDateText: resetDateDisplayText,
    expiryText: expiryDisplayText,
    autoRenewalText: autoRenewalDisplayText,
    warningMessage: usageWarningMessage,
    recommendationMessage: planRecommendationMessage,
    showUpgradeButton: !isPremium,
    usageProgressValue: usageStats.usageRate,
    isNearLimit: usageStats.isNearLimit,
    isExpiryNear: periodInfo.isExpiryNear,
  );

  /// 既存のSubscriptionInfoに変換（後方互換性用）
  SubscriptionInfo toLegacy() {
    final subscriptionPlan = SubscriptionPlan.fromId(currentPlan.id);

    return SubscriptionInfo(
      currentPlan: subscriptionPlan,
      status: status,
      usageStats: usageStats,
      periodInfo: periodInfo,
      autoRenewalInfo: autoRenewalInfo,
    );
  }
}
