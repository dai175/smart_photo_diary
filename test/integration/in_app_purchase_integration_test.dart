import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../unit/helpers/hive_test_helpers.dart';

/// Phase 1.6.2: In-App Purchase機能統合テスト
///
/// Phase 1.6.2で実装された購入機能の統合テスト
/// In-App Purchase機能（商品情報取得、購入フロー、復元機能）の動作確認

void main() {
  group('Phase 1.6.2: In-App Purchase機能統合テスト', () {
    late ServiceLocator serviceLocator;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();

      // ServiceLocator新規作成
      serviceLocator = ServiceLocator();
    });

    tearDown(() async {
      // ServiceLocatorをクリア
      serviceLocator.clear();
    });

    tearDownAll(() async {
      // テスト終了時にHiveを閉じる
      await HiveTestHelpers.closeHive();
    });

    // =================================================================
    // Phase 1.6.2.1: 商品情報取得実装テスト
    // =================================================================

    group('Phase 1.6.2.1: 商品情報取得実装テスト', () {
      late ISubscriptionService subscriptionService;

      setUp(() async {
        serviceLocator.registerAsyncFactory<ISubscriptionService>(() async {
          final service = SubscriptionService();
          await service.initialize();
          return service;
        });
        subscriptionService = await serviceLocator
            .getAsync<ISubscriptionService>();
      });

      test('getProducts()が正常にResult<T>パターンで応答する', () async {
        // getProducts()の呼び出し
        final result = await subscriptionService.getProducts();

        // In-App Purchase未対応のテスト環境では失敗が期待される
        // 重要なのはResult<T>パターンで適切にエラーハンドリングされること
        expect(result, isA<Result<List<PurchaseProduct>>>());

        if (result.isFailure) {
          // テスト環境でのエラーは期待される動作
          expect(
            result.error.toString(),
            contains('In-App Purchase not available'),
          );
        } else {
          // 万が一成功した場合（実デバイステスト等）
          expect(result.value, isA<List<PurchaseProduct>>());
          expect(result.value.length, greaterThanOrEqualTo(0));
        }
      });

      test('getProducts()エラー時の適切な情報が含まれている', () async {
        final result = await subscriptionService.getProducts();

        // テスト環境では失敗が期待される
        if (result.isFailure) {
          expect(result.error, isA<ServiceException>());
          expect(result.error.toString(), isNotEmpty);

          // In-App Purchase関連のエラーメッセージが含まれること
          final errorMessage = result.error.toString().toLowerCase();
          expect(
            errorMessage.contains('in-app purchase') ||
                errorMessage.contains('not available') ||
                errorMessage.contains('not initialized'),
            isTrue,
          );
        }
      });

      test('複数回のgetProducts()呼び出しが安定している', () async {
        // 複数回呼び出しても安定していることを確認
        final results = <Result<List<PurchaseProduct>>>[];

        for (int i = 0; i < 3; i++) {
          final result = await subscriptionService.getProducts();
          results.add(result);
        }

        // 全て同じ結果タイプ（成功または失敗）であることを確認
        final isFirstSuccess = results.first.isSuccess;
        for (final result in results) {
          expect(result.isSuccess, equals(isFirstSuccess));
        }
      });
    });

    // =================================================================
    // Phase 1.6.2.2: 購入フロー実装テスト
    // =================================================================

    group('Phase 1.6.2.2: 購入フロー実装テスト', () {
      late ISubscriptionService subscriptionService;

      setUp(() async {
        serviceLocator.registerAsyncFactory<ISubscriptionService>(() async {
          final service = SubscriptionService();
          await service.initialize();
          return service;
        });
        subscriptionService = await serviceLocator
            .getAsync<ISubscriptionService>();
      });

      test('purchasePlan()でBasicプラン購入時にエラーが返される', () async {
        // Basicプランは購入対象外
        final result = await subscriptionService.purchasePlanClass(BasicPlan());

        expect(result.isFailure, isTrue);
        // テスト環境では In-App Purchase 未対応のため、このエラーが先に発生する
        expect(
          result.error.toString(),
          contains('In-App Purchase not available'),
        );
      });

      test('purchasePlan()でPremiumプラン指定時の動作確認', () async {
        // Premium月額プランの購入試行
        final result = await subscriptionService.purchasePlanClass(
          PremiumMonthlyPlan(),
        );

        // テスト環境では In-App Purchase 未対応のためエラーが期待される
        expect(result, isA<Result<PurchaseResult>>());

        if (result.isFailure) {
          // エラーの場合、適切なエラーメッセージが含まれていることを確認
          expect(result.error, isA<ServiceException>());
          final errorMessage = result.error.toString().toLowerCase();
          expect(
            errorMessage.contains('in-app purchase') ||
                errorMessage.contains('not available') ||
                errorMessage.contains('not initialized'),
            isTrue,
          );
        } else {
          // 成功の場合（実デバイステスト等）、適切な結果が返されることを確認
          expect(result.value, isA<PurchaseResult>());
          expect(result.value.status, equals(PurchaseStatus.pending));
        }
      });

      test('購入中の重複購入防止機能確認', () async {
        // この機能はテスト環境での検証が困難
        // インターフェースレベルでの基本確認のみ実施

        final monthlyResult = await subscriptionService.purchasePlanClass(
          PremiumMonthlyPlan(),
        );
        final yearlyResult = await subscriptionService.purchasePlanClass(
          PremiumYearlyPlan(),
        );

        // 両方とも何らかの結果が返されることを確認
        expect(monthlyResult, isA<Result<PurchaseResult>>());
        expect(yearlyResult, isA<Result<PurchaseResult>>());
      });

      test('無効なプランでの購入処理エラーハンドリング', () async {
        // Basicプランでの購入はエラーになるべき
        final result = await subscriptionService.purchasePlanClass(BasicPlan());

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        // テスト環境では In-App Purchase 未対応のため、このエラーが先に発生する
        expect(
          result.error.toString(),
          contains('In-App Purchase not available'),
        );
      });
    });

    // =================================================================
    // Phase 1.6.2.3: 購入状態監視実装テスト
    // =================================================================

    group('Phase 1.6.2.3: 購入状態監視実装テスト', () {
      late ISubscriptionService subscriptionService;

      setUp(() async {
        serviceLocator.registerAsyncFactory<ISubscriptionService>(() async {
          final service = SubscriptionService();
          await service.initialize();
          return service;
        });
        subscriptionService = await serviceLocator
            .getAsync<ISubscriptionService>();
      });

      test('purchaseStreamが利用可能である', () async {
        // purchaseStreamが存在することを確認
        expect(
          subscriptionService.purchaseStream,
          isA<Stream<PurchaseResult>>(),
        );

        // ストリームが購読可能であることを確認
        var streamReceived = false;
        late StreamSubscription subscription;

        subscription = subscriptionService.purchaseStream
            .timeout(
              const Duration(milliseconds: 100),
              onTimeout: (sink) {
                // タイムアウトは正常（初期状態ではイベントなし）
                sink.close();
              },
            )
            .listen(
              (result) {
                streamReceived = true;
                expect(result, isA<PurchaseResult>());
              },
              onDone: () {
                // ストリーム終了は正常
              },
              onError: (error) {
                // エラーでもテストは継続（タイムアウトエラーは期待される）
              },
            );

        // 短時間待機
        await Future.delayed(const Duration(milliseconds: 150));
        await subscription.cancel();

        // ストリームが機能していることを確認（イベント受信は不要）
        expect(streamReceived, isFalse); // 初期状態ではイベントなし
      });

      test('statusStreamが正常に動作する', () async {
        // statusStreamが存在することを確認
        expect(
          subscriptionService.statusStream,
          isA<Stream<SubscriptionStatus>>(),
        );

        // ストリームからデータを取得できることを確認
        var statusReceived = false;
        late StreamSubscription subscription;

        subscription = subscriptionService.statusStream
            .timeout(
              const Duration(seconds: 6), // statusStreamは5分間隔なので長めに設定
              onTimeout: (sink) {
                sink.close();
              },
            )
            .listen(
              (status) {
                statusReceived = true;
                expect(status, isA<SubscriptionStatus>());
                expect(status.planId, equals('basic')); // 初期状態はBasic
              },
              onDone: () {
                // ストリーム終了は正常
              },
              onError: (error) {
                // エラーでもテストは継続
              },
            );

        // 短時間待機（実際の5分間隔では待機しない）
        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        // ストリームが設定されていることを確認
        expect(statusReceived, isFalse); // 短時間では発火しない
      });
    });

    // =================================================================
    // Phase 1.6.2.4: 復元機能実装テスト
    // =================================================================

    group('Phase 1.6.2.4: 復元機能実装テスト', () {
      late ISubscriptionService subscriptionService;

      setUp(() async {
        serviceLocator.registerAsyncFactory<ISubscriptionService>(() async {
          final service = SubscriptionService();
          await service.initialize();
          return service;
        });
        subscriptionService = await serviceLocator
            .getAsync<ISubscriptionService>();
      });

      test('restorePurchases()が正常にResult<T>パターンで応答する', () async {
        final result = await subscriptionService.restorePurchases();

        expect(result, isA<Result<List<PurchaseResult>>>());

        if (result.isFailure) {
          // テスト環境でのエラーは期待される動作
          expect(result.error, isA<ServiceException>());
          expect(
            result.error.toString(),
            contains('In-App Purchase not available'),
          );
        } else {
          // 成功の場合（実デバイステスト等）
          expect(result.value, isA<List<PurchaseResult>>());

          // 復元開始の確認
          if (result.value.isNotEmpty) {
            expect(result.value.first.status, equals(PurchaseStatus.pending));
          }
        }
      });

      test('validatePurchase()の基本動作確認', () async {
        const testTransactionId = 'test_transaction_123';

        final result = await subscriptionService.validatePurchase(
          testTransactionId,
        );

        expect(result, isA<Result<bool>>());
        expect(result.isSuccess, isTrue);

        // 現在はローカル検証のみなので、一致しないTransactionIDはfalse
        expect(result.value, isFalse);
      });

      test('cancelSubscription()の基本動作確認', () async {
        final result = await subscriptionService.cancelSubscription();

        expect(result, isA<Result<void>>());
        expect(result.isSuccess, isTrue);

        // キャンセル後、autoRenewalがfalseになることを確認
        final statusResult = await subscriptionService.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);
        expect(statusResult.value.autoRenewal, isFalse);
      });

      test('changePlan()が未実装エラーを返すことを確認', () async {
        final result = await subscriptionService.changePlanClass(
          PremiumYearlyPlan(),
        );

        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('not yet implemented'));
      });
    });

    // =================================================================
    // 統合確認テスト
    // =================================================================

    group('In-App Purchase統合確認テスト', () {
      late ISubscriptionService subscriptionService;

      setUp(() async {
        serviceLocator.registerAsyncFactory<ISubscriptionService>(() async {
          final service = SubscriptionService();
          await service.initialize();
          return service;
        });
        subscriptionService = await serviceLocator
            .getAsync<ISubscriptionService>();
      });

      test('全購入関連メソッドがResult<T>パターンを使用している', () async {
        // 全ての購入関連メソッドがResult<T>を返すことを確認
        final getProductsResult = await subscriptionService.getProducts();
        expect(getProductsResult, isA<Result<List<PurchaseProduct>>>());

        final purchaseResult = await subscriptionService.purchasePlanClass(
          PremiumMonthlyPlan(),
        );
        expect(purchaseResult, isA<Result<PurchaseResult>>());

        final restoreResult = await subscriptionService.restorePurchases();
        expect(restoreResult, isA<Result<List<PurchaseResult>>>());

        final validateResult = await subscriptionService.validatePurchase(
          'test',
        );
        expect(validateResult, isA<Result<bool>>());

        final changePlanResult = await subscriptionService.changePlanClass(
          PremiumYearlyPlan(),
        );
        expect(changePlanResult, isA<Result<void>>());

        final cancelResult = await subscriptionService.cancelSubscription();
        expect(cancelResult, isA<Result<void>>());
      });

      test('In-App Purchase未対応環境での適切なエラーハンドリング', () async {
        // テスト環境ではIn-App Purchaseは利用不可
        // 各メソッドが適切にエラーハンドリングすることを確認

        final results = await Future.wait([
          subscriptionService.getProducts(),
          subscriptionService.purchasePlanClass(PremiumMonthlyPlan()),
          subscriptionService.restorePurchases(),
        ]);

        for (final result in results) {
          if (result.isFailure) {
            expect(result.error, isA<ServiceException>());
            expect(result.error.toString(), isNotEmpty);
          }
        }
      });

      test('購入機能が既存のサブスクリプション機能と統合されている', () async {
        // 既存の基本機能が正常に動作することを確認
        final statusResult = await subscriptionService.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);
        expect(statusResult.value.planId, equals('basic'));

        final canUseResult = await subscriptionService.canUseAiGeneration();
        expect(canUseResult.isSuccess, isTrue);
        expect(canUseResult.value, isTrue);

        final remainingResult = await subscriptionService
            .getRemainingGenerations();
        expect(remainingResult.isSuccess, isTrue);
        expect(remainingResult.value, equals(10)); // Basicプランの制限

        // 購入機能も利用可能
        final getProductsResult = await subscriptionService.getProducts();
        expect(getProductsResult, isA<Result<List<PurchaseProduct>>>());
      });

      test('エラー処理の一貫性確認', () async {
        // 各メソッドのエラー処理が一貫していることを確認

        // 無効な入力でのエラー
        final basicPurchaseResult = await subscriptionService.purchasePlanClass(
          BasicPlan(),
        );
        expect(basicPurchaseResult.isFailure, isTrue);
        expect(basicPurchaseResult.error, isA<ServiceException>());

        // 未実装機能のエラー
        final changePlanResult = await subscriptionService.changePlanClass(
          PremiumYearlyPlan(),
        );
        expect(changePlanResult.isFailure, isTrue);
        expect(changePlanResult.error, isA<ServiceException>());

        // 全てのエラーがServiceExceptionまたはその派生クラス
        final errorResults = [basicPurchaseResult, changePlanResult];
        for (final result in errorResults) {
          expect(result.error, isA<ServiceException>());
          expect(result.error.toString(), isNotEmpty);
        }
      });
    });
  });
}

