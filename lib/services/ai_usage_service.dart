import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan_factory.dart';
import 'interfaces/ai_usage_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'mixins/service_logging.dart';
import '../utils/date_utils.dart';

/// AiUsageService
///
/// AI生成の使用量追跡、月次リセット、残回数計算を担当する。
class AiUsageService with ServiceLogging implements IAiUsageService {
  final ISubscriptionStateService _stateService;
  final ILoggingService? _loggingService;

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  String get logTag => 'AiUsageService';

  AiUsageService({
    required ISubscriptionStateService stateService,
    ILoggingService? logger,
  }) : _stateService = stateService,
       _loggingService = logger;

  @override
  Future<Result<bool>> canUseAiGeneration() async {
    try {
      log('Checking AI generation usage availability', level: LogLevel.debug);

      final statusResult = await _getInitializedStatus();
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

      final usageCount = await _resetMonthlyUsageIfNeeded(status);
      final currentPlan = PlanFactory.createPlan(status.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      final canUse = usageCount < monthlyLimit;

      log(
        'AI generation availability check completed',
        level: LogLevel.debug,
        data: {
          'usage': usageCount,
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
      final statusResult = await _getInitializedStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;

      if (!_stateService.isSubscriptionValid(status)) {
        return const Failure(
          ServiceException('Cannot increment usage: subscription is not valid'),
        );
      }

      final usageCount = await _resetMonthlyUsageIfNeeded(status);
      final currentPlan = PlanFactory.createPlan(status.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

      if (usageCount >= monthlyLimit) {
        return Failure(
          ServiceException(
            'Monthly AI generation limit reached: $usageCount/$monthlyLimit',
          ),
        );
      }

      // forcePlan 由来の planId/expiryDate を永続化しないよう raw を経由する
      final rawStatusResult = await _getInitializedRawStatus();
      if (rawStatusResult.isFailure) {
        return Failure(rawStatusResult.error);
      }
      final rawStatus = rawStatusResult.value;
      final updatedStatus = rawStatus.copyWith(
        monthlyUsageCount: rawStatus.monthlyUsageCount + 1,
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
      final statusResult = await _getInitializedStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;

      if (!_stateService.isSubscriptionValid(status)) {
        return const Success(0);
      }

      final usageCount = await _resetMonthlyUsageIfNeeded(status);
      final currentPlan = PlanFactory.createPlan(status.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      final remaining = monthlyLimit - usageCount;

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
      final statusResult = await _getInitializedStatus();
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
      final rawStatusResult = await _getInitializedRawStatus();
      if (rawStatusResult.isFailure) {
        return Failure(rawStatusResult.error);
      }

      final resetStatus = rawStatusResult.value.copyWith(
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
      final statusResult = await _getInitializedStatus();
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
      final statusResult = await _getInitializedStatus();
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

  /// 初期化チェック + ステータス取得を一括で行うヘルパー
  Future<Result<SubscriptionStatus>> _getInitializedStatus() async {
    if (!_stateService.isInitialized) {
      return const Failure(
        ServiceException('SubscriptionStateService is not initialized'),
      );
    }
    return _stateService.getCurrentStatus();
  }

  /// 書き戻し用: 初期化チェック + raw ステータス取得を一括で行うヘルパー
  ///
  /// forcePlan で上書きされた値を DB に書き戻さないよう、永続化操作の直前に
  /// 必ずこの helper 経由で raw status を取得する。
  Future<Result<SubscriptionStatus>> _getInitializedRawStatus() async {
    if (!_stateService.isInitialized) {
      return const Failure(
        ServiceException('SubscriptionStateService is not initialized'),
      );
    }
    return _stateService.getRawStatus();
  }

  /// 月次リセットを必要に応じて適用し、適用後の使用量カウントを返す。
  ///
  /// [status] は forced view を許容するが、`monthlyUsageCount` /
  /// `lastResetDate` は forced と raw で同値のため判定に使える。リセット時のみ
  /// raw を取得して書き戻す。raw 取得に失敗した場合は best-effort として
  /// `status.monthlyUsageCount` をそのまま返し、呼び出し側のフローを止めない。
  Future<int> _resetMonthlyUsageIfNeeded(SubscriptionStatus status) async {
    final currentMonth = _getCurrentMonth();
    final statusMonth = _getUsageMonth(status);

    if (statusMonth == currentMonth) {
      return status.monthlyUsageCount;
    }

    log(
      'Resetting monthly usage',
      level: LogLevel.info,
      data: {'previousMonth': statusMonth, 'currentMonth': currentMonth},
    );

    final rawStatusResult = await _getInitializedRawStatus();
    if (rawStatusResult.isFailure) {
      log(
        'Failed to fetch raw status for reset; skipping reset',
        level: LogLevel.warning,
        error: rawStatusResult.error,
      );
      return status.monthlyUsageCount;
    }

    final resetStatus = rawStatusResult.value.copyWith(
      monthlyUsageCount: 0,
      lastResetDate: DateTime.now(),
      usageMonth: currentMonth,
    );

    await _stateService.updateStatus(resetStatus);
    return 0;
  }

  String _getCurrentMonth() => DateTime.now().toYearMonth();

  String _getUsageMonth(SubscriptionStatus status) {
    return status.lastResetDate?.toYearMonth() ?? _getCurrentMonth();
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
