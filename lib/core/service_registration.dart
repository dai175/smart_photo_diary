import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/ai/ai_service_interface.dart';
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
import '../services/logging_service.dart';
import 'service_locator.dart';

/// Service registration configuration
///
/// This class handles the registration of all services in the ServiceLocator.
/// It provides a centralized place to configure dependency injection.
///
/// ## Service Initialization Order
///
/// ### Phase 1: Core Services (No Dependencies)
/// 1. PhotoService - 写真アクセス機能
/// 2. SettingsService - アプリ設定管理
/// 3. StorageService - ストレージ操作
/// 4. AiService - AI日記生成
/// 5. SubscriptionService - サブスクリプション管理 ✅
///
/// ### Phase 2: Dependent Services
/// 1. DiaryService - 日記管理（AiService, PhotoServiceに依存）
///
/// ## Subscription Service Dependencies
/// - **直接依存**: Hive (データ永続化)
/// - **間接依存**: なし
/// - **登録場所**: Core Services (_registerCoreServices)
/// - **登録タイプ**: AsyncFactory (Hive初期化が必要)
class ServiceRegistration {
  static bool _isInitialized = false;

  /// Initialize and register all services
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('ServiceRegistration: Already initialized');
      return;
    }

    debugPrint('ServiceRegistration: Initializing services...');

    try {
      // Register core services that don't have dependencies
      await _registerCoreServices();

      // Register services with dependencies
      await _registerDependentServices();

      _isInitialized = true;
      debugPrint('ServiceRegistration: All services initialized successfully');

      // Debug print all registered services
      serviceLocator.debugPrintServices();
    } catch (e) {
      debugPrint('ServiceRegistration: Error during initialization: $e');
      rethrow;
    }
  }

  /// Register services that don't have dependencies
  static Future<void> _registerCoreServices() async {
    debugPrint('ServiceRegistration: Registering core services...');

    // LoggingService (基盤サービス - 他のサービスの依存関係として使用)
    serviceLocator.registerAsyncFactory<LoggingService>(
      () => LoggingService.getInstance(),
    );

    // PhotoService (singleton pattern)
    serviceLocator.registerFactory<PhotoServiceInterface>(
      () => PhotoService.getInstance(),
    );

    // PhotoCacheService (singleton pattern)
    serviceLocator.registerFactory<PhotoCacheServiceInterface>(
      () => PhotoCacheService.getInstance(),
    );

    // PhotoAccessControlService (singleton pattern)
    serviceLocator.registerFactory<PhotoAccessControlServiceInterface>(
      () => PhotoAccessControlService.getInstance(),
    );

    // SettingsService (async initialization)
    serviceLocator.registerAsyncFactory<SettingsService>(
      () => SettingsService.getInstance(),
    );

    // StorageService (singleton pattern)
    serviceLocator.registerFactory<StorageServiceInterface>(
      () => StorageService.getInstance(),
    );

    // SubscriptionService (Hive依存のみ - コアサービス)
    serviceLocator.registerAsyncFactory<ISubscriptionService>(
      () => SubscriptionService.getInstance(),
    );

    // PromptService (JSONアセット読み込み - コアサービス)
    serviceLocator.registerAsyncFactory<IPromptService>(() async {
      final service = PromptService.instance;
      await service.initialize();
      return service;
    });
  }

  /// Register services that have dependencies on other services
  static Future<void> _registerDependentServices() async {
    debugPrint('ServiceRegistration: Registering dependent services...');

    // Phase 1.7.1.1: AiService with SubscriptionService dependency injection
    serviceLocator.registerAsyncFactory<AiServiceInterface>(() async {
      // Get SubscriptionService dependency
      final subscriptionService = await serviceLocator
          .getAsync<ISubscriptionService>();

      // Create AiService with dependency injection
      return AiService(subscriptionService: subscriptionService);
    });

    // DiaryService (depends on AiService and PhotoService)
    serviceLocator.registerAsyncFactory<DiaryServiceInterface>(() async {
      // Get dependencies
      final aiService = await serviceLocator.getAsync<AiServiceInterface>();
      final photoService = serviceLocator.get<PhotoServiceInterface>();

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
    debugPrint('ServiceRegistration: Resetting...');
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
