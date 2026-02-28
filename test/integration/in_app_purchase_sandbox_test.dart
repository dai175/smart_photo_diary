import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/config/in_app_purchase_config.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
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
        // 全商品IDが定義されていることを確認
        expect(InAppPurchaseConfig.allProductIds, isNotEmpty);
        expect(InAppPurchaseConfig.allProductIds.length, equals(2));

        // 期待される商品IDが含まれていることを確認
        expect(
          InAppPurchaseConfig.allProductIds,
          containsAll([
            'smart_photo_diary_premium_monthly_plan',
            'smart_photo_diary_premium_yearly_plan',
          ]),
        );
      });

      test('プランと商品IDのマッピングが正しい', () {
        // プランから商品IDを取得
        expect(
          InAppPurchaseConfig.getProductIdFromPlan(PremiumMonthlyPlan()),
          equals('smart_photo_diary_premium_monthly_plan'),
        );
        expect(
          InAppPurchaseConfig.getProductIdFromPlan(PremiumYearlyPlan()),
          equals('smart_photo_diary_premium_yearly_plan'),
        );

        // 商品IDからプランを取得
        expect(
          InAppPurchaseConfig.getPlanFromProductId(
            'smart_photo_diary_premium_monthly_plan',
          ).id,
          equals(PremiumMonthlyPlan().id),
        );
        expect(
          InAppPurchaseConfig.getPlanFromProductId(
            'smart_photo_diary_premium_yearly_plan',
          ).id,
          equals(PremiumYearlyPlan().id),
        );

        // Basicプランは商品IDを持たない
        expect(
          () => InAppPurchaseConfig.getProductIdFromPlan(BasicPlan()),
          throwsA(isA<ArgumentError>()),
        );
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
      test('不正な商品IDでエラーが発生する', () {
        expect(
          () => InAppPurchaseConfig.getPlanFromProductId('invalid_product_id'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Basicプランの商品ID取得でエラーが発生する', () {
        expect(
          () => InAppPurchaseConfig.getProductIdFromPlan(BasicPlan()),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    // =================================================================
    // 統合確認テスト
    // =================================================================

    group('Integration Confirmation Tests', () {
      test('全体的な設定の一貫性確認', () {
        // 全商品IDが有効であることを確認
        for (final productId in InAppPurchaseConfig.allProductIds) {
          expect(
            () => InAppPurchaseConfig.getPlanFromProductId(productId),
            returnsNormally,
          );
        }

        // フォールバック価格の一貫性確認
        expect(SubscriptionConstants.premiumMonthlyPrice, greaterThan(0));
        expect(SubscriptionConstants.premiumYearlyPrice, greaterThan(0));
      });
    });
  });
}
