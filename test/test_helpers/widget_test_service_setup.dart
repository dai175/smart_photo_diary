import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/core/service_registration.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/image_classifier_service.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import '../integration/mocks/mock_services.dart';

/// Widget test specific service setup to avoid service registration errors
class WidgetTestServiceSetup {
  static bool _isInitialized = false;
  
  /// Initialize widget test environment
  static void initializeForWidgetTests() {
    if (_isInitialized) return;
    
    // Register all fallback values
    registerMockFallbacks();
    
    _isInitialized = true;
  }
  
  /// Setup service locator with mocks for a widget test
  static ServiceLocator setupServiceLocatorForWidget() {
    final serviceLocator = ServiceLocator();
    
    // Register all mock services
    serviceLocator.registerSingleton<PhotoServiceInterface>(TestServiceSetup.getPhotoService());
    serviceLocator.registerSingleton<AiServiceInterface>(TestServiceSetup.getAiService());
    serviceLocator.registerSingleton<DiaryServiceInterface>(TestServiceSetup.getDiaryService());
    serviceLocator.registerSingleton<ImageClassifierService>(TestServiceSetup.getImageClassifierService());
    serviceLocator.registerSingleton<SettingsService>(TestServiceSetup.getSettingsService());
    serviceLocator.registerSingleton<StorageService>(TestServiceSetup.getStorageService());
    
    return serviceLocator;
  }
  
  /// Setup global ServiceRegistration with mocks for widgets that use ServiceRegistration.get<T>()
  static void setupGlobalServiceRegistration() {
    // Clear any existing ServiceLocator
    final globalServiceLocator = ServiceLocator();
    globalServiceLocator.clear();
    
    // Register mock services globally
    globalServiceLocator.registerSingleton<PhotoServiceInterface>(TestServiceSetup.getPhotoService());
    globalServiceLocator.registerSingleton<AiServiceInterface>(TestServiceSetup.getAiService());
    globalServiceLocator.registerSingleton<DiaryServiceInterface>(TestServiceSetup.getDiaryService());
    globalServiceLocator.registerSingleton<ImageClassifierService>(TestServiceSetup.getImageClassifierService());
    globalServiceLocator.registerSingleton<SettingsService>(TestServiceSetup.getSettingsService());
    globalServiceLocator.registerSingleton<StorageService>(TestServiceSetup.getStorageService());
  }
  
  /// Quick setup for widget tests - call this in setUpAll
  static void setUpForWidgetGroup() {
    setUpAll(() {
      initializeForWidgetTests();
    });
  }
  
  /// Setup for individual widget tests - call this in setUp
  static void setUpForWidgetTest() {
    setUp(() {
      // Reset mocks for test isolation
      TestServiceSetup.clearAllMocks();
    });
  }
  
  /// Clean up widget test environment
  static void tearDownWidgetGroup() {
    tearDownAll(() {
      TestServiceSetup.clearAllMocks();
      _isInitialized = false;
    });
  }
}