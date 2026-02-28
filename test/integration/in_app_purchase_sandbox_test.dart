import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';

/// Phase 1.6.1.4: サンドボックステスト準備
///
/// In-App Purchase設定とサンドボックス環境の統合テスト
/// 実際の購入処理は行わず、設定とデータ構造の検証を実施

void main() {
  group('Phase 1.6.1.4: In-App Purchase Sandbox Test Preparation', () {
    // =================================================================
    // 商品設定テスト
    // =================================================================

    group('Product Configuration Tests', () {
      test('商品IDが正しく設定されている', () {
        // 有料プランの商品IDを取得
        final paidProductIds = PlanFactory.getPaidPlans()
            .map((p) => p.productId)
            .toList();
        expect(paidProductIds, isNotEmpty);

        // 期待される商品IDが含まれていることを確認
        expect(
          paidProductIds,
          containsAll([
            'smart_photo_diary_premium_monthly_plan',
            'smart_photo_diary_premium_yearly_plan',
          ]),
        );
      });

      test('プランと商品IDのマッピングが正しい', () {
        // プランから商品IDを取得
        expect(
          PremiumMonthlyPlan().productId,
          equals('smart_photo_diary_premium_monthly_plan'),
        );
        expect(
          PremiumYearlyPlan().productId,
          equals('smart_photo_diary_premium_yearly_plan'),
        );

        // 商品IDからプランを取得
        expect(
          PlanFactory.getPlanByProductId(
            'smart_photo_diary_premium_monthly_plan',
          )?.id,
          equals(PremiumMonthlyPlan().id),
        );
        expect(
          PlanFactory.getPlanByProductId(
            'smart_photo_diary_premium_yearly_plan',
          )?.id,
          equals(PremiumYearlyPlan().id),
        );

        // Basicプランの商品IDは空文字列
        expect(BasicPlan().productId, isEmpty);
      });
    });

    // =================================================================
    // 価格設定テスト (SubscriptionConstants経由)
    // =================================================================

    group('Dynamic Pricing Tests', () {
      test('価格設定が適切に構成されている', () {
        // 年額プランが月額プランより安価であることを確認
        final monthlyPrice = SubscriptionConstants.premiumMonthlyPrice;
        final yearlyPrice = SubscriptionConstants.premiumYearlyPrice;
        final expectedYearlyPrice = monthlyPrice * 12;

        expect(yearlyPrice, lessThan(expectedYearlyPrice));

        // 割引率が適切な範囲内であることを確認
        final discountPercentage =
            ((expectedYearlyPrice - yearlyPrice) / expectedYearlyPrice) * 100;
        expect(discountPercentage, greaterThan(10.0));
        expect(discountPercentage, lessThan(30.0));
      });

      test('デフォルト設定が適切に構成されている', () {
        // デフォルト通貨設定の確認
        expect(SubscriptionConstants.defaultCurrencyCode, equals('JPY'));
        expect(SubscriptionConstants.defaultCurrencySymbol, equals('¥'));
      });
    });

    // =================================================================
    // エラーハンドリングテスト
    // =================================================================

    group('Error Handling Tests', () {
      test('不正な商品IDでnullが返される', () {
        expect(PlanFactory.getPlanByProductId('invalid_product_id'), isNull);
      });

      test('空文字列の商品IDでnullが返される', () {
        expect(PlanFactory.getPlanByProductId(''), isNull);
      });
    });

    // =================================================================
    // 統合確認テスト
    // =================================================================

    group('Integration Confirmation Tests', () {
      test('全体的な設定の一貫性確認', () {
        // 全有料プランの商品IDが有効であることを確認
        for (final plan in PlanFactory.getPaidPlans()) {
          expect(PlanFactory.getPlanByProductId(plan.productId), isNotNull);
        }

        // フォールバック価格の一貫性確認
        expect(SubscriptionConstants.premiumMonthlyPrice, greaterThan(0));
        expect(SubscriptionConstants.premiumYearlyPrice, greaterThan(0));
      });
    });
  });
}
