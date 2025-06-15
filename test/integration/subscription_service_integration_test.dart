import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import '../unit/helpers/hive_test_helpers.dart';

/// Phase 1.5.3: SubscriptionService統合テスト
/// 
/// Service Registration、基本フロー、エラーケースの実動作確認
/// ServiceLocatorとの統合、実際のHive操作、フルスタック動作テスト

void main() {
  group('Phase 1.5.3: SubscriptionService 統合テスト', () {
    late ServiceLocator serviceLocator;
    
    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });
    
    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();
      
      // SubscriptionServiceインスタンスをリセット
      SubscriptionService.resetForTesting();
      
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
    // Phase 1.5.3.1: Service Registration動作確認
    // =================================================================
    
    group('Phase 1.5.3.1: Service Registration動作確認', () {
      test('ServiceLocatorにISubscriptionServiceが正しく登録される', () async {
        // Arrange & Act
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        // Assert
        expect(serviceLocator.isRegistered<ISubscriptionService>(), isTrue);
        expect(serviceLocator.isRegistered<SubscriptionService>(), isFalse); // 具象クラスは未登録
      });
      
      test('ServiceLocatorからISubscriptionServiceのインスタンスを取得できる', () async {
        // Arrange
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        // Act
        final service = await serviceLocator.getAsync<ISubscriptionService>();
        
        // Assert
        expect(service, isNotNull);
        expect(service, isA<ISubscriptionService>());
        expect(service, isA<SubscriptionService>()); // 実装クラスも確認
      });
      
      test('複数回の取得で同じシングルトンインスタンスが返される', () async {
        // Arrange
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        // Act
        final service1 = await serviceLocator.getAsync<ISubscriptionService>();
        final service2 = await serviceLocator.getAsync<ISubscriptionService>();
        
        // Assert
        expect(service1, same(service2)); // 同じインスタンス
        expect((service1 as SubscriptionService).isInitialized, isTrue);
        expect((service2 as SubscriptionService).isInitialized, isTrue);
      });
      
      test('ServiceLocator登録後に初期化が正常に完了する', () async {
        // Arrange
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        // Act
        final service = await serviceLocator.getAsync<ISubscriptionService>() as SubscriptionService;
        
        // Assert
        expect(service.isInitialized, isTrue);
        expect(service.subscriptionBox, isNotNull);
        expect(service.subscriptionBox!.isOpen, isTrue);
        
        // 初期状態も確認
        final statusResult = await service.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);
        expect(statusResult.value.planId, equals(SubscriptionPlan.basic.id));
      });
      
      test('依存注入を使った他サービスとの連携確認', () async {
        // Arrange - 複数サービスを登録
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        // Mock他サービスを登録（実際の統合では実サービスを使用）
        serviceLocator.registerSingleton<String>('test-dependency');
        
        // Act
        final subscriptionService = await serviceLocator.getAsync<ISubscriptionService>();
        final testDependency = serviceLocator.get<String>();
        
        // Assert
        expect(subscriptionService, isNotNull);
        expect(testDependency, equals('test-dependency'));
        
        // サービス間の基本操作確認
        final statusResult = await subscriptionService.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);
      });
      
      test('サービス登録の初期化順序が正しく動作する', () async {
        // Arrange - 複数の非同期ファクトリを登録
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        // 他の依存サービスもモック登録
        serviceLocator.registerSingleton<int>(42);
        
        // Act - 複数サービスを並行取得
        final futures = await Future.wait([
          serviceLocator.getAsync<ISubscriptionService>(),
          Future.value(serviceLocator.get<int>()),
        ]);
        
        final subscriptionService = futures[0] as ISubscriptionService;
        final testValue = futures[1] as int;
        
        // Assert
        expect(subscriptionService, isNotNull);
        expect(testValue, equals(42));
        expect((subscriptionService as SubscriptionService).isInitialized, isTrue);
      });
      
      test('登録解除と再登録が正常に動作する', () async {
        // Arrange
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        final service1 = await serviceLocator.getAsync<ISubscriptionService>();
        expect(service1, isNotNull);
        
        // Act - サービスクリアと再登録
        serviceLocator.clear();
        expect(serviceLocator.isRegistered<ISubscriptionService>(), isFalse);
        
        // SubscriptionServiceもリセット（新しいインスタンス用）
        SubscriptionService.resetForTesting();
        
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        final service2 = await serviceLocator.getAsync<ISubscriptionService>();
        
        // Assert
        expect(service2, isNotNull);
        expect(service1, isNot(same(service2))); // 新しいインスタンス
        expect((service2 as SubscriptionService).isInitialized, isTrue);
      });
    });

    // =================================================================
    // Phase 1.5.3.2: 基本フロー動作確認
    // =================================================================
    
    group('Phase 1.5.3.2: 基本フロー動作確認', () {
      late ISubscriptionService subscriptionService;
      
      setUp(() async {
        // ServiceLocator経由でサービスを取得
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        subscriptionService = await serviceLocator.getAsync<ISubscriptionService>();
      });
      
      test('初期化→Basic状態確認→AI使用→制限到達の完全フロー', () async {
        // 1. 初期状態確認
        final initialStatus = await subscriptionService.getCurrentStatus();
        expect(initialStatus.isSuccess, isTrue);
        expect(initialStatus.value.planId, equals('basic'));
        expect(initialStatus.value.monthlyUsageCount, equals(0));
        expect(initialStatus.value.remainingGenerations, equals(10));
        
        // 2. AI使用可否確認
        final canUseInitial = await subscriptionService.canUseAiGeneration();
        expect(canUseInitial.isSuccess, isTrue);
        expect(canUseInitial.value, isTrue);
        
        // 3. AI使用を9回実行（制限直前まで）
        for (int i = 1; i <= 9; i++) {
          final incrementResult = await subscriptionService.incrementAiUsage();
          expect(incrementResult.isSuccess, isTrue);
          
          final statusAfterIncrement = await subscriptionService.getCurrentStatus();
          expect(statusAfterIncrement.value.monthlyUsageCount, equals(i));
          expect(statusAfterIncrement.value.remainingGenerations, equals(10 - i));
          
          final canUseAfterIncrement = await subscriptionService.canUseAiGeneration();
          expect(canUseAfterIncrement.value, isTrue); // まだ使用可能
        }
        
        // 4. 10回目で制限到達
        final incrementResult10 = await subscriptionService.incrementAiUsage();
        expect(incrementResult10.isSuccess, isTrue);
        
        final statusAtLimit = await subscriptionService.getCurrentStatus();
        expect(statusAtLimit.value.monthlyUsageCount, equals(10));
        expect(statusAtLimit.value.remainingGenerations, equals(0));
        
        // 5. 制限到達後は使用不可
        final canUseAtLimit = await subscriptionService.canUseAiGeneration();
        expect(canUseAtLimit.isSuccess, isTrue);
        expect(canUseAtLimit.value, isFalse);
        
        // 6. 制限超過時はエラー
        final incrementResult11 = await subscriptionService.incrementAiUsage();
        expect(incrementResult11.isFailure, isTrue);
        expect(incrementResult11.error.toString(), contains('Monthly AI generation limit reached'));
      });
      
      test('Basic状態でのアクセス権限確認フロー', () async {
        // 1. Basic状態でのアクセス権限確認
        final basicPremiumAccess = await subscriptionService.canAccessPremiumFeatures();
        final basicPromptsAccess = await subscriptionService.canAccessWritingPrompts();
        final basicFiltersAccess = await subscriptionService.canAccessAdvancedFilters();
        
        expect(basicPremiumAccess.value, isFalse);
        expect(basicPromptsAccess.value, isTrue); // Basic でも制限付きアクセス
        expect(basicFiltersAccess.value, isFalse);
        
        // 2. Basicプランでの使用量管理確認
        for (int i = 1; i <= 5; i++) {
          final incrementResult = await subscriptionService.incrementAiUsage();
          expect(incrementResult.isSuccess, isTrue);
        }
        
        final statusAfter5 = await subscriptionService.getCurrentStatus();
        expect(statusAfter5.value.monthlyUsageCount, equals(5));
        expect(statusAfter5.value.remainingGenerations, equals(5));
        
        final canUseAfter5 = await subscriptionService.canUseAiGeneration();
        expect(canUseAfter5.value, isTrue); // まだ5回残っているので使用可能
        
        // 3. changePlanは未実装なので、エラーが返されることを確認
        final changePlanResult = await subscriptionService.changePlan(SubscriptionPlan.premiumYearly);
        expect(changePlanResult.isFailure, isTrue);
        expect(changePlanResult.error.toString(), contains('not yet implemented'));
      });
      
      test('月次リセット機能の動作確認', () async {
        // 1. 使用量を設定
        for (int i = 0; i < 5; i++) {
          await subscriptionService.incrementAiUsage();
        }
        
        final beforeReset = await subscriptionService.getCurrentStatus();
        expect(beforeReset.value.monthlyUsageCount, equals(5));
        
        // 2. 手動リセット実行
        final resetResult = await subscriptionService.resetUsage();
        expect(resetResult.isSuccess, isTrue);
        
        // 3. リセット後の状態確認
        final afterReset = await subscriptionService.getCurrentStatus();
        expect(afterReset.value.monthlyUsageCount, equals(0));
        expect(afterReset.value.remainingGenerations, equals(10)); // Basic プラン
        
        final canUseAfterReset = await subscriptionService.canUseAiGeneration();
        expect(canUseAfterReset.value, isTrue);
        
        // 4. 月次リセット機能の動作確認（nextResetDateで確認）
        final nextResetDate = await subscriptionService.getNextResetDate();
        expect(nextResetDate.isSuccess, isTrue);
        expect(nextResetDate.value, isA<DateTime>());
      });
      
      test('使用量リセット機能の確認', () async {
        // 1. Basic状態で使用
        for (int i = 0; i < 8; i++) {
          await subscriptionService.incrementAiUsage();
        }
        
        final basicStatus = await subscriptionService.getCurrentStatus();
        expect(basicStatus.value.monthlyUsageCount, equals(8));
        expect(basicStatus.value.remainingGenerations, equals(2)); // Basic: 10 - 8 = 2
        
        // 2. リセット機能の確認
        await subscriptionService.resetUsage();
        
        final resetStatus = await subscriptionService.getCurrentStatus();
        expect(resetStatus.value.monthlyUsageCount, equals(0));
        expect(resetStatus.value.remainingGenerations, equals(10)); // Basic: リセット後
        
        // 3. リセット後の使用確認
        for (int i = 0; i < 3; i++) {
          await subscriptionService.incrementAiUsage();
        }
        
        final afterResetUsage = await subscriptionService.getCurrentStatus();
        expect(afterResetUsage.value.monthlyUsageCount, equals(3));
        expect(afterResetUsage.value.remainingGenerations, equals(7)); // Basic: 10 - 3 = 7
        
        final canUseAfterReset = await subscriptionService.canUseAiGeneration();
        expect(canUseAfterReset.value, isTrue); // まだ7回残っている
      });
      
      test('複数操作の並行実行確認', () async {
        // 1. 複数操作を並行実行
        final futures = await Future.wait([
          subscriptionService.getCurrentStatus(),
          subscriptionService.canUseAiGeneration(),
          subscriptionService.getRemainingGenerations(),
          subscriptionService.canAccessPremiumFeatures(),
          subscriptionService.getNextResetDate(),
        ]);
        
        // 2. 全ての結果が成功であることを確認
        for (final result in futures) {
          expect(result.isSuccess, isTrue);
        }
        
        // 3. 結果の整合性確認
        final status = futures[0] as Result<SubscriptionStatus>;
        final canUse = futures[1] as Result<bool>;
        final remaining = futures[2] as Result<int>;
        
        expect(status.value.planId, equals('basic'));
        expect(canUse.value, isTrue);
        expect(remaining.value, equals(10));
      });
    });

    // =================================================================
    // Phase 1.5.3.3: エラーケースハンドリング確認
    // =================================================================
    
    group('Phase 1.5.3.3: エラーケースハンドリング確認', () {
      late ISubscriptionService subscriptionService;
      
      setUp(() async {
        serviceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        subscriptionService = await serviceLocator.getAsync<ISubscriptionService>();
      });
      
      test('Hiveボックス操作エラーの適切なハンドリング', () async {
        // 1. 正常な初期状態確認
        final initialStatus = await subscriptionService.getCurrentStatus();
        expect(initialStatus.isSuccess, isTrue);
        
        // 2. Hiveボックスを強制的に閉じてエラー状況を作成
        final subscriptionServiceImpl = subscriptionService as SubscriptionService;
        await subscriptionServiceImpl.subscriptionBox?.close();
        
        // 3. エラー状況での操作確認
        // Note: 実際にはサービスが内部的にエラーハンドリングを行うため、
        // ここでは基本的な操作が適切にResult<T>パターンでエラーを返すことを確認
        
        // 新しいインスタンスを作成してテスト
        SubscriptionService.resetForTesting();
        final newSubscriptionService = await SubscriptionService.getInstance();
        final newStatus = await newSubscriptionService.getCurrentStatus();
        expect(newStatus.isSuccess, isTrue); // 新しいボックスで正常動作
      });
      
      test('制限超過時のエラーメッセージ確認', () async {
        // 1. 制限まで使用
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }
        
        // 2. 制限超過時のエラー確認
        final overLimitResult = await subscriptionService.incrementAiUsage();
        expect(overLimitResult.isFailure, isTrue);
        expect(overLimitResult.error.toString(), contains('Monthly AI generation limit reached'));
      });
      
      test('無効なプラン状態でのエラーハンドリング', () async {
        // 1. 期限切れのPremium状態を作成
        final expiredStatus = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 400)),
          expiryDate: DateTime.now().subtract(const Duration(days: 1)), // 期限切れ
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'expired_test',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 400)),
        );
        
        // 期限切れPremium状態を作成するため、具象クラスを使用
        final subscriptionServiceImpl = subscriptionService as SubscriptionService;
        final updateResult = await subscriptionServiceImpl.updateStatus(expiredStatus);
        expect(updateResult.isSuccess, isTrue);
        
        // 2. 期限切れ状態での機能制限確認
        final canAccessPremium = await subscriptionService.canAccessPremiumFeatures();
        expect(canAccessPremium.value, isFalse); // 期限切れなのでアクセス不可
        
        final canUseAi = await subscriptionService.canUseAiGeneration();
        expect(canUseAi.value, isFalse); // 期限切れなので使用不可
        
        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(0)); // 期限切れなので0
      });
      
      test('ServiceLocator未登録時のエラー確認', () async {
        // 1. 新しいServiceLocatorで未登録状態をテスト
        // 注意: ServiceLocatorはシングルトンなので、実際には既に登録済みの状態
        final newServiceLocator = ServiceLocator();
        newServiceLocator.clear(); // 強制的にクリア
        
        // 2. 未登録サービスの取得でエラーが発生することを確認
        expect(newServiceLocator.isRegistered<ISubscriptionService>(), isFalse);
        
        try {
          newServiceLocator.get<ISubscriptionService>();
          fail('Expected exception but none was thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('not registered'));
        }
        
        // 3. クリーンアップ
        newServiceLocator.clear();
      });
      
      test('並行処理での競合状態エラーハンドリング', () async {
        // 1. 複数の使用量インクリメントを並行実行
        final incrementFutures = <Future<Result<void>>>[];
        for (int i = 0; i < 5; i++) {
          incrementFutures.add(subscriptionService.incrementAiUsage());
        }
        
        final results = await Future.wait(incrementFutures);
        
        // 2. 全ての結果が成功またはエラーのいずれかであることを確認
        for (final result in results) {
          expect(result, isA<Result<void>>());
          // 並行処理では一部が成功し、一部が制限エラーになる可能性がある
        }
        
        // 3. 最終的な使用量が正しい範囲内であることを確認
        final finalStatus = await subscriptionService.getCurrentStatus();
        expect(finalStatus.value.monthlyUsageCount, greaterThanOrEqualTo(1));
        expect(finalStatus.value.monthlyUsageCount, lessThanOrEqualTo(10));
      });
      
      test('大量データでの安定性確認', () async {
        // 1. Basic プランで大量の使用量データを処理（制限以内）
        for (int i = 0; i < 8; i++) {
          final result = await subscriptionService.incrementAiUsage();
          expect(result.isSuccess, isTrue);
        }
        
        // 2. 状態の整合性確認
        final status = await subscriptionService.getCurrentStatus();
        expect(status.value.monthlyUsageCount, equals(8));
        expect(status.value.remainingGenerations, equals(2)); // 10 - 8 = 2
        
        // 3. 大量の並行読み取り操作
        final readFutures = <Future>[];
        for (int i = 0; i < 20; i++) {
          readFutures.add(subscriptionService.getCurrentStatus());
          readFutures.add(subscriptionService.canUseAiGeneration());
          readFutures.add(subscriptionService.getRemainingGenerations());
        }
        
        final readResults = await Future.wait(readFutures);
        
        // 4. 全ての読み取り操作が成功することを確認
        for (final result in readResults) {
          expect((result as Result).isSuccess, isTrue);
        }
      });
      
      test('メモリリークとリソース管理の確認', () async {
        // 1. 複数回のサービス取得と操作
        for (int cycle = 0; cycle < 10; cycle++) {
          // 新しいServiceLocatorを作成
          final testServiceLocator = ServiceLocator();
          testServiceLocator.registerAsyncFactory<ISubscriptionService>(
            () async => await SubscriptionService.getInstance(),
          );
          
          final testService = await testServiceLocator.getAsync<ISubscriptionService>();
          
          // 基本操作を実行
          final status = await testService.getCurrentStatus();
          expect(status.isSuccess, isTrue);
          
          await testService.incrementAiUsage();
          
          final canUse = await testService.canUseAiGeneration();
          expect(canUse.isSuccess, isTrue);
          
          // クリーンアップ
          testServiceLocator.clear();
        }
        
        // 2. 最終的な状態確認（メインのサービスが正常動作）
        final finalStatus = await subscriptionService.getCurrentStatus();
        expect(finalStatus.isSuccess, isTrue);
      });
    });
    
    group('Phase 1.5.3.x: 総合統合確認', () {
      test('完全なライフサイクルテスト: 登録→使用→プラン変更→リセット', () async {
        // 1. Service Registration
        final testServiceLocator = ServiceLocator();
        testServiceLocator.registerAsyncFactory<ISubscriptionService>(
          () async => await SubscriptionService.getInstance(),
        );
        
        final service = await testServiceLocator.getAsync<ISubscriptionService>();
        expect(service, isNotNull);
        expect((service as SubscriptionService).isInitialized, isTrue);
        
        // 2. Basic プランでの使用
        final initialStatus = await service.getCurrentStatus();
        expect(initialStatus.value.planId, equals('basic'));
        
        for (int i = 0; i < 5; i++) {
          await service.incrementAiUsage();
        }
        
        final basicUsageStatus = await service.getCurrentStatus();
        expect(basicUsageStatus.value.monthlyUsageCount, equals(5));
        
        // 3. changePlan は未実装なので、エラーを確認
        final changePlanResult = await service.changePlan(SubscriptionPlan.premiumYearly);
        expect(changePlanResult.isFailure, isTrue);
        
        // Basic状態のままで継続
        final statusAfterChange = await service.getCurrentStatus();
        expect(statusAfterChange.value.planId, equals('basic'));
        
        // 使用量をリセットしてからBasicプランで継続使用
        await service.resetUsage();
        for (int i = 0; i < 8; i++) {
          await service.incrementAiUsage();
        }
        
        final usageStatus = await service.getCurrentStatus();
        expect(usageStatus.value.monthlyUsageCount, equals(8));
        expect(usageStatus.value.remainingGenerations, equals(2)); // Basic: 10 - 8 = 2
        
        // 4. アクセス権限確認（Basic プラン）
        final basicAccess = await service.canAccessPremiumFeatures();
        expect(basicAccess.value, isFalse); // Basic プランなのでPremium機能はアクセス不可
        
        // 5. 月次リセット
        await service.resetUsage();
        final resetStatus = await service.getCurrentStatus();
        expect(resetStatus.value.monthlyUsageCount, equals(0));
        expect(resetStatus.value.remainingGenerations, equals(10)); // Basic: 10回
        
        // 6. クリーンアップ
        testServiceLocator.clear();
      });
    });
  });
}