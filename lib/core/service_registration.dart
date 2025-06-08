import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/diary_service.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/photo_service.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/image_classifier_service.dart';
import 'service_locator.dart';

/// Service registration configuration
/// 
/// This class handles the registration of all services in the ServiceLocator.
/// It provides a centralized place to configure dependency injection.
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
    
    // PhotoService (singleton pattern)
    serviceLocator.registerFactory<PhotoServiceInterface>(
      () => PhotoService.getInstance()
    );
    
    // SettingsService (async initialization)
    serviceLocator.registerAsyncFactory<SettingsService>(
      () => SettingsService.getInstance()
    );
    
    // StorageService (singleton pattern)
    serviceLocator.registerFactory<StorageService>(
      () => StorageService.getInstance()
    );
    
    // ImageClassifierService (no dependencies)
    serviceLocator.registerFactory<ImageClassifierService>(
      () => ImageClassifierService()
    );
    
    // AiService (no dependencies for interface)
    serviceLocator.registerFactory<AiServiceInterface>(
      () => AiService()
    );
  }
  
  /// Register services that have dependencies on other services
  static Future<void> _registerDependentServices() async {
    debugPrint('ServiceRegistration: Registering dependent services...');
    
    // DiaryService (depends on AiService and PhotoService)
    serviceLocator.registerAsyncFactory<DiaryServiceInterface>(
      () async {
        // Get dependencies
        final aiService = serviceLocator.get<AiServiceInterface>();
        final photoService = serviceLocator.get<PhotoServiceInterface>();
        
        // Create DiaryService with dependency injection
        final diaryService = DiaryService.createWithDependencies(
          aiService: aiService,
          photoService: photoService,
        );
        
        // Initialize the service
        await diaryService.initialize();
        
        return diaryService;
      }
    );
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