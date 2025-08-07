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

  /// 年額プランへの切り替えによる節約額を計算
  int calculateYearlySavings() {
    final yearlyTotal = price * 12;
    final yearlyPlanPrice = SubscriptionConstants.premiumYearlyPrice;
    return yearlyTotal - yearlyPlanPrice;
  }

  /// 年額プランへの切り替え推奨メッセージ
  String getYearlyUpgradeMessage() {
    final savings = calculateYearlySavings();
    final savingsPercentage = SubscriptionConstants.yearlyDiscountPercentage;

    return '年額プランに切り替えると、年間¥${savings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}（$savingsPercentage%OFF）お得になります。';
  }

  /// 利用状況に基づくメッセージ
  String getUsageMessage(int currentUsage) {
    final usageRate = currentUsage / monthlyAiGenerationLimit;

    if (usageRate >= 0.9) {
      return '今月のAI生成回数が残り少なくなっています。';
    } else if (usageRate >= 0.7) {
      return 'AI生成を活発にご利用いただいています。';
    }

    return '';
  }

  /// 月額プランの特徴リスト
  List<String> getMonthlyBenefits() {
    return ['月単位での柔軟な契約', 'いつでもキャンセル可能', '初月から全機能利用可能', '自動更新で手間いらず'];
  }
}
