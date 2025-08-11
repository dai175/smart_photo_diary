import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:async';

import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/environment_config.dart';
import 'logging_service.dart';

/// SubscriptionStatusManager
///
/// サブスクリプションサービスのステータス管理機能を管理するクラス
/// SubscriptionService からステータス関連の機能を分離して責任を明確化
///
/// ## 主な機能
/// - サブスクリプション状態の取得・更新・管理
/// - プラン情報の取得と判定
/// - 有効期限の管理とチェック
/// - プレミアム機能のアクセス権限判定
///
/// ## 設計方針
/// - Result<T>パターンによる関数型エラーハンドリング
/// - 依存性注入によるテスト可能な設計
/// - デバッグモード対応（強制プラン設定）
/// - オフライン対応のローカル状態管理
class SubscriptionStatusManager {
  // =================================================================
  // プロパティ
  // =================================================================

  // Hiveボックス（SubscriptionServiceから注入）
  final Box<SubscriptionStatus> _subscriptionBox;
  
  // ロギングサービス（SubscriptionServiceから注入）
  final LoggingService _loggingService;

  // 初期化フラグ
  bool _isInitialized = false;

  // =================================================================
  // コンストラクタ
  // =================================================================

  /// コンストラクタ（依存性注入）
  SubscriptionStatusManager(
    this._subscriptionBox,
    this._loggingService,
  ) {
    _isInitialized = true;
    _log('SubscriptionStatusManager initialized', level: LogLevel.debug);
  }

  // =================================================================
  // プロパティアクセサー
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

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
    final logContext = context ?? 'SubscriptionStatusManager';

    // 構造化ログを使用
    switch (level) {
      case LogLevel.debug:
        _loggingService.debug(message, context: logContext, data: data);
        break;
      case LogLevel.info:
        _loggingService.info(message, context: logContext, data: data);
        break;
      case LogLevel.warning:
        _loggingService.warning(message, context: logContext, data: data);
        break;
      case LogLevel.error:
        _loggingService.error(message, context: logContext, error: data);
        break;
    }

