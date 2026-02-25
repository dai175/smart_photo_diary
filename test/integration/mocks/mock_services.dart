import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_crud_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_query_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_access_control_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_tag_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_statistics_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/models/diary_change.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';

/// Mock PhotoService for integration testing
class MockIPhotoService extends Mock implements IPhotoService {}

/// Mock AiService for integration testing
class MockIAiService extends Mock implements IAiService {}

/// Mock DiaryService for integration testing
class MockIDiaryService extends Mock implements IDiaryService {}

/// Mock DiaryCrudService for integration testing
class MockIDiaryCrudService extends Mock implements IDiaryCrudService {}

/// Mock DiaryQueryService for integration testing
class MockIDiaryQueryService extends Mock implements IDiaryQueryService {}

/// Mock SubscriptionService for integration testing
class MockSubscriptionServiceInterface extends Mock
    implements ISubscriptionService {}

/// Mock PhotoAccessControlService for integration testing
class MockIPhotoAccessControlService extends Mock
    implements IPhotoAccessControlService {}

/// Mock SettingsService for integration testing
class MockSettingsService extends Mock implements ISettingsService {}

/// Mock StorageService for integration testing
class MockStorageService extends Mock implements IStorageService {}

/// Mock DiaryTagService for integration testing
class MockIDiaryTagService extends Mock implements IDiaryTagService {}

/// Mock DiaryStatisticsService for integration testing
class MockIDiaryStatisticsService extends Mock
    implements IDiaryStatisticsService {}

/// Mock LoggingService for integration testing
class MockILoggingService extends Mock implements ILoggingService {}

/// Mock AssetEntity for integration testing
class MockAssetEntity extends Mock implements AssetEntity {}

/// Mock AssetPathEntity for integration testing
class MockAssetPathEntity extends Mock implements AssetPathEntity {}

/// Mock classes for other dependencies can be added here as needed
class MockConnectivity extends Mock {}

class MockImageClassifier extends Mock {}

/// Central service mock setup for consistent testing
class TestServiceSetup {
  static MockILoggingService? _mockLoggingService;
  static MockIPhotoService? _mockPhotoService;
  static MockIAiService? _mockAiService;
  static MockIDiaryService? _mockDiaryService;
  static MockSubscriptionServiceInterface? _mockSubscriptionService;
  static MockSettingsService? _mockSettingsService;
  static MockStorageService? _mockStorageService;

  /// Get or create mock LoggingService with default behavior
  static MockILoggingService getLoggingService() {
    return _mockLoggingService ??= _createLoggingServiceMock();
  }

  /// Get or create mock PhotoService with default behavior
  static MockIPhotoService getPhotoService() {
    return _mockPhotoService ??= _createPhotoServiceMock();
  }

  /// Get or create mock AiService with default behavior
  static MockIAiService getAiService() {
    return _mockAiService ??= _createAiServiceMock();
  }

  /// Get or create mock DiaryService with default behavior
  static MockIDiaryService getDiaryService() {
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
    _mockLoggingService = null;
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
    getLoggingService();
    getPhotoService();
    getAiService();
    getDiaryService();
    getSubscriptionService();
    getSettingsService();
    getStorageService();
  }

  // Private factory methods with default mock behavior
  static MockILoggingService _createLoggingServiceMock() {
    final mock = MockILoggingService();

    when(
      () => mock.debug(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mock.info(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mock.warning(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mock.error(
        any(),
        context: any(named: 'context'),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
    when(
      () => mock.startTimer(any(), context: any(named: 'context')),
    ).thenReturn(Stopwatch());

    return mock;
  }

  static MockIPhotoService _createPhotoServiceMock() {
    final mock = MockIPhotoService();

    // Default mock behavior for PhotoService
    when(
      () => mock.requestPermission(),
    ).thenAnswer((_) async => const Success(true));
    when(
      () => mock.getTodayPhotos(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));
    when(
      () => mock.getPhotosForDate(
        any(),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));
    when(
      () => mock.getPhotosInDateRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));
    when(
      () => mock.getThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure(PhotoAccessException('No thumbnail available in test')),
    );
    when(() => mock.getPhotoData(any())).thenAnswer(
      (_) async => const Success([1, 2, 3, 4, 5]),
    ); // Mock image data
    when(
      () => mock.getThumbnailData(any()),
    ).thenAnswer((_) async => const Success([1, 2, 3])); // Mock thumbnail data
    when(
      () => mock.getImageForAi(any()),
    ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3, 4, 5])));
    when(
      () => mock.getOriginalFile(any()),
    ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3, 4, 5])));
    when(
      () => mock.isLimitedAccess(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => mock.getPhotosEfficient(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));
    when(
      () => mock.isPermissionPermanentlyDenied(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => mock.capturePhoto(),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => mock.getAssetsByIds(any()),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));

    return mock;
  }

  static MockIAiService _createAiServiceMock() {
    final mock = MockIAiService();

    // Default mock behavior for AiService
    when(() => mock.isOnline()).thenAnswer((_) async => true);

    when(
      () => mock.generateDiaryFromImage(
        imageData: any(named: 'imageData'),
        date: any(named: 'date'),
        location: any(named: 'location'),
        photoTimes: any(named: 'photoTimes'),
        locale: any(named: 'locale'),
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
        locale: any(named: 'locale'),
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
    ).thenAnswer((_) async => const Success(['mock', 'test', 'generated']));

    return mock;
  }

  static MockIDiaryService _createDiaryServiceMock() {
    final mock = MockIDiaryService();

    // Stream for diary changes
    when(
      () => mock.changes,
    ).thenAnswer((_) => const Stream<DiaryChange>.empty());

    // Default mock behavior for DiaryService (all methods return Result)
    when(
      () => mock.getSortedDiaryEntries(descending: any(named: 'descending')),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mock.getDiaryEntry(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => mock.getFilteredDiaryEntries(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mock.getFilteredDiaryEntriesPage(
        any(),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Success([]));
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
    when(
      () => mock.updateDiaryEntry(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => mock.deleteDiaryEntry(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => mock.getDiaryEntryByPhotoId(any()),
    ).thenAnswer((_) async => const Success(null));

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
    when(() => mock.diaryLength).thenReturn(DiaryLength.standard);
    when(
      () => mock.setDiaryLength(any()),
    ).thenAnswer((_) async => const Success(null));

    // Photo type filter defaults
    when(() => mock.photoTypeFilter).thenReturn(PhotoTypeFilter.all);
    when(
      () => mock.photoTypeFilterNotifier,
    ).thenReturn(ValueNotifier<PhotoTypeFilter>(PhotoTypeFilter.all));
    when(
      () => mock.setPhotoTypeFilter(any()),
    ).thenAnswer((_) async => const Success(null));

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
  registerFallbackValue(Stopwatch());
  registerFallbackValue(MockAssetEntity());
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(<AssetEntity>[]);
  registerFallbackValue(<String>[]);
  registerFallbackValue(<DateTime>[]);
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(<({Uint8List imageData, DateTime time})>[]);
  registerFallbackValue(const Locale('ja'));
  registerFallbackValue(DiaryLength.standard);
  registerFallbackValue(PhotoTypeFilter.all);
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
