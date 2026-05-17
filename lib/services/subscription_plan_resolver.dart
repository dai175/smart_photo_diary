import 'package:flutter/foundation.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/environment_config.dart';
import 'interfaces/logging_service_interface.dart';

/// プラン種別の判定・状態生成・forcePlan 処理を担当するユーティリティクラス。
final class SubscriptionPlanResolver {
  const SubscriptionPlanResolver._();

  /// planId から Plan インスタンスを解決する。
  static Result<Plan> resolve(String planId) {
    try {
      final plan = PlanFactory.createPlan(planId);
      return Success(plan);
    } catch (e) {
      return Failure(
        ServiceException('Unknown plan ID: $planId', originalError: e),
      );
    }
  }

  /// forcePlan 名から planId へ変換する（デバッグ用）。
  static String resolveForcedPlanId(String forcePlan) {
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

  /// Plan から SubscriptionStatus の初期値を構築する（Hive 操作を含まない純粋関数）。
  static SubscriptionStatus buildStatusForPlan(Plan plan) {
    final now = DateTime.now();
    if (plan is BasicPlan) {
      return SubscriptionStatus(
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
    }
    final expiryDate = plan.isYearly
        ? now.add(
            const Duration(days: SubscriptionConstants.subscriptionYearDays),
          )
        : now.add(
            const Duration(days: SubscriptionConstants.subscriptionMonthDays),
          );
    return SubscriptionStatus(
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

  /// デバッグモード時の forcePlan 上書きを適用する。
  ///
  /// forcePlan が null または未設定の場合は status をそのまま返す。
  /// データベースの状態は変更しない（返り値のみ上書き）。
  static SubscriptionStatus applyForcePlan(
    SubscriptionStatus status, {
    ILoggingService? logger,
  }) {
    if (!kDebugMode) return status;

    final forcePlan = EnvironmentConfig.forcePlan;
    if (forcePlan == null) return status;

    logger?.debug(
      'Forced plan setting - returning $forcePlan (database unchanged)',
      context: 'SubscriptionPlanResolver',
      data: {'forcedPlan': forcePlan},
    );

    final forcedPlanId = resolveForcedPlanId(forcePlan);
    final expiryDuration =
        forcedPlanId == SubscriptionConstants.premiumYearlyPlanId
        ? const Duration(days: SubscriptionConstants.subscriptionYearDays)
        : const Duration(days: SubscriptionConstants.subscriptionMonthDays);
    final now = DateTime.now();
    return status.copyWith(
      planId: forcedPlanId,
      isActive: true,
      startDate: status.startDate ?? now,
      expiryDate: now.add(expiryDuration),
    );
  }
}
