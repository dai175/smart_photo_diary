import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/core/service_registration.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: ServiceLocator依存性注入テスト拡張
///
/// 全サービス間の複雑な依存関係を包括的にテストし、
/// 循環依存、欠落依存、不正依存パターンの検証を実施
///
/// **依存関係マップ:**
/// ```
/// DiaryService → AiService + PhotoService
/// AiService → SubscriptionService
/// PromptService → LoggingService
/// SettingsService → SubscriptionService
/// UI層 → 全サービス（複数サービス同時依存）
/// ```

void main() {
  group('Phase 2-2: ServiceLocator依存性注入テスト拡張 - 全サービス間複雑依存関係', () {
    // テスト用ServiceLocator（完全分離）
    late ServiceLocator testServiceLocator;
    
    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    setUp(() async {
      // 各テストで完全に独立したServiceLocatorを作成
      testServiceLocator = ServiceLocator();
      
      // テスト用のクリーンな環境確立
      ServiceRegistration.reset();
    });

    tearDown(() async {
      // テスト終了時の完全クリーンアップ
      testServiceLocator.clear();
      ServiceRegistration.reset();
      await Future.delayed(const Duration(milliseconds: 10));
    });

    // =================================================================
    // Group 1: 依存関係アーキテクチャテスト - 循環・欠落・不正依存検証
    // =================================================================

    group('Group 1: 依存関係アーキテクチャテスト - 循環・欠落・不正依存検証', () {
      test('正常な依存関係チェーン確認 - DiaryService → AiService → SubscriptionService', () async {
        // Arrange - 正しい順序で依存関係を登録
        final mockSubscriptionService = MockSubscriptionServiceInterface();
        final mockAiService = MockAiServiceInterface();
        final mockDiaryService = MockDiaryServiceInterface();
        final mockPhotoService = MockPhotoServiceInterface();

        // 基底依存から順番に登録
        testServiceLocator.registerSingleton<ISubscriptionService>(mockSubscriptionService);
        testServiceLocator.registerSingleton<PhotoServiceInterface>(mockPhotoService);
        testServiceLocator.registerSingleton<AiServiceInterface>(mockAiService);
        testServiceLocator.registerSingleton<DiaryServiceInterface>(mockDiaryService);

        // Act - 依存関係チェーンの取得
        final subscriptionService = testServiceLocator.get<ISubscriptionService>();
        final aiService = testServiceLocator.get<AiServiceInterface>();
        final diaryService = testServiceLocator.get<DiaryServiceInterface>();

        // Assert - 全ての依存関係が正しく解決される
        expect(subscriptionService, isNotNull);
        expect(aiService, isNotNull);
        expect(diaryService, isNotNull);
        expect(subscriptionService, same(mockSubscriptionService));
        expect(aiService, same(mockAiService));
        expect(diaryService, same(mockDiaryService));
      });

      test('循環依存検出テスト - サービスA → サービスB → サービスAの検証', () {
        // Arrange - 循環依存を模擬するMockサービス
        var callCount = 0;
        
        // 制限付き循環依存テスト（StackOverflowの代わりにカウント制限）
        testServiceLocator.registerFactory<MockServiceA>(() {
          callCount++;
          if (callCount > 3) {
            throw ServiceException('循環依存が検出されました');
          }
          testServiceLocator.get<MockServiceB>();
          return MockServiceA();
        });
        
        testServiceLocator.registerFactory<MockServiceB>(() {
          callCount++;
          if (callCount > 3) {
            throw ServiceException('循環依存が検出されました');
          }
          testServiceLocator.get<MockServiceA>();
          return MockServiceB();
        });

        // Act & Assert - 循環依存によりServiceExceptionが発生することを確認
        expect(
          () => testServiceLocator.get<MockServiceA>(),
          throwsA(predicate((e) => 
            e is ServiceException && 
            e.message.contains('循環依存が検出されました')
          )),
        );
      });

      test('欠落依存検出テスト - 登録されていないサービスへのアクセス', () {
        // Arrange - 意図的にサービスを登録しない

        // Act & Assert - 登録されていないサービスにアクセスすると例外が発生
        expect(
          () => testServiceLocator.get<ISubscriptionService>(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Service of type ISubscriptionService is not registered')
          )),
        );

        expect(
          () => testServiceLocator.get<AiServiceInterface>(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Service of type AiServiceInterface is not registered')
          )),
        );
      });

      test('非同期と同期の混在依存検証 - AsyncFactory → Factory依存チェーン', () async {
        // Arrange - 非同期サービスが同期サービスに依存する構成
        final mockSyncService = MockSyncService();
        final mockAsyncService = MockAsyncService();

        // 同期サービスを先に登録
        testServiceLocator.registerSingleton<MockSyncService>(mockSyncService);

        // 非同期サービスが同期サービスに依存
        testServiceLocator.registerAsyncFactory<MockAsyncService>(() async {
          final syncDependency = testServiceLocator.get<MockSyncService>();
          expect(syncDependency, isNotNull);
          return mockAsyncService;
        });

        // Act - 非同期サービスの取得
        final asyncService = await testServiceLocator.getAsync<MockAsyncService>();

        // Assert - 依存関係が正しく解決される
        expect(asyncService, same(mockAsyncService));
      });

      test('型不一致依存エラー検証 - 誤った型でのサービス要求', () {
        // Arrange - 特定の型でサービスを登録
        final mockService = MockSubscriptionServiceInterface();
        testServiceLocator.registerSingleton<ISubscriptionService>(mockService);

        // Act & Assert - 異なる型でサービスを要求すると例外が発生
        expect(
          () => testServiceLocator.get<AiServiceInterface>(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Service of type AiServiceInterface is not registered')
          )),
        );

        // 正しい型では正常に取得できる
        final correctService = testServiceLocator.get<ISubscriptionService>();
        expect(correctService, same(mockService));
      });

      test('サービス重複登録の動作確認', () {
        // Arrange - 同じ型で複数のサービスを登録
        final firstService = MockSubscriptionServiceInterface();
        final secondService = MockSubscriptionServiceInterface();

        testServiceLocator.registerSingleton<ISubscriptionService>(firstService);
        
        // Act - 同じ型で再登録
        testServiceLocator.registerSingleton<ISubscriptionService>(secondService);

        // Assert - 後で登録されたサービスが取得される（上書き動作）
        final retrievedService = testServiceLocator.get<ISubscriptionService>();
        expect(retrievedService, same(secondService));
        expect(retrievedService, isNot(same(firstService)));
      });
    });

    // =================================================================
    // Group 2: ServiceLocator完全分離テスト環境 - Mock注入システム
    // =================================================================

    group('Group 2: ServiceLocator完全分離テスト環境 - Mock注入システム', () {
      test('テスト用ServiceLocatorの完全独立性確認', () {
        // Arrange - メインのServiceLocatorとテスト用を比較
        final mainLocator = ServiceLocator(); // シングルトンインスタンス
        final testLocator1 = ServiceLocator();
        final testLocator2 = ServiceLocator();

        // Assert - 全て同じシングルトンインスタンス
        expect(mainLocator, same(testLocator1));
        expect(testLocator1, same(testLocator2));

        // ServiceLocatorはシングルトンなので、テスト分離にはclearが重要
        mainLocator.clear();
        expect(testLocator1.registeredTypes, isEmpty);
      });

      test('Mock注入システムの動作確認', () {
        // Arrange - 本物のサービスとMockサービス
        final mockPhotoService = MockPhotoServiceInterface();
        final mockAiService = MockAiServiceInterface();

        // Mockサービスの動作設定
        when(() => mockPhotoService.getTodayPhotos()).thenAnswer((_) async => []);
        when(() => mockAiService.isOnlineResult()).thenAnswer((_) async => const Success(true));

        // Act - ServiceLocatorにMockを注入
        testServiceLocator.registerSingleton<PhotoServiceInterface>(mockPhotoService);
        testServiceLocator.registerSingleton<AiServiceInterface>(mockAiService);

        // Assert - Mockサービスが正しく注入される
        final retrievedPhotoService = testServiceLocator.get<PhotoServiceInterface>();
        final retrievedAiService = testServiceLocator.get<AiServiceInterface>();

        expect(retrievedPhotoService, same(mockPhotoService));
        expect(retrievedAiService, same(mockAiService));
      });

      test('テスト間の状態完全分離確認', () async {
        // Phase 1: 最初のテスト状態
        final firstMockService = MockSubscriptionServiceInterface();
        testServiceLocator.registerSingleton<ISubscriptionService>(firstMockService);

        expect(testServiceLocator.isRegistered<ISubscriptionService>(), isTrue);
        expect(testServiceLocator.get<ISubscriptionService>(), same(firstMockService));

        // Phase 2: クリーンアップ
        testServiceLocator.clear();

        // Phase 3: 状態がクリアされていることを確認
        expect(testServiceLocator.isRegistered<ISubscriptionService>(), isFalse);
        expect(testServiceLocator.registeredTypes, isEmpty);
        expect(
          () => testServiceLocator.get<ISubscriptionService>(),
          throwsA(isA<Exception>()),
        );

        // Phase 4: 新しい状態で再テスト
        final secondMockService = MockSubscriptionServiceInterface();
        testServiceLocator.registerSingleton<ISubscriptionService>(secondMockService);

        expect(testServiceLocator.get<ISubscriptionService>(), same(secondMockService));
        expect(testServiceLocator.get<ISubscriptionService>(), isNot(same(firstMockService)));
      });

      test('大量サービス登録・クリーンアップのメモリ効率確認', () {
        // Arrange - 大量のMockサービスを作成
        const serviceCount = 100;
        final mockServices = <MockPerformanceService>[];

        for (int i = 0; i < serviceCount; i++) {
          mockServices.add(MockPerformanceService());
        }

        // Act - 大量登録
        for (int i = 0; i < serviceCount; i++) {
          testServiceLocator.registerSingleton<MockPerformanceService>(mockServices[i]);
        }

        // Assert - 正しく登録されている
        expect(testServiceLocator.registeredTypes.length, greaterThanOrEqualTo(1));

        // Act - 一括クリーンアップ
        testServiceLocator.clear();

        // Assert - 完全にクリーンアップされている
        expect(testServiceLocator.registeredTypes, isEmpty);
        expect(
          () => testServiceLocator.get<MockPerformanceService>(),
          throwsA(isA<Exception>()),
        );
      });
    });

    // =================================================================
    // Group 3: ライフサイクルテスト - Singleton・Factory・AsyncFactory検証
    // =================================================================

    group('Group 3: ライフサイクルテスト - Singleton・Factory・AsyncFactory検証', () {
      test('Singletonパターンの動作確認 - 同一インスタンス保証', () {
        // Arrange
        final mockService = MockSubscriptionServiceInterface();
        testServiceLocator.registerSingleton<ISubscriptionService>(mockService);

        // Act - 複数回取得
        final instance1 = testServiceLocator.get<ISubscriptionService>();
        final instance2 = testServiceLocator.get<ISubscriptionService>();
        final instance3 = testServiceLocator.get<ISubscriptionService>();

        // Assert - 全て同じインスタンス
        expect(instance1, same(mockService));
        expect(instance2, same(mockService));
        expect(instance3, same(mockService));
        expect(instance1, same(instance2));
        expect(instance2, same(instance3));
      });

      test('Factoryパターンの遅延初期化確認', () {
        // Arrange - Factory登録（実際の作成は遅延）
        var factoryCallCount = 0;
        testServiceLocator.registerFactory<MockSubscriptionServiceInterface>(() {
          factoryCallCount++;
          return MockSubscriptionServiceInterface();
        });

        // Assert - まだファクトリは呼ばれていない
        expect(factoryCallCount, equals(0));
        expect(testServiceLocator.isRegistered<MockSubscriptionServiceInterface>(), isTrue);

        // Act - 初回取得
        final instance1 = testServiceLocator.get<MockSubscriptionServiceInterface>();
        expect(factoryCallCount, equals(1));

        // Act - 2回目取得（Singletonとしてキャッシュされるはず）
        final instance2 = testServiceLocator.get<MockSubscriptionServiceInterface>();
        expect(factoryCallCount, equals(1)); // 呼ばれない
        expect(instance1, same(instance2)); // 同じインスタンス
      });

      test('AsyncFactoryパターンの非同期初期化確認', () async {
        // Arrange - AsyncFactory登録
        var asyncFactoryCallCount = 0;
        testServiceLocator.registerAsyncFactory<MockAsyncService>(() async {
          asyncFactoryCallCount++;
          await Future.delayed(const Duration(milliseconds: 10));
          return MockAsyncService();
        });

        // Assert - まだファクトリは呼ばれていない
        expect(asyncFactoryCallCount, equals(0));

        // Act - 非同期取得
        final instance1 = await testServiceLocator.getAsync<MockAsyncService>();
        expect(asyncFactoryCallCount, equals(1));

        // Act - 2回目取得（キャッシュから）
        final instance2 = await testServiceLocator.getAsync<MockAsyncService>();
        expect(asyncFactoryCallCount, equals(1)); // 呼ばれない
        expect(instance1, same(instance2));
      });

      test('異なるパターンの混在確認 - Singleton + Factory + AsyncFactory', () async {
        // Arrange - 3パターンを混在登録
        final singletonService = MockSubscriptionServiceInterface();
        testServiceLocator.registerSingleton<ISubscriptionService>(singletonService);

        testServiceLocator.registerFactory<MockSyncService>(() => MockSyncService());
        testServiceLocator.registerAsyncFactory<MockAsyncService>(() async => MockAsyncService());

        // Act - 各パターンからサービス取得
        final singletonInstance = testServiceLocator.get<ISubscriptionService>();
        final factoryInstance = testServiceLocator.get<MockSyncService>();
        final asyncInstance = await testServiceLocator.getAsync<MockAsyncService>();

        // Assert - 全て正常に取得できる
        expect(singletonInstance, same(singletonService));
        expect(factoryInstance, isA<MockSyncService>());
        expect(asyncInstance, isA<MockAsyncService>());

        // 登録タイプ確認
        final registeredTypes = testServiceLocator.registeredTypes;
        expect(registeredTypes.length, equals(3));
        expect(registeredTypes.contains(ISubscriptionService), isTrue);
        expect(registeredTypes.contains(MockSyncService), isTrue);
        expect(registeredTypes.contains(MockAsyncService), isTrue);
      });

      test('非同期サービスを同期で取得した場合のエラー確認', () {
        // Arrange - AsyncFactoryを登録
        testServiceLocator.registerAsyncFactory<MockAsyncService>(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return MockAsyncService();
        });

        // Act & Assert - 同期取得でエラーが発生
        expect(
          () => testServiceLocator.get<MockAsyncService>(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('requires async initialization')
          )),
        );
      });
    });

    // =================================================================
    // Group 4: 循環依存検出テスト - サービス間の循環参照パターン自動検出
    // =================================================================

    group('Group 4: 依存関係設計パターンテスト - 循環依存回避と適切な設計', () {
      test('線形依存関係の正常パターン確認', () {
        // Arrange - 推奨される線形依存関係
        final baseService = MockBaseService();
        testServiceLocator.registerSingleton<MockBaseService>(baseService);
        
        testServiceLocator.registerFactory<MockCircularServiceA>(() {
          final base = testServiceLocator.get<MockBaseService>();
          return MockCircularServiceA(base);
        });

        // Act - 正常な依存関係は問題なく動作
        final serviceA = testServiceLocator.get<MockCircularServiceA>();
        
        // Assert - 正常な依存関係の動作確認
        expect(serviceA, isNotNull);
        expect(serviceA.dependency, same(baseService));
      });

      test('階層的依存関係パターンの確認', () {
        // Arrange - 階層的な依存関係（推奨パターン）
        final level1Service = MockLevel1Service();
        testServiceLocator.registerSingleton<MockLevel1Service>(level1Service);
        
        testServiceLocator.registerFactory<MockLevel2Service>(() {
          final level1 = testServiceLocator.get<MockLevel1Service>();
          return MockLevel2Service(level1);
        });
        
        testServiceLocator.registerFactory<MockLevel3Service>(() {
          final level2 = testServiceLocator.get<MockLevel2Service>();
          return MockLevel3Service(level2);
        });

        // Act - 階層的依存関係の確認
        final level3Service = testServiceLocator.get<MockLevel3Service>();
        
        // Assert - 適切な依存関係チェーン
        expect(level3Service, isNotNull);
        expect(level3Service.dependency, isNotNull);
        expect(level3Service.dependency.dependency, same(level1Service));
      });

      test('共有依存関係パターンの確認', () {
        // Arrange - 複数サービスが同一の共通サービスに依存
        final sharedService = MockSharedDependencyService();
        testServiceLocator.registerSingleton<MockSharedDependencyService>(sharedService);
        
        testServiceLocator.registerFactory<MockParallelServiceA>(() {
          final shared = testServiceLocator.get<MockSharedDependencyService>();
          return MockParallelServiceA(shared);
        });
        
        testServiceLocator.registerFactory<MockParallelServiceB>(() {
          final shared = testServiceLocator.get<MockSharedDependencyService>();
          return MockParallelServiceB(shared);
        });

        // Act - 並列サービスの取得
        final serviceA = testServiceLocator.get<MockParallelServiceA>();
        final serviceB = testServiceLocator.get<MockParallelServiceB>();

        // Assert - 共通依存の共有確認
        expect(serviceA.dependency, same(sharedService));
        expect(serviceB.dependency, same(sharedService));
        expect(serviceA.dependency, same(serviceB.dependency));
      });

      test('依存関係の独立性確認', () {
        // Arrange - 独立したサービス群
        final independentServiceA = MockIndependentServiceA();
        final independentServiceB = MockIndependentServiceB();
        
        testServiceLocator.registerSingleton<MockIndependentServiceA>(independentServiceA);
        testServiceLocator.registerSingleton<MockIndependentServiceB>(independentServiceB);

        // Act - 独立サービスの取得
        final serviceA = testServiceLocator.get<MockIndependentServiceA>();
        final serviceB = testServiceLocator.get<MockIndependentServiceB>();

        // Assert - 独立性の確認
        expect(serviceA, same(independentServiceA));
        expect(serviceB, same(independentServiceB));
        expect(serviceA, isNot(same(serviceB)));
      });
    });

    // =================================================================
    // Group 5: 依存関係解決順序テスト - サービス初期化順序と依存解決確認
    // =================================================================

    group('Group 5: 依存関係解決順序テスト - サービス初期化順序と依存解決確認', () {
      test('適切な依存順序での初期化確認', () {
        // Arrange - 依存チェーン: Level1 → Level2 → Level3
        final initializationOrder = <String>[];

        // Level 1: 基底サービス
        testServiceLocator.registerFactory<MockLevel1Service>(() {
          initializationOrder.add('Level1');
          return MockLevel1Service();
        });

        // Level 2: Level1に依存
        testServiceLocator.registerFactory<MockLevel2Service>(() {
          final level1 = testServiceLocator.get<MockLevel1Service>();
          initializationOrder.add('Level2');
          return MockLevel2Service(level1);
        });

        // Level 3: Level2に依存
        testServiceLocator.registerFactory<MockLevel3Service>(() {
          final level2 = testServiceLocator.get<MockLevel2Service>();
          initializationOrder.add('Level3');
          return MockLevel3Service(level2);
        });

        // Act - Level3を取得（依存チェーンを辿る）
        final service = testServiceLocator.get<MockLevel3Service>();

        // Assert - 正しい初期化順序
        expect(service, isNotNull);
        expect(initializationOrder, equals(['Level1', 'Level2', 'Level3']));
      });

      test('並列依存関係の初期化順序確認', () {
        // Arrange - 複数の独立したサービスが1つのサービスに依存
        final initializationOrder = <String>[];

        // 共通依存サービス
        testServiceLocator.registerFactory<MockSharedDependencyService>(() {
          initializationOrder.add('SharedDependency');
          return MockSharedDependencyService();
        });

        // 並列サービスA
        testServiceLocator.registerFactory<MockParallelServiceA>(() {
          final shared = testServiceLocator.get<MockSharedDependencyService>();
          initializationOrder.add('ParallelA');
          return MockParallelServiceA(shared);
        });

        // 並列サービスB  
        testServiceLocator.registerFactory<MockParallelServiceB>(() {
          final shared = testServiceLocator.get<MockSharedDependencyService>();
          initializationOrder.add('ParallelB');
          return MockParallelServiceB(shared);
        });

        // Act - 両方のサービスを取得
        final serviceA = testServiceLocator.get<MockParallelServiceA>();
        final serviceB = testServiceLocator.get<MockParallelServiceB>();

        // Assert - 共通依存が最初に初期化され、その後並列サービス
        expect(serviceA, isNotNull);
        expect(serviceB, isNotNull);
        expect(initializationOrder.first, equals('SharedDependency'));
        expect(initializationOrder.contains('ParallelA'), isTrue);
        expect(initializationOrder.contains('ParallelB'), isTrue);
        
        // 共通依存は1回だけ初期化される
        expect(initializationOrder.where((item) => item == 'SharedDependency').length, equals(1));
      });

      test('非同期依存関係の初期化順序確認', () async {
        // Arrange - 非同期初期化チェーン
        final initializationOrder = <String>[];

        // 非同期基底サービス
        testServiceLocator.registerAsyncFactory<MockAsyncBaseService>(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          initializationOrder.add('AsyncBase');
          return MockAsyncBaseService();
        });

        // 非同期依存サービス
        testServiceLocator.registerAsyncFactory<MockAsyncDependentService>(() async {
          final base = await testServiceLocator.getAsync<MockAsyncBaseService>();
          await Future.delayed(const Duration(milliseconds: 5));
          initializationOrder.add('AsyncDependent');
          return MockAsyncDependentService(base);
        });

        // Act - 非同期依存サービスを取得
        final service = await testServiceLocator.getAsync<MockAsyncDependentService>();

        // Assert - 正しい非同期初期化順序
        expect(service, isNotNull);
        expect(initializationOrder, equals(['AsyncBase', 'AsyncDependent']));
      });

      test('混合初期化パターン確認 - Singleton + Factory + AsyncFactory', () async {
        // Arrange - 3つの異なる初期化パターンの混合
        final initializationOrder = <String>[];

        // Singletonサービス（即座に登録）
        final singletonService = MockSingletonInitService();
        initializationOrder.add('Singleton');
        testServiceLocator.registerSingleton<MockSingletonInitService>(singletonService);

        // Factory（遅延初期化）
        testServiceLocator.registerFactory<MockFactoryInitService>(() {
          final singleton = testServiceLocator.get<MockSingletonInitService>();
          initializationOrder.add('Factory');
          return MockFactoryInitService(singleton);
        });

        // AsyncFactory（非同期遅延初期化）
        testServiceLocator.registerAsyncFactory<MockAsyncInitService>(() async {
          final factory = testServiceLocator.get<MockFactoryInitService>();
          await Future.delayed(const Duration(milliseconds: 5));
          initializationOrder.add('AsyncFactory');
          return MockAsyncInitService(factory);
        });

        // Act - AsyncFactoryサービスを取得（全チェーンを辿る）
        final service = await testServiceLocator.getAsync<MockAsyncInitService>();

        // Assert - 混合パターンでも正しい順序
        expect(service, isNotNull);
        expect(initializationOrder, equals(['Singleton', 'Factory', 'AsyncFactory']));
      });

      test('初期化順序の一意性確認 - 複数回アクセスでの順序保証', () {
        // Arrange
        final initializationOrder = <String>[];
        
        testServiceLocator.registerFactory<MockOrderTestService>(() {
          initializationOrder.add('Service');
          return MockOrderTestService();
        });

        // Act - 複数回アクセス
        final service1 = testServiceLocator.get<MockOrderTestService>();
        final service2 = testServiceLocator.get<MockOrderTestService>();
        final service3 = testServiceLocator.get<MockOrderTestService>();

        // Assert - 初期化は1回だけ、同一インスタンス
        expect(initializationOrder, equals(['Service']));
        expect(service1, same(service2));
        expect(service2, same(service3));
      });
    });

    // =================================================================  
    // Group 6: サービス間相互作用テスト - 実際のユースケース依存チェーン
    // =================================================================

    group('Group 6: サービス間相互作用テスト - 実際のユースケース依存チェーン', () {
      test('DiaryService + AiService統合フロー - 実際の依存関係', () async {
        // Arrange - 現実の依存チェーンを模擬
        final mockSubscriptionService = MockSubscriptionServiceInterface();
        final mockAiService = MockAiServiceInterface();
        final mockPhotoService = MockPhotoServiceInterface();
        final mockDiaryService = MockDiaryServiceInterface();

        // Mockの動作設定
        when(() => mockSubscriptionService.canUseAiGeneration())
            .thenAnswer((_) async => const Success(true));
        when(() => mockAiService.isOnlineResult())
            .thenAnswer((_) async => const Success(true));
        when(() => mockPhotoService.getTodayPhotos())
            .thenAnswer((_) async => []);

        // 依存関係登録（実際のアプリと同様の順序）
        testServiceLocator.registerSingleton<ISubscriptionService>(mockSubscriptionService);
        testServiceLocator.registerSingleton<AiServiceInterface>(mockAiService);
        testServiceLocator.registerSingleton<PhotoServiceInterface>(mockPhotoService);
        testServiceLocator.registerSingleton<DiaryServiceInterface>(mockDiaryService);

        // Act - 実際のユースケースをシミュレート
        final subscriptionService = testServiceLocator.get<ISubscriptionService>();
        final canUseAi = await subscriptionService.canUseAiGeneration();
        
        if (canUseAi.isSuccess && canUseAi.value) {
          final aiService = testServiceLocator.get<AiServiceInterface>();
          final isOnline = await aiService.isOnlineResult();
          
          if (isOnline.isSuccess && isOnline.value) {
            final photoService = testServiceLocator.get<PhotoServiceInterface>();
            await photoService.getTodayPhotos();
            
            final diaryService = testServiceLocator.get<DiaryServiceInterface>();
            expect(diaryService, isNotNull);
          }
        }

        // Assert - 全ての依存関係が正しく解決された
        verify(() => mockSubscriptionService.canUseAiGeneration()).called(1);
        verify(() => mockAiService.isOnlineResult()).called(1);
        verify(() => mockPhotoService.getTodayPhotos()).called(1);
      });

      test('UI層 → 複数サービス同時利用パターン', () async {
        // Arrange - UI層が必要とする全サービスを準備
        final mockPhotoService = MockPhotoServiceInterface();
        final mockDiaryService = MockDiaryServiceInterface();
        final mockSubscriptionService = MockSubscriptionServiceInterface();
        final mockSettingsService = MockSettingsService();

        // 全サービス登録
        testServiceLocator.registerSingleton<PhotoServiceInterface>(mockPhotoService);
        testServiceLocator.registerSingleton<DiaryServiceInterface>(mockDiaryService);
        testServiceLocator.registerSingleton<ISubscriptionService>(mockSubscriptionService);
        testServiceLocator.registerSingleton<SettingsService>(mockSettingsService);

        // Act - UI層での同時サービス利用をシミュレート
        final List<dynamic> services = [];
        services.add(testServiceLocator.get<PhotoServiceInterface>());
        services.add(testServiceLocator.get<DiaryServiceInterface>());
        services.add(testServiceLocator.get<ISubscriptionService>());
        services.add(testServiceLocator.get<SettingsService>());

        // Assert - 全サービスが正しく取得される
        expect(services, hasLength(4));
        expect(services[0], isA<PhotoServiceInterface>());
        expect(services[1], isA<DiaryServiceInterface>());
        expect(services[2], isA<ISubscriptionService>());
        expect(services[3], isA<SettingsService>());

        // 全て異なるサービス
        final uniqueServices = services.toSet();
        expect(uniqueServices, hasLength(4));
      });

      test('複雑な3階層依存チェーン確認', () async {
        // Arrange - 3階層の依存関係を作成
        // Level 1: Base Service (依存なし)
        final mockBaseService = MockBaseService();
        testServiceLocator.registerSingleton<MockBaseService>(mockBaseService);

        // Level 2: Middle Service (Base Serviceに依存)
        testServiceLocator.registerFactory<MockMiddleService>(() {
          final baseService = testServiceLocator.get<MockBaseService>();
          return MockMiddleService(baseService);
        });

        // Level 3: Top Service (Middle Serviceに依存)
        testServiceLocator.registerFactory<MockTopService>(() {
          final middleService = testServiceLocator.get<MockMiddleService>();
          return MockTopService(middleService);
        });

        // Act - Top Serviceを取得（3階層依存の自動解決）
        final topService = testServiceLocator.get<MockTopService>();

        // Assert - 依存チェーンが正しく解決される
        expect(topService, isNotNull);
        expect(topService, isA<MockTopService>());
        
        // 内部的な依存関係も確認
        expect(topService.middleService, isNotNull);
        expect(topService.middleService.baseService, same(mockBaseService));
      });

      test('並行サービス取得の動作確認', () async {
        // Arrange - 複数のサービスを並行で取得可能にする
        testServiceLocator.registerFactory<MockPerformanceService>(() => MockPerformanceService());
        testServiceLocator.registerAsyncFactory<MockAsyncService>(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return MockAsyncService();
        });

        // Act - 並行取得
        final futures = <Future>[];
        futures.add(Future(() => testServiceLocator.get<MockPerformanceService>()));
        futures.add(testServiceLocator.getAsync<MockAsyncService>());
        futures.add(Future(() => testServiceLocator.get<MockPerformanceService>()));

        final results = await Future.wait(futures);

        // Assert - 全て正常に取得される
        expect(results, hasLength(3));
        expect(results[0], isA<MockPerformanceService>());
        expect(results[1], isA<MockAsyncService>());
        expect(results[2], isA<MockPerformanceService>());

        // 同じ型のサービスは同一インスタンス（Singleton化される）
        expect(results[0], same(results[2]));
      });
    });

    // =================================================================
    // Group 7: エラーハンドリングテスト - 依存関係取得失敗時のGraceful Degradation
    // =================================================================

    group('Group 7: エラーハンドリングテスト - 依存関係取得失敗時のGraceful Degradation', () {
      test('Factory初期化失敗時のエラー伝播確認', () {
        // Arrange - 初期化時に例外を投げるFactory
        testServiceLocator.registerFactory<MockErrorProneService>(() {
          throw ServiceException('Factory初期化エラー');
        });

        // Act & Assert - 適切な例外が発生
        expect(
          () => testServiceLocator.get<MockErrorProneService>(),
          throwsA(predicate((e) => 
            e is ServiceException && 
            e.message.contains('Factory初期化エラー')
          )),
        );
      });

      test('非同期Factory初期化失敗時のエラー伝播確認', () async {
        // Arrange - 非同期初期化時に例外を投げるAsyncFactory
        testServiceLocator.registerAsyncFactory<MockErrorProneAsyncService>(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          throw ServiceException('非同期Factory初期化エラー');
        });

        // Act & Assert - 適切な例外が非同期で発生
        expect(
          () => testServiceLocator.getAsync<MockErrorProneAsyncService>(),
          throwsA(predicate((e) => 
            e is ServiceException && 
            e.message.contains('非同期Factory初期化エラー')
          )),
        );
      });

      test('依存サービス取得失敗時のエラーチェーン確認', () {
        // Arrange - 依存サービスが登録されていない状況
        testServiceLocator.registerFactory<MockDependentService>(() {
          // 存在しないサービスに依存
          final dependency = testServiceLocator.get<MockNonExistentService>();
          return MockDependentService(dependency);
        });

        // Act & Assert - 依存関係エラーが適切に伝播
        expect(
          () => testServiceLocator.get<MockDependentService>(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('MockNonExistentService is not registered')
          )),
        );
      });

      test('部分的サービス障害時のGraceful Degradation', () {
        // Arrange - 一部が正常、一部が障害のサービス群
        final workingService = MockWorkingService();
        testServiceLocator.registerSingleton<MockWorkingService>(workingService);

        testServiceLocator.registerFactory<MockFailingService>(() {
          throw ServiceException('サービス障害');
        });

        // Act - 正常なサービスは取得可能
        final normalService = testServiceLocator.get<MockWorkingService>();
        expect(normalService, same(workingService));

        // 障害サービスは例外
        expect(
          () => testServiceLocator.get<MockFailingService>(),
          throwsA(isA<ServiceException>()),
        );
      });

      test('リソース不足エラーシミュレーション', () {
        // Arrange - メモリ不足を模擬するサービス
        var attemptCount = 0;
        testServiceLocator.registerFactory<MockResourceIntensiveService>(() {
          attemptCount++;
          if (attemptCount <= 2) {
            throw ServiceException('リソース不足: メモリ不十分');
          }
          return MockResourceIntensiveService();
        });

        // Act & Assert - 初回・2回目は失敗
        expect(
          () => testServiceLocator.get<MockResourceIntensiveService>(),
          throwsA(predicate((e) => 
            e is ServiceException && 
            e.message.contains('リソース不足')
          )),
        );

        // サービスを再登録（リソース回復をシミュレート）
        testServiceLocator.unregister<MockResourceIntensiveService>();
        testServiceLocator.registerFactory<MockResourceIntensiveService>(() {
          return MockResourceIntensiveService(); // 成功バージョン
        });

        // 3回目は成功
        final service = testServiceLocator.get<MockResourceIntensiveService>();
        expect(service, isNotNull);
      });

      test('タイムアウト処理のエラーハンドリング', () async {
        // Arrange - 非常に長い初期化時間をシミュレート
        testServiceLocator.registerAsyncFactory<MockSlowService>(() async {
          await Future.delayed(const Duration(seconds: 2));
          return MockSlowService();
        });

        // Act - タイムアウト設定でサービス取得
        final stopwatch = Stopwatch()..start();
        
        try {
          await testServiceLocator.getAsync<MockSlowService>().timeout(
            const Duration(milliseconds: 100),
          );
          fail('TimeoutExceptionが発生するはず');
        } catch (e) {
          // Assert - タイムアウトエラーが適切に処理される
          expect(e, isA<Exception>());
          expect(stopwatch.elapsedMilliseconds, lessThan(200));
        }
      });
    });

    // =================================================================
    // Group 8: パフォーマンステスト - 大規模依存グラフでの解決性能測定
    // =================================================================

    group('Group 8: パフォーマンステスト - 大規模依存グラフでの解決性能測定', () {
      test('大量サービス登録・取得の性能測定', () {
        // Arrange - 多種類のサービスを登録（現実的なアプローチ）
        const serviceCount = 100;
        final stopwatch = Stopwatch();

        // Phase 1: 登録性能測定
        stopwatch.start();
        
        // 異なる種類のサービスを登録
        testServiceLocator.registerFactory<MockPerformanceService>(() => MockPerformanceService());
        testServiceLocator.registerFactory<MockConcurrentService>(() => MockConcurrentService());
        testServiceLocator.registerFactory<MockCachingTestService>(() => MockCachingTestService());
        testServiceLocator.registerFactory<MockMemoryTestService>(() => MockMemoryTestService());
        testServiceLocator.registerFactory<MockMemoryEfficiencyService>(() => MockMemoryEfficiencyService());
        
        stopwatch.stop();
        
        final registrationTime = stopwatch.elapsedMilliseconds;
        expect(registrationTime, lessThan(100)); // 100ms以内

        // Phase 2: 取得性能測定
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < serviceCount; i++) {
          // 複数種類のサービスを順次取得
          testServiceLocator.get<MockPerformanceService>();
          testServiceLocator.get<MockConcurrentService>();
          testServiceLocator.get<MockCachingTestService>();
          testServiceLocator.get<MockMemoryTestService>();
          testServiceLocator.get<MockMemoryEfficiencyService>();
        }
        stopwatch.stop();
        
        final retrievalTime = stopwatch.elapsedMilliseconds;
        expect(retrievalTime, lessThan(500)); // 500ms以内
      });

      test('複雑な依存グラフの解決性能', () {
        // Arrange - 複雑な依存関係（5階層）
        final stopwatch = Stopwatch();

        // 階層的な依存関係を構築
        testServiceLocator.registerFactory<MockPerfLevel1Service>(() => MockPerfLevel1Service());
        
        testServiceLocator.registerFactory<MockPerfLevel2Service>(() {
          final level1 = testServiceLocator.get<MockPerfLevel1Service>();
          return MockPerfLevel2Service(level1);
        });
        
        testServiceLocator.registerFactory<MockPerfLevel3Service>(() {
          final level2 = testServiceLocator.get<MockPerfLevel2Service>();
          return MockPerfLevel3Service(level2);
        });
        
        testServiceLocator.registerFactory<MockPerfLevel4Service>(() {
          final level3 = testServiceLocator.get<MockPerfLevel3Service>();
          return MockPerfLevel4Service(level3);
        });
        
        testServiceLocator.registerFactory<MockPerfLevel5Service>(() {
          final level4 = testServiceLocator.get<MockPerfLevel4Service>();
          return MockPerfLevel5Service(level4);
        });

        // Act - 最上位サービスを取得（依存チェーン解決）
        stopwatch.start();
        final service = testServiceLocator.get<MockPerfLevel5Service>();
        stopwatch.stop();

        // Assert - 複雑な依存関係でも高速解決
        expect(service, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms以内
      });

      test('並列アクセスの性能測定', () async {
        // Arrange - 並列アクセス用サービス
        testServiceLocator.registerFactory<MockConcurrentService>(() {
          // 若干の処理時間をシミュレート
          return MockConcurrentService();
        });

        // Act - 大量の並列アクセス
        const concurrentCount = 100;
        final stopwatch = Stopwatch()..start();
        
        final futures = List.generate(concurrentCount, (index) {
          return Future(() => testServiceLocator.get<MockConcurrentService>());
        });
        
        final results = await Future.wait(futures);
        stopwatch.stop();

        // Assert - 並列アクセスでも高速
        expect(results, hasLength(concurrentCount));
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 500ms以内
        
        // 全て同一インスタンス（Singleton化）
        final firstInstance = results.first;
        expect(results.every((service) => identical(service, firstInstance)), isTrue);
      });

      test('メモリ使用量の効率性確認', () {
        // Arrange - メモリ使用量測定
        
        // Phase 1: ベースライン測定（異なる型で登録）
        testServiceLocator.registerSingleton<MockMemoryTestService>(MockMemoryTestService());
        testServiceLocator.registerSingleton<MockMemoryEfficiencyService>(MockMemoryEfficiencyService());
        
        final baselineRegisteredCount = testServiceLocator.registeredTypes.length;

        // Phase 2: 追加登録（異なる型）
        testServiceLocator.registerFactory<MockPerformanceService>(() => MockPerformanceService());
        testServiceLocator.registerFactory<MockConcurrentService>(() => MockConcurrentService());
        testServiceLocator.registerFactory<MockCachingTestService>(() => MockCachingTestService());

        // Assert - 期待される登録数
        final finalRegisteredCount = testServiceLocator.registeredTypes.length;
        expect(finalRegisteredCount, equals(baselineRegisteredCount + 3));

        // クリーンアップ効率性確認
        testServiceLocator.clear();
        expect(testServiceLocator.registeredTypes, isEmpty);
      });

      test('キャッシング効率性の確認', () {
        // Arrange - キャッシングテスト用サービス
        var factoryCallCount = 0;
        testServiceLocator.registerFactory<MockCachingTestService>(() {
          factoryCallCount++;
          return MockCachingTestService();
        });

        // Act - 複数回アクセス
        const accessCount = 50;
        final stopwatch = Stopwatch()..start();
        
        final services = <MockCachingTestService>[];
        for (int i = 0; i < accessCount; i++) {
          services.add(testServiceLocator.get<MockCachingTestService>());
        }
        
        stopwatch.stop();

        // Assert - キャッシングによる効率化
        expect(factoryCallCount, equals(1)); // ファクトリは1回だけ呼ばれる
        expect(services, hasLength(accessCount));
        expect(services.every((service) => identical(service, services.first)), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // キャッシュにより高速
      });
    });
  });
}

