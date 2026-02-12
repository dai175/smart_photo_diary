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
import '../core/service_locator.dart';

/// FeatureAccessService
///
/// プラン別の機能アクセス権限チェックを担当する。
class FeatureAccessService
    with ServiceLogging
    implements IFeatureAccessService {
  final ISubscriptionStateService _stateService;
  ILoggingService? _loggingService;

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  String get logTag => 'FeatureAccessService';

  FeatureAccessService({required ISubscriptionStateService stateService})
    : _stateService = stateService {
    try {
      _loggingService = ServiceLocator().get<ILoggingService>();
    } catch (_) {
      // テスト環境など、LoggingServiceが未登録の場合はnullのまま
    }
  }

  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    // デバッグモードでプラン強制設定をチェック
    if (kDebugMode) {
      final forcePlan = EnvironmentConfig.forcePlan;
      log('デバッグモードチェック', level: LogLevel.debug, data: {'forcePlan': forcePlan});
      if (forcePlan != null) {
        final forceResult = forcePlan.toLowerCase().startsWith('premium');
        log(
          'プラン強制設定により Premium アクセス',
          level: LogLevel.debug,
          data: {'access': forceResult, 'plan': forcePlan},
        );
        return Success(forceResult);
      } else {
        log('プラン強制設定なし、通常のプランチェックに進む', level: LogLevel.debug);
      }
    }

    return _checkFeatureAccess('Premium features');
  }

  @override
  Future<Result<bool>> canAccessWritingPrompts() async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      // デバッグモードでプラン強制設定をチェック
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        if (forcePlan != null) {
          log(
            'プラン強制設定により Writing Prompts アクセス: true',
            level: LogLevel.debug,
            data: {'plan': forcePlan},
          );
          return const Success(true);
        }
      }

      final statusResult = await _stateService.getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      if (currentPlan is BasicPlan) {
        log(
          'Writing prompts access - Basic plan (limited prompts)',
          level: LogLevel.debug,
        );
        return const Success(true);
      }

      final isPremiumValid = _stateService.isSubscriptionValid(status);
      if (isPremiumValid) {
        log(
          'Writing prompts access - Premium plan',
          level: LogLevel.debug,
          data: {'valid': isPremiumValid},
        );
        return const Success(true);
      } else {
        log(
          'Writing prompts access - Premium plan expired/inactive, basic access only',
          level: LogLevel.debug,
        );
        return const Success(true);
      }
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
        log(
          'Data export access - Basic plan (JSON only)',
          level: LogLevel.debug,
        );
        return const Success(true);
      }

      final isPremiumValid = _stateService.isSubscriptionValid(status);
      log(
        'Data export access - Premium plan',
        level: LogLevel.debug,
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      log('Error checking data export access', level: LogLevel.error, error: e);
      return Failure(
        ServiceException(
          'Failed to check data export access',
          details: e.toString(),
        ),
      );
    }
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

      final premiumFeaturesResult = await canAccessPremiumFeatures();
      final writingPromptsResult = await canAccessWritingPrompts();
      final advancedFiltersResult = await canAccessAdvancedFilters();
      final advancedAnalyticsResult = await canAccessAdvancedAnalytics();
      final prioritySupportResult = await canAccessPrioritySupport();
      final dataExportResult = await canAccessDataExport();
      final statsDashboardResult = await canAccessStatsDashboard();

      if (premiumFeaturesResult.isFailure)
        return Failure(premiumFeaturesResult.error);
      if (writingPromptsResult.isFailure)
        return Failure(writingPromptsResult.error);
      if (advancedFiltersResult.isFailure)
        return Failure(advancedFiltersResult.error);
      if (advancedAnalyticsResult.isFailure)
        return Failure(advancedAnalyticsResult.error);
      if (prioritySupportResult.isFailure)
        return Failure(prioritySupportResult.error);
      if (dataExportResult.isFailure) return Failure(dataExportResult.error);
      if (statsDashboardResult.isFailure)
        return Failure(statsDashboardResult.error);

      final featureAccess = {
        'premiumFeatures': premiumFeaturesResult.value,
        'writingPrompts': writingPromptsResult.value,
        'advancedFilters': advancedFiltersResult.value,
        'advancedAnalytics': advancedAnalyticsResult.value,
        'prioritySupport': prioritySupportResult.value,
        'dataExport': dataExportResult.value,
        'statsDashboard': statsDashboardResult.value,
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

  Future<Result<bool>> _checkFeatureAccess(String featureName) async {
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
        return const Success(false);
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
