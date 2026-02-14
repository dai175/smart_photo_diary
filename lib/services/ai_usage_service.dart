import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan_factory.dart';
import 'interfaces/ai_usage_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'mixins/service_logging.dart';
import '../core/service_locator.dart';

/// AiUsageService
///
/// AI生成の使用量追跡、月次リセット、残回数計算を担当する。
class AiUsageService with ServiceLogging implements IAiUsageService {
  final ISubscriptionStateService _stateService;
  ILoggingService? _loggingService;

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  String get logTag => 'AiUsageService';

  AiUsageService({required ISubscriptionStateService stateService})
    : _stateService = stateService {
    try {
      _loggingService = ServiceLocator().get<ILoggingService>();
    } catch (_) {
      // テスト環境など、LoggingServiceが未登録の場合はnullのまま
    }
  }

  @override
  Future<Result<bool>> canUseAiGeneration() async {
    try {
      log('Checking AI generation usage availability', level: LogLevel.debug);

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

      if (!_stateService.isSubscriptionValid(status)) {
        log(
          'Subscription is not valid - AI generation unavailable',
          level: LogLevel.warning,
          data: {'planId': status.planId, 'isActive': status.isActive},
        );
        return const Success(false);
      }

      await _resetMonthlyUsageIfNeeded(status);

      final updatedStatusResult = await _stateService.getCurrentStatus();
      if (updatedStatusResult.isFailure) {
        return Failure(updatedStatusResult.error);
      }

      final updatedStatus = updatedStatusResult.value;
      final currentPlan = PlanFactory.createPlan(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

      final canUse = updatedStatus.monthlyUsageCount < monthlyLimit;

      log(
        'AI generation availability check completed',
        level: LogLevel.debug,
        data: {
          'usage': updatedStatus.monthlyUsageCount,
          'limit': monthlyLimit,
          'canUse': canUse,
          'planId': currentPlan.id,
        },
      );

      return Success(canUse);
    } catch (e) {
      log('Error checking AI generation', level: LogLevel.error, error: e);
      return Failure(
        ServiceException(
          'Failed to check AI generation availability',
          details: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<void>> incrementAiUsage() async {
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

      if (!_stateService.isSubscriptionValid(status)) {
        return const Failure(
          ServiceException('Cannot increment usage: subscription is not valid'),
        );
      }

      await _resetMonthlyUsageIfNeeded(status);

      final latestStatusResult = await _stateService.getCurrentStatus();
      if (latestStatusResult.isFailure) {
        return Failure(latestStatusResult.error);
      }

      final latestStatus = latestStatusResult.value;
      final currentPlan = PlanFactory.createPlan(latestStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

      if (latestStatus.monthlyUsageCount >= monthlyLimit) {
        return Failure(
          ServiceException(
            'Monthly AI generation limit reached: ${latestStatus.monthlyUsageCount}/$monthlyLimit',
          ),
        );
      }

      final updatedStatus = latestStatus.copyWith(
        monthlyUsageCount: latestStatus.monthlyUsageCount + 1,
      );

      await _stateService.updateStatus(updatedStatus);
      log(
        'AI usage incremented',
        level: LogLevel.info,
        data: {'usage': updatedStatus.monthlyUsageCount, 'limit': monthlyLimit},
      );

      return const Success(null);
    } catch (e) {
      log('Error incrementing AI usage', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to increment AI usage', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<int>> getRemainingGenerations() async {
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

      if (!_stateService.isSubscriptionValid(status)) {
        return const Success(0);
      }

      await _resetMonthlyUsageIfNeeded(status);

      final updatedStatusResult = await _stateService.getCurrentStatus();
      if (updatedStatusResult.isFailure) {
        return Failure(updatedStatusResult.error);
      }

      final updatedStatus = updatedStatusResult.value;
      final currentPlan = PlanFactory.createPlan(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      final remaining = monthlyLimit - updatedStatus.monthlyUsageCount;

      return Success(remaining > 0 ? remaining : 0);
    } catch (e) {
      log(
        'Error getting remaining generations',
        level: LogLevel.error,
        error: e,
      );
      return Failure(
        ServiceException(
          'Failed to get remaining generations',
          details: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<int>> getMonthlyUsage() async {
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
      return Success(status.monthlyUsageCount);
    } catch (e) {
      log('Error getting monthly usage', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to get monthly usage', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> resetUsage() async {
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
      final resetStatus = status.copyWith(
        monthlyUsageCount: 0,
        lastResetDate: DateTime.now(),
        usageMonth: _getCurrentMonth(),
      );

      await _stateService.updateStatus(resetStatus);
      log('Usage manually reset', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      log('Error resetting usage', level: LogLevel.error, error: e);
      return Failure(
        ServiceException('Failed to reset usage', details: e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> resetMonthlyUsageIfNeeded() async {
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
      await _resetMonthlyUsageIfNeeded(status);
      return const Success(null);
    } catch (e) {
      log('Error resetting monthly usage', level: LogLevel.error, error: e);
      return Failure(
        ServiceException(
          'Failed to reset monthly usage',
          details: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<DateTime>> getNextResetDate() async {
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
      final nextResetDate = _calculateNextResetDate(status.lastResetDate);

      return Success(nextResetDate);
    } catch (e) {
      log('Error getting next reset date', level: LogLevel.error, error: e);
      return Failure(
        ServiceException(
          'Failed to get next reset date',
          details: e.toString(),
        ),
      );
    }
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  Future<void> _resetMonthlyUsageIfNeeded(SubscriptionStatus status) async {
    final currentMonth = _getCurrentMonth();
    final statusMonth = _getUsageMonth(status);

    if (statusMonth != currentMonth) {
      log(
        'Resetting monthly usage',
        level: LogLevel.info,
        data: {'previousMonth': statusMonth, 'currentMonth': currentMonth},
      );

      final resetStatus = status.copyWith(
        monthlyUsageCount: 0,
        lastResetDate: DateTime.now(),
        usageMonth: currentMonth,
      );

      await _stateService.updateStatus(resetStatus);
    }
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  String _getUsageMonth(SubscriptionStatus status) {
    if (status.lastResetDate != null) {
      final resetDate = status.lastResetDate!;
      return '${resetDate.year.toString().padLeft(4, '0')}-${resetDate.month.toString().padLeft(2, '0')}';
    }
    return _getCurrentMonth();
  }

  DateTime _calculateNextResetDate(DateTime? lastResetDate) {
    final baseDate = lastResetDate ?? DateTime.now();
    final currentYear = baseDate.year;
    final currentMonth = baseDate.month;

    if (currentMonth == 12) {
      return DateTime(currentYear + 1, 1, 1);
    } else {
      return DateTime(currentYear, currentMonth + 1, 1);
    }
  }
}
