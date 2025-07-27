import 'plan.dart';
import 'basic_plan.dart';
import 'premium_monthly_plan.dart';
import 'premium_yearly_plan.dart';
import '../../constants/subscription_constants.dart';

/// プランインスタンスを管理するファクトリクラス
///
/// プランIDからプランインスタンスを生成し、
/// プラン一覧の取得などの機能を提供します。
class PlanFactory {
  /// プライベートコンストラクタ（インスタンス化を防ぐ）
  PlanFactory._();

  /// プランインスタンスのキャッシュ
  static final Map<String, Plan> _planCache = {
    SubscriptionConstants.basicPlanId: BasicPlan(),
    SubscriptionConstants.premiumMonthlyPlanId: PremiumMonthlyPlan(),
    SubscriptionConstants.premiumYearlyPlanId: PremiumYearlyPlan(),
  };

  /// プランIDから対応するPlanインスタンスを取得
  ///
  /// [planId] プランの識別子
  ///
  /// 存在しないプランIDが指定された場合は[ArgumentError]をスロー
  static Plan createPlan(String planId) {
    final normalizedId = planId.toLowerCase();
    final plan = _planCache[normalizedId];

    if (plan == null) {
      throw ArgumentError(
        'Unknown plan ID: $planId. '
        'Valid plan IDs are: ${_planCache.keys.join(", ")}',
      );
    }

    return plan;
  }

  /// プランIDから安全にPlanインスタンスを取得
  ///
  /// [planId] プランの識別子
  ///
  /// 存在しないプランIDの場合はnullを返す
  static Plan? tryCreatePlan(String planId) {
    try {
      return createPlan(planId);
    } catch (_) {
      return null;
    }
  }

  /// 全プランのリストを取得
  ///
  /// Basic、Premium月額、Premium年額の順で返す
  static List<Plan> getAllPlans() {
    return [
      _planCache[SubscriptionConstants.basicPlanId]!,
      _planCache[SubscriptionConstants.premiumMonthlyPlanId]!,
      _planCache[SubscriptionConstants.premiumYearlyPlanId]!,
    ];
  }

  /// 有料プランのみ取得
  static List<Plan> getPaidPlans() {
    return _planCache.values.where((plan) => plan.isPaid).toList()
      ..sort((a, b) => a.price.compareTo(b.price)); // 価格の安い順
  }

  /// プレミアムプランのみ取得
  static List<Plan> getPremiumPlans() {
    return _planCache.values.where((plan) => plan.isPremium).toList()
      ..sort((a, b) => a.price.compareTo(b.price)); // 価格の安い順
  }

  /// 無料プランを取得
  static Plan getFreePlan() {
    return _planCache[SubscriptionConstants.basicPlanId]!;
  }

  /// 指定した機能を持つプランのみ取得
  static List<Plan> getPlansWithFeature({
    bool? hasWritingPrompts,
    bool? hasAdvancedFilters,
    bool? hasAdvancedAnalytics,
    bool? hasPrioritySupport,
  }) {
    return _planCache.values.where((plan) {
      if (hasWritingPrompts != null &&
          plan.hasWritingPrompts != hasWritingPrompts) {
        return false;
      }
      if (hasAdvancedFilters != null &&
          plan.hasAdvancedFilters != hasAdvancedFilters) {
        return false;
      }
      if (hasAdvancedAnalytics != null &&
          plan.hasAdvancedAnalytics != hasAdvancedAnalytics) {
        return false;
      }
      if (hasPrioritySupport != null &&
          plan.hasPrioritySupport != hasPrioritySupport) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 月額制限回数が指定値以上のプランを取得
  static List<Plan> getPlansWithMinimumLimit(int minimumLimit) {
    return _planCache.values
        .where((plan) => plan.monthlyAiGenerationLimit >= minimumLimit)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price)); // 価格の安い順
  }

  /// プランIDが有効かどうかを確認
  static bool isValidPlanId(String planId) {
    return _planCache.containsKey(planId.toLowerCase());
  }

  /// 商品IDからプランを取得
  static Plan? getPlanByProductId(String productId) {
    // 空文字列の場合はnullを返す（BasicPlanのproductIdは空文字列）
    if (productId.isEmpty) {
      return null;
    }

    try {
      return _planCache.values.firstWhere(
        (plan) => plan.productId == productId,
      );
    } catch (_) {
      return null;
    }
  }

  /// デバッグ用: 全プランの情報を文字列として取得
  static String debugGetAllPlansInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== Registered Plans ===');
    for (final entry in _planCache.entries) {
      buffer.writeln('ID: ${entry.key}');
      buffer.writeln('  ${entry.value}');
    }
    buffer.writeln('=======================');
    return buffer.toString();
  }
}
