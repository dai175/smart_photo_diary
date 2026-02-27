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
    return ResultHelper.tryExecuteAsync(() async {
      final statusResult = await _subscriptionService.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }
      return SubscriptionInfoV2.fromStatus(statusResult.value);
    }, context: 'SettingsSubscriptionDelegate.getSubscriptionInfoV2');
  }

  /// 現在のプラン情報を取得（Planクラス版）
  Future<Result<Plan>> getCurrentPlanClass() =>
      _subscriptionService.getCurrentPlanClass();

  /// プラン期限情報を取得（V2版）
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      final statusResult = await _subscriptionService.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final planResult = await _subscriptionService.getCurrentPlanClass();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return PlanPeriodInfoV2.fromStatusAndPlan(
        statusResult.value,
        planResult.value,
      );
    }, context: 'SettingsSubscriptionDelegate.getPlanPeriodInfoV2');
  }

  /// 自動更新状態情報を取得
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo() async {
    return ResultHelper.tryExecuteAsync(() async {
      final statusResult = await _subscriptionService.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }
      return AutoRenewalInfoV2.fromStatus(statusResult.value);
    }, context: 'SettingsSubscriptionDelegate.getAutoRenewalInfo');
  }

  /// 使用統計情報を取得（Planクラス版）
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass() async {
    return ResultHelper.tryExecuteAsync(() async {
      final statusResult = await _subscriptionService.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final planResult = await _subscriptionService.getCurrentPlanClass();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return UsageStatisticsV2.fromStatusAndPlan(
        statusResult.value,
        planResult.value,
      );
    }, context: 'SettingsSubscriptionDelegate.getUsageStatisticsWithPlanClass');
  }

  /// 残り使用可能回数を取得
  Future<Result<int>> getRemainingGenerations() =>
      _subscriptionService.getRemainingGenerations();

  /// 次回リセット日を取得
  Future<Result<DateTime>> getNextResetDate() =>
      _subscriptionService.getNextResetDate();

  /// プラン変更可能かどうかを確認
  Future<Result<bool>> canChangePlan() async {
    return ResultHelper.tryExecuteAsync(() async {
      // サービス正常性チェック（値は不要だが、失敗時にFailureを返すためのガード）
      final statusResult = await _subscriptionService.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }
      return _subscriptionService.isInitialized;
    }, context: 'SettingsSubscriptionDelegate.canChangePlan');
  }

  /// プラン比較情報を取得（V2版）
  Future<Result<List<Plan>>> getAvailablePlansV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      final plans = PlanFactory.getAllPlans();
      return plans;
    }, context: 'SettingsSubscriptionDelegate.getAvailablePlansV2');
  }
}
