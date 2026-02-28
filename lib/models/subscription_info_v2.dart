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

  /// 使用状況の表示文字列（多言語化対応）
  String getLocalizedUsageDisplay(
    String Function(int used, int limit) formatter,
  ) {
    return formatter(monthlyUsageCount, monthlyLimit);
  }

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
      description =
          'Auto-renewal is enabled. Subscription will renew automatically before expiry.';
      managementUrl = 'https://apps.apple.com/account/subscriptions';
    } else {
      description =
          'Auto-renewal is disabled. Please renew manually before expiry.';
    }

    return AutoRenewalInfoV2(
      isAutoRenewalEnabled: status.autoRenewal,
      autoRenewalDescription: description,
      managementUrl: managementUrl,
    );
  }
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

  /// プランの表示名（多言語化対応）
  String getLocalizedPlanDisplayName(String locale) {
    // PlanFactoryで作られたプランのIDに基づいて適切な表示名を返す
    switch (currentPlan.id) {
      case 'basic':
        return 'Basic';
      case 'premium_monthly':
        return locale == 'ja' ? 'Premium（月額）' : 'Premium (monthly)';
      case 'premium_yearly':
        return locale == 'ja' ? 'Premium（年額）' : 'Premium (yearly)';
      default:
        return currentPlan.displayName; // フォールバック
    }
  }

  /// プランの機能一覧
  List<String> get planFeatures => currentPlan.features;

  /// 設定画面用の使用量警告メッセージ（多言語化対応）
  String? getLocalizedUsageWarningMessage(
    String Function() limitReachedFormatter,
    String Function(int remaining) remainingFormatter,
  ) {
    if (usageStats.isNearLimit) {
      final remaining = usageStats.remainingCount;
      if (remaining == 0) return limitReachedFormatter();
      return remainingFormatter(remaining);
    }
    return null;
  }

  /// 設定画面用のプラン推奨メッセージ（多言語化対応）
  String? getLocalizedPlanRecommendationMessage(
    String Function(int limit) limitFormatter,
    String Function() generalFormatter,
  ) {
    if (isPremium) return null;

    final usageRate = usageStats.usageRate;
    if (usageRate >= 0.8) {
      return limitFormatter(currentPlan.monthlyAiGenerationLimit);
    }
    if (usageRate >= 0.5) {
      return generalFormatter();
    }
    return null;
  }

  /// 設定画面表示用の統合データ（多言語化対応）
  SubscriptionDisplayDataV2 getLocalizedDisplayData({
    required String locale,
    required String Function(int used, int limit) usageFormatter,
    required String Function(int remaining) remainingFormatter,
    required String Function() limitReachedFormatter,
    required String Function(int remaining) warningRemainingFormatter,
    required String Function(int limit) upgradeRecommendationLimitFormatter,
    required String Function() upgradeRecommendationGeneralFormatter,
    required String expiredText,
    required String todayText,
    required String tomorrowText,
    required String inactiveStatusText,
    required String expiryNearStatusText,
    required String autoRenewalNotApplicableText,
    required String autoRenewalEnabledText,
    required String autoRenewalDisabledText,
  }) {
    // planStatus（ローカライズ版）
    String? localizedPlanStatus;
    if (!isActive) {
      localizedPlanStatus = inactiveStatusText;
    } else if (isPremium && periodInfo.isExpiryNear) {
      localizedPlanStatus = expiryNearStatusText;
    }

    // 日付計算用の正規化された「今日」
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // expiryText（ローカライズ版）
    String? localizedExpiryText;
    if (periodInfo.expiryDate != null) {
      final expiry = periodInfo.expiryDate!;
      final daysUntil = periodInfo.daysUntilExpiry ?? 0;
      if (daysUntil <= 0) {
        localizedExpiryText = expiredText;
      } else if (expiry.year != today.year) {
        localizedExpiryText = '${expiry.year}/${expiry.month}/${expiry.day}';
      } else {
        localizedExpiryText = '${expiry.month}/${expiry.day}';
      }
    }

    // autoRenewalText（ローカライズ版）
    String localizedAutoRenewalText;
    if (!isPremium) {
      localizedAutoRenewalText = autoRenewalNotApplicableText;
    } else {
      localizedAutoRenewalText = autoRenewalInfo.isAutoRenewalEnabled
          ? autoRenewalEnabledText
          : autoRenewalDisabledText;
    }

    // resetDateText（ローカライズ版）
    String localizedResetDateText;
    final resetDate = usageStats.nextResetDate;
    final daysUntilReset = resetDate.difference(today).inDays;
    if (daysUntilReset <= 0) {
      localizedResetDateText = todayText;
    } else if (daysUntilReset == 1) {
      localizedResetDateText = tomorrowText;
    } else if (resetDate.year != today.year) {
      localizedResetDateText =
          '${resetDate.year}/${resetDate.month}/${resetDate.day}';
    } else {
      localizedResetDateText = '${resetDate.month}/${resetDate.day}';
    }

    return SubscriptionDisplayDataV2(
      planName: getLocalizedPlanDisplayName(locale),
      planStatus: localizedPlanStatus,
      usageText: usageStats.getLocalizedUsageDisplay(usageFormatter),
      remainingText: remainingFormatter(usageStats.remainingCount),
      resetDateText: localizedResetDateText,
      expiryText: localizedExpiryText,
      autoRenewalText: localizedAutoRenewalText,
      warningMessage: getLocalizedUsageWarningMessage(
        limitReachedFormatter,
        warningRemainingFormatter,
      ),
      recommendationMessage: getLocalizedPlanRecommendationMessage(
        upgradeRecommendationLimitFormatter,
        upgradeRecommendationGeneralFormatter,
      ),
      showUpgradeButton: !isPremium,
      usageProgressValue: usageStats.usageRate,
      isNearLimit: usageStats.isNearLimit,
      isExpiryNear: periodInfo.isExpiryNear,
    );
  }
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
