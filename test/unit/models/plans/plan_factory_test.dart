import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';

void main() {
  group('PlanFactory', () {
    group('createPlan', () {
      test('basic IDでBasicPlanが作成される', () {
        final plan = PlanFactory.createPlan('basic');
        expect(plan, isA<BasicPlan>());
        expect(plan.id, 'basic');
      });

      test('premium_monthly IDでPremiumMonthlyPlanが作成される', () {
        final plan = PlanFactory.createPlan('premium_monthly');
        expect(plan, isA<PremiumMonthlyPlan>());
        expect(plan.id, 'premium_monthly');
      });

      test('premium_yearly IDでPremiumYearlyPlanが作成される', () {
        final plan = PlanFactory.createPlan('premium_yearly');
        expect(plan, isA<PremiumYearlyPlan>());
        expect(plan.id, 'premium_yearly');
      });

      test('大文字小文字を区別しない', () {
        final plan1 = PlanFactory.createPlan('BASIC');
        final plan2 = PlanFactory.createPlan('Premium_Monthly');
        final plan3 = PlanFactory.createPlan('PREMIUM_YEARLY');

        expect(plan1, isA<BasicPlan>());
        expect(plan2, isA<PremiumMonthlyPlan>());
        expect(plan3, isA<PremiumYearlyPlan>());
      });

      test('無効なIDでArgumentErrorがスローされる', () {
        expect(
          () => PlanFactory.createPlan('invalid_plan'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('シングルトンインスタンスが返される', () {
        final plan1 = PlanFactory.createPlan('basic');
        final plan2 = PlanFactory.createPlan('basic');
        expect(identical(plan1, plan2), true);
      });
    });

    group('tryCreatePlan', () {
      test('有効なIDでPlanインスタンスが返される', () {
        final plan = PlanFactory.tryCreatePlan('basic');
        expect(plan, isNotNull);
        expect(plan, isA<BasicPlan>());
      });

      test('無効なIDでnullが返される', () {
        final plan = PlanFactory.tryCreatePlan('invalid_plan');
        expect(plan, isNull);
      });
    });

    group('getAllPlans', () {
      test('全てのプランが正しい順序で返される', () {
        final plans = PlanFactory.getAllPlans();

        expect(plans.length, 3);
        expect(plans[0], isA<BasicPlan>());
        expect(plans[1], isA<PremiumMonthlyPlan>());
        expect(plans[2], isA<PremiumYearlyPlan>());
      });
    });

    group('getPaidPlans', () {
      test('有料プランのみが価格順で返される', () {
        final plans = PlanFactory.getPaidPlans();

        expect(plans.length, 2);
        expect(plans.every((plan) => plan.isPaid), true);
        expect(plans[0].price, 300); // Premium Monthly
        expect(plans[1].price, 2800); // Premium Yearly
      });
    });

    group('getPremiumPlans', () {
      test('プレミアムプランのみが価格順で返される', () {
        final plans = PlanFactory.getPremiumPlans();

        expect(plans.length, 2);
        expect(plans.every((plan) => plan.isPremium), true);
        expect(plans[0], isA<PremiumMonthlyPlan>());
        expect(plans[1], isA<PremiumYearlyPlan>());
      });
    });

    group('getFreePlan', () {
      test('無料プランが返される', () {
        final plan = PlanFactory.getFreePlan();

        expect(plan, isA<BasicPlan>());
        expect(plan.isFree, true);
        expect(plan.id, 'basic');
      });
    });

    group('isValidPlanId', () {
      test('有効なプランIDでtrueが返される', () {
        expect(PlanFactory.isValidPlanId('basic'), true);
        expect(PlanFactory.isValidPlanId('premium_monthly'), true);
        expect(PlanFactory.isValidPlanId('premium_yearly'), true);
      });

      test('大文字小文字を区別しない', () {
        expect(PlanFactory.isValidPlanId('BASIC'), true);
        expect(PlanFactory.isValidPlanId('Premium_Monthly'), true);
      });

      test('無効なプランIDでfalseが返される', () {
        expect(PlanFactory.isValidPlanId('invalid'), false);
        expect(PlanFactory.isValidPlanId(''), false);
      });
    });

    group('getPlanByProductId', () {
      test('有効な商品IDでプランが返される', () {
        final plan = PlanFactory.getPlanByProductId(
          'smart_photo_diary_premium_monthly_plan',
        );

        expect(plan, isNotNull);
        expect(plan, isA<PremiumMonthlyPlan>());
      });

      test('年額プランの商品IDでプランが返される', () {
        final plan = PlanFactory.getPlanByProductId(
          'smart_photo_diary_premium_yearly_plan',
        );

        expect(plan, isNotNull);
        expect(plan, isA<PremiumYearlyPlan>());
      });

      test('無効な商品IDでnullが返される', () {
        final plan = PlanFactory.getPlanByProductId('invalid_product_id');

        expect(plan, isNull);
      });

      test('空の商品ID（Basicプラン）でnullが返される', () {
        final plan = PlanFactory.getPlanByProductId('');

        expect(plan, isNull);
      });
    });
  });
}
