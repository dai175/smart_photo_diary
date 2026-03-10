import 'package:flutter/foundation.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../config/environment_config.dart';
import 'interfaces/feature_access_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'mixins/service_logging.dart';

/// FeatureAccessService
///
/// プラン別の機能アクセス権限チェックを担当する。
class FeatureAccessService
    with ServiceLogging
    implements IFeatureAccessService {
  final ISubscriptionStateService _stateService;
  final ILoggingService? _loggingService;

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  String get logTag => 'FeatureAccessService';

  FeatureAccessService({
    required ISubscriptionStateService stateService,
    ILoggingService? logger,
  }) : _stateService = stateService,
       _loggingService = logger;

  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    // デバッグモードでプラン強制設定をチェック
    if (kDebugMode) {
      final forcePlan = EnvironmentConfig.forcePlan;
      log(
        'Debug mode check',
        level: LogLevel.debug,
        data: {'forcePlan': forcePlan},
      );
      if (forcePlan != null) {
        final forceResult = forcePlan.toLowerCase().startsWith('premium');
        log(
          'Forced plan setting: Premium access',
          level: LogLevel.debug,
          data: {'access': forceResult, 'plan': forcePlan},
        );
        return Success(forceResult);
      } else {
        log(
          'No forced plan setting, proceeding with normal plan check',
          level: LogLevel.debug,
        );
      }
    }

    return _checkFeatureAccess('Premium features');
  }

  @override
  Future<Result<bool>> canAccessWritingPrompts() async {
    // Writing prompts are accessible for all plans (Basic gets limited set,
    // Premium gets full set — filtering is handled by PromptService).
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }
      log(
        'Writing prompts access: accessible for all plans',
        level: LogLevel.debug,
      );
      return const Success(true);
    } catch (e) {
      log(
        'Error checking writing prompts access',
        level: LogLevel.error,
        error: e,
      );
      return Failure(
        ServiceException(
          'Failed to check writing prompts access',
          details: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<bool>> canAccessAdvancedFilters() async {
    return _checkFeatureAccess('Advanced filters');
  }

  @override
  Future<Result<bool>> canAccessAdvancedAnalytics() async {
    return _checkFeatureAccess('Advanced analytics');
  }

  @override
  Future<Result<bool>> canAccessPrioritySupport() async {
    return _checkFeatureAccess('Priority support');
  }

  @override
  Future<Result<bool>> canAccessDataExport() async {
    return _checkFeatureAccess('Data export', basicPlanResult: true);
  }

  @override
  Future<Result<bool>> canAccessStatsDashboard() async {
    return _checkFeatureAccess('Stats dashboard');
  }

  @override
  Future<Result<Map<String, bool>>> getFeatureAccess() async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      final results = await Future.wait([
        canAccessPremiumFeatures(),
        canAccessWritingPrompts(),
        canAccessAdvancedFilters(),
        canAccessAdvancedAnalytics(),
        canAccessPrioritySupport(),
        canAccessDataExport(),
        canAccessStatsDashboard(),
      ]);

      final keys = [
        'premiumFeatures',
        'writingPrompts',
        'advancedFilters',
        'advancedAnalytics',
        'prioritySupport',
        'dataExport',
        'statsDashboard',
      ];

      for (final result in results) {
        if (result.isFailure) return Failure(result.error);
      }

      final featureAccess = {
        for (var i = 0; i < keys.length; i++) keys[i]: results[i].value,
      };

      log('Feature access map', level: LogLevel.debug, data: featureAccess);
      return Success(featureAccess);
    } catch (e) {
      log('Error getting feature access', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to get feature access', details: e.toString()),
      );
    }
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  Future<Result<bool>> _checkFeatureAccess(
    String featureName, {
    bool basicPlanResult = false,
  }) async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      final statusResult = await _stateService.getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      if (currentPlan is BasicPlan) {
        return Success(basicPlanResult);
      }

      final isPremiumValid = _stateService.isSubscriptionValid(status);
      log(
        '$featureName access check',
        level: LogLevel.debug,
        data: {'plan': currentPlan.id, 'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      log(
        'Error checking $featureName access',
        level: LogLevel.error,
        error: e,
      );
      return Failure(
        ServiceException(
          'Failed to check $featureName access',
          details: e.toString(),
        ),
      );
    }
  }
}
