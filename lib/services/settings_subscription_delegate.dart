import '../core/result/result.dart';
import '../core/result/result_extensions.dart';
import '../models/subscription_info_v2.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import 'interfaces/subscription_service_interface.dart';

/// サブスクリプション情報取得を担当する内部委譲クラス
///
/// SettingsService から分離された、ISubscriptionService への
/// 委譲メソッド群を管理する。
class SettingsSubscriptionDelegate {
  final ISubscriptionService _subscriptionService;

  SettingsSubscriptionDelegate({
    required ISubscriptionService subscriptionService,
  }) : _subscriptionService = subscriptionService;

  /// 包括的なサブスクリプション情報を取得（V2版）
  Future<Result<SubscriptionInfoV2>> getSubscriptionInfoV2() async {
    final statusResult = await _subscriptionService.getCurrentStatus();
    if (statusResult.isFailure) return Failure(statusResult.error);
    return Success(SubscriptionInfoV2.fromStatus(statusResult.value));
  }

  /// 現在のプラン情報を取得（Planクラス版）
  Future<Result<Plan>> getCurrentPlanClass() =>
      _subscriptionService.getCurrentPlanClass();

  /// プラン期限情報を取得（V2版）
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2() async {
    final (statusResult, planResult) = await (
      _subscriptionService.getCurrentStatus(),
      _subscriptionService.getCurrentPlanClass(),
    ).wait;
    if (statusResult.isFailure) return Failure(statusResult.error);
    if (planResult.isFailure) return Failure(planResult.error);
    return Success(
      PlanPeriodInfoV2.fromStatusAndPlan(statusResult.value, planResult.value),
    );
  }

  /// 自動更新状態情報を取得
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo() async {
    final statusResult = await _subscriptionService.getCurrentStatus();
    if (statusResult.isFailure) return Failure(statusResult.error);
    return Success(AutoRenewalInfoV2.fromStatus(statusResult.value));
  }

  /// 使用統計情報を取得（Planクラス版）
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass() async {
    final (statusResult, planResult) = await (
      _subscriptionService.getCurrentStatus(),
      _subscriptionService.getCurrentPlanClass(),
    ).wait;
    if (statusResult.isFailure) return Failure(statusResult.error);
    if (planResult.isFailure) return Failure(planResult.error);
    return Success(
      UsageStatisticsV2.fromStatusAndPlan(statusResult.value, planResult.value),
    );
  }

  /// 残り使用可能回数を取得
  Future<Result<int>> getRemainingGenerations() =>
      _subscriptionService.getRemainingGenerations();

  /// 次回リセット日を取得
  Future<Result<DateTime>> getNextResetDate() =>
      _subscriptionService.getNextResetDate();

  /// プラン変更可能かどうかを確認
  Future<Result<bool>> canChangePlan() async {
    final statusResult = await _subscriptionService.getCurrentStatus();
    if (statusResult.isFailure) return Failure(statusResult.error);
    return Success(_subscriptionService.isInitialized);
  }

  /// プラン比較情報を取得（V2版）
  Future<Result<List<Plan>>> getAvailablePlansV2() =>
      ResultHelper.tryExecuteAsync(
        () async => PlanFactory.getAllPlans(),
        context: 'SettingsSubscriptionDelegate.getAvailablePlansV2',
      );
}
