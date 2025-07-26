import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/purchase_data_v2.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

void main() {
  group('PurchaseProductV2', () {
    group('基本機能', () {
      test('プロパティが正しく設定される', () {
        final plan = PremiumMonthlyPlan();
        final product = PurchaseProductV2(
          id: 'test_id',
          title: 'Test Product',
          description: 'Test Description',
          price: '¥300',
          priceAmount: 300.0,
          currencyCode: 'JPY',
          plan: plan,
        );

        expect(product.id, 'test_id');
        expect(product.title, 'Test Product');
        expect(product.description, 'Test Description');
        expect(product.price, '¥300');
        expect(product.priceAmount, 300.0);
        expect(product.currencyCode, 'JPY');
        expect(product.plan, plan);
      });

      test('年額プランの価格表示テキストが正しく生成される', () {
        final yearlyPlan = PremiumYearlyPlan();
        final product = PurchaseProductV2(
          id: 'yearly',
          title: 'Yearly Plan',
          description: 'Yearly subscription',
          price: '¥2,800',
          priceAmount: 2800.0,
          currencyCode: 'JPY',
          plan: yearlyPlan,
        );

        expect(product.priceDisplay, '¥2,800（月額換算 ¥233）');
      });

      test('月額プランの価格表示テキストが正しく生成される', () {
        final monthlyPlan = PremiumMonthlyPlan();
        final product = PurchaseProductV2(
          id: 'monthly',
          title: 'Monthly Plan',
          description: 'Monthly subscription',
          price: '¥300',
          priceAmount: 300.0,
          currencyCode: 'JPY',
          plan: monthlyPlan,
        );

        expect(product.priceDisplay, '¥300');
      });
    });

    group('相互変換', () {
      test('既存PurchaseProductから正しく変換される', () {
        final legacy = PurchaseProduct(
          id: 'legacy_id',
          title: 'Legacy Product',
          description: 'Legacy Description',
          price: '¥300',
          priceAmount: 300.0,
          currencyCode: 'JPY',
          plan: PremiumMonthlyPlan(),
        );

        final v2 = PurchaseProductV2.fromLegacy(legacy);

        expect(v2.id, legacy.id);
        expect(v2.title, legacy.title);
        expect(v2.description, legacy.description);
        expect(v2.price, legacy.price);
        expect(v2.priceAmount, legacy.priceAmount);
        expect(v2.currencyCode, legacy.currencyCode);
        expect(v2.plan, isA<PremiumMonthlyPlan>());
        expect(v2.plan.id, 'premium_monthly');
      });

      test('既存PurchaseProductへ正しく変換される', () {
        final plan = PremiumYearlyPlan();
        final v2 = PurchaseProductV2(
          id: 'v2_id',
          title: 'V2 Product',
          description: 'V2 Description',
          price: '¥2,800',
          priceAmount: 2800.0,
          currencyCode: 'JPY',
          plan: plan,
        );

        final legacy = v2.toLegacy();

        expect(legacy.id, v2.id);
        expect(legacy.title, v2.title);
        expect(legacy.description, v2.description);
        expect(legacy.price, v2.price);
        expect(legacy.priceAmount, v2.priceAmount);
        expect(legacy.currencyCode, v2.currencyCode);
        expect(legacy.plan, isA<PremiumYearlyPlan>());
      });

      test('全プランタイプで相互変換が機能する', () {
        final plans = [BasicPlan(), PremiumMonthlyPlan(), PremiumYearlyPlan()];

        for (final plan in plans) {
          final v2 = PurchaseProductV2(
            id: 'test',
            title: 'Test',
            description: 'Test',
            price: '¥${plan.price}',
            priceAmount: plan.price.toDouble(),
            currencyCode: 'JPY',
            plan: plan,
          );

          final legacy = v2.toLegacy();
          final converted = PurchaseProductV2.fromLegacy(legacy);

          expect(converted.plan.id, plan.id);
          expect(converted.plan.runtimeType, plan.runtimeType);
        }
      });
    });

    group('toString', () {
      test('適切な文字列表現を返す', () {
        final plan = BasicPlan();
        final product = PurchaseProductV2(
          id: 'basic_id',
          title: 'Basic Plan',
          description: 'Basic Description',
          price: '¥0',
          priceAmount: 0.0,
          currencyCode: 'JPY',
          plan: plan,
        );

        final str = product.toString();
        expect(str, contains('PurchaseProductV2'));
        expect(str, contains('basic_id'));
        expect(str, contains('Basic Plan'));
        expect(str, contains('basic'));
      });
    });
  });

  group('PurchaseResultV2', () {
    group('基本機能', () {
      test('成功状態のプロパティが正しく設定される', () {
        final plan = PremiumMonthlyPlan();
        final result = PurchaseResultV2(
          status: PurchaseStatus.purchased,
          productId: 'product_id',
          transactionId: 'transaction_id',
          purchaseDate: DateTime(2025, 1, 1),
          plan: plan,
        );

        expect(result.status, PurchaseStatus.purchased);
        expect(result.productId, 'product_id');
        expect(result.transactionId, 'transaction_id');
        expect(result.purchaseDate, DateTime(2025, 1, 1));
        expect(result.plan, plan);
        expect(result.errorMessage, isNull);
      });

      test('エラー状態のプロパティが正しく設定される', () {
        final result = const PurchaseResultV2(
          status: PurchaseStatus.error,
          errorMessage: 'Network error',
        );

        expect(result.status, PurchaseStatus.error);
        expect(result.errorMessage, 'Network error');
        expect(result.productId, isNull);
        expect(result.transactionId, isNull);
        expect(result.plan, isNull);
      });

      test('状態判定メソッドが正しく動作する', () {
        const successResult = PurchaseResultV2(
          status: PurchaseStatus.purchased,
        );
        const cancelResult = PurchaseResultV2(status: PurchaseStatus.cancelled);
        const errorResult = PurchaseResultV2(status: PurchaseStatus.error);

        expect(successResult.isSuccess, true);
        expect(successResult.isCancelled, false);
        expect(successResult.isError, false);

        expect(cancelResult.isSuccess, false);
        expect(cancelResult.isCancelled, true);
        expect(cancelResult.isError, false);

        expect(errorResult.isSuccess, false);
        expect(errorResult.isCancelled, false);
        expect(errorResult.isError, true);
      });
    });

    group('エラーメッセージ処理', () {
      test('キャンセルエラーが適切に処理される', () {
        const result = PurchaseResultV2(
          status: PurchaseStatus.error,
          errorMessage: 'User cancelled the purchase',
        );

        expect(result.userFriendlyErrorMessage, '購入がキャンセルされました');
      });

      test('ネットワークエラーが適切に処理される', () {
        const result = PurchaseResultV2(
          status: PurchaseStatus.error,
          errorMessage: 'Network connection failed',
        );

        expect(result.userFriendlyErrorMessage, 'ネットワークエラーが発生しました');
      });

      test('重複購入エラーが適切に処理される', () {
        const result = PurchaseResultV2(
          status: PurchaseStatus.error,
          errorMessage: 'Product already owned',
        );

        expect(result.userFriendlyErrorMessage, 'すでに購入済みのプランです');
      });

      test('その他のエラーが適切に処理される', () {
        const result = PurchaseResultV2(
          status: PurchaseStatus.error,
          errorMessage: 'Unknown error occurred',
        );

        expect(result.userFriendlyErrorMessage, 'Unknown error occurred');
      });

      test('エラーメッセージがない場合のデフォルト', () {
        const result = PurchaseResultV2(status: PurchaseStatus.error);

        expect(result.userFriendlyErrorMessage, '購入処理中にエラーが発生しました');
      });

      test('エラーでない場合は空文字列を返す', () {
        const result = PurchaseResultV2(status: PurchaseStatus.purchased);

        expect(result.userFriendlyErrorMessage, '');
      });
    });

    group('相互変換', () {
      test('既存PurchaseResultから正しく変換される（成功時）', () {
        final legacy = PurchaseResult(
          status: PurchaseStatus.purchased,
          productId: 'legacy_product',
          transactionId: 'legacy_transaction',
          purchaseDate: null,
          plan: PremiumYearlyPlan(),
        );

        final v2 = PurchaseResultV2.fromLegacy(legacy);

        expect(v2.status, legacy.status);
        expect(v2.productId, legacy.productId);
        expect(v2.transactionId, legacy.transactionId);
        expect(v2.purchaseDate, legacy.purchaseDate);
        expect(v2.plan, isA<PremiumYearlyPlan>());
        expect(v2.plan?.id, 'premium_yearly');
      });

      test('既存PurchaseResultから正しく変換される（エラー時）', () {
        final legacy = PurchaseResult(
          status: PurchaseStatus.error,
          errorMessage: 'Legacy error',
        );

        final v2 = PurchaseResultV2.fromLegacy(legacy);

        expect(v2.status, legacy.status);
        expect(v2.errorMessage, legacy.errorMessage);
        expect(v2.plan, isNull);
      });

      test('既存PurchaseResultへ正しく変換される', () {
        final plan = PremiumMonthlyPlan();
        final v2 = PurchaseResultV2(
          status: PurchaseStatus.purchased,
          productId: 'v2_product',
          transactionId: 'v2_transaction',
          purchaseDate: DateTime(2025, 1, 1),
          plan: plan,
        );

        final legacy = v2.toLegacy();

        expect(legacy.status, v2.status);
        expect(legacy.productId, v2.productId);
        expect(legacy.transactionId, v2.transactionId);
        expect(legacy.purchaseDate, v2.purchaseDate);
        expect(legacy.plan, isA<PremiumMonthlyPlan>());
      });

      test('planがnullの場合の変換', () {
        const v2 = PurchaseResultV2(status: PurchaseStatus.cancelled);

        final legacy = v2.toLegacy();

        expect(legacy.plan, isNull);
      });
    });

    group('toString', () {
      test('適切な文字列表現を返す', () {
        final plan = BasicPlan();
        final result = PurchaseResultV2(
          status: PurchaseStatus.purchased,
          productId: 'prod_123',
          transactionId: 'trans_456',
          plan: plan,
        );

        final str = result.toString();
        expect(str, contains('PurchaseResultV2'));
        expect(str, contains('purchased'));
        expect(str, contains('prod_123'));
        expect(str, contains('trans_456'));
        expect(str, contains('basic'));
      });

      test('planがnullの場合も適切に処理される', () {
        const result = PurchaseResultV2(
          status: PurchaseStatus.error,
          errorMessage: 'Error occurred',
        );

        final str = result.toString();
        expect(str, contains('PurchaseResultV2'));
        expect(str, contains('error'));
        expect(str, contains('null'));
      });
    });
  });
}
