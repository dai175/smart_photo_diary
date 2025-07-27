import 'plans/plan.dart';
import 'plans/plan_factory.dart';
import 'subscription_status.dart';

/// 使用統計情報（新Planクラス版）
class UsageStatisticsV2 {
  /// 今月の使用回数
  final int monthlyUsageCount;

  /// 月間制限回数
  final int monthlyLimit;

  /// 残り使用可能回数
  final int remainingCount;

  /// 次回リセット日
  final DateTime nextResetDate;

  /// 日平均制限
  final double dailyAverageLimit;

  const UsageStatisticsV2({
    required this.monthlyUsageCount,
    required this.monthlyLimit,
    required this.remainingCount,
    required this.nextResetDate,
    required this.dailyAverageLimit,
  });

  /// 使用率（0.0〜1.0）
  double get usageRate {
    if (monthlyLimit == 0) return 0.0;
    return monthlyUsageCount / monthlyLimit;
  }

  /// 制限に近づいているか（80%以上）
  bool get isNearLimit => usageRate >= 0.8 && remainingCount > 0;

  /// 使用状況の表示文字列
  String get usageDisplay => '$monthlyUsageCount / $monthlyLimit回';

  /// SubscriptionStatusとPlanから構築
  factory UsageStatisticsV2.fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    final monthlyLimit = plan.monthlyAiGenerationLimit;
    final remaining = monthlyLimit - status.monthlyUsageCount;
    final nextReset = _calculateNextResetDate(status.lastResetDate);

    return UsageStatisticsV2(
      monthlyUsageCount: status.monthlyUsageCount,
      monthlyLimit: monthlyLimit,
      remainingCount: remaining > 0 ? remaining : 0,
      nextResetDate: nextReset,
      dailyAverageLimit: plan.dailyAverageGenerations,
    );
  }

  /// 次のリセット日を計算
  static DateTime _calculateNextResetDate(DateTime? lastResetDate) {
    final baseDate = lastResetDate ?? DateTime.now();
    final currentYear = baseDate.year;
    final currentMonth = baseDate.month;

    if (currentMonth == 12) {
      return DateTime(currentYear + 1, 1, 1);
    } else {
      return DateTime(currentYear, currentMonth + 1, 1);
    }
  }
}

/// 自動更新情報（V2版）
class AutoRenewalInfoV2 {
  /// 自動更新が有効かどうか
  final bool isAutoRenewalEnabled;

  /// 自動更新の説明テキスト
  final String autoRenewalDescription;

  /// 自動更新管理のディープリンクURL（プラットフォーム別）
  final String? managementUrl;

  const AutoRenewalInfoV2({
    required this.isAutoRenewalEnabled,
    required this.autoRenewalDescription,
    required this.managementUrl,
  });

  /// ファクトリコンストラクタ
  factory AutoRenewalInfoV2.fromStatus(SubscriptionStatus status) {
    String description;
    String? managementUrl;

    if (status.autoRenewal) {
      description = '自動更新が有効です。期限前に自動的に更新されます。';
      managementUrl = 'https://apps.apple.com/account/subscriptions';
    } else {
      description = '自動更新は無効です。期限切れ前に手動で更新してください。';
    }

    return AutoRenewalInfoV2(
      isAutoRenewalEnabled: status.autoRenewal,
      autoRenewalDescription: description,
      managementUrl: managementUrl,
    );
  }

  /// 自動更新状態の表示テキスト
  String get statusDisplay => isAutoRenewalEnabled ? '有効' : '無効';
}

/// プラン期限情報（新Planクラス版）
class PlanPeriodInfoV2 {
  /// 開始日
  final DateTime? startDate;

  /// 有効期限
  final DateTime? expiryDate;

  /// 自動更新有無
  final bool autoRenewal;

  /// 期限切れまでの日数
  final int? daysUntilExpiry;

  /// 期限が近いかどうか（7日以内）
  final bool isExpiryNear;

  /// 期限切れかどうか
  final bool isExpired;

  const PlanPeriodInfoV2({
    required this.startDate,
    required this.expiryDate,
    required this.autoRenewal,
    required this.daysUntilExpiry,
    required this.isExpiryNear,
    required this.isExpired,
  });

  /// SubscriptionStatusとPlanから構築
  factory PlanPeriodInfoV2.fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    final now = DateTime.now();
    int? daysUntilExpiry;
    bool isExpiryNear = false;
    bool isExpired = false;

    if (status.expiryDate != null) {
      final difference = status.expiryDate!.difference(now);
      daysUntilExpiry = difference.inDays;
      isExpiryNear = daysUntilExpiry <= 7 && daysUntilExpiry > 0;
      isExpired = daysUntilExpiry < 0;
    }

    return PlanPeriodInfoV2(
      startDate: status.startDate,
      expiryDate: status.expiryDate,
      autoRenewal: status.autoRenewal == true,
      daysUntilExpiry: daysUntilExpiry,
      isExpiryNear: isExpiryNear,
      isExpired: isExpired,
    );
  }
}

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
  final UsageStatisticsV2 usageStats;

  /// プラン期限情報
  final PlanPeriodInfoV2 periodInfo;

  /// 自動更新情報
  final AutoRenewalInfoV2 autoRenewalInfo;

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

    return SubscriptionInfoV2(
      currentPlan: plan,
      status: status,
      usageStats: UsageStatisticsV2.fromStatusAndPlan(status, plan),
      periodInfo: PlanPeriodInfoV2.fromStatusAndPlan(status, plan),
      autoRenewalInfo: AutoRenewalInfoV2.fromStatus(status),
    );
  }

  /// SubscriptionStatusとPlanから構築
  factory SubscriptionInfoV2.fromStatusAndPlan(
    SubscriptionStatus status,
    Plan plan,
  ) {
    return SubscriptionInfoV2(
      currentPlan: plan,
      status: status,
      usageStats: UsageStatisticsV2.fromStatusAndPlan(status, plan),
      periodInfo: PlanPeriodInfoV2.fromStatusAndPlan(status, plan),
      autoRenewalInfo: AutoRenewalInfoV2.fromStatus(status),
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
    final resetDate = usageStats.nextResetDate;
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
  SubscriptionDisplayDataV2 get displayData => SubscriptionDisplayDataV2(
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

}

/// 設定画面表示用のデータクラス（V2版）
class SubscriptionDisplayDataV2 {
  final String planName;
  final String? planStatus;
  final String usageText;
  final String remainingText;
  final String resetDateText;
  final String? expiryText;
  final String autoRenewalText;
  final String? warningMessage;
  final String? recommendationMessage;
  final bool showUpgradeButton;
  final double usageProgressValue;
  final bool isNearLimit;
  final bool isExpiryNear;

  const SubscriptionDisplayDataV2({
    required this.planName,
    required this.planStatus,
    required this.usageText,
    required this.remainingText,
    required this.resetDateText,
    required this.expiryText,
    required this.autoRenewalText,
    required this.warningMessage,
    required this.recommendationMessage,
    required this.showUpgradeButton,
    required this.usageProgressValue,
    required this.isNearLimit,
    required this.isExpiryNear,
  });
}
