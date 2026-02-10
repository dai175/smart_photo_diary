import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
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
    serviceLocator.registerSingleton<IPhotoService>(
      TestServiceSetup.getPhotoService(),
    );
    serviceLocator.registerSingleton<IAiService>(
      TestServiceSetup.getAiService(),
    );
    serviceLocator.registerSingleton<IDiaryService>(
      TestServiceSetup.getDiaryService(),
    );
    serviceLocator.registerSingleton<ISettingsService>(
      TestServiceSetup.getSettingsService(),
    );
    serviceLocator.registerSingleton<IStorageService>(
      TestServiceSetup.getStorageService(),
    );

    return serviceLocator;
  }

  /// Setup global ServiceRegistration with mocks for widgets that use ServiceRegistration.get<T>()
  static void setupGlobalServiceRegistration() {
    // Clear any existing ServiceLocator
    final globalServiceLocator = ServiceLocator();
    globalServiceLocator.clear();

    // Register mock services globally
    globalServiceLocator.registerSingleton<IPhotoService>(
      TestServiceSetup.getPhotoService(),
    );
    globalServiceLocator.registerSingleton<IAiService>(
      TestServiceSetup.getAiService(),
    );
    globalServiceLocator.registerSingleton<IDiaryService>(
      TestServiceSetup.getDiaryService(),
    );
    globalServiceLocator.registerSingleton<ISettingsService>(
      TestServiceSetup.getSettingsService(),
    );
    globalServiceLocator.registerSingleton<IStorageService>(
      TestServiceSetup.getStorageService(),
    );
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
