import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'dart:async';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'mixins/service_logging.dart';
import 'subscription_plan_resolver.dart';
import 'subscription_limit_checker.dart';

class SubscriptionStateService
    with ServiceLogging
    implements ISubscriptionStateService {
  Box<SubscriptionStatus>? _subscriptionBox;
  bool _isInitialized = false;
  final StreamController<SubscriptionStatus> _statusController =
      StreamController<SubscriptionStatus>.broadcast();
  final ILoggingService? _loggingService;

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  String get logTag => 'SubscriptionStateService';

  SubscriptionStateService({ILoggingService? logger})
    : _loggingService = logger;

  Future<void> _initialize() async {
    if (_isInitialized) {
      log(
        'SubscriptionStateService already initialized',
        level: LogLevel.debug,
      );
      return;
    }

    try {
      log('Initializing SubscriptionStateService...', level: LogLevel.info);
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName,
      );
      await _ensureInitialStatus();
      _isInitialized = true;
      log(
        'SubscriptionStateService initialization completed successfully',
        level: LogLevel.info,
      );
    } catch (e) {
      const errorContext = 'SubscriptionStateService._initialize';
      log(
        'SubscriptionStateService initialization failed',
        level: LogLevel.error,
        error: e,
        context: errorContext,
      );
      throw ErrorHandler.handleError(e, context: errorContext);
    }
  }

  Future<void> _ensureInitialStatus() async {
    const statusKey = SubscriptionConstants.statusKey;
    if (_subscriptionBox?.get(statusKey) == null) {
      log('Creating initial Basic plan status', level: LogLevel.info);
      final initialStatus = SubscriptionPlanResolver.buildStatusForPlan(
        BasicPlan(),
      );
      await _subscriptionBox?.put(statusKey, initialStatus);
      log('Initial status created successfully', level: LogLevel.info);
    } else {
      log('Existing status found, skipping creation', level: LogLevel.debug);
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
      log('Error in public initialize', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to initialize service', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    try {
      final rawResult = await _readPersistedStatus();
      if (rawResult.isFailure) return rawResult;
      final resolved = SubscriptionPlanResolver.applyForcePlan(
        rawResult.value,
        logger: _loggingService,
      );
      return Success(resolved);
    } catch (e) {
      log('Error getting current status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to get current status', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<SubscriptionStatus>> getRawStatus() async {
    try {
      return await _readPersistedStatus();
    } catch (e) {
      log('Error getting raw status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to get raw status', details: e.toString()),
      );
    }
  }

  /// Hive から永続化済みステータスを取得する共通処理。
  ///
  /// forcePlan などの動的上書きは適用しない。
  Future<Result<SubscriptionStatus>> _readPersistedStatus() async {
    if (!_isInitialized) {
      return const Failure(
        ServiceException('SubscriptionStateService is not initialized'),
      );
    }

    final status = _subscriptionBox?.get(SubscriptionConstants.statusKey);
    if (status != null) return Success(status);

    await _ensureInitialStatus();
    final initialStatus = _subscriptionBox?.get(
      SubscriptionConstants.statusKey,
    );
    if (initialStatus == null) {
      return const Failure(
        ServiceException('Failed to create initial subscription status'),
      );
    }
    return Success(initialStatus);
  }

  @override
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    try {
      if (!_isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }
      if (_subscriptionBox == null) {
        return const Failure(
          ServiceException('Subscription box is not available'),
        );
      }
      await _subscriptionBox!.put(SubscriptionConstants.statusKey, status);
      log('Status updated successfully', level: LogLevel.info);
      await _emitStatusChange();
      return const Success(null);
    } catch (e) {
      log('Error updating status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to update status', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> refreshStatus() async {
    try {
      if (!_isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }
      await _subscriptionBox?.close();
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName,
      );
      await _emitStatusChange();
      return const Success(null);
    } catch (e) {
      log('Error refreshing status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to refresh status', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<SubscriptionStatus>> createStatusForPlan(Plan plan) async {
    try {
      if (!_isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }
      if (_subscriptionBox == null) {
        return const Failure(
          ServiceException('Subscription box is not available'),
        );
      }
      final newStatus = SubscriptionPlanResolver.buildStatusForPlan(plan);
      await _subscriptionBox!.put(SubscriptionConstants.statusKey, newStatus);
      log(
        'Created new status for plan',
        level: LogLevel.info,
        data: {'planId': plan.id},
      );
      await _emitStatusChange();
      return Success(newStatus);
    } catch (e) {
      log('Error creating status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to create status', details: e.toString()),
      );
    }
  }

  @override
  Result<Plan> getPlanClass(String planId) {
    try {
      return SubscriptionPlanResolver.resolve(planId);
    } catch (e) {
      return _handleError(e, 'getPlanClass', details: 'planId: $planId');
    }
  }

  @override
  Future<Result<Plan>> getCurrentPlanClass() async {
    try {
      if (!_isInitialized) {
        return _handleError(
          StateError('Service not initialized'),
          'getCurrentPlanClass',
          details: 'SubscriptionStateService must be initialized before use',
        );
      }
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) return Failure(statusResult.error);
      return SubscriptionPlanResolver.resolve(statusResult.value.planId);
    } catch (e) {
      return _handleError(e, 'getCurrentPlanClass');
    }
  }

  @override
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;

  /// forcePlan などの動的上書きを適用した実効ステータスを流すため、
  /// 永続化済みの値ではなく [getCurrentStatus] の結果を emit する。
  Future<void> _emitStatusChange() async {
    if (_statusController.isClosed) return;
    final statusResult = await getCurrentStatus();
    if (statusResult.isSuccess && !_statusController.isClosed) {
      _statusController.add(statusResult.value);
    }
  }

  @override
  Future<void> dispose() async {
    log('Disposing SubscriptionStateService...', level: LogLevel.info);
    await _subscriptionBox?.close();
    await _statusController.close();
    _isInitialized = false;
    log('SubscriptionStateService disposed', level: LogLevel.info);
  }

  @override
  bool isSubscriptionValid(SubscriptionStatus status) =>
      SubscriptionLimitChecker.isValid(status);

  @visibleForTesting
  Box<SubscriptionStatus>? get subscriptionBox => _subscriptionBox;

  @visibleForTesting
  Future<Result<void>> clearStatus() async {
    try {
      if (!_isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }
      await _subscriptionBox?.delete(SubscriptionConstants.statusKey);
      log('Status cleared', level: LogLevel.info);
      return const Success(null);
    } catch (e) {
      log('Error clearing status', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to clear status', details: e.toString()),
      );
    }
  }

  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'SubscriptionStateService.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';
    log(message, level: LogLevel.error, error: error, context: errorContext);
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
