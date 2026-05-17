import '../models/subscription_status.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';

final class SubscriptionLimitChecker {
  const SubscriptionLimitChecker._();

  /// 不明な planId は無効として false を返す。
  /// SubscriptionStatus.isValid は不明な planId を BasicPlan にフォールバックするため使用しない。
  static bool isValid(SubscriptionStatus status) {
    if (!status.isActive) return false;
    if (!PlanFactory.isValidPlanId(status.planId)) return false;
    final plan = PlanFactory.createPlan(status.planId);
    if (plan is BasicPlan) return true;
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }
}
