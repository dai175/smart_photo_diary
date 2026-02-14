import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock implementations for testing
class MockIPhotoService extends Mock implements IPhotoService {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('PhotoService Mock Tests', () {
    late MockIPhotoService mockPhotoService;
    late MockAssetEntity mockAssetEntity;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
      registerFallbackValue(MockAssetEntity());
      registerFallbackValue(DateTime.now());
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockPhotoService = MockIPhotoService();
      mockAssetEntity = MockAssetEntity();
    });

    group('getPhotosForDate', () {
      test(
        'should get photos for specific date with offset and limit',
        () async {
          // Arrange
          final testDate = DateTime(2024, 7, 29);
          const offset = 0;
          const limit = 10;
          final mockAssets = [mockAssetEntity];

          when(
            () => mockPhotoService.getPhotosForDate(
              testDate,
              offset: offset,
              limit: limit,
            ),
          ).thenAnswer((_) async => Success(mockAssets));

          // Act
          final result = await mockPhotoService.getPhotosForDate(
            testDate,
            offset: offset,
            limit: limit,
          );

          // Assert
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockAssets));
          verify(
            () => mockPhotoService.getPhotosForDate(
              testDate,
              offset: offset,
              limit: limit,
            ),
          ).called(1);
        },
      );

      test('should return empty list when no photos found for date', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 1);
        const offset = 0;
        const limit = 10;

        when(
          () => mockPhotoService.getPhotosForDate(
            testDate,
            offset: offset,
            limit: limit,
          ),
        ).thenAnswer((_) async => const Success(<AssetEntity>[]));

