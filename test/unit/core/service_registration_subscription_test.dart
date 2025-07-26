import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/core/service_registration.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'dart:io';

void main() {
  group('ServiceRegistration - SubscriptionService統合テスト', () {
    setUpAll(() async {
      // テスト環境でのHive初期化
      final tempDir = Directory.systemTemp.createTempSync('hive_test');
      Hive.init(tempDir.path);

      // SubscriptionStatusアダプターの登録
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SubscriptionStatusAdapter());
      }
    });

    setUp(() async {
      // ServiceLocatorをリセット
      ServiceRegistration.reset();
    });

    tearDown(() async {
      // ServiceLocatorをリセット
      ServiceRegistration.reset();
    });

    tearDownAll(() async {
      // テスト環境のクリーンアップ
      await Hive.close();
    });

    test('SubscriptionServiceがServiceLocatorに正しく登録される', () async {
      // Act - サービス登録を初期化
      await ServiceRegistration.initialize();

      // Assert - SubscriptionServiceが登録されていることを確認
      expect(ServiceRegistration.isInitialized, isTrue);

      // ISubscriptionServiceが取得できることを確認
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();
      expect(subscriptionService, isNotNull);
      expect(subscriptionService, isA<ISubscriptionService>());
    });

    test('SubscriptionServiceが初期化済み状態で取得される', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();

      // Act - SubscriptionServiceを取得
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Assert - 初期化済み状態であることを確認
      expect(subscriptionService.isInitialized, isTrue);

      // 基本操作が正常に動作することを確認
      final statusResult = await subscriptionService.getCurrentStatus();
      expect(statusResult.isSuccess, isTrue);
      expect(statusResult.value.planId, equals('basic'));
    });

    test('複数回の取得で同じインスタンスが返される', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();

      // Act - 複数回SubscriptionServiceを取得
      final service1 =
          await ServiceRegistration.getAsync<ISubscriptionService>();
      final service2 =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Assert - 同じインスタンスであることを確認（シングルトンパターン）
      expect(identical(service1, service2), isTrue);
    });

    test('ServiceLocator統合後の基本機能が正常動作する', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Act & Assert - 基本機能の動作確認

      // 1. プラン一覧取得
      final allPlans = PlanFactory.getAllPlans();
      expect(allPlans.length, equals(3));

      // 2. 現在のプラン取得
      final currentPlanResult = await subscriptionService.getCurrentPlanClass();
      expect(currentPlanResult.isSuccess, isTrue);
      expect(currentPlanResult.value.id, equals('basic'));

      // 3. AI生成使用可否チェック
      final canUseResult = await subscriptionService.canUseAiGeneration();
      expect(canUseResult.isSuccess, isTrue);
      expect(canUseResult.value, isTrue);

      // 4. 使用量インクリメント
      final incrementResult = await subscriptionService.incrementAiUsage();
      expect(incrementResult.isSuccess, isTrue);

      // 5. 使用量確認
      final usageResult = await subscriptionService.getMonthlyUsage();
      expect(usageResult.isSuccess, isTrue);
      expect(usageResult.value, equals(1));
    });

    test('アクセス権限チェック機能が正常動作する', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Act & Assert - アクセス権限チェックの動作確認

      // Basicプランでのアクセス権限確認
      final premiumAccessResult = await subscriptionService
          .canAccessPremiumFeatures();
      expect(premiumAccessResult.isSuccess, isTrue);
      expect(premiumAccessResult.value, isFalse); // Basicプランはfalse

      final writingPromptsResult = await subscriptionService
          .canAccessWritingPrompts();
      expect(writingPromptsResult.isSuccess, isTrue);
      expect(writingPromptsResult.value, isTrue); // Basicプランでも基本プロンプトは利用可能

      final advancedFiltersResult = await subscriptionService
          .canAccessAdvancedFilters();
      expect(advancedFiltersResult.isSuccess, isTrue);
      expect(advancedFiltersResult.value, isFalse); // Basicプランはfalse

      final analyticsResult = await subscriptionService
          .canAccessAdvancedAnalytics();
      expect(analyticsResult.isSuccess, isTrue);
      expect(analyticsResult.value, isFalse); // Basicプランはfalse

      final supportResult = await subscriptionService
          .canAccessPrioritySupport();
      expect(supportResult.isSuccess, isTrue);
      expect(supportResult.value, isFalse); // Basicプランはfalse
    });

    test('Phase 1.6 購入機能がテスト環境で適切なエラーを返す', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Act & Assert - Phase 1.6メソッドのテスト環境での動作確認

      // 商品情報取得（テスト環境では In-App Purchase 未対応のため失敗）
      final productsResult = await subscriptionService.getProducts();
      expect(productsResult.isFailure, isTrue);
      expect(
        productsResult.error.toString(),
        contains('In-App Purchase not available'),
      );

      // 購入機能（テスト環境では失敗）
      final premiumMonthlyPlan = PremiumMonthlyPlan();
      final purchaseResult = await subscriptionService.purchasePlanClass(
        premiumMonthlyPlan,
      );
      expect(purchaseResult.isFailure, isTrue);
      expect(
        purchaseResult.error.toString(),
        contains('In-App Purchase not available'),
      );

      // 復元機能（テスト環境では失敗）
      final restoreResult = await subscriptionService.restorePurchases();
      expect(restoreResult.isFailure, isTrue);
      expect(
        restoreResult.error.toString(),
        contains('In-App Purchase not available'),
      );

      // 検証機能（未実装）
      final validateResult = await subscriptionService.validatePurchase(
        'test_transaction',
      );
      expect(validateResult.isSuccess, isTrue);
      expect(validateResult.value, isFalse);

      // プラン変更（未実装）
      final allPlans = PlanFactory.getAllPlans();
      final lastPlan = allPlans.last;
      final changeResult = await subscriptionService.changePlanClass(
        lastPlan,
      );
      expect(changeResult.isFailure, isTrue);

      // キャンセル（実装済み）
      final cancelResult = await subscriptionService.cancelSubscription();
      expect(cancelResult.isSuccess, isTrue);
    });

    test('Stream機能が基本動作する', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Act & Assert - Stream機能の動作確認

      // 状態ストリーム
      final statusStream = subscriptionService.statusStream;
      expect(statusStream, isA<Stream>());

      // 購入ストリーム
      final purchaseStream = subscriptionService.purchaseStream;
      expect(purchaseStream, isA<Stream>());
    });

    test('dispose機能が正常動作する', () async {
      // Arrange - サービス登録を初期化
      await ServiceRegistration.initialize();
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // サービスが初期化済みであることを確認
      expect(subscriptionService.isInitialized, isTrue);

      // Act - サービスを破棄
      await subscriptionService.dispose();

      // Assert - 例外が発生しないことを確認
      // disposeは例外を投げずに完了すべき
    });
  });
}
