import '../../core/result/result.dart';
import '../../models/plans/plan.dart';

/// In-App Purchase サービスのインターフェース
///
/// IAP商品情報取得、購入フロー、復元、検証を担当する。
abstract class IInAppPurchaseService {
  /// サービスを初期化（IAP利用可能性チェックと購入ストリーム監視開始）
  Future<Result<void>> initialize();

  /// In-App Purchase商品情報を取得
  Future<Result<List<PurchaseProduct>>> getProducts();

  /// 指定プランの実際の価格情報を取得
  Future<Result<PurchaseProduct?>> getProductPrice(String planId);

  /// プランを購入
  Future<Result<PurchaseResult>> purchasePlan(Plan plan);

  /// 購入を復元
  Future<Result<List<PurchaseResult>>> restorePurchases();

  /// 購入状態を検証
  Future<Result<bool>> validatePurchase(String transactionId);

  /// プランを変更
  Future<Result<void>> changePlan(Plan newPlan);

  /// サブスクリプションをキャンセル
  Future<Result<void>> cancelSubscription();

  /// 購入状態変更を監視
  Stream<PurchaseResult> get purchaseStream;

  /// サービスを破棄
  Future<void> dispose();
}

// ========================================
// 関連データクラス
// ========================================

/// 購入可能商品情報
class PurchaseProduct {
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

  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmount,
    required this.currencyCode,
    required this.plan,
  });

  @override
  String toString() {
    return 'PurchaseProduct(id: $id, title: $title, price: $price, plan: ${plan.id})';
  }
}

/// 購入結果
class PurchaseResult {
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

  const PurchaseResult({
    required this.status,
    this.productId,
    this.transactionId,
    this.purchaseDate,
    this.errorMessage,
    this.plan,
  });

  /// 購入が成功したかどうか
  bool get isSuccess => status == PurchaseStatus.purchased;

  /// 購入がキャンセルされたかどうか
  bool get isCancelled => status == PurchaseStatus.cancelled;

  /// 購入が失敗したかどうか
  bool get isError => status == PurchaseStatus.error;

  @override
  String toString() {
    return 'PurchaseResult(status: $status, productId: $productId, '
        'transactionId: $transactionId, plan: ${plan?.id})';
  }
}

/// 購入状態enum
enum PurchaseStatus {
  /// 購入完了
  purchased,

  /// ユーザーによるキャンセル
  cancelled,

  /// エラー発生
  error,

  /// 復元完了
  restored,

  /// 処理中
  pending,

  /// 商品が見つからない
  productNotFound,

  /// ネットワークエラー
  networkError,

  /// ストア利用不可
  storeNotAvailable,

  /// 既に所有済み
  alreadyOwned,
}

/// サブスクリプション関連の例外
class SubscriptionException implements Exception {
  /// エラーメッセージ
  final String message;

  /// 詳細情報
  final String? details;

  /// 元の例外
  final dynamic originalError;

  /// エラーコード
  final String? errorCode;

  const SubscriptionException(
    this.message, {
    this.details,
    this.originalError,
    this.errorCode,
  });

  @override
  String toString() {
    final buffer = StringBuffer('SubscriptionException: $message');
    if (details != null) {
      buffer.write(' ($details)');
    }
    if (errorCode != null) {
      buffer.write(' [Code: $errorCode]');
    }
    return buffer.toString();
  }
}
