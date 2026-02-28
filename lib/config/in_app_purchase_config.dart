import '../constants/subscription_constants.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';

/// In-App Purchase設定管理クラス
///
/// App Store Connect/Google Play Console用の商品設定を一元管理します。
class InAppPurchaseConfig {
  // プライベートコンストラクタでインスタンス化を防ぐ
  InAppPurchaseConfig._();

  // ========================================
  // 商品ID設定
  // ========================================

  /// 全商品IDのリスト
  static List<String> get allProductIds => [
    SubscriptionConstants.premiumMonthlyProductId,
    SubscriptionConstants.premiumYearlyProductId,
  ];

  /// プランから商品IDを取得（メイン実装 - Planクラス版）
  static String getProductIdFromPlan(Plan plan) {
    if (plan is BasicPlan) {
      throw ArgumentError('Basic plan does not have a product ID');
    }
    return plan.productId;
  }

  /// 商品IDからプランを取得（メイン実装 - Planクラス版）
  static Plan getPlanFromProductId(String productId) {
    // 全プランから商品IDが一致するものを検索
    for (final plan in PlanFactory.getAllPlans()) {
      if (plan.productId == productId) {
        return plan;
      }
    }
    throw ArgumentError('Unknown product ID: $productId');
  }
}