    // エラーオブジェクトがある場合は追加ログ
    if (error != null) {
      _loggingService.error('Error details: $error', context: logContext);
    }
  }

  /// Result<T>パターンでのエラーハンドリングヘルパー
  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'SubscriptionStatusManager.$operation';
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
  // ステータス管理の中核メソッド
  // =================================================================

  /// 現在のサブスクリプション状態を取得
  ///
  /// デバッグモードでプラン強制設定がある場合、実際のデータは変更せずに
  /// 返り値のみプレミアムプランとして返します
  ///
  /// [Returns] 現在のサブスクリプション状態
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('StatusManager is not initialized'),
        );
      }

      _log('Getting current subscription status...', level: LogLevel.debug);

      // Hiveから現在の状態を取得
      final statusKey = SubscriptionConstants.statusKey;
      final storedStatus = _subscriptionBox.get(statusKey);

      SubscriptionStatus currentStatus;
      if (storedStatus == null) {
        _log(
          'No stored status found, creating initial Basic plan status',
          level: LogLevel.info,
        );

        // 初期状態（Basicプラン）を作成
        final basicPlan = BasicPlan();
        final initialStatusResult = await createStatus(basicPlan);
        
        if (initialStatusResult.isFailure) {
          return Failure(initialStatusResult.error);
        }
        
        currentStatus = initialStatusResult.value;
      } else {
        currentStatus = storedStatus;
        _log(
          'Retrieved status from storage',
          level: LogLevel.debug,
          data: {
            'planId': currentStatus.planId,
            'isActive': currentStatus.isActive,
            'expiryDate': currentStatus.expiryDate?.toIso8601String(),
          },
        );
      }

      // デバッグモードでの強制プラン設定チェック
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        if (forcePlan != null && forcePlan.isNotEmpty) {
          final forcedPlanId = getForcedPlanId(forcePlan);
          
          _log(
            'Debug mode: Force plan detected, returning modified status',
            level: LogLevel.warning,
            data: {'forcePlan': forcePlan, 'forcedPlanId': forcedPlanId},
          );

          // 実際のデータは変更せず、返り値のみ変更
          final modifiedStatus = SubscriptionStatus(
            planId: forcedPlanId,
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: forcedPlanId != SubscriptionConstants.basicPlanId
                ? DateTime.now().add(const Duration(days: 365))
                : null,
            autoRenewal: true,
            monthlyUsageCount: currentStatus.monthlyUsageCount,
            lastResetDate: currentStatus.lastResetDate,
            transactionId: 'debug_forced_${DateTime.now().millisecondsSinceEpoch}',
            lastPurchaseDate: DateTime.now(),
          );

          return Success(modifiedStatus);
        }
      }

      _log(
        'Successfully retrieved current subscription status',
        level: LogLevel.debug,
      );

      return Success(currentStatus);
    } catch (e) {
      return _handleError(e, 'getCurrentStatus');
    }
  }

  /// サブスクリプション状態を更新
  ///
  /// [status] 新しいサブスクリプション状態
  /// [Returns] 更新処理の結果
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('StatusManager is not initialized'),
        );
      }

      _log(
        'Updating subscription status...',
        level: LogLevel.info,
        data: {
          'planId': status.planId,
          'isActive': status.isActive,
          'expiryDate': status.expiryDate?.toIso8601String(),
        },
      );

      // Hiveに保存
      const statusKey = SubscriptionConstants.statusKey;
      await _subscriptionBox.put(statusKey, status);

      _log('Subscription status updated successfully', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(
        e,
        'updateStatus',
        details: 'planId: ${status.planId}',
      );
    }
  }

  /// サブスクリプション状態をリロード
  ///
  /// キャッシュを無視して最新の状態を取得します
  /// [Returns] リロード処理の結果
  Future<Result<void>> refreshStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('StatusManager is not initialized'),
        );
      }

      _log('Refreshing subscription status...', level: LogLevel.info);

      // 現在の状態を再取得（キャッシュはHiveが管理）
      final currentResult = await getCurrentStatus();
      if (currentResult.isFailure) {
        return Failure(currentResult.error);
      }

      _log('Subscription status refreshed successfully', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'refreshStatus');
    }
  }

  /// 指定されたプランでサブスクリプション状態を作成
  ///
  /// [plan] 作成するプラン
  /// [Returns] 作成されたサブスクリプション状態
  Future<Result<SubscriptionStatus>> createStatus(Plan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('StatusManager is not initialized'),
        );
      }

      _log(
        'Creating subscription status for plan',
        level: LogLevel.info,
        data: {'planId': plan.id, 'planName': plan.displayName},
      );

      final now = DateTime.now();

      // プランに応じた有効期限を設定
      DateTime? expiryDate;
      if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
        expiryDate = now.add(const Duration(days: 30));
      } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
        expiryDate = now.add(const Duration(days: 365));
      }
      // Basicプランは有効期限なし（null）

      // 新しいサブスクリプション状態を作成
      final newStatus = SubscriptionStatus(
        planId: plan.id,
        isActive: true,
        startDate: now,
        expiryDate: expiryDate,
        autoRenewal: plan.id != SubscriptionConstants.basicPlanId,
        monthlyUsageCount: 0,
        lastResetDate: now,
        transactionId: plan.id == SubscriptionConstants.basicPlanId
            ? ''
            : 'created_${now.millisecondsSinceEpoch}',
        lastPurchaseDate: plan.id == SubscriptionConstants.basicPlanId 
            ? null 
            : now,
      );

      // データベースに保存
      const statusKey = SubscriptionConstants.statusKey;
      await _subscriptionBox.put(statusKey, newStatus);

      _log(
        'Subscription status created and saved successfully',
        level: LogLevel.info,
        data: {'planId': newStatus.planId},
      );

      return Success(newStatus);
    } catch (e) {
      return _handleError(
        e,
        'createStatus',
        details: 'planId: ${plan.id}',
      );
    }
  }

  /// サブスクリプション状態を削除
  ///
  /// テスト用のメソッドです。本番環境では使用しないでください。
  /// [Returns] 削除処理の結果
  Future<Result<void>> clearStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('StatusManager is not initialized'),
        );
      }

      _log('Clearing subscription status (TEST ONLY)...', level: LogLevel.warning);

      // Hiveから削除
      const statusKey = SubscriptionConstants.statusKey;
      await _subscriptionBox.delete(statusKey);

      _log(
        'Subscription status cleared successfully',
        level: LogLevel.warning,
      );

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'clearStatus');
    }
  }

  // =================================================================
  // プラン管理メソッド
  // =================================================================

  /// 特定のプラン情報を取得
  ///
  /// [planId] 取得するプランのID
  /// [Returns] プラン情報
  Result<Plan> getPlanClass(String planId) {
    try {
      _log(
        'Getting plan information',
        level: LogLevel.debug,
        data: {'planId': planId},
      );

      final plan = PlanFactory.createPlan(planId);

      _log('Plan information retrieved successfully', level: LogLevel.debug);

      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getPlanClass', details: 'planId: $planId');
    }
  }

  /// 現在のプランを取得
  ///
  /// [Returns] 現在のプラン情報
  Future<Result<Plan>> getCurrentPlanClass() async {
    try {
      _log('Getting current plan...', level: LogLevel.debug);

      // 現在の状態を取得
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      
      // プラン情報を取得
      final planResult = getPlanClass(status.planId);
      if (planResult.isFailure) {
        return Failure(planResult.error);
      }

      final plan = planResult.value;

      _log(
        'Current plan retrieved successfully',
        level: LogLevel.debug,
        data: {'planId': plan.id, 'planName': plan.displayName},
      );

      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getCurrentPlanClass');
    }
  }

  /// 強制プラン名からプランIDを取得（デバッグ用）
  ///
  /// [forcePlan] 強制プラン名（premium等）
  /// [Returns] 対応するプランID
  String getForcedPlanId(String forcePlan) {
    switch (forcePlan.toLowerCase()) {
      case 'premium':
      case 'premium_monthly':
        return SubscriptionConstants.premiumMonthlyPlanId;
      case 'premium_yearly':
        return SubscriptionConstants.premiumYearlyPlanId;
      case 'basic':
      default:
        return SubscriptionConstants.basicPlanId;
    }
  }

  // =================================================================
  // 有効性判定メソッド
  // =================================================================

  /// サブスクリプションが有効かどうかをチェック
  ///
  /// [status] チェックするサブスクリプション状態
  /// [Returns] 有効かどうか
  bool isSubscriptionValid(SubscriptionStatus status) {
    if (!status.isActive) return false;

    // Basicプランは常に有効
    if (status.planId == SubscriptionConstants.basicPlanId) return true;

    // Premiumプランは有効期限をチェック
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }

  /// プレミアム機能にアクセスできるかどうか
  ///
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessPremiumFeatures() async {
    try {
      _log('Checking premium features access...', level: LogLevel.debug);

      // 現在の状態を取得
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;

      // サブスクリプションの有効性をチェック
      if (!isSubscriptionValid(status)) {
        _log('Premium features access denied: inactive subscription', level: LogLevel.debug);
        return const Success(false);
      }

      // プレミアムプランかどうかをチェック
      final isPremium = status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
                       status.planId == SubscriptionConstants.premiumYearlyPlanId;

      _log(
        'Premium features access check completed',
        level: LogLevel.debug,
        data: {'hasAccess': isPremium, 'planId': status.planId},
      );

      return Success(isPremium);
    } catch (e) {
      return _handleError(e, 'canAccessPremiumFeatures');
    }
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  void dispose() {
    _log('Disposing SubscriptionStatusManager...', level: LogLevel.info);
    _isInitialized = false;
    _log('SubscriptionStatusManager disposed', level: LogLevel.info);
  }
}