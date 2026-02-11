import '../services/ai_service.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/logging_service.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/diary_service.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/photo_service.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/photo_cache_service.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/photo_access_control_service.dart';
import '../services/interfaces/photo_access_control_service_interface.dart';
import '../services/settings_service.dart';
import '../services/interfaces/settings_service_interface.dart';
import '../services/storage_service.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/subscription_service.dart';
import '../services/interfaces/subscription_state_service_interface.dart';
import '../services/subscription_state_service.dart';
import '../services/interfaces/ai_usage_service_interface.dart';
import '../services/ai_usage_service.dart';
import '../services/interfaces/feature_access_service_interface.dart';
import '../services/feature_access_service.dart';
import '../services/interfaces/in_app_purchase_service_interface.dart';
import '../services/in_app_purchase_service.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/prompt_service.dart';
import '../services/social_share_service.dart';
import '../services/interfaces/social_share_service_interface.dart';
import '../services/diary_image_generator.dart';
import 'service_locator.dart';

/// Service registration configuration
///
/// This class handles the registration of all services in the ServiceLocator.
/// It provides a centralized place to configure dependency injection.
///
/// ## Service Initialization Order and Dependencies
///
/// ### Phase 1: Core Services (Internal Dependencies)
/// 1. **LoggingService** - 基盤ログ機能（他サービスの依存基盤）
/// 2. **SubscriptionStateService** - サブスクリプション状態管理（Hive依存のみ）
/// 3. **AiUsageService** - AI使用量管理（SubscriptionStateServiceに依存）
/// 4. **FeatureAccessService** - 機能アクセス制御（SubscriptionStateServiceに依存）
/// 5. **InAppPurchaseService** - IAP処理（SubscriptionStateServiceに依存）
/// 6. **SubscriptionService** - Facade（上記4サービスに委譲）
/// 7. **PhotoService** - 写真アクセス機能（LoggingServiceに依存）
/// 8. **PhotoCacheService** - 写真キャッシュ機能（LoggingServiceに依存）
/// 9. **PhotoAccessControlService** - 写真アクセス制御
/// 10. **SettingsService** - アプリ設定管理（SubscriptionServiceに依存）
/// 11. **StorageService** - ストレージ操作
/// 12. **PromptService** - ライティングプロンプト管理（JSONアセット読み込み）
/// 13. **SocialShareService** - ソーシャル共有機能（LoggingServiceに依存）
///
/// ### Phase 2: Dependent Services
/// 1. **AiService** - AI日記生成（SubscriptionServiceに依存）
/// 2. **DiaryService** - 日記管理（AiService, PhotoServiceに依存）
///
/// ## 依存関係マップ
/// - LoggingService → なし（基盤サービス）
/// - SubscriptionStateService → LoggingService
/// - AiUsageService → SubscriptionStateService
/// - FeatureAccessService → SubscriptionStateService
/// - InAppPurchaseService → SubscriptionStateService
/// - SubscriptionService(Facade) → SubscriptionStateService + AiUsageService + FeatureAccessService + InAppPurchaseService
/// - PhotoService → LoggingService
/// - PhotoCacheService → LoggingService
/// - SettingsService → SubscriptionService
/// - AiService → SubscriptionService
/// - DiaryService → AiService + PhotoService + LoggingService
/// - StorageService → DiaryService（DatabaseOptimization用）
///
/// **循環依存**: なし（全て単方向の依存関係）
class ServiceRegistration {
  static bool _isInitialized = false;
  static ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// Initialize and register all services
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.debug('サービス既に初期化済み', context: 'ServiceRegistration.initialize');
      return;
    }

    final startTime = DateTime.now();
    try {
      // Register core services that don't have dependencies
      await _registerCoreServices();

      // LoggingService登録後にログ出力
      _logger.debug(
        'ServiceRegistration初期化開始',
        context: 'ServiceRegistration.initialize',
      );

      // Register services with dependencies
      await _registerDependentServices();

      _isInitialized = true;
      final duration = DateTime.now().difference(startTime);
      _logger.info(
        'サービス初期化完了',
        context: 'ServiceRegistration.initialize',
        data: '初期化時間: ${duration.inMilliseconds}ms',
      );

      // Debug print all registered services
      serviceLocator.debugPrintServices();
    } catch (e) {
      // LoggingServiceが登録済みの場合のみエラーログを出力
      try {
        _logger.error(
          'サービス初期化エラー',
          context: 'ServiceRegistration.initialize',
          error: e,
        );
      } catch (_) {
        // LoggingService未登録の場合は無視
      }
      rethrow;
    }
  }

  /// Register services that don't have dependencies
  static Future<void> _registerCoreServices() async {
    // 1. LoggingService (基盤サービス - 他のサービスの依存関係として使用)
    final loggingService = LoggingService();
    serviceLocator.registerSingleton<ILoggingService>(loggingService);

    _logger.debug(
      'コアサービス登録開始',
      context: 'ServiceRegistration._registerCoreServices',
    );

    // 2. SubscriptionStateService (Hive依存のみ、基盤サブスクリプション状態管理)
    serviceLocator.registerAsyncFactory<ISubscriptionStateService>(() async {
      final service = SubscriptionStateService();
      await service.initialize();
      return service;
    });

    // 3. AiUsageService (SubscriptionStateServiceに依存)
    serviceLocator.registerAsyncFactory<IAiUsageService>(() async {
      final stateService = await serviceLocator
          .getAsync<ISubscriptionStateService>();
      return AiUsageService(stateService: stateService);
    });

    // 4. FeatureAccessService (SubscriptionStateServiceに依存)
    serviceLocator.registerAsyncFactory<IFeatureAccessService>(() async {
      final stateService = await serviceLocator
          .getAsync<ISubscriptionStateService>();
      return FeatureAccessService(stateService: stateService);
    });

    // 5. InAppPurchaseService (SubscriptionStateServiceに依存)
    serviceLocator.registerAsyncFactory<IInAppPurchaseService>(() async {
      final stateService = await serviceLocator
          .getAsync<ISubscriptionStateService>();
      final service = InAppPurchaseService(stateService: stateService);
      await service.initialize();
      return service;
    });

    // 6. SubscriptionService (Facade - 後方互換性のため)
    serviceLocator.registerAsyncFactory<ISubscriptionService>(() async {
      final stateService = await serviceLocator
          .getAsync<ISubscriptionStateService>();
      final usageService = await serviceLocator.getAsync<IAiUsageService>();
      final accessService = await serviceLocator
          .getAsync<IFeatureAccessService>();
      final purchaseService = await serviceLocator
          .getAsync<IInAppPurchaseService>();
      return SubscriptionService(
        stateService: stateService,
        usageService: usageService,
        accessService: accessService,
        purchaseService: purchaseService,
      );
    });

    // 7. SettingsService (SubscriptionServiceに依存)
    serviceLocator.registerAsyncFactory<ISettingsService>(() async {
      final service = SettingsService();
      await service.initialize();
      return service;
    });

    // 8. PhotoService (LoggingServiceに依存)
    serviceLocator.registerSingleton<IPhotoService>(
      PhotoService(logger: serviceLocator.get<ILoggingService>()),
    );

    // 9. PhotoCacheService (LoggingServiceに依存)
    serviceLocator.registerSingleton<IPhotoCacheService>(
      PhotoCacheService(logger: serviceLocator.get<ILoggingService>()),
    );

    // 10. PhotoAccessControlService (依存なし)
    serviceLocator.registerFactory<IPhotoAccessControlService>(
      () => PhotoAccessControlService(),
    );

    // 11. StorageService (DiaryServiceに依存するが、最適化機能のみ)
    serviceLocator.registerFactory<IStorageService>(() => StorageService());

    // 12. PromptService (JSONアセット読み込み - 依存なし)
    serviceLocator.registerAsyncFactory<IPromptService>(() async {
      final service = PromptService.instance;
      await service.initialize();
      return service;
    });

    // 13. SocialShareService (LoggingServiceに依存)
    serviceLocator.registerFactory<ISocialShareService>(
      () => SocialShareService(),
    );

    // 14. DiaryImageGenerator (ソーシャル共有用画像生成)
    serviceLocator.registerFactory<DiaryImageGenerator>(
      () => DiaryImageGenerator(),
    );

    // X共有はSocialShareService内のチャネルで対応（別登録不要）
  }

  /// Register services that have dependencies on other services
  static Future<void> _registerDependentServices() async {
    _logger.debug(
      '依存関係サービス登録開始',
      context: 'ServiceRegistration._registerDependentServices',
    );

    // Phase 1.7.1.1: AiService with SubscriptionService dependency injection
    serviceLocator.registerAsyncFactory<IAiService>(() async {
      // Get SubscriptionService dependency
      final subscriptionService = await serviceLocator
          .getAsync<ISubscriptionService>();

      // Create AiService with dependency injection
      return AiService(subscriptionService: subscriptionService);
    });

    // DiaryService (depends on AiService and PhotoService)
    serviceLocator.registerAsyncFactory<IDiaryService>(() async {
      // Get dependencies
      final aiService = await serviceLocator.getAsync<IAiService>();
      final photoService = serviceLocator.get<IPhotoService>();

      // Create DiaryService with dependency injection
      final diaryService = DiaryService.createWithDependencies(
        aiService: aiService,
        photoService: photoService,
      );

      // Initialize the service
      await diaryService.initialize();

      return diaryService;
    });
  }

  /// Reset service registration (useful for testing)
  static void reset() {
    if (_isInitialized) {
      _logger.info('サービス登録リセット', context: 'ServiceRegistration.reset');
    }
    serviceLocator.clear();
    _isInitialized = false;
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Get a service from the locator (convenience method)
  static T get<T>() => serviceLocator.get<T>();

  /// Get a service asynchronously from the locator (convenience method)
  static Future<T> getAsync<T>() => serviceLocator.getAsync<T>();
}
