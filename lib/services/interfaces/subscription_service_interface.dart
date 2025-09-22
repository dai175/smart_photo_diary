import '../../core/result/result.dart';
import '../../models/plans/plan.dart';
import '../../models/subscription_status.dart';

/// サブスクリプションサービスのインターフェース
///
/// サブスクリプション管理機能の抽象化を提供します。
/// Result<T>パターンを使用して型安全なエラーハンドリングを実現します。
abstract class ISubscriptionService {
  // ========================================
  // 基本的なサービスメソッド
  // ========================================

  /// サービスを初期化
  Future<Result<void>> initialize();

  /// 現在のサブスクリプション状態を取得
  /// デバッグモードでプラン強制設定がある場合、実際のデータは変更せずに返り値のみプレミアムプランとして返します
  Future<Result<SubscriptionStatus>> getCurrentStatus();

  /// サブスクリプション状態をリロード
  Future<Result<void>> refreshStatus();

  /// サービスが初期化済みかどうか
  bool get isInitialized;

  // ========================================
  // プラン管理メソッド
  // ========================================

  /// 特定のプラン情報を取得（新Planクラス）
  Result<Plan> getPlanClass(String planId);

  /// 現在のプランを取得（新Planクラス）
  Future<Result<Plan>> getCurrentPlanClass();

  // ========================================
  // 使用量管理メソッド
  // ========================================

  /// AI生成を使用できるかどうかをチェック
  Future<Result<bool>> canUseAiGeneration();

  /// AI生成使用量をインクリメント
  Future<Result<void>> incrementAiUsage();

  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingGenerations();

  /// 今月の使用量を取得
  Future<Result<int>> getMonthlyUsage();

  /// 使用量を手動でリセット（管理者・テスト用）
  Future<Result<void>> resetUsage();

  /// 月次使用量を必要に応じてリセット（自動）
  /// AiService統合で使用
  Future<void> resetMonthlyUsageIfNeeded();

  /// 次の使用量リセット日を取得
  Future<Result<DateTime>> getNextResetDate();

  // ========================================
  // アクセス権限チェックメソッド
  // ========================================

  /// プレミアム機能にアクセスできるかどうか
  Future<Result<bool>> canAccessPremiumFeatures();

  /// ライティングプロンプトにアクセスできるかどうか
  Future<Result<bool>> canAccessWritingPrompts();

  /// 高度なフィルタにアクセスできるかどうか
  Future<Result<bool>> canAccessAdvancedFilters();

  /// 高度な分析にアクセスできるかどうか
  Future<Result<bool>> canAccessAdvancedAnalytics();

  /// 優先サポートにアクセスできるかどうか
  Future<Result<bool>> canAccessPrioritySupport();

  // ========================================
  // 購入・復元メソッド
  // ========================================

  /// In-App Purchase商品情報を取得
  Future<Result<List<PurchaseProduct>>> getProducts();

  /// 指定プランの実際の価格情報を取得
  Future<Result<PurchaseProduct?>> getProductPrice(String planId);

  /// プランを購入（新Planクラス）
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan);

  /// 購入を復元
  Future<Result<List<PurchaseResult>>> restorePurchases();

  /// 購入状態を検証
  Future<Result<bool>> validatePurchase(String transactionId);

  /// プランを変更（新Planクラス）
  Future<Result<void>> changePlanClass(Plan newPlan);

  /// サブスクリプションをキャンセル
  Future<Result<void>> cancelSubscription();

  // ========================================
  // 状態監視・通知
  // ========================================

  /// サブスクリプション状態変更を監視
  Stream<SubscriptionStatus> get statusStream;

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
