import 'plan.dart';

/// Premium プランの共通基底クラス
///
/// [PremiumMonthlyPlan] と [PremiumYearlyPlan] の共通機能フラグを定義します。
abstract class PremiumPlan extends Plan {
  const PremiumPlan({
    required super.id,
    required super.displayName,
    required super.description,
    required super.price,
    required super.monthlyAiGenerationLimit,
    required super.features,
    required super.productId,
  });

  @override
  bool get isPremium => true;

  @override
  bool get hasWritingPrompts => true;

  @override
  bool get hasAdvancedFilters => true;

  @override
  bool get hasAdvancedAnalytics => true;

  @override
  bool get hasPrioritySupport => true;

  @override
  int get pastPhotoAccessDays => 365;
}
