import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/config/in_app_purchase_config.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';

/// Phase 1.6.1.4: サンドボックステスト準備
///
/// In-App Purchase設定とサンドボックス環境の統合テスト
/// 実際の購入処理は行わず、設定とデータ構造の検証を実施

void main() {
  group('Phase 1.6.1.4: In-App Purchase Sandbox Test Preparation', () {
    // =================================================================
    // 商品設定・価格調整テスト
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

      test('価格設定が正しく設定されている', () {
        // 月額プランの価格
        expect(InAppPurchaseConfig.premiumMonthlyPrice, equals(300));

        // 年額プランの価格
        expect(InAppPurchaseConfig.premiumYearlyPrice, equals(2800));

        // 年額割引計算が正しい
        expect(
          InAppPurchaseConfig.yearlyDiscountAmount,
          equals(800),
        ); // 300*12 - 2800
        expect(
          InAppPurchaseConfig.yearlyDiscountPercentage,
          closeTo(22.22, 0.1),
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

      test('商品説明文が設定されている', () {
        // 表示名が設定されている
        expect(
          InAppPurchaseConfig.getDisplayNameFromPlan(PremiumMonthlyPlan()),
          isNotEmpty,
        );
        expect(
          InAppPurchaseConfig.getDisplayNameFromPlan(PremiumYearlyPlan()),
          isNotEmpty,
        );
        expect(
          InAppPurchaseConfig.getDisplayNameFromPlan(BasicPlan()),
          isNotEmpty,
        );

        // 説明文が設定されている
        expect(
          InAppPurchaseConfig.getDescriptionFromPlan(PremiumMonthlyPlan()),
          isNotEmpty,
        );
        expect(
          InAppPurchaseConfig.getDescriptionFromPlan(PremiumYearlyPlan()),
          isNotEmpty,
        );
        expect(
          InAppPurchaseConfig.getDescriptionFromPlan(BasicPlan()),
          isNotEmpty,
        );

        // 年額プランの説明が設定されている
        expect(
          InAppPurchaseConfig.getDescriptionFromPlan(PremiumYearlyPlan()),
          isNotEmpty,
        );
      });
    });

    // =================================================================
    // 地域別価格設定テスト
    // =================================================================

    group('Dynamic Pricing Tests', () {
      test('動的価格取得システムが利用可能', () {
        // 動的価格取得システムの基本設定確認
        expect(InAppPurchaseConfig.inAppPurchaseEnabled, isTrue);
        expect(InAppPurchaseConfig.allProductIds, isNotEmpty);

        // フォールバック価格の確認（SubscriptionConstants経由）
        expect(SubscriptionConstants.premiumMonthlyPrice, isPositive);
        expect(SubscriptionConstants.premiumYearlyPrice, isPositive);
      });

      test('価格フォーマット関数が正しく動作する', () {
        // 日本円のフォーマット
        expect(InAppPurchaseConfig.formatPrice(300, 'JPY'), equals('¥300'));
        expect(InAppPurchaseConfig.formatPrice(2800, 'JPY'), equals('¥2,800'));

        // USドルのフォーマット
        expect(InAppPurchaseConfig.formatPrice(2.99, 'USD'), equals('\$2.99'));
        expect(
          InAppPurchaseConfig.formatPrice(28.99, 'USD'),
          equals('\$28.99'),
        );
      });

      test('デフォルト設定が適切に構成されている', () {
        // デフォルト通貨設定の確認
        expect(SubscriptionConstants.defaultCurrencyCode, equals('JPY'));
        expect(SubscriptionConstants.defaultCurrencySymbol, equals('¥'));
      });

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
    });

    // =================================================================
    // 無料トライアル設定テスト
    // =================================================================

    group('Free Trial Configuration Tests', () {
      test('無料トライアル期間が正しく設定されている', () {
        expect(InAppPurchaseConfig.freeTrialDays, equals(7));
        expect(SubscriptionConstants.freeTrialDays, equals(7));
      });

      test('無料トライアル対象商品が正しく設定されている', () {
        // 対象商品ID
        expect(InAppPurchaseConfig.freeTrialEligibleProductIds, hasLength(2));
        expect(
          InAppPurchaseConfig.freeTrialEligibleProductIds,
          containsAll([
            'smart_photo_diary_premium_monthly_plan',
            'smart_photo_diary_premium_yearly_plan',
          ]),
        );

        // 対象商品チェック
        expect(
          InAppPurchaseConfig.isEligibleForFreeTrial(
            'smart_photo_diary_premium_monthly_plan',
          ),
          isTrue,
        );
        expect(
          InAppPurchaseConfig.isEligibleForFreeTrial(
            'smart_photo_diary_premium_yearly_plan',
          ),
          isTrue,
        );
        expect(
          InAppPurchaseConfig.isEligibleForFreeTrial('invalid_product_id'),
          isFalse,
        );
      });

      test('無料トライアル機能フラグが有効になっている', () {
        expect(InAppPurchaseConfig.freeTrialEnabled, isTrue);
      });
    });

    // =================================================================
    // テスト環境設定テスト
    // =================================================================

    group('Test Environment Configuration Tests', () {
      test('テストアカウントが設定されている', () {
        expect(InAppPurchaseConfig.testAccounts, isNotEmpty);
        expect(InAppPurchaseConfig.testAccounts['ios'], isNotNull);
        expect(InAppPurchaseConfig.testAccounts['android'], isNotNull);

        // テストアカウントのフォーマット確認
        expect(
          InAppPurchaseConfig.testAccounts['ios'],
          contains('@smartphotodiary.app'),
        );
        expect(
          InAppPurchaseConfig.testAccounts['android'],
          contains('@smartphotodiary.app'),
        );
      });

      test('プラットフォーム設定が定義されている', () {
        // iOS設定
        expect(InAppPurchaseConfig.iosConfig, isNotEmpty);
        expect(InAppPurchaseConfig.iosConfig['bundleId'], isNotNull);
        expect(InAppPurchaseConfig.iosConfig['sandboxEnabled'], isTrue);

        // Android設定
        expect(InAppPurchaseConfig.androidConfig, isNotEmpty);
        expect(InAppPurchaseConfig.androidConfig['packageName'], isNotNull);
        expect(
          InAppPurchaseConfig.androidConfig['licenseTestingEnabled'],
          isTrue,
        );
      });

      test('機能フラグが正しく設定されている', () {
        // 基本機能フラグ
        expect(InAppPurchaseConfig.inAppPurchaseEnabled, isTrue);
        expect(InAppPurchaseConfig.restorePurchasesEnabled, isTrue);
        expect(InAppPurchaseConfig.planChangeEnabled, isTrue);
        expect(InAppPurchaseConfig.purchaseHistoryEnabled, isTrue);

        // セキュリティ設定（Phase 1では無効）
        expect(InAppPurchaseConfig.serverSideValidationEnabled, isFalse);
        expect(InAppPurchaseConfig.fraudDetectionEnabled, isTrue);
      });
    });

    // =================================================================
    // 設定検証テスト
    // =================================================================

    group('Configuration Validation Tests', () {
      test('設定の妥当性が検証される', () {
        // 設定検証エラーがないことを確認
        final errors = InAppPurchaseConfigValidator.validateConfig();
        expect(
          errors,
          isEmpty,
          reason: 'Configuration validation errors: ${errors.join(', ')}',
        );

        // 設定が有効であることを確認
        expect(InAppPurchaseConfigValidator.isConfigValid(), isTrue);
      });

      test('商品IDの妥当性チェックが動作する', () {
        // 有効な商品ID
        expect(
          InAppPurchaseConfig.isValidProductId(
            'smart_photo_diary_premium_monthly_plan',
          ),
          isTrue,
        );
        expect(
          InAppPurchaseConfig.isValidProductId(
            'smart_photo_diary_premium_yearly_plan',
          ),
          isTrue,
        );

        // 無効な商品ID
        expect(
          InAppPurchaseConfig.isValidProductId('invalid_product_id'),
          isFalse,
        );
        expect(InAppPurchaseConfig.isValidProductId(''), isFalse);
      });

      test('購入可能プランの判定が正しい', () {
        // 購入可能プラン
        expect(
          InAppPurchaseConfig.isPurchasableFromPlan(PremiumMonthlyPlan()),
          isTrue,
        );
        expect(
          InAppPurchaseConfig.isPurchasableFromPlan(PremiumYearlyPlan()),
          isTrue,
        );

        // 購入不可プラン
        expect(InAppPurchaseConfig.isPurchasableFromPlan(BasicPlan()), isFalse);
      });
    });

    // =================================================================
    // デバッグ情報テスト
    // =================================================================

    group('Debug Information Tests', () {
      test('デバッグ情報が取得できる', () {
        final debugInfo = InAppPurchaseConfig.getDebugInfo();

        // 基本情報が含まれている
        expect(debugInfo['platform'], isNotNull);
        expect(debugInfo['productIds'], isNotNull);
        expect(debugInfo['note'], isNotNull); // 価格情報の代わりに説明が含まれる
        expect(debugInfo['freeTrialDays'], equals(7));

        // 商品ID情報
        expect(debugInfo['productIds'], isA<List<String>>());
        expect((debugInfo['productIds'] as List).length, equals(2));

        // 動的価格取得システムに関する説明
        expect(debugInfo['note'], contains('動的価格取得システム'));
      });

      test('テスト用商品IDが生成される', () {
        // サンドボックス環境でのテスト商品ID生成
        const testProductId = 'smart_photo_diary_premium_monthly';
        final testId = InAppPurchaseConfig.getTestProductId(testProductId);

        // テスト環境フラグに応じて適切な商品IDが返される
        expect(testId, isNotNull);
        expect(testId, isNotEmpty);
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

      test('InAppPurchaseExceptionが正しく動作する', () {
        const exception = InAppPurchaseException(
          'Test error message',
          code: 'TEST_ERROR',
        );

        expect(exception.message, equals('Test error message'));
        expect(exception.code, equals('TEST_ERROR'));
        expect(exception.toString(), contains('InAppPurchaseException'));
        expect(exception.toString(), contains('TEST_ERROR'));
      });
    });

    // =================================================================
    // 統合確認テスト
    // =================================================================

    group('Integration Confirmation Tests', () {
      test('SubscriptionConstantsとの整合性確認', () {
        // 価格の整合性
        expect(
          InAppPurchaseConfig.premiumMonthlyPrice,
          equals(SubscriptionConstants.premiumMonthlyPrice),
        );
        expect(
          InAppPurchaseConfig.premiumYearlyPrice,
          equals(SubscriptionConstants.premiumYearlyPrice),
        );

        // 商品IDの整合性
        expect(
          InAppPurchaseConfig.premiumMonthlyProductId,
          equals(SubscriptionConstants.premiumMonthlyProductId),
        );
        expect(
          InAppPurchaseConfig.premiumYearlyProductId,
          equals(SubscriptionConstants.premiumYearlyProductId),
        );

        // 無料トライアル期間の整合性
        expect(
          InAppPurchaseConfig.freeTrialDays,
          equals(SubscriptionConstants.freeTrialDays),
        );
      });

      test('全体的な設定の一貫性確認', () {
        // 全商品IDが有効であることを確認
        for (final productId in InAppPurchaseConfig.allProductIds) {
          expect(InAppPurchaseConfig.isValidProductId(productId), isTrue);
          expect(
            () => InAppPurchaseConfig.getPlanFromProductId(productId),
            returnsNormally,
          );
        }

        // 全プランの表示名・説明が設定されていることを確認
        for (final plan in PlanFactory.getAllPlans()) {
          expect(InAppPurchaseConfig.getDisplayNameFromPlan(plan), isNotEmpty);
          expect(InAppPurchaseConfig.getDescriptionFromPlan(plan), isNotEmpty);
        }

        // 動的価格取得システムの基本設定確認
        expect(InAppPurchaseConfig.inAppPurchaseEnabled, isTrue);
        expect(InAppPurchaseConfig.allProductIds, isNotEmpty);

        // フォールバック価格の一貫性確認
        expect(SubscriptionConstants.premiumMonthlyPrice, greaterThan(0));
        expect(SubscriptionConstants.premiumYearlyPrice, greaterThan(0));
      });
    });
  });
}

/// サンドボックステスト用ヘルパークラス
class SandboxTestHelpers {
  /// テスト用商品IDリストを取得
  static List<String> getTestProductIds() {
    return InAppPurchaseConfig.allProductIds.map((id) {
      return InAppPurchaseConfig.getTestProductId(id);
    }).toList();
  }

  /// テスト用価格情報を取得
  static Map<String, dynamic> getTestPricing() {
    return {
      'monthly': InAppPurchaseConfig.premiumMonthlyPrice,
      'yearly': InAppPurchaseConfig.premiumYearlyPrice,
      'discount': InAppPurchaseConfig.yearlyDiscountAmount,
      'discountPercentage': InAppPurchaseConfig.yearlyDiscountPercentage,
    };
  }

  /// サンドボックス環境の設定状況を確認
  static Map<String, dynamic> getSandboxStatus() {
    return {
      'sandboxEnabled': InAppPurchaseConfig.isSandboxEnvironment,
      'testAccounts': InAppPurchaseConfig.testAccounts,
      'freeTrialEnabled': InAppPurchaseConfig.freeTrialEnabled,
      'configValid': InAppPurchaseConfigValidator.isConfigValid(),
    };
  }
}
