import '../services/ai_service.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/logging_service.dart';
import '../services/diary_service.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/photo_service.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/photo_cache_service.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/photo_access_control_service.dart';
import '../services/interfaces/photo_access_control_service_interface.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/subscription_service.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/prompt_service.dart';
import 'service_locator.dart';

/// Service registration configuration
///
/// This class handles the registration of all services in the ServiceLocator.
/// It provides a centralized place to configure dependency injection.
///
/// ## Service Initialization Order and Dependencies
///
/// ### Phase 1: Core Services (No Dependencies)
/// 1. **LoggingService** - 基盤ログ機能（他サービスの依存基盤）
/// 2. **PhotoService** - 写真アクセス機能（LoggingServiceに依存）
/// 3. **PhotoCacheService** - 写真キャッシュ機能（LoggingServiceに依存）
/// 4. **PhotoAccessControlService** - 写真アクセス制御
/// 5. **SettingsService** - アプリ設定管理（SubscriptionServiceに依存）
/// 6. **StorageService** - ストレージ操作
/// 7. **SubscriptionService** - サブスクリプション管理（Hive依存のみ）
/// 8. **PromptService** - ライティングプロンプト管理（JSONアセット読み込み）
///
/// ### Phase 2: Dependent Services
/// 1. **AiService** - AI日記生成（SubscriptionServiceに依存）
/// 2. **DiaryService** - 日記管理（AiService, PhotoServiceに依存）
///
/// ## 依存関係マップ
/// - LoggingService → なし（基盤サービス）
/// - PhotoService → LoggingService
/// - PhotoCacheService → LoggingService
/// - SettingsService → SubscriptionService
/// - SubscriptionService → LoggingService
/// - AiService → SubscriptionService
/// - DiaryService → AiService + PhotoService + LoggingService
/// - StorageService → DiaryService（DatabaseOptimization用）
///
/// **循環依存**: なし（全て単方向の依存関係）
class ServiceRegistration {
  static bool _isInitialized = false;
  static LoggingService get _logger => serviceLocator.get<LoggingService>();

  /// Initialize and register all services
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.debug('サービス既に初期化済み', context: 'ServiceRegistration.initialize');
      return;
    }

    try {
      // Register core services that don't have dependencies
      await _registerCoreServices();

      // Register services with dependencies
      await _registerDependentServices();

      _isInitialized = true;
      _logger.info('サービス初期化完了', context: 'ServiceRegistration.initialize');

      // Debug print all registered services
      serviceLocator.debugPrintServices();
    } catch (e) {
      // LoggingService may not be available if initialization failed
      if (_isInitialized) {
        _logger.error(
          'サービス初期化エラー',
          context: 'ServiceRegistration.initialize',
          error: e,
        );
      }
      rethrow;
    }
  }

  /// Register services that don't have dependencies
  static Future<void> _registerCoreServices() async {
    // 1. LoggingService (基盤サービス - 他のサービスの依存関係として使用)
    final loggingService = await LoggingService.getInstance();
    serviceLocator.registerSingleton<LoggingService>(loggingService);

    _logger.debug(
      'コアサービス登録開始',
      context: 'ServiceRegistration._registerCoreServices',
    );

    // 2. SubscriptionService (Hive依存のみ、LoggingServiceに後で依存)
    serviceLocator.registerAsyncFactory<ISubscriptionService>(
      () => SubscriptionService.getInstance(),
    );

    // 3. SettingsService (SubscriptionServiceに依存)
    serviceLocator.registerAsyncFactory<SettingsService>(
      () => SettingsService.getInstance(),
    );

    // 4. PhotoService (LoggingServiceに依存)
    serviceLocator.registerFactory<IPhotoService>(
      () => PhotoService.getInstance(),
    );

    // 5. PhotoCacheService (LoggingServiceに依存)
    serviceLocator.registerFactory<IPhotoCacheService>(
      () => PhotoCacheService.getInstance(),
    );

    // 6. PhotoAccessControlService (依存なし)
    serviceLocator.registerFactory<IPhotoAccessControlService>(
      () => PhotoAccessControlService.getInstance(),
    );

    // 7. StorageService (DiaryServiceに依存するが、最適化機能のみ)
    serviceLocator.registerFactory<IStorageService>(
      () => StorageService.getInstance(),
    );

    // 8. PromptService (JSONアセット読み込み - 依存なし)
    serviceLocator.registerAsyncFactory<IPromptService>(() async {
      final service = PromptService.instance;
      await service.initialize();
      return service;
    });
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
