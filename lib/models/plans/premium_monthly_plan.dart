import 'premium_plan.dart';
import '../../constants/subscription_constants.dart';

/// Premium月額プランの実装クラス
///
/// Smart Photo Diaryの月額有料プランを表現します。
/// 全ての機能が利用可能で、AI生成回数が大幅に増加します。
class PremiumMonthlyPlan extends PremiumPlan {
  /// シングルトンインスタンス
  static final PremiumMonthlyPlan _instance = PremiumMonthlyPlan._internal();

  /// ファクトリコンストラクタ
  factory PremiumMonthlyPlan() => _instance;

  /// プライベートコンストラクタ
  PremiumMonthlyPlan._internal()
    : super(
        id: SubscriptionConstants.premiumMonthlyPlanId,
        displayName: '${SubscriptionConstants.premiumDisplayName} (Monthly)',
        description: SubscriptionConstants.premiumDescription,
        price: SubscriptionConstants.premiumMonthlyPrice,
        monthlyAiGenerationLimit: SubscriptionConstants.premiumMonthlyAiLimit,
        features: SubscriptionConstants.premiumFeatures,
        productId: SubscriptionConstants.premiumMonthlyProductId,
      );
}
