import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

// テスト用のモックサービス実装
class MockSubscriptionService implements ISubscriptionService {
  bool _isInitialized = false;
  // Hiveに依存しないカスタム状態管理
  String _planId = 'basic';
  bool _isActive = true;
  int _monthlyUsageCount = 0;
  DateTime? _expiryDate;

  SubscriptionStatus get _currentStatus {
    return SubscriptionStatus(
      planId: _planId,
      isActive: _isActive,
      monthlyUsageCount: _monthlyUsageCount,
      expiryDate: _expiryDate,
    );
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<Result<void>> initialize() async {
    _isInitialized = true;
    return const Success(null);
  }

  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    return Success(_currentStatus);
  }

  @override
  Future<Result<void>> refreshStatus() async {
    return const Success(null);
  }

  @override
  Result<List<SubscriptionPlan>> getAvailablePlans() {
    return Success(SubscriptionPlan.values);
  }

  @override
  Result<SubscriptionPlan> getPlan(String planId) {
    try {
      final plan = SubscriptionPlan.fromId(planId);
      return Success(plan);
    } catch (e) {
      return Failure(ServiceException('Invalid plan ID: $planId'));
    }
  }

  @override
  Future<Result<SubscriptionPlan>> getCurrentPlan() async {
    return Success(_currentStatus.currentPlan);
  }

  @override
  Future<Result<bool>> canUseAiGeneration() async {
    return Success(_currentStatus.canUseAiGeneration);
  }

  @override
  Future<Result<void>> incrementAiUsage() async {
    _monthlyUsageCount++;
    return const Success(null);
  }

  @override
  Future<Result<int>> getRemainingGenerations() async {
    return Success(_currentStatus.remainingGenerations);
  }

  @override
  Future<Result<int>> getMonthlyUsage() async {
    return Success(_currentStatus.monthlyUsageCount);
  }

  @override
  Future<Result<void>> resetUsage() async {
    _monthlyUsageCount = 0;
    return const Success(null);
  }

  @override
  Future<void> resetMonthlyUsageIfNeeded() async {
    // テスト用のシンプルな実装
  }