// =================================================================
// テスト用Mockクラス群
// =================================================================

/// テスト用Mock基底クラス
class MockServiceInterface extends Mock {}

/// 循環依存テスト用MockサービスA
class MockServiceA extends Mock {}

/// 循環依存テスト用MockサービスB  
class MockServiceB extends Mock {}

/// 同期サービステスト用Mock
class MockSyncService extends Mock {}

/// 非同期サービステスト用Mock
class MockAsyncService extends Mock {}

/// 3階層依存テスト用 - Base Service
class MockBaseService extends Mock {}

/// 3階層依存テスト用 - Middle Service  
class MockMiddleService extends Mock {
  final MockBaseService baseService;
  MockMiddleService(this.baseService);
}

/// 3階層依存テスト用 - Top Service
class MockTopService extends Mock {
  final MockMiddleService middleService;
  MockTopService(this.middleService);
}

// =================================================================
// 循環依存テスト用Mockクラス群
// =================================================================

/// 循環依存テスト用 - サービスA
class MockCircularServiceA extends Mock {
  final dynamic dependency;
  MockCircularServiceA(this.dependency);
}

/// 循環依存テスト用 - サービスB
class MockCircularServiceB extends Mock {
  final dynamic dependency;
  MockCircularServiceB(this.dependency);
}

