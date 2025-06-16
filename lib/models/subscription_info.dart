import 'subscription_plan.dart';
import 'subscription_status.dart';

/// サブスクリプション情報を統合的に管理するデータモデル
/// 設定画面や状態表示で使用するための包括的な情報を提供します

/// 設定画面表示用のサブスクリプション情報
class SubscriptionInfo {
  /// 現在のプラン
  final SubscriptionPlan currentPlan;
  
  /// サブスクリプション状態
  final SubscriptionStatus status;
  
  /// 使用量統計
  final UsageStatistics usageStats;
  
  /// プラン期限情報
  final PlanPeriodInfo periodInfo;
  
  /// 自動更新情報
  final AutoRenewalInfo autoRenewalInfo;

  const SubscriptionInfo({
    required this.currentPlan,
    required this.status,
    required this.usageStats,
    required this.periodInfo,
    required this.autoRenewalInfo,
  });

  /// ファクトリコンストラクタ - SubscriptionStatusから構築
  factory SubscriptionInfo.fromStatus(SubscriptionStatus status) {
    final plan = SubscriptionPlan.fromId(status.planId);
    
    return SubscriptionInfo(
      currentPlan: plan,
      status: status,
      usageStats: UsageStatistics.fromStatus(status, plan),
      periodInfo: PlanPeriodInfo.fromStatus(status, plan),
      autoRenewalInfo: AutoRenewalInfo.fromStatus(status),
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
    
    if (daysUntil <= 0) return '期限切れ';
    if (daysUntil <= 7) return '${expiry.month}/${expiry.day} (あと$daysUntil日)';
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
      return 'Premiumプランにアップグレードすると月間100回まで利用できます';
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
    if (daysUntilReset <= 7) return '${resetDate.month}/${resetDate.day} (あと$daysUntilReset日)';
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
}

/// 使用量統計情報
class UsageStatistics {
  /// 今月の使用回数
  final int currentMonthUsage;
  
  /// 月間制限回数
  final int monthlyLimit;
  
  /// 残り使用可能回数
  final int remainingCount;
  
  /// 使用率（0.0 - 1.0）
  final double usageRate;
  
  /// 制限に近いかどうか（80%以上で警告）
  final bool isNearLimit;

  const UsageStatistics({
    required this.currentMonthUsage,
    required this.monthlyLimit,
    required this.remainingCount,
    required this.usageRate,
    required this.isNearLimit,
  });

  /// ファクトリコンストラクタ
  factory UsageStatistics.fromStatus(SubscriptionStatus status, SubscriptionPlan plan) {
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

  /// 使用率の表示用文字列（例: "70%"）
  String get usageRateDisplay => '${(usageRate * 100).round()}%';
  
  /// 使用状況の表示用文字列（例: "7/10回"）
  String get usageDisplay => '$currentMonthUsage/$monthlyLimit回';
}

/// プラン期限情報
class PlanPeriodInfo {
  /// 購入開始日
  final DateTime? startDate;
  
  /// プラン有効期限（Basicプランの場合はnull）
  final DateTime? expiryDate;
  
  /// 次回更新日（自動更新の場合）
  final DateTime? nextRenewalDate;
  
  /// 期限切れまでの日数（有効期限がある場合）
  final int? daysUntilExpiry;
  
  /// 期限が近いかどうか（7日以内で警告）
  final bool isExpiryNear;

  const PlanPeriodInfo({
    required this.startDate,
    required this.expiryDate,
    required this.nextRenewalDate,
    required this.daysUntilExpiry,
    required this.isExpiryNear,
  });

  /// ファクトリコンストラクタ
  factory PlanPeriodInfo.fromStatus(SubscriptionStatus status, SubscriptionPlan plan) {
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

  /// 期限の表示用文字列
  String? get expiryDisplay {
    if (expiryDate == null) return null;
    
    return '${expiryDate!.month}月${expiryDate!.day}日';
  }

  /// 期限までの表示用文字列
  String? get daysUntilExpiryDisplay {
    if (daysUntilExpiry == null) return null;
    
    if (daysUntilExpiry! < 0) return '期限切れ';
    if (daysUntilExpiry! == 0) return '本日期限切れ';
    if (daysUntilExpiry! == 1) return '明日期限切れ';
    
    return 'あと$daysUntilExpiry日';
  }
}

/// 自動更新情報
class AutoRenewalInfo {
  /// 自動更新が有効かどうか
  final bool isAutoRenewalEnabled;
  
  /// 自動更新の説明テキスト
  final String autoRenewalDescription;
  
  /// 自動更新管理のディープリンクURL（プラットフォーム別）
  final String? managementUrl;

  const AutoRenewalInfo({
    required this.isAutoRenewalEnabled,
    required this.autoRenewalDescription,
    required this.managementUrl,
  });

  /// ファクトリコンストラクタ
  factory AutoRenewalInfo.fromStatus(SubscriptionStatus status) {
    String description;
    String? managementUrl;

    if (status.autoRenewal) {
      description = '自動更新が有効です。期限前に自動的に更新されます。';
      // TODO: プラットフォーム判定してディープリンクを設定
      managementUrl = 'https://apps.apple.com/account/subscriptions'; // iOS用（実際はプラットフォーム判定が必要）
    } else {
      description = '自動更新は無効です。期限切れ前に手動で更新してください。';
    }

    return AutoRenewalInfo(
      isAutoRenewalEnabled: status.autoRenewal,
      autoRenewalDescription: description,
      managementUrl: managementUrl,
    );
  }

  /// 自動更新状態の表示テキスト
  String get statusDisplay => isAutoRenewalEnabled ? '有効' : '無効';
}

/// 設定画面表示用のデータクラス
/// Phase 1.8.2.4: UI用データフォーマット実装
class SubscriptionDisplayData {
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

  const SubscriptionDisplayData({
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