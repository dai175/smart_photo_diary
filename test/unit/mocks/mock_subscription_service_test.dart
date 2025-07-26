import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import '../../mocks/mock_subscription_service.dart';

void main() {
  group('MockSubscriptionService - Phase 1.5.1テスト', () {
    late MockSubscriptionService mockService;

    setUp(() {
      mockService = MockSubscriptionService();
    });

    tearDown(() {
      mockService.resetToDefaults();
    });

    // =================================================================
    // 1.5.1.1: インターフェース実装テスト
    // =================================================================

    group('インターフェース実装確認', () {
      test('ISubscriptionServiceインターフェースを正しく実装している', () {
        expect(mockService, isA<ISubscriptionService>());
      });

      test('初期化前はisInitializedがfalseを返す', () {
        expect(mockService.isInitialized, isFalse);
      });

      test('初期化後はisInitializedがtrueを返す', () async {
        final result = await mockService.initialize();

        expect(result.isSuccess, isTrue);
        expect(mockService.isInitialized, isTrue);
      });

      test('初期化前のメソッド呼び出しは適切なエラーを返す', () async {
        final statusResult = await mockService.getCurrentStatus();

        expect(statusResult.isFailure, isTrue);
        expect(statusResult.error.message, contains('not initialized'));
      });
    });

    // =================================================================
    // 1.5.1.2: テスト用データ作成確認
    // =================================================================

    group('テスト用データとシナリオ管理', () {
      test('デフォルト状態でBasicプランが設定される', () async {
        await mockService.initialize();

        final statusResult = await mockService.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);

        final status = statusResult.value;
        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
      });

      test('カスタム初期状態でサービスを作成できる', () async {
        final customMock = MockSubscriptionService(
          initialPlanId: 'premium_yearly',
          initialIsActive: true,
          initialUsageCount: 15,
          initialExpiryDate: DateTime.now().add(const Duration(days: 300)),
        );

        await customMock.initialize();
        final statusResult = await customMock.getCurrentStatus();

        expect(statusResult.isSuccess, isTrue);
        final status = statusResult.value;
        expect(status.planId, equals('premium_yearly'));
        expect(status.monthlyUsageCount, equals(15));
        expect(status.expiryDate, isNotNull);
      });

      test('setCurrentPlan()でプランを動的に変更できる', () async {
        await mockService.initialize();

        final premiumMonthlyPlan = PremiumMonthlyPlan();
        mockService.setCurrentPlan(
          premiumMonthlyPlan,
          isActive: true,
          usageCount: 25,
        );

        final statusResult = await mockService.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);

        final status = statusResult.value;
        expect(status.planId, equals('premium_monthly'));
        expect(status.monthlyUsageCount, equals(25));
      });

      test('setUsageCount()で使用量を設定できる', () async {
        await mockService.initialize();

        mockService.setUsageCount(8);

        final usageResult = await mockService.getMonthlyUsage();
        expect(usageResult.isSuccess, isTrue);
        expect(usageResult.value, equals(8));
      });

      test('resetToDefaults()で初期状態に戻る', () async {
        await mockService.initialize();
        final premiumYearlyPlan = PremiumYearlyPlan();
        mockService.setCurrentPlan(premiumYearlyPlan);
        mockService.setUsageCount(50);

        mockService.resetToDefaults();

        expect(mockService.isInitialized, isFalse);

        await mockService.initialize();
        final statusResult = await mockService.getCurrentStatus();
        expect(statusResult.value.planId, equals('basic'));
        expect(statusResult.value.monthlyUsageCount, equals(0));
      });
    });

    // =================================================================
    // 1.5.1.3: 基本動作モック実装確認
    // =================================================================

    group('基本動作モック実装', () {
      setUp(() async {
        await mockService.initialize();
      });

      test('利用可能なプラン一覧を取得できる', () {
        final result = mockService.getAvailablePlansClass();

        expect(result.isSuccess, isTrue);
        expect(result.value.length, equals(3));
        expect(result.value[0], isA<BasicPlan>());
        expect(result.value[1], isA<PremiumMonthlyPlan>());
        expect(result.value[2], isA<PremiumYearlyPlan>());
      });

      test('特定プランの情報を取得できる', () {
        final basicResult = mockService.getPlanClass('basic');
        final premiumResult = mockService.getPlanClass('premium_yearly');
        final invalidResult = mockService.getPlanClass('invalid');

        expect(basicResult.isSuccess, isTrue);
        expect(basicResult.value, isA<BasicPlan>());

        expect(premiumResult.isSuccess, isTrue);
        expect(premiumResult.value, isA<PremiumYearlyPlan>());

        expect(invalidResult.isFailure, isTrue);
      });

      test('AI生成の使用可否をチェックできる', () async {
        // Basicプランで制限内
        final canUseResult = await mockService.canUseAiGeneration();
        expect(canUseResult.isSuccess, isTrue);
        expect(canUseResult.value, isTrue);

        // 制限に達した場合
        mockService.setUsageCount(10); // Basic plan limit
        final limitReachedResult = await mockService.canUseAiGeneration();
        expect(limitReachedResult.value, isFalse);
      });

      test('AI使用量をインクリメントできる', () async {
        final beforeUsage = await mockService.getMonthlyUsage();
        expect(beforeUsage.value, equals(0));

        await mockService.incrementAiUsage();
        await mockService.incrementAiUsage();

        final afterUsage = await mockService.getMonthlyUsage();
        expect(afterUsage.value, equals(2));
      });

      test('残りAI生成回数を取得できる', () async {
        mockService.setUsageCount(3);

        final remainingResult = await mockService.getRemainingGenerations();
        expect(remainingResult.isSuccess, isTrue);
        expect(remainingResult.value, equals(7)); // Basic: 10 - 3 = 7
      });

      test('使用量をリセットできる', () async {
        mockService.setUsageCount(5);

        final resetResult = await mockService.resetUsage();
        expect(resetResult.isSuccess, isTrue);

        final usageResult = await mockService.getMonthlyUsage();
        expect(usageResult.value, equals(0));
      });

      test('次のリセット日を取得できる', () async {
        final resetDateResult = await mockService.getNextResetDate();

        expect(resetDateResult.isSuccess, isTrue);
        expect(resetDateResult.value, isA<DateTime>());
      });
    });

    group('アクセス権限チェック', () {
      setUp(() async {
        await mockService.initialize();
      });

      test('Basicプランでのアクセス権限が正しい', () async {
        final basicPlan = BasicPlan();
        mockService.setCurrentPlan(basicPlan);

        final premiumResult = await mockService.canAccessPremiumFeatures();
        final promptsResult = await mockService.canAccessWritingPrompts();
        final filtersResult = await mockService.canAccessAdvancedFilters();
        final analyticsResult = await mockService.canAccessAdvancedAnalytics();
        final supportResult = await mockService.canAccessPrioritySupport();

        expect(premiumResult.value, isFalse);
        expect(promptsResult.value, isFalse); // Basic does not have prompts
        expect(filtersResult.value, isFalse);
        expect(analyticsResult.value, isFalse);
        expect(supportResult.value, isFalse);
      });

      test('Premiumプランでのアクセス権限が正しい', () async {
        final premiumYearlyPlan = PremiumYearlyPlan();
        mockService.setCurrentPlan(
          premiumYearlyPlan,
          isActive: true,
        );

        final premiumResult = await mockService.canAccessPremiumFeatures();
        final promptsResult = await mockService.canAccessWritingPrompts();
        final filtersResult = await mockService.canAccessAdvancedFilters();
        final analyticsResult = await mockService.canAccessAdvancedAnalytics();
        final supportResult = await mockService.canAccessPrioritySupport();

        expect(premiumResult.value, isTrue);
        expect(promptsResult.value, isTrue);
        expect(filtersResult.value, isTrue);
        expect(analyticsResult.value, isTrue);
        expect(supportResult.value, isTrue);
      });
    });

    group('購入・復元機能モック', () {
      setUp(() async {
        await mockService.initialize();
      });

      test('利用可能な商品を取得できる', () async {
        final productsResult = await mockService.getProducts();

        expect(productsResult.isSuccess, isTrue);
        expect(productsResult.value.length, equals(2));

        final products = productsResult.value;
        expect(
          products.any((p) => p.plan == SubscriptionPlan.premiumMonthly),
          isTrue,
        );
        expect(
          products.any((p) => p.plan == SubscriptionPlan.premiumYearly),
          isTrue,
        );
      });

      test('プラン購入をシミュレートできる', () async {
        final premiumYearlyPlan = PremiumYearlyPlan();
        final purchaseResult = await mockService.purchasePlanClass(
          premiumYearlyPlan,
        );

        expect(purchaseResult.isSuccess, isTrue);
        expect(purchaseResult.value.status, equals(PurchaseStatus.purchased));
        expect(
          purchaseResult.value.productId,
          equals(premiumYearlyPlan.productId),
        );
        expect(purchaseResult.value.transactionId, isNotNull);

        // プラン変更が反映されているか確認
        final statusResult = await mockService.getCurrentStatus();
        expect(statusResult.value.planId, equals('premium_yearly'));
      });

      test('購入履歴を復元できる', () async {
        // 複数回購入
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        final premiumYearlyPlan = PremiumYearlyPlan();
        await mockService.purchasePlanClass(premiumMonthlyPlan);
        await mockService.purchasePlanClass(premiumYearlyPlan);

        final restoreResult = await mockService.restorePurchases();

        expect(restoreResult.isSuccess, isTrue);
        expect(restoreResult.value.length, equals(2));
      });

      test('購入の検証ができる', () async {
        final premiumYearlyPlan = PremiumYearlyPlan();
        final purchaseResult = await mockService.purchasePlanClass(
          premiumYearlyPlan,
        );
        final transactionId = purchaseResult.value.transactionId!;

        final validResult = await mockService.validatePurchase(transactionId);
        expect(validResult.value, isTrue);

        final invalidResult = await mockService.validatePurchase('invalid_id');
        expect(invalidResult.value, isFalse);
      });

      test('サブスクリプションをキャンセルできる', () async {
        final premiumYearlyPlan = PremiumYearlyPlan();
        mockService.setCurrentPlan(premiumYearlyPlan);

        final cancelResult = await mockService.cancelSubscription();
        expect(cancelResult.isSuccess, isTrue);

        final statusResult = await mockService.getCurrentStatus();
        expect(statusResult.value.planId, equals('basic'));
        expect(statusResult.value.isActive, isFalse);
      });
    });

    group('エラーシミュレーション', () {
      test('初期化失敗をシミュレートできる', () async {
        mockService.setInitializationFailure(true, 'Test initialization error');

        final result = await mockService.initialize();

        expect(result.isFailure, isTrue);
        expect(result.error.message, contains('Test initialization error'));
        expect(mockService.isInitialized, isFalse);
      });

      test('状態取得失敗をシミュレートできる', () async {
        await mockService.initialize();
        mockService.setStatusRetrievalFailure(true, 'Test status error');

        final result = await mockService.getCurrentStatus();

        expect(result.isFailure, isTrue);
        expect(result.error.message, contains('Test status error'));
      });

      test('購入失敗をシミュレートできる', () async {
        await mockService.initialize();
        mockService.setPurchaseFailure(true, 'Test purchase error');

        final premiumYearlyPlan = PremiumYearlyPlan();
        final result = await mockService.purchasePlanClass(
          premiumYearlyPlan,
        );

        expect(result.isSuccess, isTrue); // Success with error status
        expect(result.value.status, equals(PurchaseStatus.error));
        expect(result.value.errorMessage, contains('Test purchase error'));
      });
    });

    group('ストリーム機能', () {
      setUp(() async {
        await mockService.initialize();
      });

      test('statusStreamが状態変更を通知する', () async {
        // 状態変更
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        mockService.setCurrentPlan(premiumMonthlyPlan);
        mockService.setUsageCount(5);

        final stream = mockService.statusStream;
        expect(stream, isA<Stream<SubscriptionStatus>>());

        // ストリームから値を取得
        final statuses = await stream.take(2).toList();
        expect(statuses.length, equals(2));
      });

      test('purchaseStreamが購入結果を通知する', () async {
        final stream = mockService.purchaseStream;

        // 購入実行
        final premiumYearlyPlan = PremiumYearlyPlan();
        await mockService.purchasePlanClass(premiumYearlyPlan);

        expect(stream, isA<Stream<PurchaseResult>>());
      });

      test('dispose()が正常に動作する', () async {
        await expectLater(mockService.dispose(), completes);
        expect(mockService.isInitialized, isFalse);
      });
    });
  });
}
