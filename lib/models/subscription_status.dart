import 'package:hive/hive.dart';
import 'subscription_plan.dart';
import '../constants/subscription_constants.dart';

part 'subscription_status.g.dart';

/// サブスクリプション状態管理モデル
///
/// ユーザーの現在のサブスクリプション状態、使用量、
/// 有効期限などを管理するHiveデータモデルです。
@HiveType(typeId: 2)
class SubscriptionStatus extends HiveObject {
  /// 現在のプランID
  @HiveField(0)
  String planId;

  /// サブスクリプションがアクティブかどうか
  @HiveField(1)
  bool isActive;

  /// サブスクリプション開始日時
  @HiveField(2)
  DateTime? startDate;

  /// サブスクリプション有効期限
  @HiveField(3)
  DateTime? expiryDate;

  /// 現在月のAI生成使用回数
  @HiveField(4)
  int monthlyUsageCount;

  /// 使用量カウントの基準月（YYYY-MM形式）
  @HiveField(5)
  String usageMonth;

  /// 最後の使用量リセット日時
  @HiveField(6)
  DateTime? lastResetDate;

  /// 自動更新が有効かどうか
  @HiveField(7)
  bool autoRenewal;

  /// 購入取引ID（レシート検証用）
  @HiveField(8)
  String? transactionId;

  /// 最後の購入日時
  @HiveField(9)
  DateTime? lastPurchaseDate;

  /// キャンセル予定日（キャンセルされた場合）
  @HiveField(10)
  DateTime? cancelDate;

  /// プラン変更予定日
  @HiveField(11)
  DateTime? planChangeDate;

  /// 変更予定の新プランID
  @HiveField(12)
  String? pendingPlanId;

  SubscriptionStatus({
    this.planId = SubscriptionConstants.basicPlanId,
    this.isActive = true,
    this.startDate,
    this.expiryDate,
    this.monthlyUsageCount = 0,
    String? usageMonth,
    this.lastResetDate,
    this.autoRenewal = false,
    this.transactionId,
    this.lastPurchaseDate,
    this.cancelDate,
    this.planChangeDate,
    this.pendingPlanId,
  }) : usageMonth = usageMonth ?? _getCurrentMonth();

  /// 現在の月を YYYY-MM 形式で取得
  static String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  /// 現在のプランを取得
  SubscriptionPlan get currentPlan {
    try {
      return SubscriptionPlan.fromId(planId);
    } catch (e) {
      // 不正なプランIDの場合はBasicにフォールバック
      return SubscriptionPlan.basic;
    }
  }

  /// プランを変更
  void changePlan(SubscriptionPlan newPlan, {DateTime? effectiveDate}) {
    planId = newPlan.planId;
    if (effectiveDate != null) {
      planChangeDate = effectiveDate;
    }

    // Premium プランの場合は有効期限を設定
    if (newPlan.isPremium) {
      startDate ??= DateTime.now();

      // 年額プランと月額プランで有効期限を設定
      if (newPlan.isYearly) {
        expiryDate = startDate!.add(
          Duration(days: SubscriptionConstants.subscriptionYearDays),
        );
      } else {
        expiryDate = startDate!.add(
          Duration(days: SubscriptionConstants.subscriptionMonthDays),
        );
      }

      isActive = true;
      autoRenewal = true;
    } else {
      // Basic プランは無期限
      expiryDate = null;
      isActive = true;
      autoRenewal = false;
    }

    save();
  }

  /// サブスクリプションが有効かどうかをチェック
  bool get isValid {
    if (!isActive) return false;

    // Basic プランは常に有効
    if (currentPlan == SubscriptionPlan.basic) return true;

    // Premium プランは有効期限をチェック
    if (expiryDate == null) return false;
    return DateTime.now().isBefore(expiryDate!);
  }

