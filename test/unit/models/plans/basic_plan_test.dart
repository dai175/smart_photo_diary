import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

void main() {
  group('BasicPlan', () {
    late BasicPlan plan;

    setUp(() {
      plan = BasicPlan();
    });

    group('プロパティ', () {
      test('正しいIDを持つ', () {
        expect(plan.id, 'basic');
        expect(plan.id, SubscriptionConstants.basicPlanId);
      });

      test('正しい表示名を持つ', () {
        expect(plan.displayName, 'Basic');
        expect(plan.displayName, SubscriptionConstants.basicDisplayName);
      });

      test('正しい説明を持つ', () {
        expect(plan.description, contains('新規ユーザー'));
        expect(plan.description, SubscriptionConstants.basicDescription);
      });

      test('正しい価格を持つ', () {
        expect(plan.price, 0);
        expect(plan.price, SubscriptionConstants.basicYearlyPrice);
      });

      test('正しいAI生成制限を持つ', () {
        expect(plan.monthlyAiGenerationLimit, 10);
        expect(
          plan.monthlyAiGenerationLimit,
          SubscriptionConstants.basicMonthlyAiLimit,
        );
      });

      test('正しい機能リストを持つ', () {
        expect(plan.features, isNotEmpty);
        expect(plan.features, SubscriptionConstants.basicFeatures);
        expect(plan.features.length, 6);
        expect(plan.features[0], contains('AI日記'));
        expect(plan.features[1], contains('写真'));
        expect(plan.features[2], contains('検索'));
      });

      test('空の商品IDを持つ', () {
        expect(plan.productId, '');
        expect(plan.productId, isEmpty);
      });
    });

    group('機能フラグ', () {
      test('isPremiumがfalseを返す', () {
        expect(plan.isPremium, false);
      });

      test('hasWritingPromptsがfalseを返す', () {
        expect(plan.hasWritingPrompts, false);
      });

      test('hasAdvancedFiltersがfalseを返す', () {
        expect(plan.hasAdvancedFilters, false);
      });

      test('hasAdvancedAnalyticsがfalseを返す', () {
        expect(plan.hasAdvancedAnalytics, false);
      });

      test('hasPrioritySupportがfalseを返す', () {
        expect(plan.hasPrioritySupport, false);
      });
    });

    group('計算プロパティ', () {
      test('isPaidがfalseを返す', () {
        expect(plan.isPaid, false);
      });

      test('isFreeがtrueを返す', () {
        expect(plan.isFree, true);
      });

      test('isMonthlyがfalseを返す', () {
        expect(plan.isMonthly, false);
      });

      test('isYearlyがfalseを返す', () {
        expect(plan.isYearly, false);
      });

      test('yearlyPriceが0を返す', () {
        expect(plan.yearlyPrice, 0);
      });

      test('formattedPriceが「無料」を返す', () {
        expect(plan.formattedPrice, '無料');
      });

      test('dailyAverageGenerationsが正しく計算される', () {
        expect(plan.dailyAverageGenerations, closeTo(0.333, 0.001));
      });
    });

    group('比較メソッド', () {
      test('hasMoreFeaturesThanが正しく動作する', () {
        final anotherBasicPlan = BasicPlan();

        // 同じプラン同士
        expect(plan.hasMoreFeaturesThan(anotherBasicPlan), false);

        // Basicプランは他のプランより機能が少ない
        expect(plan.features.length, 6);
      });
    });

    group('シングルトン動作', () {
      test('複数回インスタンス化しても同じインスタンスが返される', () {
        final plan1 = BasicPlan();
        final plan2 = BasicPlan();

        expect(identical(plan1, plan2), true);
        expect(plan1.hashCode, plan2.hashCode);
      });
    });

    group('toString', () {
      test('デバッグ用文字列が適切に生成される', () {
        final debugString = plan.toString();

        expect(debugString, contains('Plan('));
        expect(debugString, contains('id: basic'));
        expect(debugString, contains('displayName: Basic'));
        expect(debugString, contains('price: 無料'));
        expect(debugString, contains('monthlyLimit: 10'));
        expect(debugString, contains('isPremium: false'));
      });
    });
  });
}
