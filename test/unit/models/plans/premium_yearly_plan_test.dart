import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

void main() {
  group('PremiumYearlyPlan', () {
    late PremiumYearlyPlan plan;

    setUp(() {
      plan = PremiumYearlyPlan();
    });

    group('プロパティ', () {
      test('正しいIDを持つ', () {
        expect(plan.id, 'premium_yearly');
        expect(plan.id, SubscriptionConstants.premiumYearlyPlanId);
      });

      test('正しい表示名を持つ', () {
        expect(plan.displayName, contains('Premium'));
        expect(plan.displayName, contains('Yearly'));
        expect(
          plan.displayName,
          '${SubscriptionConstants.premiumDisplayName} (Yearly)',
        );
      });

      test('正しい説明を持つ', () {
        expect(plan.description, contains('日常的に日記を書く'));
        expect(plan.description, SubscriptionConstants.premiumDescription);
      });

      test('正しい価格を持つ', () {
        expect(plan.price, 2800);
        expect(plan.price, SubscriptionConstants.premiumYearlyPrice);
      });

      test('正しいAI生成制限を持つ', () {
        expect(plan.monthlyAiGenerationLimit, 100);
        expect(
          plan.monthlyAiGenerationLimit,
          SubscriptionConstants.premiumMonthlyAiLimit,
        );
      });

      test('正しい機能リストを持つ', () {
        expect(plan.features, isNotEmpty);
        expect(plan.features, SubscriptionConstants.premiumFeatures);
        expect(plan.features.length, greaterThanOrEqualTo(6));
        expect(plan.features[0], contains('AI日記'));
        // 割引情報はYearlyプラン固有のメソッドで取得
      });

      test('正しい商品IDを持つ', () {
        expect(plan.productId, 'smart_photo_diary_premium_yearly_plan');
        expect(plan.productId, SubscriptionConstants.premiumYearlyProductId);
      });
    });

    group('機能フラグ', () {
      test('isPremiumがtrueを返す', () {
        expect(plan.isPremium, true);
      });

      test('hasWritingPromptsがtrueを返す', () {
        expect(plan.hasWritingPrompts, true);
      });

      test('hasAdvancedFiltersがtrueを返す', () {
        expect(plan.hasAdvancedFilters, true);
      });

      test('hasAdvancedAnalyticsがtrueを返す', () {
        expect(plan.hasAdvancedAnalytics, true);
      });

      test('hasPrioritySupportがtrueを返す', () {
        expect(plan.hasPrioritySupport, true);
      });
    });

    group('計算プロパティ', () {
      test('isPaidがtrueを返す', () {
        expect(plan.isPaid, true);
      });

      test('isFreeがfalseを返す', () {
        expect(plan.isFree, false);
      });

      test('isMonthlyがfalseを返す', () {
        expect(plan.isMonthly, false);
      });

      test('isYearlyがtrueを返す', () {
        expect(plan.isYearly, true);
      });

      test('yearlyPriceが正しい値を返す', () {
        expect(plan.yearlyPrice, 2800);
      });

      test('formattedPriceが正しくフォーマットされる', () {
        expect(plan.formattedPrice, '¥2,800');
      });

      test('dailyAverageGenerationsが正しく計算される', () {
        expect(plan.dailyAverageGenerations, closeTo(3.333, 0.001));
      });

      test('discountPercentageが正しい値を返す', () {
        expect(plan.discountPercentage, 22);
      });

      test('yearlySavingsが正しく計算される', () {
        expect(plan.yearlySavings, 800); // 3600 - 2800
      });
    });

    group('シングルトン動作', () {
      test('複数回インスタンス化しても同じインスタンスが返される', () {
        final plan1 = PremiumYearlyPlan();
        final plan2 = PremiumYearlyPlan();

        expect(identical(plan1, plan2), true);
        expect(plan1.hashCode, plan2.hashCode);
      });
    });

    group('toString', () {
      test('デバッグ用文字列が適切に生成される', () {
        final debugString = plan.toString();

        expect(debugString, contains('Plan('));
        expect(debugString, contains('id: premium_yearly'));
        expect(debugString, contains('displayName: Premium (Yearly)'));
        expect(debugString, contains('price: ¥2,800'));
        expect(debugString, contains('monthlyLimit: 100'));
        expect(debugString, contains('isPremium: true'));
      });
    });
  });
}
