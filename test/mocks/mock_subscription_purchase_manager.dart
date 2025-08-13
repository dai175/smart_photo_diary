import 'dart:async';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/logging_service.dart';

/// MockSubscriptionPurchaseManager
///
/// テスト用のSubscriptionPurchaseManagerモック実装
///
/// ## 主な機能
/// - 完全なメモリベース実装でHive依存を排除
/// - テストシナリオ用の設定可能な状態管理
/// - 全公開メソッドの完全実装
/// - エラーシミュレーション機能
/// - 購入処理と状態の追跡
///
/// ## 設計原則
/// - SubscriptionPurchaseManagerの公開APIを完全に模倣
/// - 各メソッドの成功・失敗パターンを設定可能
/// - Stream通知の完全な再現
/// - テスト用のヘルパーメソッドを豊富に提供
class MockSubscriptionPurchaseManager {
  // =================================================================
  // 内部状態管理
  // =================================================================

  bool _isInitialized = false;
  bool _isPurchasing = false;
  // ignore: unused_field
  LoggingService? _loggingService; // APIの互換性のため保持、モック内では実際のログ出力は行わない

  // エラーシミュレーション設定
  bool _shouldFailInitialization = false;
  bool _shouldFailGetProducts = false;
  bool _shouldFailPurchase = false;
  bool _shouldFailRestore = false;
  bool _shouldFailValidation = false;
  String? _forcedErrorMessage;

  // 商品とストリーム管理
  List<PurchaseProduct> _availableProducts = [];
  final List<PurchaseResult> _purchaseHistory = [];
  final StreamController<PurchaseResult> _purchaseStreamController =
      StreamController<PurchaseResult>.broadcast();

  // サブスクリプション状態更新コールバック
  Function(SubscriptionStatus)? _onSubscriptionStatusUpdate;

  // =================================================================
  // コンストラクタ
  // =================================================================

  MockSubscriptionPurchaseManager({
    Function(SubscriptionStatus)? onSubscriptionStatusUpdate,
  }) : _onSubscriptionStatusUpdate = onSubscriptionStatusUpdate {
    _initializeTestData();
  }

  /// テストデータの初期化
  void _initializeTestData() {
    _availableProducts = [
      PurchaseProduct(
        id: 'smart_photo_diary_premium_monthly',
        title: 'Premium Monthly',
        description: 'Smart Photo Diary Premium Monthly Plan',
        price: '¥300',
        priceAmount: 300.0,
        currencyCode: 'JPY',
        plan: PremiumMonthlyPlan(),
      ),
      PurchaseProduct(
        id: 'smart_photo_diary_premium_yearly',
        title: 'Premium Yearly', 
        description: 'Smart Photo Diary Premium Yearly Plan',
        price: '¥2,800',
        priceAmount: 2800.0,
        currencyCode: 'JPY',
        plan: PremiumYearlyPlan(),
      ),
    ];
  }

  // =================================================================
  // テスト設定メソッド
  // =================================================================

  /// テスト用: 初期化失敗を設定
  void setInitializationFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailInitialization = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 商品取得失敗を設定
  void setGetProductsFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetProducts = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 購入失敗を設定
  void setPurchaseFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailPurchase = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 復元失敗を設定
  void setRestoreFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailRestore = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 検証失敗を設定
  void setValidationFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailValidation = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 利用可能商品を設定
  void setAvailableProducts(List<PurchaseProduct> products) {
    _availableProducts = products;
  }

  /// テスト用: 購入履歴を設定
  void setPurchaseHistory(List<PurchaseResult> history) {
    _purchaseHistory.clear();
    _purchaseHistory.addAll(history);
  }

  /// テスト用: 購入中状態を強制設定
  void setPurchasing(bool isPurchasing) {
    _isPurchasing = isPurchasing;
  }

  /// テスト用: 状態をリセット
  void resetToDefaults() {
    _isInitialized = false;
    _isPurchasing = false;
    _loggingService = null;
    _shouldFailInitialization = false;
    _shouldFailGetProducts = false;
    _shouldFailPurchase = false;
    _shouldFailRestore = false;
    _shouldFailValidation = false;
    _forcedErrorMessage = null;
    _purchaseHistory.clear();
    _initializeTestData();
  }