        // Act
        final result = await mockPhotoService.getPhotosForDate(
          testDate,
          offset: offset,
          limit: limit,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });

      test('should handle pagination with offset', () async {
        // Arrange
        final testDate = DateTime(2024, 7, 29);
        const offset = 10;
        const limit = 5;
        final mockAssets = List.generate(5, (index) => MockAssetEntity());

        when(
          () => mockPhotoService.getPhotosForDate(
            testDate,
            offset: offset,
            limit: limit,
          ),
        ).thenAnswer((_) async => Success(mockAssets));

        // Act
        final result = await mockPhotoService.getPhotosForDate(
          testDate,
          offset: offset,
          limit: limit,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.length, equals(5));
        verify(
          () => mockPhotoService.getPhotosForDate(
            testDate,
            offset: offset,
            limit: limit,
          ),
        ).called(1);
      });
    });

    group('Permission Management', () {
      test('should request permission successfully', () async {
        // Arrange
        when(
          () => mockPhotoService.requestPermission(),
        ).thenAnswer((_) async => true);

        // Act
        final result = await mockPhotoService.requestPermission();

        // Assert
        expect(result, isTrue);
        verify(() => mockPhotoService.requestPermission()).called(1);
      });

      test('should handle permission denied', () async {
        // Arrange
        when(
          () => mockPhotoService.requestPermission(),
        ).thenAnswer((_) async => false);

        // Act
        final result = await mockPhotoService.requestPermission();

        // Assert
        expect(result, isFalse);
        verify(() => mockPhotoService.requestPermission()).called(1);
      });
    });

    group('Photo Retrieval', () {
      test('should get today photos with default limit', () async {
        // Arrange
        final mockPhotos = [mockAssetEntity];
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Success(mockPhotos));

        // Act
        final result = await mockPhotoService.getTodayPhotos();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(mockPhotos));
        expect(result.value.length, equals(1));
        verify(() => mockPhotoService.getTodayPhotos(limit: 20)).called(1);
      });

      test('should get today photos with custom limit', () async {
        // Arrange
        final mockPhotos = List.generate(5, (index) => mockAssetEntity);
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Success(mockPhotos));

        // Act
        final result = await mockPhotoService.getTodayPhotos(limit: 5);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(mockPhotos));
        expect(result.value.length, equals(5));
        verify(() => mockPhotoService.getTodayPhotos(limit: 5)).called(1);
      });

      test('should get photos in date range', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        final mockPhotos = [mockAssetEntity];

        when(
          () => mockPhotoService.getPhotosInDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(mockPhotos));

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(mockPhotos));
        verify(
          () => mockPhotoService.getPhotosInDateRange(
            startDate: startDate,
            endDate: endDate,
            limit: 100,
          ),
        ).called(1);
      });

      test('should get photos in date range with custom limit', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        final mockPhotos = List.generate(50, (index) => mockAssetEntity);

        when(
          () => mockPhotoService.getPhotosInDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(mockPhotos));

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
          limit: 50,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(mockPhotos));
        expect(result.value.length, equals(50));
      });
    });

    group('Photo Data Access', () {
      test('should get photo data successfully', () async {
        // Arrange
        final mockData = [1, 2, 3, 4, 5];
        when(
          () => mockPhotoService.getPhotoData(any()),
        ).thenAnswer((_) async => mockData);

        // Act
        final result = await mockPhotoService.getPhotoData(mockAssetEntity);

        // Assert
        expect(result, equals(mockData));
        verify(() => mockPhotoService.getPhotoData(mockAssetEntity)).called(1);
      });

      test('should get thumbnail data successfully', () async {
        // Arrange
        final mockThumbnailData = [10, 20, 30];
        when(
          () => mockPhotoService.getThumbnailData(any()),
        ).thenAnswer((_) async => mockThumbnailData);

        // Act
        final result = await mockPhotoService.getThumbnailData(mockAssetEntity);

        // Assert
        expect(result, equals(mockThumbnailData));
        verify(
          () => mockPhotoService.getThumbnailData(mockAssetEntity),
        ).called(1);
      });

      test('should get original file successfully', () async {
        // Arrange
        const mockFile = 'path/to/original/file.jpg';
        when(
          () => mockPhotoService.getOriginalFile(any()),
        ).thenAnswer((_) async => mockFile);

        // Act
        final result = await mockPhotoService.getOriginalFile(mockAssetEntity);

        // Assert
        expect(result, equals(mockFile));
        verify(
          () => mockPhotoService.getOriginalFile(mockAssetEntity),
        ).called(1);
      });

      test('should get thumbnail with default size', () async {
        // Arrange
        const mockThumbnail = 'thumbnail_data';
        when(
          () => mockPhotoService.getThumbnail(
            any(),
            width: any(named: 'width'),
            height: any(named: 'height'),
          ),
        ).thenAnswer((_) async => mockThumbnail);

        // Act
        final result = await mockPhotoService.getThumbnail(mockAssetEntity);

        // Assert
        expect(result, equals(mockThumbnail));
        verify(
          () => mockPhotoService.getThumbnail(
            mockAssetEntity,
            width: 200,
            height: 200,
          ),
        ).called(1);
      });

      test('should get thumbnail with custom size', () async {
        // Arrange
        const mockThumbnail = 'custom_thumbnail_data';
        when(
          () => mockPhotoService.getThumbnail(
            any(),
            width: any(named: 'width'),
            height: any(named: 'height'),
          ),
        ).thenAnswer((_) async => mockThumbnail);

        // Act
        final result = await mockPhotoService.getThumbnail(
          mockAssetEntity,
          width: 300,
          height: 300,
        );

        // Assert
        expect(result, equals(mockThumbnail));
        verify(
          () => mockPhotoService.getThumbnail(
            mockAssetEntity,
            width: 300,
            height: 300,
          ),
        ).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle permission request failure', () async {
        // Arrange
        when(
          () => mockPhotoService.requestPermission(),
        ).thenThrow(Exception('Permission request failed'));

        // Act & Assert
        expect(
          () => mockPhotoService.requestPermission(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty photo list', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Success(<AssetEntity>[]));

        // Act
        final result = await mockPhotoService.getTodayPhotos();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });

      test('should handle null photo data', () async {
        // Arrange
        when(
          () => mockPhotoService.getPhotoData(any()),
        ).thenAnswer((_) async => null);

        // Act
        final result = await mockPhotoService.getPhotoData(mockAssetEntity);

        // Assert
        expect(result, isNull);
      });

      test('should handle null thumbnail data', () async {
        // Arrange
        when(
          () => mockPhotoService.getThumbnailData(any()),
        ).thenAnswer((_) async => null);

        // Act
        final result = await mockPhotoService.getThumbnailData(mockAssetEntity);

        // Assert
        expect(result, isNull);
      });

      test('should handle invalid date ranges', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 31);
        final endDate = DateTime(2024, 1, 1); // End before start

        when(
          () => mockPhotoService.getPhotosInDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success(<AssetEntity>[]));

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle very large limits', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Success(<AssetEntity>[]));

        // Act
        final result = await mockPhotoService.getTodayPhotos(limit: 999999);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
        verify(() => mockPhotoService.getTodayPhotos(limit: 999999)).called(1);
      });

      test('should handle zero limit', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Success(<AssetEntity>[]));

        // Act
        final result = await mockPhotoService.getTodayPhotos(limit: 0);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });

      test('should handle future dates', () async {
        // Arrange
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final endDate = futureDate.add(const Duration(days: 1));

        when(
          () => mockPhotoService.getPhotosInDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success(<AssetEntity>[]));

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: futureDate,
          endDate: endDate,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });

      test('should handle same start and end dates', () async {
        // Arrange
        final sameDate = DateTime(2024, 1, 15);

        when(
          () => mockPhotoService.getPhotosInDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success([mockAssetEntity]));

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: sameDate,
          endDate: sameDate,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotEmpty);
      });
    });

    group('Interface Compliance', () {
      test('should implement IPhotoService', () {
        expect(mockPhotoService, isA<IPhotoService>());
      });

      test('should have all required interface methods', () {
        expect(mockPhotoService.requestPermission, isA<Function>());
        expect(mockPhotoService.getTodayPhotos, isA<Function>());
        expect(mockPhotoService.getPhotosInDateRange, isA<Function>());
        expect(mockPhotoService.getPhotoData, isA<Function>());
        expect(mockPhotoService.getThumbnailData, isA<Function>());
        expect(mockPhotoService.getOriginalFile, isA<Function>());
        expect(mockPhotoService.getThumbnail, isA<Function>());
      });
    });

    group('Performance', () {
      test('should handle multiple concurrent requests', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Success([mockAssetEntity]));

        // Act
        final futures = List.generate(
          5,
          (_) => mockPhotoService.getTodayPhotos(),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.value, equals([mockAssetEntity]));
        }
        verify(() => mockPhotoService.getTodayPhotos(limit: 20)).called(5);
      });

      test('should handle batch data retrieval', () async {
        // Arrange
        final assets = List.generate(10, (index) => mockAssetEntity);
        when(
          () => mockPhotoService.getPhotoData(any()),
        ).thenAnswer((_) async => [1, 2, 3]);

        // Act
        final futures = assets.map(
          (asset) => mockPhotoService.getPhotoData(asset),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(10));
        verify(() => mockPhotoService.getPhotoData(any())).called(10);
      });
    });
  });
}