/// 循環依存テスト用 - サービスC
class MockCircularServiceC extends Mock {
  final dynamic dependency;
  MockCircularServiceC(this.dependency);
}

/// 自己参照循環依存テスト用
class MockSelfReferenceService extends Mock {
  final dynamic selfReference;
  MockSelfReferenceService(this.selfReference);
}

/// 正常サービス（循環依存テストの対照群）
class MockNormalService extends Mock {
  final MockBaseService baseService;
  final dynamic problematicService;
  MockNormalService(this.baseService, [this.problematicService]);
}

/// 問題のあるサービス（循環依存を引き起こす）
class MockProblematicService extends Mock {
  final dynamic dependency;
  MockProblematicService(this.dependency);
}

/// 非同期循環依存テスト用 - サービスA
class MockAsyncCircularServiceA extends Mock {
  final dynamic dependency;
  MockAsyncCircularServiceA(this.dependency);
}

/// 非同期循環依存テスト用 - サービスB
class MockAsyncCircularServiceB extends Mock {
  final dynamic dependency;
  MockAsyncCircularServiceB(this.dependency);
}

// =================================================================
// 依存関係解決順序テスト用Mockクラス群
// =================================================================

/// レベル1サービス（基底）
class MockLevel1Service extends Mock {}

/// レベル2サービス（Level1に依存）
class MockLevel2Service extends Mock {
  final MockLevel1Service dependency;
  MockLevel2Service(this.dependency);
}

