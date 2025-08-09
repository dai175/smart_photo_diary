import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_access_control_service_interface.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/import_result.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/core/result/result.dart';

/// Mock PhotoService for integration testing
class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}

/// Mock AiService for integration testing
class MockAiServiceInterface extends Mock implements AiServiceInterface {}

/// Mock DiaryService for integration testing
class MockDiaryServiceInterface extends Mock implements DiaryServiceInterface {}

/// Mock SubscriptionService for integration testing
class MockSubscriptionServiceInterface extends Mock
    implements ISubscriptionService {}

/// Mock PhotoAccessControlService for integration testing
class MockPhotoAccessControlServiceInterface extends Mock
    implements PhotoAccessControlServiceInterface {}

/// Mock SettingsService for integration testing
class MockSettingsService extends Mock implements SettingsService {}

/// Mock StorageService for integration testing
class MockStorageService extends Mock implements StorageService {}

/// Mock AssetEntity for integration testing
class MockAssetEntity extends Mock implements AssetEntity {}

/// Mock AssetPathEntity for integration testing
class MockAssetPathEntity extends Mock implements AssetPathEntity {}

/// Mock classes for other dependencies can be added here as needed
class MockConnectivity extends Mock {}

class MockImageClassifier extends Mock {}

/// Central service mock setup for consistent testing
class TestServiceSetup {
  static MockPhotoServiceInterface? _mockPhotoService;
  static MockAiServiceInterface? _mockAiService;
  static MockDiaryServiceInterface? _mockDiaryService;
  static MockSubscriptionServiceInterface? _mockSubscriptionService;
  static MockSettingsService? _mockSettingsService;
  static MockStorageService? _mockStorageService;

  /// Get or create mock PhotoService with default behavior
  static MockPhotoServiceInterface getPhotoService() {
    return _mockPhotoService ??= _createPhotoServiceMock();
  }

  /// Get or create mock AiService with default behavior
  static MockAiServiceInterface getAiService() {
    return _mockAiService ??= _createAiServiceMock();
  }

  /// Get or create mock DiaryService with default behavior
  static MockDiaryServiceInterface getDiaryService() {
    return _mockDiaryService ??= _createDiaryServiceMock();
  }

  /// Get or create mock SubscriptionService with default behavior
  static MockSubscriptionServiceInterface getSubscriptionService() {
    return _mockSubscriptionService ??= _createSubscriptionServiceMock();
  }

  /// Get or create mock SettingsService with default behavior
  static MockSettingsService getSettingsService() {
    return _mockSettingsService ??= _createSettingsServiceMock();
  }

  /// Get or create mock StorageService with default behavior
  static MockStorageService getStorageService() {
    return _mockStorageService ??= _createStorageServiceMock();
  }

  /// Clear all mock instances (for test isolation)
  static void clearAllMocks() {
    _mockPhotoService = null;
    _mockAiService = null;
    _mockDiaryService = null;
    _mockSubscriptionService = null;
    _mockSettingsService = null;
    _mockStorageService = null;
  }

  /// Set up all services with default mock behavior
  static void setupAllServices() {
    registerMockFallbacks();
    getPhotoService();
    getAiService();
    getDiaryService();
    getSubscriptionService();
    getSettingsService();
    getStorageService();
  }

