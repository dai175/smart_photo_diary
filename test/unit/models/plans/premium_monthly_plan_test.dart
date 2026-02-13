import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

void main() {
  group('PremiumMonthlyPlan', () {
    late PremiumMonthlyPlan plan;

    setUp(() {
      plan = PremiumMonthlyPlan();
    });

    group('プロパティ', () {
      test('正しいIDを持つ', () {
        expect(plan.id, 'premium_monthly');
        expect(plan.id, SubscriptionConstants.premiumMonthlyPlanId);
      });

      test('正しい表示名を持つ', () {
        expect(plan.displayName, contains('Premium'));
        expect(plan.displayName, contains('Monthly'));
        expect(
          plan.displayName,
          '${SubscriptionConstants.premiumDisplayName} (Monthly)',
        );
      });

      test('正しい説明を持つ', () {
        expect(plan.description, contains('日常的に日記を書く'));
        expect(plan.description, SubscriptionConstants.premiumDescription);
      });

      test('正しい価格を持つ', () {
        expect(plan.price, 300);
        expect(plan.price, SubscriptionConstants.premiumMonthlyPrice);
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
        expect(plan.features.length, 9);
        expect(plan.features[0], contains('AI日記'));
        expect(plan.features[1], contains('ライティングプロンプト'));
        expect(plan.features[2], contains('高度なフィルタ'));
      });

      test('正しい商品IDを持つ', () {
        expect(plan.productId, 'smart_photo_diary_premium_monthly_plan');
        expect(plan.productId, SubscriptionConstants.premiumMonthlyProductId);
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

      test('isMonthlyがtrueを返す', () {
        expect(plan.isMonthly, true);
      });

      test('isYearlyがfalseを返す', () {
        expect(plan.isYearly, false);
      });

      test('yearlyPriceが正しく計算される', () {
        expect(plan.yearlyPrice, 3600); // 300 * 12
      });

      test('formattedPriceが正しくフォーマットされる', () {
        expect(plan.formattedPrice, '¥300');
      });

      test('dailyAverageGenerationsが正しく計算される', () {
        expect(plan.dailyAverageGenerations, closeTo(3.333, 0.001));
      });
    });

    group('比較メソッド', () {
      test('hasMoreFeaturesThanが正しく動作する', () {
        final anotherPremiumMonthly = PremiumMonthlyPlan();

        // 同じプラン同士
        expect(plan.hasMoreFeaturesThan(anotherPremiumMonthly), false);

        // PremiumMonthlyプランは7つの機能を持つ
        expect(plan.features.length, 9);
      });
    });

    group('シングルトン動作', () {
      test('複数回インスタンス化しても同じインスタンスが返される', () {
        final plan1 = PremiumMonthlyPlan();
        final plan2 = PremiumMonthlyPlan();

        expect(identical(plan1, plan2), true);
        expect(plan1.hashCode, plan2.hashCode);
      });
    });

    group('toString', () {
      test('デバッグ用文字列が適切に生成される', () {
        final debugString = plan.toString();

        expect(debugString, contains('Plan('));
        expect(debugString, contains('id: premium_monthly'));
        expect(debugString, contains('displayName: Premium (Monthly)'));
        expect(debugString, contains('price: ¥300'));
        expect(debugString, contains('monthlyLimit: 100'));
        expect(debugString, contains('isPremium: true'));
      });
    });
  });
}