  // =================================================================
  // エラーハンドリングヘルパー
  // =================================================================

  Result<T> _simulateError<T>(String operation) {
    final message = _forcedErrorMessage ?? 'Mock error in $operation';
    return Failure(
      ServiceException(message, details: 'Simulated error for testing'),
    );
  }

  // =================================================================
  // 公開API実装
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  /// 購入処理中かどうか
  bool get isPurchasing => _isPurchasing;

  /// 購入状態ストリーム
  Stream<PurchaseResult> get purchaseStream => _purchaseStreamController.stream;

  /// Purchase Manager を初期化
  Future<Result<void>> initialize(LoggingService loggingService) async {
    if (_shouldFailInitialization) {
      return _simulateError('initialize');
    }

    _loggingService = loggingService;
    _isInitialized = true;
    return const Success(null);
  }

  /// サブスクリプション状態更新コールバックを設定
  void setSubscriptionStatusUpdateCallback(
    Function(SubscriptionStatus) callback,
  ) {
    _onSubscriptionStatusUpdate = callback;
  }

  /// In-App Purchase商品情報を取得
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('PurchaseManager is not initialized'),
      );
    }

    if (_shouldFailGetProducts) {
      return _simulateError('getProducts');
    }

    await Future.delayed(const Duration(milliseconds: 100)); // 非同期処理をシミュレート
    return Success(List.from(_availableProducts));
  }

  /// 購入を復元
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('PurchaseManager is not initialized'),
      );
    }

    if (_shouldFailRestore) {
      return _simulateError('restorePurchases');
    }

    await Future.delayed(const Duration(milliseconds: 200)); // 復元処理をシミュレート

    // 復元結果をストリームに送信
    for (final purchase in _purchaseHistory) {
      final restoredResult = PurchaseResult(
        status: PurchaseStatus.restored,
        productId: purchase.productId,
        transactionId: purchase.transactionId,
        purchaseDate: purchase.purchaseDate,
        plan: purchase.plan,
      );
      _purchaseStreamController.add(restoredResult);
    }

    return Success(List.from(_purchaseHistory));
  }

  /// 購入状態を検証
  Future<Result<bool>> validatePurchase(
    String transactionId,
    Function() getCurrentStatus,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('PurchaseManager is not initialized'),
      );
    }

    if (_shouldFailValidation) {
      return _simulateError('validatePurchase');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 検証処理をシミュレート

    // getCurrentStatusを呼び出してResult<SubscriptionStatus>を取得
    try {
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      
      // トランザクションIDが一致し、サブスクリプションが有効か確認
      final isValid = status.transactionId == transactionId && 
                      status.isActive && 
                      (status.expiryDate == null || DateTime.now().isBefore(status.expiryDate!));

      return Success(isValid);
    } catch (e) {
      return Failure(ServiceException('Failed to validate purchase: ${e.toString()}'));
    }
  }

  /// プランを購入
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('PurchaseManager is not initialized'),
      );
    }

    if (_isPurchasing) {
      return Failure(
        ServiceException('Another purchase is already in progress'),
      );
    }

    if (plan.id == BasicPlan().id) {
      return Failure(ServiceException('Basic plan cannot be purchased'));
    }

    if (_shouldFailPurchase) {
      // エラー結果をストリームに送信
      final errorResult = PurchaseResult(
        status: PurchaseStatus.error,
        productId: plan.productId,
        errorMessage: _forcedErrorMessage ?? 'Mock purchase failure',
      );
      _purchaseStreamController.add(errorResult);
      return Success(errorResult);
    }

    _isPurchasing = true;

    await Future.delayed(const Duration(milliseconds: 500)); // 購入処理をシミュレート

    // 成功した購入をシミュレート
    final now = DateTime.now();
    final transactionId = 'mock_transaction_${now.millisecondsSinceEpoch}';
    
    final result = PurchaseResult(
      status: PurchaseStatus.purchased,
      productId: plan.productId,
      transactionId: transactionId,
      purchaseDate: now,
      plan: null, // V2では使用しない
    );

    // 購入履歴に記録
    _purchaseHistory.add(result);

    // ストリームに結果を送信
    _purchaseStreamController.add(result);

    // サブスクリプション状態を更新（コールバック経由）
    if (_onSubscriptionStatusUpdate != null) {
      final expiryDate = plan.isYearly 
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      final newStatus = SubscriptionStatus(
        planId: plan.id,
        isActive: true,
        startDate: now,
        expiryDate: expiryDate,
        autoRenewal: true,
        monthlyUsageCount: 0,
        lastResetDate: now,
        transactionId: transactionId,
        lastPurchaseDate: now,
      );

      _onSubscriptionStatusUpdate!(newStatus);
    }

    _isPurchasing = false;
    return Success(result);
  }

  /// プランを変更
  Future<Result<void>> changePlanClass(Plan newPlan) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('PurchaseManager is not initialized'),
      );
    }

    // プラン変更は現在未実装
    return Failure(
      ServiceException(
        'Plan change is not yet implemented',
        details: 'This feature will be available in future versions',
      ),
    );
  }

  /// サブスクリプションをキャンセル
  Future<Result<void>> cancelSubscription(
    Function() getCurrentStatus,
    Function(SubscriptionStatus) updateStatus,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('PurchaseManager is not initialized'),
      );
    }

    await Future.delayed(const Duration(milliseconds: 100)); // キャンセル処理をシミュレート

    try {
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final currentStatus = statusResult.value;

      // 自動更新フラグを無効化
      final updatedStatus = SubscriptionStatus(
        planId: currentStatus.planId,
        isActive: currentStatus.isActive,
        startDate: currentStatus.startDate,
        expiryDate: currentStatus.expiryDate,
        autoRenewal: false, // 自動更新を無効化
        monthlyUsageCount: currentStatus.monthlyUsageCount,
        lastResetDate: currentStatus.lastResetDate,
        transactionId: currentStatus.transactionId,
        lastPurchaseDate: currentStatus.lastPurchaseDate,
      );

      updateStatus(updatedStatus);
      return const Success(null);
    } catch (e) {
      return Failure(ServiceException('Failed to cancel subscription: ${e.toString()}'));
    }
  }

  // =================================================================
  // テスト用ヘルパーメソッド
  // =================================================================

  /// テスト用: 購入完了をシミュレート
  void simulatePurchaseComplete(String productId, Plan plan) {
    final now = DateTime.now();
    final transactionId = 'mock_transaction_${now.millisecondsSinceEpoch}';
    
    final result = PurchaseResult(
      status: PurchaseStatus.purchased,
      productId: productId,
      transactionId: transactionId,
      purchaseDate: now,
      plan: null, // V2では使用しない
    );

    _purchaseHistory.add(result);
    _purchaseStreamController.add(result);
  }

  /// テスト用: 購入キャンセルをシミュレート
  void simulatePurchaseCancel(String productId) {
    final result = PurchaseResult(
      status: PurchaseStatus.cancelled,
      productId: productId,
    );

    _purchaseStreamController.add(result);
    _isPurchasing = false;
  }

  /// テスト用: 購入エラーをシミュレート
  void simulatePurchaseError(String productId, String errorMessage) {
    final result = PurchaseResult(
      status: PurchaseStatus.error,
      productId: productId,
      errorMessage: errorMessage,
    );

    _purchaseStreamController.add(result);
    _isPurchasing = false;
  }

  /// テスト用: 購入履歴をクリア
  void clearPurchaseHistory() {
    _purchaseHistory.clear();
  }

  /// テスト用: ストリームに結果を手動追加
  void addToPurchaseStream(PurchaseResult result) {
    _purchaseStreamController.add(result);
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  Future<void> dispose() async {
    if (!_purchaseStreamController.isClosed) {
      await _purchaseStreamController.close();
    }
    _isInitialized = false;
    _isPurchasing = false;
    _loggingService = null;
    _purchaseHistory.clear();
  }
}