  // Private factory methods with default mock behavior
  static MockPhotoServiceInterface _createPhotoServiceMock() {
    final mock = MockPhotoServiceInterface();

    // Default mock behavior for PhotoService
    when(() => mock.requestPermission()).thenAnswer((_) async => true);
    when(
      () => mock.getTodayPhotos(limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mock.getPhotosInDateRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mock.getThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
      ),
    ).thenAnswer((_) async => null); // Return null to avoid invalid image data
    when(
      () => mock.getPhotoData(any()),
    ).thenAnswer((_) async => [1, 2, 3, 4, 5]); // Mock image data
    when(
      () => mock.getThumbnailData(any()),
    ).thenAnswer((_) async => [1, 2, 3]); // Mock thumbnail data
    when(
      () => mock.getOriginalFile(any()),
    ).thenAnswer((_) async => 'mock_file_path');
    when(
      () => mock.getOriginalFileResult(any()),
    ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3, 4, 5])));

    return mock;
  }

  static MockAiServiceInterface _createAiServiceMock() {
    final mock = MockAiServiceInterface();

    // Default mock behavior for AiService
    when(() => mock.isOnline()).thenAnswer((_) async => true);

    when(
      () => mock.generateDiaryFromImage(
        imageData: any(named: 'imageData'),
        date: any(named: 'date'),
        location: any(named: 'location'),
        photoTimes: any(named: 'photoTimes'),
      ),
    ).thenAnswer(
      (_) async => Success(
        DiaryGenerationResult(
          title: 'Mock Image Diary',
          content: 'Mock content from image analysis.',
        ),
      ),
    );

    when(
      () => mock.generateDiaryFromMultipleImages(
        imagesWithTimes: any(named: 'imagesWithTimes'),
        location: any(named: 'location'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(
      (_) async => Success(
        DiaryGenerationResult(
          title: 'Mock Multi-Image Diary',
          content: 'Mock content from multiple images.',
        ),
      ),
    );

    when(
      () => mock.generateTagsFromContent(
        title: any(named: 'title'),
        content: any(named: 'content'),
        date: any(named: 'date'),
        photoCount: any(named: 'photoCount'),
      ),
    ).thenAnswer((_) async => Success(['mock', 'test', 'generated']));

    return mock;
  }

  static MockDiaryServiceInterface _createDiaryServiceMock() {
    final mock = MockDiaryServiceInterface();

    // Default mock behavior for DiaryService (Result<T> pattern)
    when(
      () => mock.getSortedDiaryEntries(),
    ).thenAnswer((_) async => const Success(<DiaryEntry>[]));
    when(
      () => mock.getDiaryEntry(any()),
    ).thenAnswer((_) async => const Success<DiaryEntry?>(null));
    when(
      () => mock.getTotalDiaryCount(),
    ).thenAnswer((_) async => const Success(0));
    when(
      () => mock.getAllTags(),
    ).thenAnswer((_) async => const Success({'mock', 'test', 'tags'}));
    when(
      () => mock.getDiaryCountInPeriod(any(), any()),
    ).thenAnswer((_) async => const Success(0));
    when(
      () => mock.getFilteredDiaryEntries(any()),
    ).thenAnswer((_) async => const Success(<DiaryEntry>[]));
    when(
      () => mock.getTagsForEntry(any()),
    ).thenAnswer((_) async => const Success(['mock', 'test']));
    when(
      () => mock.saveDiaryEntry(
        date: any(named: 'date'),
        title: any(named: 'title'),
        content: any(named: 'content'),
        photoIds: any(named: 'photoIds'),
        location: any(named: 'location'),
        tags: any(named: 'tags'),
      ),
    ).thenAnswer(
      (_) async => Success(
        DiaryEntry(
          id: 'mock-id',
          date: DateTime.now(),
          title: 'Mock Title',
          content: 'Mock Content',
          photoIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
    when(() => mock.updateDiaryEntry(any())).thenAnswer(
      (_) async => Success(
        DiaryEntry(
          id: 'mock-updated-id',
          date: DateTime.now(),
          title: 'Updated Mock Title',
          content: 'Updated Mock Content',
          photoIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
    when(
      () => mock.deleteDiaryEntry(any()),
    ).thenAnswer((_) async => const Success(null));

    // Additional DiaryServiceInterface methods
    when(
      () => mock.saveDiaryEntryWithPhotos(
        date: any(named: 'date'),
        title: any(named: 'title'),
        content: any(named: 'content'),
        photos: any(named: 'photos'),
      ),
    ).thenAnswer(
      (_) async => Success(
        DiaryEntry(
          id: 'mock-photo-entry-id',
          date: DateTime.now(),
          title: 'Mock Photo Entry',
          content: 'Mock Photo Content',
          photoIds: ['photo1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );

    when(
      () => mock.createDiaryForPastPhoto(
        photoDate: any(named: 'photoDate'),
        title: any(named: 'title'),
        content: any(named: 'content'),
        photoIds: any(named: 'photoIds'),
        location: any(named: 'location'),
        tags: any(named: 'tags'),
      ),
    ).thenAnswer(
      (_) async => Success(
        DiaryEntry(
          id: 'mock-past-photo-id',
          date: DateTime.now(),
          title: 'Past Photo Mock Title',
          content: 'Past Photo Mock Content',
          photoIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );

    when(
      () => mock.getDiaryByPhotoDate(any()),
    ).thenAnswer((_) async => const Success(<DiaryEntry>[]));

    when(
      () => mock.searchDiaries(
        query: any(named: 'query'),
        tags: any(named: 'tags'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Success(<DiaryEntry>[]));

    when(
      () => mock.exportDiaries(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Success('Mock export data'));

    when(() => mock.importDiaries()).thenAnswer(
      (_) async => Success(
        ImportResult(
          totalEntries: 0,
          successfulImports: 0,
          skippedEntries: 0,
          failedImports: 0,
          errors: [],
          warnings: [],
        ),
      ),
    );

    return mock;
  }

  static MockSubscriptionServiceInterface _createSubscriptionServiceMock() {
    final mock = MockSubscriptionServiceInterface();

    // Default mock behavior for SubscriptionService
    when(() => mock.isInitialized).thenReturn(true);
    when(() => mock.initialize()).thenAnswer((_) async => const Success(null));

    // Basic Plan default setup
    final basicPlan = BasicPlan();
    when(
      () => mock.getCurrentPlanClass(),
    ).thenAnswer((_) async => Success(basicPlan));

    when(() => mock.getCurrentStatus()).thenAnswer(
      (_) async => Success(
        SubscriptionStatus(
          planId: basicPlan.id,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          autoRenewal: false,
          transactionId: null,
          lastPurchaseDate: null,
        ),
      ),
    );

    // AI usage defaults
    when(
      () => mock.canUseAiGeneration(),
    ).thenAnswer((_) async => const Success(true));
    when(
      () => mock.getRemainingGenerations(),
    ).thenAnswer((_) async => Success(basicPlan.monthlyAiGenerationLimit));
    when(
      () => mock.getMonthlyUsage(),
    ).thenAnswer((_) async => const Success(0));
    when(
      () => mock.incrementAiUsage(),
    ).thenAnswer((_) async => const Success(null));

    // Access permissions defaults (Basic plan)
    when(
      () => mock.canAccessPremiumFeatures(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => mock.canAccessWritingPrompts(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => mock.canAccessAdvancedFilters(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => mock.canAccessAdvancedAnalytics(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => mock.canAccessPrioritySupport(),
    ).thenAnswer((_) async => const Success(false));

    // Date-related defaults
    when(() => mock.getNextResetDate()).thenAnswer(
      (_) async => Success(DateTime.now().add(const Duration(days: 30))),
    );

    // Purchase-related defaults
    // when(() => mock.restorePurchases()).thenAnswer((_) async => const Success(<PurchaseResult>[])); // コメントアウト - 必要に応じて有効化

    return mock;
  }

  static MockSettingsService _createSettingsServiceMock() {
    final mock = MockSettingsService();

    // Default mock behavior for SettingsService
    // Note: Basic setup, tests should specify their own behavior
    // Most settings services have getBool, getString, getInt, set methods
    // We'll set up basic fallbacks here

    return mock;
  }

  static MockStorageService _createStorageServiceMock() {
    final mock = MockStorageService();

    // Default mock behavior for StorageService
    // Note: Basic setup, tests should specify their own behavior
    // We'll set up basic fallbacks here

    return mock;
  }

  // ========================================
  // Plan Class Helper Methods
  // ========================================

  /// Configure SubscriptionService mock for specific Plan
  static void configureSubscriptionServiceForPlan(
    MockSubscriptionServiceInterface mock,
    Plan plan, {
    int usageCount = 0,
    bool isActive = true,
  }) {
    when(
      () => mock.getCurrentPlanClass(),
    ).thenAnswer((_) async => Success(plan));

    when(() => mock.getCurrentStatus()).thenAnswer(
      (_) async => Success(
        SubscriptionStatus(
          planId: plan.id,
          isActive: isActive,
          startDate: DateTime.now(),
          expiryDate: plan.isPremium
              ? DateTime.now().add(const Duration(days: 365))
              : null,
          monthlyUsageCount: usageCount,
          lastResetDate: DateTime.now(),
          autoRenewal: plan.isPremium,
          transactionId: plan.isPremium ? 'integration-test-transaction' : null,
          lastPurchaseDate: plan.isPremium ? DateTime.now() : null,
        ),
      ),
    );

    // AI usage based on plan limits and current usage
    final canUseAi = usageCount < plan.monthlyAiGenerationLimit;
    final remaining = plan.monthlyAiGenerationLimit - usageCount;

    when(
      () => mock.canUseAiGeneration(),
    ).thenAnswer((_) async => Success(canUseAi));
    when(
      () => mock.getRemainingGenerations(),
    ).thenAnswer((_) async => Success(remaining));
    when(
      () => mock.getMonthlyUsage(),
    ).thenAnswer((_) async => Success(usageCount));

    // Access permissions based on plan features
    when(
      () => mock.canAccessPremiumFeatures(),
    ).thenAnswer((_) async => Success(plan.isPremium));
    when(
      () => mock.canAccessWritingPrompts(),
    ).thenAnswer((_) async => Success(plan.hasWritingPrompts));
    when(
      () => mock.canAccessAdvancedFilters(),
    ).thenAnswer((_) async => Success(plan.hasAdvancedFilters));
    when(
      () => mock.canAccessAdvancedAnalytics(),
    ).thenAnswer((_) async => Success(plan.hasAdvancedAnalytics));
    when(
      () => mock.canAccessPrioritySupport(),
    ).thenAnswer((_) async => Success(plan.hasPrioritySupport));
  }

  /// Get SubscriptionService mock configured for Basic plan
  static MockSubscriptionServiceInterface getBasicPlanSubscriptionService({
    int usageCount = 0,
  }) {
    final mock = MockSubscriptionServiceInterface();
    when(() => mock.isInitialized).thenReturn(true);
    when(() => mock.initialize()).thenAnswer((_) async => const Success(null));

    configureSubscriptionServiceForPlan(
      mock,
      BasicPlan(),
      usageCount: usageCount,
    );
    return mock;
  }

  /// Get SubscriptionService mock configured for Premium plan
  static MockSubscriptionServiceInterface getPremiumPlanSubscriptionService({
    bool isYearly = true,
    int usageCount = 0,
  }) {
    final mock = MockSubscriptionServiceInterface();
    when(() => mock.isInitialized).thenReturn(true);
    when(() => mock.initialize()).thenAnswer((_) async => const Success(null));

    final plan = isYearly ? PremiumYearlyPlan() : PremiumMonthlyPlan();
    configureSubscriptionServiceForPlan(mock, plan, usageCount: usageCount);
    return mock;
  }
}

/// Helper to register fallback values for mocktail
void registerMockFallbacks() {
  registerFallbackValue(DateTime.now());
  registerFallbackValue(MockAssetEntity());
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(<AssetEntity>[]);
  registerFallbackValue(<String>[]);
  registerFallbackValue(<DateTime>[]);
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(<({Uint8List imageData, DateTime time})>[]);
  registerFallbackValue(const DiaryFilter());
  registerFallbackValue(
    DiaryEntry(
      id: 'fallback-id',
      date: DateTime.now(),
      title: 'Fallback Title',
      content: 'Fallback Content',
      photoIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );
  registerFallbackValue(BasicPlan());
  registerFallbackValue(
    SubscriptionStatus(
      planId: 'basic',
      isActive: true,
      startDate: DateTime.now(),
      expiryDate: null,
      monthlyUsageCount: 0,
      lastResetDate: DateTime.now(),
      autoRenewal: false,
      transactionId: null,
      lastPurchaseDate: null,
    ),
  );
}
