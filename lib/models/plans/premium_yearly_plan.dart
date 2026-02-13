import 'plan.dart';
import '../../constants/subscription_constants.dart';

/// Premium年額プランの実装クラス
///
/// Smart Photo Diaryの年額有料プランを表現します。
/// 月額プランよりお得な価格設定で、全機能が利用可能です。
class PremiumYearlyPlan extends Plan {
  /// シングルトンインスタンス
  static final PremiumYearlyPlan _instance = PremiumYearlyPlan._internal();

  /// ファクトリコンストラクタ
  factory PremiumYearlyPlan() => _instance;

  /// プライベートコンストラクタ
  PremiumYearlyPlan._internal()
    : super(
        id: SubscriptionConstants.premiumYearlyPlanId,
        displayName: '${SubscriptionConstants.premiumDisplayName} (Yearly)',
        description: SubscriptionConstants.premiumDescription,
        price: SubscriptionConstants.premiumYearlyPrice,
        monthlyAiGenerationLimit: SubscriptionConstants.premiumMonthlyAiLimit,
        features: SubscriptionConstants.premiumFeatures,
        productId: SubscriptionConstants.premiumYearlyProductId,
      );

  // ========================================
  // プラン固有の機能フラグ実装
  // ========================================

  @override
  bool get isPremium => true;

  @override
  bool get hasWritingPrompts => true;

  @override
  bool get hasAdvancedFilters => true;

  @override
  bool get hasAdvancedAnalytics => true;

  @override
  bool get hasPrioritySupport => true;

  @override
  int get pastPhotoAccessDays => 365; // Premiumプランは365日前まで

  // ========================================
  // Premium年額プラン固有のメソッド
  // ========================================

  /// 月額換算価格を計算
  double get monthlyEquivalentPrice => price / 12.0;

  /// 月額プランと比較した節約額（年間）
  int get yearlySavings {
    final monthlyTotal = SubscriptionConstants.premiumMonthlyPrice * 12;
    return monthlyTotal - price;
  }

  /// 割引率を取得
  int get discountPercentage => SubscriptionConstants.yearlyDiscountPercentage;
}
