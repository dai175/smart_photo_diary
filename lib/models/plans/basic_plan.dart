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
}
