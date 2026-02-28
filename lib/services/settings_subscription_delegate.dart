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

  /// Result から値を取り出す。Failure の場合は例外をスロー。
  T _requireResult<T>(Result<T> result) {
    if (result.isFailure) throw result.error;
    return result.value;
  }

  /// 包括的なサブスクリプション情報を取得（V2版）
  Future<Result<SubscriptionInfoV2>> getSubscriptionInfoV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      final status = _requireResult(
        await _subscriptionService.getCurrentStatus(),
      );
      return SubscriptionInfoV2.fromStatus(status);
    }, context: 'SettingsSubscriptionDelegate.getSubscriptionInfoV2');
  }

  /// 現在のプラン情報を取得（Planクラス版）
  Future<Result<Plan>> getCurrentPlanClass() =>
      _subscriptionService.getCurrentPlanClass();

  /// プラン期限情報を取得（V2版）
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      final status = _requireResult(
        await _subscriptionService.getCurrentStatus(),
      );
      final plan = _requireResult(
        await _subscriptionService.getCurrentPlanClass(),
      );

      return PlanPeriodInfoV2.fromStatusAndPlan(status, plan);
    }, context: 'SettingsSubscriptionDelegate.getPlanPeriodInfoV2');
  }

  /// 自動更新状態情報を取得
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo() async {
    return ResultHelper.tryExecuteAsync(() async {
      final status = _requireResult(
        await _subscriptionService.getCurrentStatus(),
      );
      return AutoRenewalInfoV2.fromStatus(status);
    }, context: 'SettingsSubscriptionDelegate.getAutoRenewalInfo');
  }

  /// 使用統計情報を取得（Planクラス版）
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass() async {
    return ResultHelper.tryExecuteAsync(() async {
      final status = _requireResult(
        await _subscriptionService.getCurrentStatus(),
      );
      final plan = _requireResult(
        await _subscriptionService.getCurrentPlanClass(),
      );

      return UsageStatisticsV2.fromStatusAndPlan(status, plan);
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
      _requireResult(await _subscriptionService.getCurrentStatus());
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
