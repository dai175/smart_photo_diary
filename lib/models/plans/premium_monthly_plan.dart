import 'plan.dart';
import '../../constants/subscription_constants.dart';

/// Premium月額プランの実装クラス
///
/// Smart Photo Diaryの月額有料プランを表現します。
/// 全ての機能が利用可能で、AI生成回数が大幅に増加します。
class PremiumMonthlyPlan extends Plan {
  /// シングルトンインスタンス
  static final PremiumMonthlyPlan _instance = PremiumMonthlyPlan._internal();

  /// ファクトリコンストラクタ
  factory PremiumMonthlyPlan() => _instance;

  /// プライベートコンストラクタ
  PremiumMonthlyPlan._internal()
    : super(
        id: SubscriptionConstants.premiumMonthlyPlanId,
        displayName: '${SubscriptionConstants.premiumDisplayName} (月額)',
        description: SubscriptionConstants.premiumDescription,
        price: SubscriptionConstants.premiumMonthlyPrice,
        monthlyAiGenerationLimit: SubscriptionConstants.premiumMonthlyAiLimit,
        features: SubscriptionConstants.premiumFeatures,
        productId: SubscriptionConstants.premiumMonthlyProductId,
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
  // Premium月額プラン固有のメソッド
  // ========================================
}