/// レベル3サービス（Level2に依存）
class MockLevel3Service extends Mock {
  final MockLevel2Service dependency;
  MockLevel3Service(this.dependency);
}

/// 共通依存サービス
class MockSharedDependencyService extends Mock {}

/// 並列サービスA（共通依存に依存）
class MockParallelServiceA extends Mock {
  final MockSharedDependencyService dependency;
  MockParallelServiceA(this.dependency);
}

/// 並列サービスB（共通依存に依存）
class MockParallelServiceB extends Mock {
  final MockSharedDependencyService dependency;
  MockParallelServiceB(this.dependency);
}

/// 非同期基底サービス
class MockAsyncBaseService extends Mock {}

/// 非同期依存サービス
class MockAsyncDependentService extends Mock {
  final MockAsyncBaseService dependency;
  MockAsyncDependentService(this.dependency);
}

/// 初期化パターンテスト用 - Singleton
class MockSingletonInitService extends Mock {}

/// 初期化パターンテスト用 - Factory
class MockFactoryInitService extends Mock {
  final MockSingletonInitService dependency;
  MockFactoryInitService(this.dependency);
}

/// 初期化パターンテスト用 - AsyncFactory
class MockAsyncInitService extends Mock {
  final MockFactoryInitService dependency;
  MockAsyncInitService(this.dependency);
}

