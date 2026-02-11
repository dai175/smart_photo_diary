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
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';

/// SubscriptionStateService
///
/// サブスクリプション状態の永続化（Hive）、プラン情報取得、
/// 状態変更通知を担当する基盤サービス。
class SubscriptionStateService implements ISubscriptionStateService {
  // Hiveボックス
  Box<SubscriptionStatus>? _subscriptionBox;

  // 初期化フラグ
  bool _isInitialized = false;

  // ロギングサービス
  ILoggingService? _loggingService;

  /// DI用の公開コンストラクタ
  SubscriptionStateService();

  /// サービス初期化処理
  ///
  /// Hiveボックスの初期化と初期データ作成を実行
  Future<void> _initialize() async {
    if (_isInitialized) {
      _log(
        'SubscriptionStateService already initialized',
        level: LogLevel.debug,
      );
      return;
    }

    try {
      _log('Initializing SubscriptionStateService...', level: LogLevel.info);

      // LoggingServiceを取得（ServiceLocator経由、未登録時はnullのまま）
      try {
        _loggingService = ServiceLocator().get<ILoggingService>();
      } catch (_) {
        // テスト環境など、LoggingServiceが未登録の場合はnullのまま
      }

      // Hiveボックスを開く
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName,
      );

      // 初期状態の作成（まだ状態が存在しない場合）
      await _ensureInitialStatus();

      _isInitialized = true;
      _log(
        'SubscriptionStateService initialization completed successfully',
        level: LogLevel.info,
      );
    } catch (e) {
      final errorContext = 'SubscriptionStateService._initialize';
      _log(
        'SubscriptionStateService initialization failed',
        level: LogLevel.error,
        error: e,
        context: errorContext,
      );

      throw ErrorHandler.handleError(e, context: errorContext);
    }
  }

  /// 初期サブスクリプション状態の確保
  Future<void> _ensureInitialStatus() async {
    const statusKey = SubscriptionConstants.statusKey;

    if (_subscriptionBox?.get(statusKey) == null) {
      _log('Creating initial Basic plan status', level: LogLevel.info);

      final initialStatus = SubscriptionStatus(
        planId: BasicPlan().id,
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: null,
        autoRenewal: false,
        monthlyUsageCount: 0,
        lastResetDate: DateTime.now(),
        transactionId: null,
        lastPurchaseDate: null,
      );

      await _subscriptionBox?.put(statusKey, initialStatus);
      _log('Initial status created successfully', level: LogLevel.info);
    } else {
      _log('Existing status found, skipping creation', level: LogLevel.debug);
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<Result<void>> initialize() async {
    try {
      await _initialize();
      return const Success(null);
    } catch (e) {
      _log('Error in public initialize', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to initialize service', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      final status = _subscriptionBox?.get(SubscriptionConstants.statusKey);
      if (status == null) {
        await _ensureInitialStatus();
        final initialStatus = _subscriptionBox?.get(
          SubscriptionConstants.statusKey,
        );
        if (initialStatus == null) {
          return Failure(
            ServiceException('Failed to create initial subscription status'),
          );
        }
        return Success(initialStatus);
      }

      // デバッグモードでプラン強制設定がある場合、返り値のみを動的に変更
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        if (forcePlan != null) {
          _log(
            'プラン強制設定 - 返り値を$forcePlanとして返却（データベースは変更せず）',
            level: LogLevel.debug,
            data: {'forcedPlan': forcePlan},
          );

          final forcedPlanId = _getForcedPlanId(forcePlan);
          final forcedPlan = PlanFactory.createPlan(forcedPlanId);

          final expiryDuration =
              forcedPlan.id == SubscriptionConstants.premiumYearlyPlanId
              ? const Duration(days: 365)
              : const Duration(days: 30);

          final forcedStatus = status.copyWith(
            planId: forcedPlanId,
            isActive: true,
            startDate: status.startDate ?? DateTime.now(),
            expiryDate: DateTime.now().add(expiryDuration),
          );

          return Success(forcedStatus);
        }
      }

      return Success(status);
    } catch (e) {
      _log('Error getting current status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to get current status', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, status);
      _log('Status updated successfully', level: LogLevel.info);
      return const Success(null);
    } catch (e) {
      _log('Error updating status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to update status', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> refreshStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      await _subscriptionBox?.close();
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName,
      );

      return const Success(null);
    } catch (e) {
      _log('Error refreshing status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to refresh status', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<SubscriptionStatus>> createStatusForPlan(Plan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      final now = DateTime.now();
      SubscriptionStatus newStatus;

      if (plan is BasicPlan) {
        newStatus = SubscriptionStatus(
          planId: plan.id,
          isActive: true,
          startDate: now,
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: null,
          lastPurchaseDate: null,
        );
      } else {
        final expiryDate = plan.isYearly
            ? now.add(
                Duration(days: SubscriptionConstants.subscriptionYearDays),
              )
            : now.add(
                Duration(days: SubscriptionConstants.subscriptionMonthDays),
              );

        newStatus = SubscriptionStatus(
          planId: plan.id,
          isActive: true,
          startDate: now,
          expiryDate: expiryDate,
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: null,
          lastPurchaseDate: now,
        );
      }

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, newStatus);
      _log(
        'Created new status for plan',
        level: LogLevel.info,
        data: {'planId': plan.id},
      );
      return Success(newStatus);
    } catch (e) {
      _log('Error creating status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to create status', details: e.toString()),
      );
    }
  }

  @override
  Result<Plan> getPlanClass(String planId) {
    try {
      _log(
        'Getting plan class by ID',
        level: LogLevel.debug,
        data: {'planId': planId},
      );

      final plan = PlanFactory.createPlan(planId);

      _log(
        'Successfully retrieved plan class',
        level: LogLevel.debug,
        data: {'planId': plan.id, 'displayName': plan.displayName},
      );

      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getPlanClass', details: 'planId: $planId');
    }
  }

  @override
  Future<Result<Plan>> getCurrentPlanClass() async {
    try {
      _log('Getting current plan class', level: LogLevel.debug);

      if (!_isInitialized) {
        return _handleError(
          StateError('Service not initialized'),
          'getCurrentPlanClass',
          details: 'SubscriptionStateService must be initialized before use',
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        _log(
          'Failed to get current status',
          level: LogLevel.warning,
          error: statusResult.error,
        );
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final plan = PlanFactory.createPlan(status.planId);

      _log(
        'Successfully retrieved current plan class',
        level: LogLevel.debug,
        data: {'planId': plan.id, 'displayName': plan.displayName},
      );

      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getCurrentPlanClass');
    }
  }

  @override
  Stream<SubscriptionStatus> get statusStream {
    return Stream.periodic(const Duration(minutes: 5), (_) async {
          final statusResult = await getCurrentStatus();
          return statusResult.isSuccess ? statusResult.value : null;
        })
        .asyncMap((statusFuture) => statusFuture)
        .where((status) => status != null)
        .cast<SubscriptionStatus>();
  }

  @override
  Future<void> dispose() async {
    _log('Disposing SubscriptionStateService...', level: LogLevel.info);
    await _subscriptionBox?.close();
    _log('SubscriptionStateService disposed', level: LogLevel.info);
  }

  // =================================================================
  // 公開ヘルパーメソッド（他サービスから利用）
  // =================================================================

  /// サブスクリプションが有効かどうかをチェック
  bool isSubscriptionValid(SubscriptionStatus status) {
    if (!status.isActive) return false;

    final currentPlan = PlanFactory.createPlan(status.planId);

    // Basicプランは常に有効
    if (currentPlan is BasicPlan) return true;

    // Premiumプランは有効期限をチェック
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }

  /// Hiveボックス取得（テスト用）
  @visibleForTesting
  Box<SubscriptionStatus>? get subscriptionBox => _subscriptionBox;

  /// サブスクリプション状態を削除（テスト用）
  @visibleForTesting
  Future<Result<void>> clearStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      await _subscriptionBox?.delete(SubscriptionConstants.statusKey);
      _log('Status cleared', level: LogLevel.info);
      return const Success(null);
    } catch (e) {
      _log('Error clearing status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to clear status', details: e.toString()),
      );
    }
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// 強制プラン名からプランIDを取得
  String _getForcedPlanId(String forcePlan) {
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

  /// 統一ログ出力メソッド
  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final logContext = context ?? 'SubscriptionStateService';

    if (_loggingService != null) {
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
          _loggingService!.error(message, context: logContext, error: error);
          break;
      }

      if (error != null && level != LogLevel.error) {
        _loggingService!.error('Error details: $error', context: logContext);
      }
    } else {
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
    final errorContext = 'SubscriptionStateService.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    _log(message, level: LogLevel.error, error: error, context: errorContext);

    final handledException = ErrorHandler.handleError(
      error,
      context: errorContext,
    );

    final serviceException = handledException is ServiceException
        ? handledException
        : ServiceException(
            'Failed to $operation',
            details: details ?? error.toString(),
            originalError: error,
          );

    return Failure(serviceException);
  }
}
