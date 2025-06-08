import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/image_classifier_service.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';

/// Mock PhotoService for integration testing
class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}

/// Mock AiService for integration testing
class MockAiServiceInterface extends Mock implements AiServiceInterface {}

/// Mock DiaryService for integration testing
class MockDiaryServiceInterface extends Mock implements DiaryServiceInterface {}

/// Mock ImageClassifierService for integration testing
class MockImageClassifierService extends Mock implements ImageClassifierService {}

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
  static MockImageClassifierService? _mockImageClassifierService;
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

  /// Get or create mock ImageClassifierService with default behavior
  static MockImageClassifierService getImageClassifierService() {
    return _mockImageClassifierService ??= _createImageClassifierServiceMock();
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
    _mockImageClassifierService = null;
    _mockSettingsService = null;
    _mockStorageService = null;
  }

  /// Set up all services with default mock behavior
  static void setupAllServices() {
    registerMockFallbacks();
    getPhotoService();
    getAiService();
    getDiaryService();
    getImageClassifierService();
    getSettingsService();
    getStorageService();
  }

  // Private factory methods with default mock behavior
  static MockPhotoServiceInterface _createPhotoServiceMock() {
    final mock = MockPhotoServiceInterface();
    
    // Default mock behavior for PhotoService
    when(() => mock.requestPermission()).thenAnswer((_) async => true);
    when(() => mock.getTodayPhotos(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mock.getPhotosInDateRange(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => []);
    when(() => mock.getThumbnail(
      any(),
      width: any(named: 'width'),
      height: any(named: 'height'),
    )).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4, 5]));
    when(() => mock.getPhotoData(any()))
        .thenAnswer((_) async => [1, 2, 3, 4, 5]); // Mock image data
    when(() => mock.getThumbnailData(any()))
        .thenAnswer((_) async => [1, 2, 3]); // Mock thumbnail data
    when(() => mock.getOriginalFile(any()))
        .thenAnswer((_) async => 'mock_file_path');
    
    return mock;
  }

  static MockAiServiceInterface _createAiServiceMock() {
    final mock = MockAiServiceInterface();
    
    // Default mock behavior for AiService
    when(() => mock.isOnline()).thenAnswer((_) async => true);
    
    when(() => mock.generateDiaryFromLabels(
      labels: any(named: 'labels'),
      date: any(named: 'date'),
      location: any(named: 'location'),
      photoTimes: any(named: 'photoTimes'),
      photoTimeLabels: any(named: 'photoTimeLabels'),
    )).thenAnswer((_) async => DiaryGenerationResult(
      title: 'Mock Diary Title',
      content: 'Mock diary content generated by AI service.',
    ));
    
    when(() => mock.generateDiaryFromImage(
      imageData: any(named: 'imageData'),
      date: any(named: 'date'),
      location: any(named: 'location'),
      photoTimes: any(named: 'photoTimes'),
    )).thenAnswer((_) async => DiaryGenerationResult(
      title: 'Mock Image Diary',
      content: 'Mock content from image analysis.',
    ));
    
    when(() => mock.generateDiaryFromMultipleImages(
      imagesWithTimes: any(named: 'imagesWithTimes'),
      location: any(named: 'location'),
      onProgress: any(named: 'onProgress'),
    )).thenAnswer((_) async => DiaryGenerationResult(
      title: 'Mock Multi-Image Diary',
      content: 'Mock content from multiple images.',
    ));
    
    when(() => mock.generateTagsFromContent(
      title: any(named: 'title'),
      content: any(named: 'content'),
      date: any(named: 'date'),
      photoCount: any(named: 'photoCount'),
    )).thenAnswer((_) async => ['mock', 'test', 'generated']);
    
    return mock;
  }

  static MockDiaryServiceInterface _createDiaryServiceMock() {
    final mock = MockDiaryServiceInterface();
    
    // Default mock behavior for DiaryService
    when(() => mock.getSortedDiaryEntries()).thenAnswer((_) async => []);
    when(() => mock.getDiaryEntry(any())).thenAnswer((_) async => null);
    when(() => mock.getTotalDiaryCount()).thenAnswer((_) async => 0);
    when(() => mock.getAllTags()).thenAnswer((_) async => {'mock', 'test', 'tags'});
    when(() => mock.getDiaryCountInPeriod(any(), any()))
        .thenAnswer((_) async => 0);
    when(() => mock.getFilteredDiaryEntries(any()))
        .thenAnswer((_) async => []);
    when(() => mock.getTagsForEntry(any()))
        .thenAnswer((_) async => ['mock', 'test']);
    when(() => mock.saveDiaryEntry(
      date: any(named: 'date'),
      title: any(named: 'title'),
      content: any(named: 'content'),
      photoIds: any(named: 'photoIds'),
      location: any(named: 'location'),
      tags: any(named: 'tags'),
    )).thenAnswer((_) async => DiaryEntry(
      id: 'mock-id',
      date: DateTime.now(),
      title: 'Mock Title',
      content: 'Mock Content',
      photoIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    when(() => mock.updateDiaryEntry(any())).thenAnswer((_) async {});
    when(() => mock.deleteDiaryEntry(any())).thenAnswer((_) async {});
    
    return mock;
  }

  static MockImageClassifierService _createImageClassifierServiceMock() {
    final mock = MockImageClassifierService();
    
    // Default mock behavior for ImageClassifierService
    // Note: Setup basic mocks that are commonly used, specific tests can override these
    when(() => mock.loadModel()).thenAnswer((_) async {});
    when(() => mock.classifyAsset(any(), maxResults: any(named: 'maxResults')))
        .thenAnswer((_) async => ['object', 'scene', 'activity']);
    
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
  registerFallbackValue(DiaryEntry(
    id: 'fallback-id',
    date: DateTime.now(),
    title: 'Fallback Title',
    content: 'Fallback Content',
    photoIds: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
}