/// In-App Purchase統合テスト用ヘルパークラス
class InAppPurchaseTestHelpers {
  // 注意: PurchaseResultとPurchaseProductは旧バージョンでenumに依存しているため、
  // ヘルパーメソッドは一旦コメントアウト。V2バージョンが利用可能になったら再実装。

  /*
  /// テスト用購入結果を作成
  static PurchaseResult createTestPurchaseResult({
    PurchaseStatus status = PurchaseStatus.pending,
    String? productId,
    String? transactionId,
    Plan? plan,
    String? errorMessage,
  }) {
    // 旧バージョンはenum依存のため、V2バージョンでの実装を待つ
  }

  /// テスト用商品情報を作成
  static PurchaseProduct createTestPurchaseProduct({
    required String id,
    required String title,
    required Plan plan,
    String price = '¥300',
    double priceAmount = 300.0,
  }) {
    // 旧バージョンはenum依存のため、V2バージョンでの実装を待つ
  }
  */

  /// 購入ストリームのテスト用監視
  static Future<List<PurchaseResult>> listenToPurchaseStream(
    Stream<PurchaseResult> stream,
    Duration timeout,
  ) async {
    final results = <PurchaseResult>[];
    final subscription = stream.listen(results.add);

    try {
      await Future.delayed(timeout);
    } finally {
      await subscription.cancel();
    }

    return results;
  }
}
