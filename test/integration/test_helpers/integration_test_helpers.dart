import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/image_classifier_service.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import '../mocks/mock_services.dart';
import '../../test_helpers/mock_platform_channels.dart';

/// Helper utilities for integration testing
class IntegrationTestHelpers {
  static late ServiceLocator _serviceLocator;
  static late MockPhotoServiceInterface _mockPhotoService;
  static late MockAiServiceInterface _mockAiService;

  /// Setup comprehensive test environment for integration tests
  static Future<void> setUpIntegrationEnvironment() async {
    // Initialize Flutter binding
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup mock platform channels
    MockPlatformChannels.setupMocks();
    
    // Initialize Hive for testing
    await _initializeHive();
    
    // Setup service locator with mocks
    await _setupServiceLocator();
  }

  /// Clean up test environment
  static Future<void> tearDownIntegrationEnvironment() async {
    try {
      // Clear Hive data
      await Hive.deleteFromDisk();
      
      // Clear service locator
      _serviceLocator.clear();
      
      // Clear mock platform channels
      MockPlatformChannels.clearMocks();
    } catch (e) {
      // Ignore cleanup errors in tests
      debugPrint('Cleanup error: $e');
    }
  }

  /// Initialize Hive for testing
  static Future<void> _initializeHive() async {
    const testDirectory = '/tmp/smart_photo_diary_integration_test';
    await Hive.initFlutter(testDirectory);
    
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DiaryEntryAdapter());
    }
  }

  /// Setup service locator with mock services
  static Future<void> _setupServiceLocator() async {
    _serviceLocator = ServiceLocator();
    
    // Create mock services
    _mockPhotoService = MockPhotoServiceInterface();
    _mockAiService = MockAiServiceInterface();
    
    // Create additional required mock services
    final mockDiaryService = MockDiaryServiceInterface();
    final mockImageClassifierService = MockImageClassifierService();
    final mockSettingsService = MockSettingsService();
    final mockStorageService = MockStorageService();
    
    // Setup default mock behaviors
    _setupDefaultMockBehaviors();
    _setupAdditionalMockBehaviors(mockDiaryService, mockImageClassifierService, mockSettingsService, mockStorageService);
    
    // Register all mock services
    _serviceLocator.registerSingleton<PhotoServiceInterface>(_mockPhotoService);
    _serviceLocator.registerSingleton<AiServiceInterface>(_mockAiService);
    _serviceLocator.registerSingleton<DiaryServiceInterface>(mockDiaryService);
    _serviceLocator.registerSingleton<ImageClassifierService>(mockImageClassifierService);
    _serviceLocator.registerSingleton<SettingsService>(mockSettingsService);
    _serviceLocator.registerSingleton<StorageService>(mockStorageService);
  }

  /// Setup default behaviors for mock services
  static void _setupDefaultMockBehaviors() {
    // Photo service defaults
    when(() => _mockPhotoService.requestPermission()).thenAnswer((_) async => true);
    when(() => _mockPhotoService.getTodayPhotos()).thenAnswer((_) async => []);
    when(() => _mockPhotoService.getPhotosInDateRange(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    )).thenAnswer((_) async => []);
    when(() => _mockPhotoService.getPhotoData(any())).thenAnswer((_) async => _createMockImageData().toList());
    when(() => _mockPhotoService.getThumbnailData(any())).thenAnswer((_) async => _createMockImageData().toList());
    when(() => _mockPhotoService.getOriginalFile(any())).thenAnswer((_) async => null);
    when(() => _mockPhotoService.getThumbnail(any(), width: any(named: 'width'), height: any(named: 'height'))).thenAnswer((_) async => null);
    
    // AI service defaults
    
    when(() => _mockAiService.generateDiaryFromImage(
      imageData: any(named: 'imageData'),
      date: any(named: 'date'),
      location: any(named: 'location'),
      photoTimes: any(named: 'photoTimes'),
    )).thenAnswer((_) async => _createMockDiaryResult());
    
    when(() => _mockAiService.generateDiaryFromMultipleImages(
      imagesWithTimes: any(named: 'imagesWithTimes'),
      location: any(named: 'location'),
      onProgress: any(named: 'onProgress'),
    )).thenAnswer((_) async => _createMockDiaryResult());
    
    when(() => _mockAiService.isOnline()).thenAnswer((_) async => true);
    
    when(() => _mockAiService.generateTagsFromContent(
      title: any(named: 'title'),
      content: any(named: 'content'),
      date: any(named: 'date'),
      photoCount: any(named: 'photoCount'),
    )).thenAnswer((_) async => ['テスト', 'タグ']);
  }

  /// Create mock diary generation result
  static DiaryGenerationResult _createMockDiaryResult() {
    return DiaryGenerationResult(
      title: 'テスト日記のタイトル',
      content: 'これはテスト用に生成された日記の内容です。写真から素敵な思い出を記録しました。',
    );
  }

  /// Create mock AssetEntity for testing
  static List<AssetEntity> createMockAssets(int count) {
    return List.generate(count, (index) {
      final mockAsset = MockAssetEntity();
      when(() => mockAsset.id).thenReturn('test-asset-$index');
      when(() => mockAsset.title).thenReturn('Test Photo $index');
      when(() => mockAsset.createDateTime).thenReturn(
        DateTime.now().subtract(Duration(days: index)),
      );
      when(() => mockAsset.modifiedDateTime).thenReturn(
        DateTime.now().subtract(Duration(days: index)),
      );
      when(() => mockAsset.duration).thenReturn(0);
      when(() => mockAsset.width).thenReturn(1920);
      when(() => mockAsset.height).thenReturn(1080);
      when(() => mockAsset.type).thenReturn(AssetType.image);
      when(() => mockAsset.thumbnailData).thenAnswer((_) async => _createMockImageData());
      when(() => mockAsset.originBytes).thenAnswer((_) async => _createMockImageData());
      return mockAsset;
    });
  }

  /// Create mock image data
  static Uint8List _createMockImageData() {
    // Simple PNG header
    return Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
  }

  /// Setup mock photos for today
  static void setupMockTodayPhotos(List<AssetEntity> assets) {
    when(() => _mockPhotoService.getTodayPhotos()).thenAnswer((_) async => assets);
  }

  /// Setup mock photo permission
  static void setupMockPhotoPermission(bool hasPermission) {
    when(() => _mockPhotoService.requestPermission()).thenAnswer((_) async => hasPermission);
  }

  /// Setup mock AI diary generation
  static void setupMockDiaryGeneration(DiaryGenerationResult result) {
    when(() => _mockAiService.generateDiaryFromImage(
      imageData: any(named: 'imageData'),
      date: any(named: 'date'),
      location: any(named: 'location'),
      photoTimes: any(named: 'photoTimes'),
    )).thenAnswer((_) async => result);
    
    when(() => _mockAiService.generateDiaryFromMultipleImages(
      imagesWithTimes: any(named: 'imagesWithTimes'),
      location: any(named: 'location'),
      onProgress: any(named: 'onProgress'),
    )).thenAnswer((_) async => result);
  }

  /// Pump and settle with extended timeout for integration tests
  static Future<void> pumpAndSettleWithExtendedTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    try {
      await tester.pumpAndSettle(timeout);
    } catch (e) {
      // If pumpAndSettle times out, try manual pumping
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (!tester.binding.hasScheduledFrame) break;
      }
    }
  }

  /// Wait for specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TimeoutException('Widget not found within timeout', timeout);
  }

  /// Tap widget and wait for navigation
  static Future<void> tapAndWaitForNavigation(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Animation duration
  }

  /// Enter text and pump
  static Future<void> enterTextAndPump(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Scroll to find widget
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder scrollable,
    Finder target,
  ) async {
    await tester.scrollUntilVisible(target, 100.0, scrollable: scrollable);
    await tester.pump();
  }

  /// Verify navigation to specific screen
  static void verifyNavigationToScreen<T>() {
    expect(find.byType(T), findsOneWidget);
  }

  /// Create test diary entry for integration tests
  static DiaryEntry createTestDiaryEntry({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    List<String>? photoIds,
  }) {
    final now = DateTime.now();
    return DiaryEntry(
      id: id ?? 'integration-test-${now.millisecondsSinceEpoch}',
      title: title ?? 'Integration Test Diary',
      content: content ?? 'This is a test diary entry for integration testing.',
      date: date ?? now,
      photoIds: photoIds ?? ['test-photo-1', 'test-photo-2'],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Verify error dialog appears
  static void verifyErrorDialog(String expectedMessage) {
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining(expectedMessage), findsOneWidget);
  }

  /// Verify success snackbar appears
  static void verifySuccessMessage(String expectedMessage) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining(expectedMessage), findsOneWidget);
  }

  /// Dismiss dialog or snackbar
  static Future<void> dismissDialog(WidgetTester tester) async {
    if (find.text('OK').evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
    } else if (find.text('閉じる').evaluate().isNotEmpty) {
      await tester.tap(find.text('閉じる'));
    }
    await tester.pump();
  }

  /// Setup additional mock service behaviors
  static void _setupAdditionalMockBehaviors(
    MockDiaryServiceInterface mockDiaryService,
    MockImageClassifierService mockImageClassifierService,
    MockSettingsService mockSettingsService,
    MockStorageService mockStorageService,
  ) {
    // Diary service defaults - using correct interface methods
    when(() => mockDiaryService.getSortedDiaryEntries()).thenAnswer((_) async => []);
    when(() => mockDiaryService.getFilteredDiaryEntries(any())).thenAnswer((_) async => []);
    when(() => mockDiaryService.getAllTags()).thenAnswer((_) async => <String>{});
    when(() => mockDiaryService.getTotalDiaryCount()).thenAnswer((_) async => 0);
    when(() => mockDiaryService.getDiaryCountInPeriod(any(), any())).thenAnswer((_) async => 0);
    when(() => mockDiaryService.getDiaryEntry(any())).thenAnswer((_) async => null);
    when(() => mockDiaryService.getTagsForEntry(any())).thenAnswer((_) async => []);
    
    // Image classifier defaults - basic mock setup
    when(() => mockImageClassifierService.classifyImage(any())).thenAnswer((_) async => []);
    
    // Settings service defaults - basic mock setup
    when(() => mockSettingsService.themeMode).thenReturn(ThemeMode.system);
    
    // Storage service defaults - basic mock setup  
    when(() => mockStorageService.exportData()).thenAnswer((_) async => '{}');
  }

  /// Get mock photo service for additional setup
  static MockPhotoServiceInterface get mockPhotoService => _mockPhotoService;

  /// Get mock AI service for additional setup
  static MockAiServiceInterface get mockAiService => _mockAiService;
}

/// Timeout exception for integration tests
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}