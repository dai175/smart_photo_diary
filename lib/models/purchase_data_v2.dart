import '../services/interfaces/subscription_service_interface.dart';
import 'plans/plan.dart';
import 'plans/basic_plan.dart';
import 'plans/premium_monthly_plan.dart';
import 'plans/premium_yearly_plan.dart';
import 'subscription_plan.dart';

/// 購入商品情報（Planクラスベース版）
///
/// In-App Purchase商品情報を表現するデータクラス。
/// SubscriptionPlan enumの代わりにPlanクラスを使用します。
class PurchaseProductV2 {
  /// 商品ID
  final String id;

  /// 商品名
  final String title;

  /// 商品説明
  final String description;

  /// 価格（表示用）
  final String price;

  /// 価格（数値）
  final double priceAmount;

  /// 通貨コード
  final String currencyCode;

  /// 対応するプラン
  final Plan plan;

  const PurchaseProductV2({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmount,
    required this.currencyCode,
    required this.plan,
  });

  /// 既存PurchaseProductからの変換
  factory PurchaseProductV2.fromLegacy(PurchaseProduct legacy) {
    return PurchaseProductV2(
      id: legacy.id,
      title: legacy.title,
      description: legacy.description,
      price: legacy.price,
      priceAmount: legacy.priceAmount,
      currencyCode: legacy.currencyCode,
      plan: _convertEnumToPlan(legacy.plan),
    );
  }

  /// 既存PurchaseProductへの変換（互換性のため）
  PurchaseProduct toLegacy() {
    return PurchaseProduct(
      id: id,
      title: title,
      description: description,
      price: price,
      priceAmount: priceAmount,
      currencyCode: currencyCode,
      plan: SubscriptionPlan.fromId(plan.id),
    );
  }

  /// プラン別の価格表示テキスト生成
  String get priceDisplay {
    if (plan.id == 'premium_yearly') {
      // 年額プランの場合、月額換算も表示
      final monthlyEquivalent = (priceAmount / 12).round();
      return '$price（月額換算 ¥$monthlyEquivalent）';
    }
    return price;
  }

  @override
  String toString() {
    return 'PurchaseProductV2(id: $id, title: $title, plan: ${plan.id})';
  }
}

/// 購入結果情報（Planクラスベース版）
///
/// In-App Purchaseの結果を表現するデータクラス。
/// SubscriptionPlan enumの代わりにPlanクラスを使用します。
class PurchaseResultV2 {
  /// 購入状態
  final PurchaseStatus status;

  /// 購入した商品ID
  final String? productId;

  /// 取引ID
  final String? transactionId;

  /// 購入日時
  final DateTime? purchaseDate;

  /// エラーメッセージ（失敗時）
  final String? errorMessage;

  /// 対応するプラン
  final Plan? plan;

  const PurchaseResultV2({
    required this.status,
    this.productId,
    this.transactionId,
    this.purchaseDate,
    this.errorMessage,
    this.plan,
  });

  /// 既存PurchaseResultからの変換
  factory PurchaseResultV2.fromLegacy(PurchaseResult legacy) {
    return PurchaseResultV2(
      status: legacy.status,
      productId: legacy.productId,
      transactionId: legacy.transactionId,
      purchaseDate: legacy.purchaseDate,
      errorMessage: legacy.errorMessage,
      plan: legacy.plan != null ? _convertEnumToPlan(legacy.plan!) : null,
    );
  }

  /// 既存PurchaseResultへの変換（互換性のため）
  PurchaseResult toLegacy() {
    return PurchaseResult(
      status: status,
      productId: productId,
      transactionId: transactionId,
      purchaseDate: purchaseDate,
      errorMessage: errorMessage,
      plan: plan != null ? SubscriptionPlan.fromId(plan!.id) : null,
    );
  }

  /// 購入が成功したかどうか
  bool get isSuccess => status == PurchaseStatus.purchased;

  /// 購入がキャンセルされたかどうか
  bool get isCancelled => status == PurchaseStatus.cancelled;

  /// 購入が失敗したかどうか
  bool get isError => status == PurchaseStatus.error;

  /// エラーメッセージの取得（ユーザー向け）
  String get userFriendlyErrorMessage {
    if (!isError) return '';

    final lowerMessage = errorMessage?.toLowerCase() ?? '';

    if (lowerMessage.contains('cancelled') || lowerMessage.contains('cancel')) {
      return '購入がキャンセルされました';
    } else if (lowerMessage.contains('network')) {
      return 'ネットワークエラーが発生しました';
    } else if (lowerMessage.contains('already')) {
      return 'すでに購入済みのプランです';
    }

    return errorMessage ?? '購入処理中にエラーが発生しました';
  }

  @override
  String toString() {
    return 'PurchaseResultV2(status: $status, productId: $productId, '
        'transactionId: $transactionId, plan: ${plan?.id})';
  }
}

// ヘルパー関数
Plan _convertEnumToPlan(SubscriptionPlan enumPlan) {
  // PlanFactoryを使用して変換
  // 循環依存を避けるため、ここではdynamic importは使用しない
  switch (enumPlan) {
    case SubscriptionPlan.basic:
      return BasicPlan();
    case SubscriptionPlan.premiumMonthly:
      return PremiumMonthlyPlan();
    case SubscriptionPlan.premiumYearly:
      return PremiumYearlyPlan();
  }
}