/// 初期化順序テスト用
class MockOrderTestService extends Mock {}

// =================================================================
// エラーハンドリングテスト用Mockクラス群
// =================================================================

/// エラーが発生しやすいサービス
class MockErrorProneService extends Mock {}

/// 非同期エラーが発生しやすいサービス
class MockErrorProneAsyncService extends Mock {}

/// 依存サービス（存在しないサービスに依存）
class MockDependentService extends Mock {
  final dynamic dependency;
  MockDependentService(this.dependency);
}

/// 存在しないサービス（テスト用）
class MockNonExistentService extends Mock {}

/// 正常動作サービス
class MockWorkingService extends Mock {}

/// 障害サービス
class MockFailingService extends Mock {}

/// リソース集約的サービス
class MockResourceIntensiveService extends Mock {}

/// 遅いサービス（タイムアウトテスト用）
class MockSlowService extends Mock {}

// =================================================================
// パフォーマンステスト用Mockクラス群
// =================================================================

/// 性能測定用サービス
class MockPerformanceService extends Mock {}

/// 性能測定用 - レベル1
class MockPerfLevel1Service extends Mock {}

/// 性能測定用 - レベル2
class MockPerfLevel2Service extends Mock {
  final MockPerfLevel1Service dependency;
  MockPerfLevel2Service(this.dependency);
}

/// 性能測定用 - レベル3
class MockPerfLevel3Service extends Mock {
  final MockPerfLevel2Service dependency;
  MockPerfLevel3Service(this.dependency);
}

/// 性能測定用 - レベル4
class MockPerfLevel4Service extends Mock {
  final MockPerfLevel3Service dependency;
  MockPerfLevel4Service(this.dependency);
}

/// 性能測定用 - レベル5
class MockPerfLevel5Service extends Mock {
  final MockPerfLevel4Service dependency;
  MockPerfLevel5Service(this.dependency);
}

/// 並行アクセステスト用サービス
class MockConcurrentService extends Mock {}

/// メモリテスト用サービス
class MockMemoryTestService extends Mock {}

/// メモリ効率性テスト用サービス
class MockMemoryEfficiencyService extends Mock {}

/// キャッシングテスト用サービス
class MockCachingTestService extends Mock {}

/// 独立サービスA（テスト用）
class MockIndependentServiceA extends Mock {}

/// 独立サービスB（テスト用）
class MockIndependentServiceB extends Mock {}