  @override
  Future<Result<DateTime>> getNextResetDate() async {
    return Success(_currentStatus.nextResetDate);
  }

  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    return Success(_currentStatus.canAccessPremiumFeatures);
  }

  @override
  Future<Result<bool>> canAccessWritingPrompts() async {
    return Success(_currentStatus.canAccessWritingPrompts);
  }

  @override
  Future<Result<bool>> canAccessAdvancedFilters() async {
    return Success(_currentStatus.canAccessAdvancedFilters);
  }

  @override
  Future<Result<bool>> canAccessAdvancedAnalytics() async {
    return Success(_currentStatus.canAccessAdvancedAnalytics);
  }

  @override
  Future<Result<bool>> canAccessPrioritySupport() async {
    return Success(_currentStatus.currentPlan.hasPrioritySupport);
  }

  @override
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    final products = [
      const PurchaseProduct(
        id: 'smart_photo_diary_premium_yearly',
        title: 'Premium Plan',
        description: 'Smart Photo Diary Premium',
        price: '¥2,800',
        priceAmount: 2800.0,
        currencyCode: 'JPY',
        plan: SubscriptionPlan.premiumYearly,
      ),
    ];
    return Success(products);
  }

  @override
  Future<Result<PurchaseResult>> purchasePlan(SubscriptionPlan plan) async {
    final result = PurchaseResult(
      status: PurchaseStatus.purchased,
      productId: plan.productId,
      transactionId:
          'mock_transaction_${DateTime.now().millisecondsSinceEpoch}',
      purchaseDate: DateTime.now(),
      plan: plan,
    );
    return Success(result);
  }

  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    return const Success([]);
  }

  @override
  Future<Result<bool>> validatePurchase(String transactionId) async {
    return const Success(true);
  }

  @override
  Future<Result<void>> changePlan(SubscriptionPlan newPlan) async {
    _planId = newPlan.planId;
    if (newPlan.isPremium) {
      _expiryDate = DateTime.now().add(const Duration(days: 365));
    } else {
      _expiryDate = null;
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> cancelSubscription() async {
    _planId = 'basic';
    _isActive = false;
    _expiryDate = null;
    return const Success(null);
  }

  @override
  Stream<SubscriptionStatus> get statusStream {
    return Stream.value(_currentStatus);
  }

  @override
  Stream<PurchaseResult> get purchaseStream {
    return Stream.empty();
  }

  @override
  Future<void> dispose() async {
    // Mock implementation - nothing to dispose
  }
}

void main() {
  group('ISubscriptionService', () {
    late MockSubscriptionService service;

    setUp(() {
      service = MockSubscriptionService();
    });

    group('基本サービスメソッドテスト', () {
      test('初期化が正しく動作する', () async {
        expect(service.isInitialized, isFalse);

        final result = await service.initialize();

        expect(result.isSuccess, isTrue);
        expect(service.isInitialized, isTrue);
      });

      test('現在の状態を取得できる', () async {
        await service.initialize();

        final result = await service.getCurrentStatus();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<SubscriptionStatus>());
        expect(result.value.planId, equals('basic'));
      });

      test('状態をリフレッシュできる', () async {
        await service.initialize();

        final result = await service.refreshStatus();

        expect(result.isSuccess, isTrue);
      });
    });

    group('プラン管理メソッドテスト', () {
      test('利用可能なプラン一覧を取得できる', () {
        final result = service.getAvailablePlans();

        expect(result.isSuccess, isTrue);
        expect(result.value, equals(SubscriptionPlan.values));
        expect(result.value.length, equals(3));
      });

      test('特定のプラン情報を取得できる', () {
        final basicResult = service.getPlan('basic');
        final premiumYearlyResult = service.getPlan('premium_yearly');

        expect(basicResult.isSuccess, isTrue);
        expect(basicResult.value, equals(SubscriptionPlan.basic));

        expect(premiumYearlyResult.isSuccess, isTrue);
        expect(
          premiumYearlyResult.value,
          equals(SubscriptionPlan.premiumYearly),
        );
      });

      test('不正なプランIDでエラーが返される', () {
        final result = service.getPlan('invalid');

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });

      test('現在のプランを取得できる', () async {
        await service.initialize();

        final result = await service.getCurrentPlan();

        expect(result.isSuccess, isTrue);
        expect(result.value, equals(SubscriptionPlan.basic));
      });
    });

    group('使用量管理メソッドテスト', () {
      test('AI生成の使用可否をチェックできる', () async {
        await service.initialize();

        final result = await service.canUseAiGeneration();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('AI生成使用量をインクリメントできる', () async {
        await service.initialize();

        final beforeUsage = await service.getMonthlyUsage();
        expect(beforeUsage.value, equals(0));

        final incrementResult = await service.incrementAiUsage();
        expect(incrementResult.isSuccess, isTrue);

        final afterUsage = await service.getMonthlyUsage();
        expect(afterUsage.value, equals(1));
      });

      test('残りAI生成回数を取得できる', () async {
        await service.initialize();

        final result = await service.getRemainingGenerations();

        expect(result.isSuccess, isTrue);
        expect(result.value, equals(10)); // Basic plan limit
      });

      test('使用量をリセットできる', () async {
        await service.initialize();

        // 使用量を増やす
        await service.incrementAiUsage();
        await service.incrementAiUsage();

        final beforeReset = await service.getMonthlyUsage();
        expect(beforeReset.value, equals(2));

        final resetResult = await service.resetUsage();
        expect(resetResult.isSuccess, isTrue);

        final afterReset = await service.getMonthlyUsage();
        expect(afterReset.value, equals(0));
      });

      test('次のリセット日を取得できる', () async {
        await service.initialize();

        final result = await service.getNextResetDate();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<DateTime>());
      });
    });

    group('アクセス権限チェックメソッドテスト', () {
      test('プレミアム機能のアクセス権をチェックできる', () async {
        await service.initialize();

        final result = await service.canAccessPremiumFeatures();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basic plan
      });

      test('ライティングプロンプトのアクセス権をチェックできる', () async {
        await service.initialize();

        final result = await service.canAccessWritingPrompts();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basic plan
      });

      test('高度なフィルタのアクセス権をチェックできる', () async {
        await service.initialize();

        final result = await service.canAccessAdvancedFilters();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basic plan
      });

      test('高度な分析のアクセス権をチェックできる', () async {
        await service.initialize();

        final result = await service.canAccessAdvancedAnalytics();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basic plan
      });

      test('優先サポートのアクセス権をチェックできる', () async {
        await service.initialize();

        final result = await service.canAccessPrioritySupport();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basic plan
      });
    });

    group('購入関連メソッドテスト', () {
      test('商品情報を取得できる', () async {
        await service.initialize();

        final result = await service.getProducts();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<List<PurchaseProduct>>());
        expect(result.value.length, equals(1));
        expect(result.value.first.plan, equals(SubscriptionPlan.premiumYearly));
      });

      test('プランを購入できる', () async {
        await service.initialize();

        final result = await service.purchasePlan(
          SubscriptionPlan.premiumYearly,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value.status, equals(PurchaseStatus.purchased));
        expect(result.value.plan, equals(SubscriptionPlan.premiumYearly));
        expect(result.value.isSuccess, isTrue);
      });

      test('購入を復元できる', () async {
        await service.initialize();

        final result = await service.restorePurchases();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<List<PurchaseResult>>());
      });

      test('購入を検証できる', () async {
        await service.initialize();

        final result = await service.validatePurchase('test_transaction');

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('プランを変更できる', () async {
        await service.initialize();

        final changeResult = await service.changePlan(
          SubscriptionPlan.premiumYearly,
        );
        expect(changeResult.isSuccess, isTrue);

        final currentPlan = await service.getCurrentPlan();
        expect(currentPlan.value, equals(SubscriptionPlan.premiumYearly));
      });

      test('サブスクリプションをキャンセルできる', () async {
        await service.initialize();

        // Premium に変更してからキャンセル
        await service.changePlan(SubscriptionPlan.premiumYearly);

        final cancelResult = await service.cancelSubscription();
        expect(cancelResult.isSuccess, isTrue);

        final currentPlan = await service.getCurrentPlan();
        expect(currentPlan.value, equals(SubscriptionPlan.basic));
      });
    });

    group('ストリーム・ライフサイクルテスト', () {
      test('状態ストリームが利用できる', () async {
        await service.initialize();

        final stream = service.statusStream;

        expect(stream, isA<Stream<SubscriptionStatus>>());

        final firstValue = await stream.first;
        expect(firstValue, isA<SubscriptionStatus>());
      });

      test('購入ストリームが利用できる', () async {
        await service.initialize();

        final stream = service.purchaseStream;

        expect(stream, isA<Stream<PurchaseResult>>());
      });

      test('サービスを破棄できる', () async {
        await service.initialize();

        // disposeは例外を投げないことを確認
        await expectLater(service.dispose(), completes);
      });
    });

    group('データクラステスト', () {
      test('PurchaseProductが正しく作成される', () {
        const product = PurchaseProduct(
          id: 'test_id',
          title: 'Test Title',
          description: 'Test Description',
          price: '¥100',
          priceAmount: 100.0,
          currencyCode: 'JPY',
          plan: SubscriptionPlan.premiumYearly,
        );

        expect(product.id, equals('test_id'));
        expect(product.title, equals('Test Title'));
        expect(product.description, equals('Test Description'));
        expect(product.price, equals('¥100'));
        expect(product.priceAmount, equals(100.0));
        expect(product.currencyCode, equals('JPY'));
        expect(product.plan, equals(SubscriptionPlan.premiumYearly));
      });

      test('PurchaseResultが正しく作成される', () {
        const result = PurchaseResult(
          status: PurchaseStatus.purchased,
          productId: 'test_product',
          transactionId: 'test_transaction',
          plan: SubscriptionPlan.premiumYearly,
        );

        expect(result.status, equals(PurchaseStatus.purchased));
        expect(result.productId, equals('test_product'));
        expect(result.transactionId, equals('test_transaction'));
        expect(result.plan, equals(SubscriptionPlan.premiumYearly));
        expect(result.isSuccess, isTrue);
        expect(result.isCancelled, isFalse);
        expect(result.isError, isFalse);
      });

      test('SubscriptionExceptionが正しく作成される', () {
        const exception = SubscriptionException(
          'Test error',
          details: 'Test details',
          errorCode: 'TEST_001',
        );

        expect(exception.message, equals('Test error'));
        expect(exception.details, equals('Test details'));
        expect(exception.errorCode, equals('TEST_001'));
        expect(exception.toString(), contains('Test error'));
        expect(exception.toString(), contains('Test details'));
        expect(exception.toString(), contains('TEST_001'));
      });
    });
  });
}
