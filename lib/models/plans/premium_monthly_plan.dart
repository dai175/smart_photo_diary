import 'package:intl/intl.dart';

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
  ///
  /// [monthlyPriceAmount] 実際の月額価格
  /// [yearlyPriceAmount] 実際の年額価格
  /// [currencyCode] 通貨コード
  double calculateYearlySavings({
    double? monthlyPriceAmount,
    double? yearlyPriceAmount,
  }) {
    final actualMonthlyPrice = monthlyPriceAmount ?? price.toDouble();
    final actualYearlyPrice =
        yearlyPriceAmount ??
        SubscriptionConstants.premiumYearlyPrice.toDouble();

    final yearlyTotal = actualMonthlyPrice * 12;
    return yearlyTotal - actualYearlyPrice;
  }

  /// 年額プランへの切り替え推奨メッセージ
  ///
  /// [monthlyPriceAmount] 実際の月額価格
  /// [yearlyPriceAmount] 実際の年額価格
  /// [currencyCode] 通貨コード
  String getYearlyUpgradeMessage({
    double? monthlyPriceAmount,
    double? yearlyPriceAmount,
    String? currencyCode,
  }) {
    final savings = calculateYearlySavings(
      monthlyPriceAmount: monthlyPriceAmount,
      yearlyPriceAmount: yearlyPriceAmount,
    );
    final actualMonthlyPrice = monthlyPriceAmount ?? price.toDouble();
    final actualYearlyPrice =
        yearlyPriceAmount ??
        SubscriptionConstants.premiumYearlyPrice.toDouble();
    final savingsPercentage =
        ((actualMonthlyPrice * 12 - actualYearlyPrice) /
                (actualMonthlyPrice * 12) *
                100)
            .round();

    final locale = Intl.getCurrentLocale().isEmpty
        ? 'ja'
        : Intl.getCurrentLocale();
    final currency = currencyCode ?? SubscriptionConstants.defaultCurrencyCode;

    final savingsText = formatPriceWithAmount(
      savings,
      currency,
      locale: locale,
    );

    return '年額プランに切り替えると、年間$savingsText（$savingsPercentage%OFF）お得になります。';
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
