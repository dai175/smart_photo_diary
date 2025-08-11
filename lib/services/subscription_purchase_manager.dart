import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'dart:io' show Platform;

import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/in_app_purchase_config.dart';
import 'interfaces/subscription_service_interface.dart';
import 'logging_service.dart';

// 型エイリアスで名前衝突を解決
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'interfaces/subscription_service_interface.dart' as ssi;

/// SubscriptionPurchaseManager
///
/// サブスクリプションサービスの In-App Purchase 機能を管理するクラス
/// SubscriptionService から購入関連の機能を分離して責任を明確化
///
/// ## 主な機能
/// - In-App Purchase の初期化と管理
/// - 商品情報の取得
/// - 購入処理の実行とハンドリング
/// - 購入状態の監視
/// - 復元・検証機能
///
/// ## 設計方針
/// - Result<T>パターンによる関数型エラーハンドリング
/// - 購入ストリームによるリアルタイム状態監視
/// - プラットフォーム固有の処理を抽象化
/// - テスト可能な設計
class SubscriptionPurchaseManager {
  // =================================================================
  // プロパティ
  // =================================================================

  // ロギングサービス
  LoggingService? _loggingService;

  // In-App Purchase関連
  InAppPurchase? _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // 購入状態ストリーム
  final StreamController<PurchaseResult> _purchaseStreamController =
      StreamController<PurchaseResult>.broadcast();

  // 購入処理中フラグ
  bool _isPurchasing = false;

  // 初期化フラグ
  bool _isInitialized = false;

  // サブスクリプション状態更新コールバック
  Function(SubscriptionStatus)? _onSubscriptionStatusUpdate;

  // =================================================================
  // コンストラクタ
  // =================================================================

  /// コンストラクタ
  SubscriptionPurchaseManager({
    Function(SubscriptionStatus)? onSubscriptionStatusUpdate,
  }) : _onSubscriptionStatusUpdate = onSubscriptionStatusUpdate;

  // =================================================================
  // 初期化
  // =================================================================

  /// Purchase Manager を初期化
  Future<Result<void>> initialize(LoggingService loggingService) async {
    if (_isInitialized) {
      _log('PurchaseManager already initialized', level: LogLevel.debug);
      return const Success(null);
    }

    try {
      _log('Initializing SubscriptionPurchaseManager...', level: LogLevel.info);
      _loggingService = loggingService;

      // In-App Purchase初期化
      await _initializeInAppPurchase();

      _isInitialized = true;
      _log(
        'SubscriptionPurchaseManager initialization completed',
        level: LogLevel.info,
      );

      return const Success(null);
    } catch (e) {
      final errorContext = 'SubscriptionPurchaseManager.initialize';
      _log(
        'PurchaseManager initialization failed',
        level: LogLevel.error,
        error: e,
        context: errorContext,
      );

      // ErrorHandlerを使用して適切な例外に変換
      throw ErrorHandler.handleError(e, context: errorContext);
    }
  }

  /// サブスクリプション状態更新コールバックを設定
  void setSubscriptionStatusUpdateCallback(
    Function(SubscriptionStatus) callback,
  ) {
    _onSubscriptionStatusUpdate = callback;
  }

  // =================================================================
  // プロパティアクセサー
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  /// 購入処理中かどうか
  bool get isPurchasing => _isPurchasing;

  /// 購入状態ストリーム
  Stream<PurchaseResult> get purchaseStream => _purchaseStreamController.stream;

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// 統一ログ出力メソッド
  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final logContext = context ?? 'SubscriptionPurchaseManager';