  /// サブスクリプションが期限切れかどうか
  bool get isExpired {
    if (currentPlan == SubscriptionPlan.basic) return false;
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// 今月のAI生成回数制限に達しているかどうか
  bool get hasReachedMonthlyLimit {
    _resetMonthlyUsageIfNeeded();
    return monthlyUsageCount >= currentPlan.monthlyAiGenerationLimit;
  }

  /// AI生成を使用できるかどうか
  bool get canUseAiGeneration {
    return isValid && !hasReachedMonthlyLimit;
  }

  /// 残りAI生成回数を取得
  int get remainingGenerations {
    _resetMonthlyUsageIfNeeded();
    final remaining = currentPlan.monthlyAiGenerationLimit - monthlyUsageCount;
    return remaining > 0 ? remaining : 0;
  }

  /// AI生成使用量をインクリメント
  void incrementAiUsage() {
    _resetMonthlyUsageIfNeeded();
    monthlyUsageCount++;
    save();
  }

  /// 月が変わった場合に使用量をリセット
  void _resetMonthlyUsageIfNeeded() {
    final currentMonth = _getCurrentMonth();
    if (usageMonth != currentMonth) {
      monthlyUsageCount = 0;
      usageMonth = currentMonth;
      lastResetDate = DateTime.now();
      save();
    }
  }

  /// 使用量を手動でリセット（テスト用）
  void resetUsage() {
    monthlyUsageCount = 0;
    usageMonth = _getCurrentMonth();
    lastResetDate = DateTime.now();
    save();
  }

  /// サブスクリプションをキャンセル
  void cancel({DateTime? effectiveDate}) {
    autoRenewal = false;
    cancelDate = effectiveDate ?? DateTime.now();

    // 即座にキャンセルする場合
    if (effectiveDate == null || effectiveDate.isBefore(DateTime.now())) {
      isActive = false;
      planId = SubscriptionConstants.basicPlanId;
    }

    save();
  }

  /// サブスクリプションを復活
  void restore() {
    isActive = true;
    cancelDate = null;
    save();
  }

  /// プレミアム機能にアクセスできるかどうか
  bool get canAccessPremiumFeatures {
    return isValid && currentPlan.isPremium;
  }

  /// ライティングプロンプトにアクセスできるかどうか
  bool get canAccessWritingPrompts {
    return canAccessPremiumFeatures && currentPlan.hasWritingPrompts;
  }

  /// 高度なフィルタにアクセスできるかどうか
  bool get canAccessAdvancedFilters {
    return canAccessPremiumFeatures && currentPlan.hasAdvancedFilters;
  }

  /// 高度な分析にアクセスできるかどうか
  bool get canAccessAdvancedAnalytics {
    return canAccessPremiumFeatures && currentPlan.hasAdvancedAnalytics;
  }

  /// 次の使用量リセット日を取得
  DateTime get nextResetDate {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return nextMonth;
  }

  /// 期限までの残り日数
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    if (expiryDate!.isBefore(now)) return 0;
    return expiryDate!.difference(now).inDays;
  }

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'SubscriptionStatus('
        'planId: $planId, '
        'isActive: $isActive, '
        'isValid: $isValid, '
        'monthlyUsageCount: $monthlyUsageCount/'
        '${currentPlan.monthlyAiGenerationLimit}, '
        'usageMonth: $usageMonth, '
        'expiryDate: $expiryDate'
        ')';
  }

  /// デフォルトのBasicプラン状態を作成
  static SubscriptionStatus createDefault() {
    return SubscriptionStatus(
      planId: SubscriptionConstants.basicPlanId,
      isActive: true,
      startDate: DateTime.now(),
      monthlyUsageCount: 0,
      autoRenewal: false,
    );
  }

  /// Premium プランの状態を作成
  static SubscriptionStatus createPremium({
    required DateTime startDate,
    required SubscriptionPlan plan,
    String? transactionId,
  }) {
    if (!plan.isPremium) {
      throw ArgumentError('Premium plan required, got: $plan');
    }

    final expiryDate = plan.isYearly
        ? startDate.add(
            Duration(days: SubscriptionConstants.subscriptionYearDays),
          )
        : startDate.add(
            Duration(days: SubscriptionConstants.subscriptionMonthDays),
          );

    return SubscriptionStatus(
      planId: plan.planId,
      isActive: true,
      startDate: startDate,
      expiryDate: expiryDate,
      monthlyUsageCount: 0,
      autoRenewal: true,
      transactionId: transactionId,
      lastPurchaseDate: startDate,
    );
  }
}
