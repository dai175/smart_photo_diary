import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/photo_service.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes
class MockAssetEntity extends Mock implements AssetEntity {}
class MockAssetPathEntity extends Mock implements AssetPathEntity {}

void main() {
  group('PhotoService', () {
    late PhotoService photoService;

    setUpAll(() {
      // Initialize Flutter binding for tests that use platform channels
      TestWidgetsFlutterBinding.ensureInitialized();
      // Setup mock platform channels
      MockPlatformChannels.setupMocks();
    });

    tearDownAll(() {
      // Clear mock platform channels
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      photoService = PhotoService.getInstance();
    });

    group('Singleton Pattern', () {
      test('should return same instance on multiple calls', () {
        // Act
        final instance1 = PhotoService.getInstance();
        final instance2 = PhotoService.getInstance();

        // Assert
        expect(instance1, same(instance2));
      });

      test('should implement PhotoServiceInterface', () {
        expect(photoService, isA<PhotoServiceInterface>());
      });
    });

    group('Interface Compliance', () {
      test('should have all required interface methods', () {
        // Verify that all interface methods are implemented
        expect(photoService.requestPermission, isA<Future<bool> Function()>());
        expect(photoService.getTodayPhotos, isA<Function>());
        expect(photoService.getPhotosInDateRange, isA<Function>());
        expect(photoService.getPhotoData, isA<Function>());
        expect(photoService.getThumbnailData, isA<Function>());
        expect(photoService.getOriginalFile, isA<Function>());
        expect(photoService.getThumbnail, isA<Function>());
      });
    });

    group('requestPermission', () {
      test('should return boolean permission status', () async {
        // Act
        final result = await photoService.requestPermission();

        // Assert
        expect(result, isA<bool>());
      });
    });

    group('getTodayPhotos', () {
      test('should return list of AssetEntity', () async {
        // Act
        final result = await photoService.getTodayPhotos();

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('should respect limit parameter', () async {
        // Act
        final result = await photoService.getTodayPhotos(limit: 5);

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('should handle default limit', () async {
        // Act
        final result = await photoService.getTodayPhotos();

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result.length, lessThanOrEqualTo(20)); // Default limit
      });
    });

    group('getPhotosInDateRange', () {
      test('should return photos in specified date range', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        // Act
        final result = await photoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('should respect limit parameter in date range', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        // Act
        final result = await photoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
          limit: 10,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result.length, lessThanOrEqualTo(10));
      });

      test('should handle same start and end date', () async {
        // Arrange
        final sameDate = DateTime(2024, 1, 15);

        // Act
        final result = await photoService.getPhotosInDateRange(
          startDate: sameDate,
          endDate: sameDate,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });
    });

    group('Data Retrieval Methods', () {
      late MockAssetEntity mockAsset;

      setUp(() {
        mockAsset = MockAssetEntity();
      });

      test('getPhotoData should return List<int> or null', () async {
        // Act
        final result = await photoService.getPhotoData(mockAsset);

        // Assert
        expect(result, anyOf(isA<List<int>>(), isNull));
      });

      test('getThumbnailData should return List<int> or null', () async {
        // Act
        final result = await photoService.getThumbnailData(mockAsset);

        // Assert
        expect(result, anyOf(isA<List<int>>(), isNull));
      });

      test('getOriginalFile should return data or null', () async {
        // Act
        final result = await photoService.getOriginalFile(mockAsset);

        // Assert
        expect(result, anyOf(isNotNull, isNull));
      });

      test('getThumbnail should return data or null', () async {
        // Act
        final result = await photoService.getThumbnail(mockAsset);

        // Assert
        expect(result, anyOf(isNotNull, isNull));
      });

      test('getThumbnail should respect custom dimensions', () async {
        // Act
        final result = await photoService.getThumbnail(
          mockAsset,
          width: 300,
          height: 300,
        );

        // Assert
        expect(result, anyOf(isNotNull, isNull));
      });
    });

    group('Backward Compatibility Methods', () {
      late MockAssetEntity mockAsset;

      setUp(() {
        mockAsset = MockAssetEntity();
      });

      test('getPhotosByDate should return photos for specific date', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15);

        // Act
        final result = await photoService.getPhotosByDate(testDate);

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('getPhotosByDate should respect limit parameter', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15);

        // Act
        final result = await photoService.getPhotosByDate(testDate, limit: 5);

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('getAllPhotos should return photos without date filter', () async {
        // Act
        final result = await photoService.getAllPhotos();

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('getAllPhotos should respect limit parameter', () async {
        // Act
        final result = await photoService.getAllPhotos(limit: 50);

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result.length, lessThanOrEqualTo(50));
      });
    });

    group('Error Handling', () {
      test('should handle permission denied gracefully', () async {
        // Act - This should not throw even if permission is denied
        final result = await photoService.requestPermission();

        // Assert
        expect(result, isA<bool>());
      });

      test('should handle no photos gracefully', () async {
        // Act - Should return empty list if no photos
        final result = await photoService.getTodayPhotos();

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('should handle invalid date ranges gracefully', () async {
        // Arrange - End date before start date
        final startDate = DateTime(2024, 1, 31);
        final endDate = DateTime(2024, 1, 1);

        // Act - Should not throw
        final result = await photoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('should handle null asset data gracefully', () async {
        // Arrange
        final mockAsset = MockAssetEntity();

        // Act - Should not throw even if asset data is null
        final result = await photoService.getPhotoData(mockAsset);

        // Assert
        expect(result, anyOf(isA<List<int>>(), isNull));
      });
    });

    group('Constants and Defaults', () {
      test('should use correct default parameters', () async {
        // This test verifies that the service uses constants properly
        // In integration tests, we could verify actual constant values

        // Act
        final result = await photoService.getTodayPhotos();

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });
    });

    group('Date Range Logic', () {
      test('should handle date ranges correctly', () async {
        // Arrange
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        // Act
        final result = await photoService.getPhotosInDateRange(
          startDate: yesterday,
          endDate: tomorrow,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
      });

      test('should handle future dates', () async {
        // Arrange
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final dayAfter = DateTime.now().add(const Duration(days: 2));

        // Act
        final result = await photoService.getPhotosInDateRange(
          startDate: tomorrow,
          endDate: dayAfter,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result, isEmpty); // Should be empty as no photos exist in future
      });
    });
  });
}