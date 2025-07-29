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
        displayName: '${SubscriptionConstants.premiumDisplayName} (年額)',
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

  /// 年額プランの利点を説明するメッセージ
  String getValueProposition() {
    final savings = yearlySavings;
    final monthlyEquiv = monthlyEquivalentPrice.round();

    return '年額プランなら、実質月額¥$monthlyEquivで全機能をご利用いただけます。'
        '月額プランと比べて年間¥${savings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}（$discountPercentage%）お得です。';
  }

  /// 利用状況に基づくメッセージ
  String getUsageMessage(int currentUsage) {
    final usageRate = currentUsage / monthlyAiGenerationLimit;

    if (usageRate >= 0.9) {
      return '今月のAI生成回数が残り少なくなっています。来月にリセットされます。';
    } else if (usageRate <= 0.3) {
      return 'まだまだたくさんのAI生成回数が残っています。どんどん活用しましょう！';
    }

    return '';
  }

  /// 年額プランの特徴リスト
  List<String> getYearlyBenefits() {
    return [
      '月額プランより$discountPercentage%お得',
      '年間¥${yearlySavings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}の節約',
      '1年間の安心サポート',
      '支払い手続きは年1回のみ',
      '全機能を存分に活用可能',
    ];
  }

  /// 更新時期の通知メッセージ
  String getRenewalReminder(int daysUntilRenewal) {
    if (daysUntilRenewal <= 0) {
      return '本日が更新日です。';
    } else if (daysUntilRenewal <= 7) {
      return 'あと$daysUntilRenewal日で更新日です。';
    } else if (daysUntilRenewal <= 30) {
      return '更新日まであと$daysUntilRenewal日です。';
    }

    return '';
  }
}