    if (_loggingService != null) {
      // 構造化ログを使用
      switch (level) {
        case LogLevel.debug:
          _loggingService!.debug(message, context: logContext, data: data);
          break;
        case LogLevel.info:
          _loggingService!.info(message, context: logContext, data: data);
          break;
        case LogLevel.warning:
          _loggingService!.warning(message, context: logContext, data: data);
          break;
        case LogLevel.error:
          _loggingService!.error(message, context: logContext, error: data);
          break;
      }

      // エラーオブジェクトがある場合は追加ログ
      if (error != null) {
        _loggingService!.error('Error details: $error', context: logContext);
      }
    } else {
      // フォールバックとしてdebugPrintを使用
      final prefix = level == LogLevel.error
          ? 'ERROR'
          : level == LogLevel.warning
              ? 'WARNING'
              : level == LogLevel.debug
                  ? 'DEBUG'
                  : 'INFO';

      debugPrint('[$prefix] $logContext: $message');
      if (error != null) {
        debugPrint('[$prefix] $logContext: Error - $error');
      }
    }
  }

  /// Result<T>パターンでのエラーハンドリングヘルパー
  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'SubscriptionPurchaseManager.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    _log(message, level: LogLevel.error, error: error, context: errorContext);

    // ErrorHandlerを使用して適切な例外に変換
    final handledException = ErrorHandler.handleError(
      error,
      context: errorContext,
    );

    // ServiceExceptionに変換
    final serviceException = handledException is ServiceException
        ? handledException
        : ServiceException(
            'Failed to $operation',
            details: details ?? error.toString(),
            originalError: error,
          );

    return Failure(serviceException);
  }

  // =================================================================
  // In-App Purchase初期化処理
  // =================================================================

  /// In-App Purchase初期化処理
  Future<void> _initializeInAppPurchase() async {
    try {
      _log('Initializing In-App Purchase...', level: LogLevel.info);

      // テスト環境やbinding未初期化の場合のエラーハンドリング
      try {
        // シミュレーター環境での特別な処理
        if (kDebugMode && Platform.isIOS) {
          _log(
            'Running in iOS debug mode - checking simulator environment',
            level: LogLevel.debug,
          );
        }

        // In-App Purchase利用可能性チェック
        final bool isAvailable = await InAppPurchase.instance.isAvailable();
        if (!isAvailable) {
          _log(
            'In-App Purchase not available on this device',
            level: LogLevel.warning,
          );
          return;
        }

        _inAppPurchase = InAppPurchase.instance;

        // 購入ストリームの監視開始
        _purchaseSubscription = _inAppPurchase!.purchaseStream.listen(
          _onPurchaseUpdated,
          onError: _onPurchaseError,
          onDone: () =>
              _log('Purchase stream completed', level: LogLevel.debug),
        );

        _log('In-App Purchase initialization completed', level: LogLevel.info);
      } catch (bindingError) {
        // テスト環境でよくある binding 未初期化エラーをキャッチ
        final errorString = bindingError.toString();
        if (errorString.contains('Binding has not yet been initialized') ||
            errorString.contains('ServicesBinding')) {
          _log(
            'In-App Purchase not available (test/simulator environment)',
            level: LogLevel.warning,
          );
          return;
        }
        // その他のエラーは再スロー
        rethrow;
      }
    } catch (e) {
      _log(
        'Failed to initialize In-App Purchase',
        level: LogLevel.error,
        error: e,
      );
      _log('Error details: $e', level: LogLevel.error);
      // In-App Purchase初期化失敗は致命的エラーではない
    }
  }

  /// 購入状態更新ハンドラー
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _processPurchaseUpdate(purchaseDetails);
    }
  }

  /// 購入エラーハンドラー
  void _onPurchaseError(dynamic error) {
    _log('Purchase stream error', level: LogLevel.error, error: error);

    // エラー情報をストリームに送信
    final errorResult = PurchaseResult(
      status: ssi.PurchaseStatus.error,
      errorMessage: error.toString(),
    );
    _purchaseStreamController.add(errorResult);
  }

  /// 購入状態更新の処理
  Future<void> _processPurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Processing purchase update: ${purchaseDetails.status}',
        level: LogLevel.info,
      );

      switch (purchaseDetails.status) {
        case iap.PurchaseStatus.purchased:
          await _handlePurchaseCompleted(purchaseDetails);
          break;

        case iap.PurchaseStatus.restored:
          await _handlePurchaseRestored(purchaseDetails);
          break;

        case iap.PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails);
          break;

        case iap.PurchaseStatus.canceled:
          await _handlePurchaseCanceled(purchaseDetails);
          break;

        case iap.PurchaseStatus.pending:
          await _handlePurchasePending(purchaseDetails);
          break;
      }

      // 購入完了処理（プラットフォーム側への完了通知）
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase!.completePurchase(purchaseDetails);
        _log(
          'Purchase completion confirmed to platform',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      _log('Error processing purchase update', level: LogLevel.error, error: e);
    }
  }

  /// 購入完了処理
  Future<void> _handlePurchaseCompleted(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Purchase completed: ${purchaseDetails.productID}',
        level: LogLevel.info,
      );

      // 商品IDからプランを特定
      final plan = InAppPurchaseConfig.getPlanFromProductId(
        purchaseDetails.productID,
      );

      // サブスクリプション状態を更新
      await _updateSubscriptionFromPurchase(purchaseDetails, plan);

      // 購入結果をストリームに送信
      final result = PurchaseResult(
        status: ssi.PurchaseStatus.purchased,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: plan,
      );
      _purchaseStreamController.add(result);

      // 購入完了後にフラグをリセット
      _isPurchasing = false;
      _log(
        '購入フラグをリセットしました',
        level: LogLevel.debug,
        context: 'SubscriptionPurchaseManager._handlePurchaseCompleted',
      );
    } catch (e) {
      _log(
        'Error handling purchase completion',
        level: LogLevel.error,
        error: e,
      );
      await _handlePurchaseError(purchaseDetails);
    }
  }

  /// 購入復元処理
  Future<void> _handlePurchaseRestored(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Purchase restored: ${purchaseDetails.productID}',
        level: LogLevel.info,
      );

      // 復元の場合も購入完了と同様の処理
      await _handlePurchaseCompleted(purchaseDetails);

      // ストリームの状態を復元として更新
      final result = PurchaseResult(
        status: ssi.PurchaseStatus.restored,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: InAppPurchaseConfig.getPlanFromProductId(
          purchaseDetails.productID,
        ),
      );
      _purchaseStreamController.add(result);
    } catch (e) {
      _log(
        'Error handling purchase restoration',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  /// 購入エラー処理
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase error: ${purchaseDetails.error?.message}',
      level: LogLevel.error,
    );

    final result = PurchaseResult(
      status: ssi.PurchaseStatus.error,
      productId: purchaseDetails.productID,
      errorMessage: purchaseDetails.error?.message ?? 'Unknown purchase error',
    );
    _purchaseStreamController.add(result);

    // エラー時にフラグをリセット
    _isPurchasing = false;
    _log(
      '購入フラグをリセットしました',
      level: LogLevel.debug,
      context: 'SubscriptionPurchaseManager._handlePurchaseError',
    );
  }

  /// 購入キャンセル処理
  Future<void> _handlePurchaseCanceled(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase canceled: ${purchaseDetails.productID}',
      level: LogLevel.info,
    );

    final result = PurchaseResult(
      status: ssi.PurchaseStatus.cancelled,
      productId: purchaseDetails.productID,
    );
    _purchaseStreamController.add(result);

    // キャンセル時にフラグをリセット
    _isPurchasing = false;
    _log(
      '購入フラグをリセットしました',
      level: LogLevel.debug,
      context: 'SubscriptionPurchaseManager._handlePurchaseCanceled',
    );
  }

  /// 購入保留処理
  Future<void> _handlePurchasePending(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase pending: ${purchaseDetails.productID}',
      level: LogLevel.info,
    );

    final result = PurchaseResult(
      status: ssi.PurchaseStatus.pending,
      productId: purchaseDetails.productID,
    );
    _purchaseStreamController.add(result);
  }

  /// 購入からサブスクリプション状態を更新
  Future<void> _updateSubscriptionFromPurchase(
    PurchaseDetails purchaseDetails,
    Plan plan,
  ) async {
    try {
      final now = DateTime.now();

      // 有効期限を計算
      DateTime expiryDate;
      if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
        expiryDate = now.add(const Duration(days: 30));
      } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
        expiryDate = now.add(const Duration(days: 365));
      } else {
        // Basicプランは購入対象外
        throw ArgumentError('Basic plan cannot be purchased');
      }

      // 新しいサブスクリプション状態を作成
      final newStatus = SubscriptionStatus(
        planId: plan.id,
        isActive: true,
        startDate: now,
        expiryDate: expiryDate,
        autoRenewal: true,
        monthlyUsageCount: 0,
        lastResetDate: now,
        transactionId: purchaseDetails.purchaseID ?? '',
        lastPurchaseDate: now,
      );

      // コールバック経由でサブスクリプション状態を更新
      _onSubscriptionStatusUpdate?.call(newStatus);

      _log('Subscription status updated from purchase', level: LogLevel.info);
    } catch (e) {
      _log(
        'Error updating subscription from purchase',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

  // =================================================================
  // 商品情報取得
  // =================================================================

  /// In-App Purchase商品情報を取得
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('PurchaseManager is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Fetching product information...', level: LogLevel.info);

      // 商品IDリストを取得
      final productIds = InAppPurchaseConfig.allProductIds.toSet();

      // ストアから商品情報を取得
      final ProductDetailsResponse response = await _inAppPurchase!
          .queryProductDetails(productIds);

      if (response.error != null) {
        return Failure(
          ServiceException(
            'Failed to fetch product details',
            details: response.error.toString(),
          ),
        );
      }

      // 見つからない商品があるかチェック
      if (response.notFoundIDs.isNotEmpty) {
        _log(
          'Products not found: ${response.notFoundIDs}',
          level: LogLevel.warning,
        );
      }

      // ProductDetailsをPurchaseProductに変換
      final products = response.productDetails.map((productDetail) {
        final plan = InAppPurchaseConfig.getPlanFromProductId(productDetail.id);

        return PurchaseProduct(
          id: productDetail.id,
          title: productDetail.title,
          description: productDetail.description,
          price: productDetail.price,
          priceAmount:
              double.tryParse(productDetail.rawPrice.toString()) ?? 0.0,
          currencyCode: productDetail.currencyCode,
          plan: plan,
        );
      }).toList();

      _log(
        'Successfully fetched ${products.length} products',
        level: LogLevel.info,
      );

      return Success(products);
    } catch (e) {
      return _handleError(e, 'getProducts');
    }
  }

  // =================================================================
  // 復元・検証機能
  // =================================================================

  /// 購入を復元
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('PurchaseManager is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Starting purchase restoration...', level: LogLevel.info);

      // 復元処理を開始
      await _inAppPurchase!.restorePurchases();

      _log('Purchase restoration initiated', level: LogLevel.info);

      // 復元結果は購入ストリームで非同期に処理される
      // ここでは復元開始の成功を返す
      return Success([PurchaseResult(status: ssi.PurchaseStatus.pending)]);
    } catch (e) {
      return _handleError(e, 'restorePurchases');
    }
  }

  /// 購入状態を検証
  Future<Result<bool>> validatePurchase(
    String transactionId,
    Function() getCurrentStatus,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('PurchaseManager is not initialized'),
        );
      }

      _log('Validating purchase: $transactionId', level: LogLevel.info);

      // 現在の実装では基本的なローカル検証のみ
      // 将来的にサーバーサイド検証を追加予定

      // トランザクションIDの存在確認
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final isValid = status.transactionId == transactionId && 
                     _isSubscriptionValid(status);

      _log('Purchase validation result: $isValid', level: LogLevel.info);

      return Success(isValid);
    } catch (e) {
      return _handleError(e, 'validatePurchase', details: transactionId);
    }
  }

  /// サブスクリプションが有効かどうかをチェック（ヘルパー）
  bool _isSubscriptionValid(SubscriptionStatus status) {
    if (!status.isActive) return false;

    // Basicプランは常に有効
    if (status.planId == SubscriptionConstants.basicPlanId) return true;

    // Premiumプランは有効期限をチェック
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }

  // =================================================================
  // 購入処理
  // =================================================================

  /// プランを購入
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('PurchaseManager is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      if (_isPurchasing) {
        return Failure(
          ServiceException('Another purchase is already in progress'),
        );
      }

      if (plan.id == BasicPlan().id) {
        return Failure(ServiceException('Basic plan cannot be purchased'));
      }

      _log(
        '購入処理開始',
        level: LogLevel.info,
        context: 'SubscriptionPurchaseManager.purchasePlanClass',
        data: {'planId': plan.id, 'productId': plan.productId},
      );
      _isPurchasing = true;

      // 商品IDを取得
      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);
      _log(
        '商品ID取得完了',
        level: LogLevel.debug,
        context: 'SubscriptionPurchaseManager.purchasePlanClass',
        data: {'productId': productId},
      );

      try {
        // 商品詳細を取得
        _log(
          '商品詳細をクエリ中',
          level: LogLevel.debug,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
          data: {'productId': productId},
        );
        final productResponse = await _inAppPurchase!.queryProductDetails({
          productId,
        });
        _log(
          '商品クエリ完了',
          level: LogLevel.debug,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
          data: {
            'error': productResponse.error,
            'productCount': productResponse.productDetails.length,
          },
        );

        if (productResponse.error != null) {
          _isPurchasing = false;
          return Failure(
            ServiceException(
              'Failed to get product details for purchase',
              details: productResponse.error.toString(),
            ),
          );
        }

        if (productResponse.productDetails.isEmpty) {
          _isPurchasing = false;
          return Failure(ServiceException('Product not found: $productId'));
        }

        final productDetails = productResponse.productDetails.first;
        _log(
          '商品詳細取得',
          level: LogLevel.info,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
          data: {
            'id': productDetails.id,
            'title': productDetails.title,
            'price': productDetails.price,
          },
        );

        // 購入リクエストを作成
        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );

        // 購入を開始（サブスクリプションはbuyNonConsumableを使用）
        _log(
          'buyNonConsumable呼び出し中',
          level: LogLevel.info,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
        );
        final bool success = await _inAppPurchase!.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        _log(
          'buyNonConsumable結果',
          level: LogLevel.info,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
          data: {'success': success},
        );

        if (!success) {
          _isPurchasing = false;
          return Failure(ServiceException('Failed to initiate purchase'));
        }

        _log(
          '購入処理が正常に開始されました',
          level: LogLevel.info,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
        );

        // 購入結果は購入ストリームで非同期に処理される
        // ここでは購入開始の成功を返す
        return Success(
          PurchaseResult(
            status: ssi.PurchaseStatus.pending,
            productId: productId,
            plan: plan,
          ),
        );
      } catch (storeError) {
        _isPurchasing = false;
        _log(
          'ストアエラー発生',
          level: LogLevel.error,
          context: 'SubscriptionPurchaseManager.purchasePlanClass',
          error: storeError,
        );

        // シミュレーター環境でのストアエラー処理
        if (kDebugMode && Platform.isIOS) {
          final errorString = storeError.toString();
          if (errorString.contains('not connected to app store') ||
              errorString.contains('sandbox') ||
              errorString.contains('StoreKit')) {
            _log(
              'シミュレーター環境のストア接続エラー - 成功をモック',
              level: LogLevel.warning,
              context: 'SubscriptionPurchaseManager.purchasePlanClass',
            );

            await Future.delayed(const Duration(milliseconds: 1000));
            
            // モック成功のためのダミー状態作成
            final now = DateTime.now();
            DateTime expiryDate;
            if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
              expiryDate = now.add(const Duration(days: 30));
            } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
              expiryDate = now.add(const Duration(days: 365));
            } else {
              expiryDate = now.add(const Duration(days: 30));
            }

            final mockStatus = SubscriptionStatus(
              planId: plan.id,
              isActive: true,
              startDate: now,
              expiryDate: expiryDate,
              autoRenewal: true,
              monthlyUsageCount: 0,
              lastResetDate: now,
              transactionId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
              lastPurchaseDate: now,
            );

            _onSubscriptionStatusUpdate?.call(mockStatus);
            
            return Success(
              PurchaseResult(
                status: ssi.PurchaseStatus.purchased,
                productId: productId,
                plan: plan,
                purchaseDate: now,
              ),
            );
          }
        }

        // その他のエラーは再スロー
        rethrow;
      }
    } catch (e) {
      _isPurchasing = false;
      _log(
        '予期しないエラー',
        level: LogLevel.error,
        context: 'SubscriptionPurchaseManager.purchasePlanClass',
        error: e,
      );
      return _handleError(
        e,
        'purchasePlanClass',
        details: 'planId: ${plan.id}, productId: ${plan.productId}',
      );
    }
  }

  /// プランを変更
  Future<Result<void>> changePlanClass(Plan newPlan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('PurchaseManager is not initialized'),
        );
      }

      // 直接実装（プラン変更は将来の実装予定）
      return Failure(
        ServiceException(
          'Plan change is not yet implemented',
          details: 'This feature will be available in future versions',
        ),
      );
    } catch (e) {
      return _handleError(e, 'changePlanClass', details: newPlan.id);
    }
  }

  /// サブスクリプションをキャンセル
  Future<Result<void>> cancelSubscription(
    Function() getCurrentStatus,
    Function(SubscriptionStatus) updateStatus,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('PurchaseManager is not initialized'),
        );
      }

      _log('Canceling subscription...', level: LogLevel.info);

      // プラットフォーム側での自動更新停止はユーザーが設定アプリで行う
      // ここではローカル状態の更新のみ実行

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

      _log('Subscription auto-renewal disabled', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'cancelSubscription');
    }
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  Future<void> dispose() async {
    _log('Disposing SubscriptionPurchaseManager...', level: LogLevel.info);

    // 購入ストリーム監視を停止
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    // ストリームコントローラーを閉じる
    await _purchaseStreamController.close();

    // In-App Purchaseリソースをクリア
    _inAppPurchase = null;
    _isInitialized = false;

    _log('SubscriptionPurchaseManager disposed', level: LogLevel.info);
  }
}