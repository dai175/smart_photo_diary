import 'plan.dart';
import '../../constants/subscription_constants.dart';

/// Basicプラン（無料）の実装クラス
///
/// Smart Photo Diaryの無料プランを表現します。
/// 基本機能のみ利用可能で、AI生成回数に制限があります。
class BasicPlan extends Plan {
  /// シングルトンインスタンス
  static final BasicPlan _instance = BasicPlan._internal();

  /// ファクトリコンストラクタ
  factory BasicPlan() => _instance;

  /// プライベートコンストラクタ
  BasicPlan._internal()
    : super(
        id: SubscriptionConstants.basicPlanId,
        displayName: SubscriptionConstants.basicDisplayName,
        description: SubscriptionConstants.basicDescription,
        price: SubscriptionConstants.basicYearlyPrice,
        monthlyAiGenerationLimit: SubscriptionConstants.basicMonthlyAiLimit,
        features: SubscriptionConstants.basicFeatures,
        productId: '', // 無料プランは商品IDなし
      );

  // ========================================
  // プラン固有の機能フラグ実装
  // ========================================

  @override
  bool get isPremium => false;

  @override
  bool get hasWritingPrompts => false;

  @override
  bool get hasAdvancedFilters => false;

  @override
  bool get hasAdvancedAnalytics => false;

  @override
  bool get hasPrioritySupport => false;

  @override
  int get pastPhotoAccessDays => 1; // Basicプランは1日前まで

  // ========================================
  // Basicプラン固有のメソッド
  // ========================================

  /// アップグレード推奨メッセージを生成
  String getUpgradeMessage(int currentUsage) {
    final usageRate = currentUsage / monthlyAiGenerationLimit;

    if (usageRate >= 1.0) {
      return '今月のAI生成回数の上限に達しました。Premiumプランにアップグレードすると、月${SubscriptionConstants.premiumMonthlyAiLimit}回まで利用できます。';
    } else if (usageRate >= 0.8) {
      return 'AI生成の残り回数が少なくなっています。Premiumプランでより多く利用できます。';
    } else if (usageRate >= 0.5) {
      return 'より多くの機能をお楽しみいただくには、Premiumプランがおすすめです。';
    }

    return '';
  }

  /// プレミアムプランとの差分機能リストを取得
  List<String> getMissingFeatures() {
    return [
      'ライティングプロンプト機能',
      '高度なフィルタ・検索機能',
      '統計・分析ダッシュボード',
      '月${SubscriptionConstants.premiumMonthlyAiLimit}回のAI生成',
      '優先カスタマーサポート',
    ];
  }
}
