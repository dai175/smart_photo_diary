import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock implementations for testing
class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('PhotoService Mock Tests', () {
    late MockPhotoServiceInterface mockPhotoService;
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
      mockPhotoService = MockPhotoServiceInterface();
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
          ).thenAnswer((_) async => mockAssets);

          // Act
          final result = await mockPhotoService.getPhotosForDate(
            testDate,
            offset: offset,
            limit: limit,
          );

          // Assert
          expect(result, equals(mockAssets));
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
        ).thenAnswer((_) async => []);

        // Act
        final result = await mockPhotoService.getPhotosForDate(
          testDate,
          offset: offset,
          limit: limit,
        );

        // Assert
        expect(result, isEmpty);
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
        ).thenAnswer((_) async => mockAssets);

        // Act
        final result = await mockPhotoService.getPhotosForDate(
          testDate,
          offset: offset,
          limit: limit,
        );

        // Assert
        expect(result.length, equals(5));
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
        ).thenAnswer((_) async => mockPhotos);

        // Act
        final result = await mockPhotoService.getTodayPhotos();

        // Assert
        expect(result, equals(mockPhotos));
        expect(result.length, equals(1));
        verify(() => mockPhotoService.getTodayPhotos(limit: 20)).called(1);
      });

      test('should get today photos with custom limit', () async {
        // Arrange
        final mockPhotos = List.generate(5, (index) => mockAssetEntity);
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => mockPhotos);

        // Act
        final result = await mockPhotoService.getTodayPhotos(limit: 5);

        // Assert
        expect(result, equals(mockPhotos));
        expect(result.length, equals(5));
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
        ).thenAnswer((_) async => mockPhotos);

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, equals(mockPhotos));
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
        ).thenAnswer((_) async => mockPhotos);

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
          limit: 50,
        );

        // Assert
        expect(result, equals(mockPhotos));
        expect(result.length, equals(50));
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

      test('should get original file result successfully', () async {
        // Arrange
        final mockData = Uint8List.fromList([1, 2, 3, 4]);
        when(
          () => mockPhotoService.getOriginalFileResult(any()),
        ).thenAnswer((_) async => Success(mockData));

        // Act
        final result = await mockPhotoService.getOriginalFileResult(
          mockAssetEntity,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(mockData));
        verify(
          () => mockPhotoService.getOriginalFileResult(mockAssetEntity),
        ).called(1);
      });

      test('should handle original file result error', () async {
        // Arrange
        final mockError = PhotoAccessException('画像データの取得に失敗しました');
        when(
          () => mockPhotoService.getOriginalFileResult(any()),
        ).thenAnswer((_) async => Failure(mockError));

        // Act
        final result = await mockPhotoService.getOriginalFileResult(
          mockAssetEntity,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, equals(mockError));
        verify(
          () => mockPhotoService.getOriginalFileResult(mockAssetEntity),
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
        ).thenAnswer((_) async => []);

        // Act
        final result = await mockPhotoService.getTodayPhotos();

        // Assert
        expect(result, isEmpty);
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
        ).thenAnswer((_) async => []);

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle very large limits', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => []);

        // Act
        final result = await mockPhotoService.getTodayPhotos(limit: 999999);

        // Assert
        expect(result, isEmpty);
        verify(() => mockPhotoService.getTodayPhotos(limit: 999999)).called(1);
      });

      test('should handle zero limit', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => []);

        // Act
        final result = await mockPhotoService.getTodayPhotos(limit: 0);

        // Assert
        expect(result, isEmpty);
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
        ).thenAnswer((_) async => []);

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: futureDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isEmpty);
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
        ).thenAnswer((_) async => [mockAssetEntity]);

        // Act
        final result = await mockPhotoService.getPhotosInDateRange(
          startDate: sameDate,
          endDate: sameDate,
        );

        // Assert
        expect(result, isNotEmpty);
      });
    });

    // Result<T> Mock Tests - 新規追加
    group('Result<T> Mock Tests - Permission Methods', () {
      group('requestPermissionResult', () {
        test(
          'should return Success(true) when permission is granted',
          () async {
            // Arrange
            when(
              () => mockPhotoService.requestPermissionResult(),
            ).thenAnswer((_) async => const Success(true));

            // Act
            final result = await mockPhotoService.requestPermissionResult();

            // Assert
            expect(result, isA<Result<bool>>());
            expect(result.isSuccess, isTrue);
            expect(result.value, isTrue);
            verify(() => mockPhotoService.requestPermissionResult()).called(1);
          },
        );

        test(
          'should return Success(false) when permission is denied',
          () async {
            // Arrange
            when(
              () => mockPhotoService.requestPermissionResult(),
            ).thenAnswer((_) async => const Success(false));

            // Act
            final result = await mockPhotoService.requestPermissionResult();

            // Assert
            expect(result, isA<Result<bool>>());
            expect(result.isSuccess, isTrue);
            expect(result.value, isFalse);
            verify(() => mockPhotoService.requestPermissionResult()).called(1);
          },
        );

        test('should return Failure when permission request fails', () async {
          // Arrange
          final mockError = PhotoAccessException('権限リクエストに失敗しました');
          when(
            () => mockPhotoService.requestPermissionResult(),
          ).thenAnswer((_) async => Failure(mockError));

          // Act
          final result = await mockPhotoService.requestPermissionResult();

          // Assert
          expect(result, isA<Result<bool>>());
          expect(result.isFailure, isTrue);
          expect(result.error, equals(mockError));
          verify(() => mockPhotoService.requestPermissionResult()).called(1);
        });
      });

      group('isPermissionPermanentlyDeniedResult', () {
        test(
          'should return Success(true) when permission permanently denied',
          () async {
            // Arrange
            when(
              () => mockPhotoService.isPermissionPermanentlyDeniedResult(),
            ).thenAnswer((_) async => const Success(true));

            // Act
            final result = await mockPhotoService
                .isPermissionPermanentlyDeniedResult();

            // Assert
            expect(result, isA<Result<bool>>());
            expect(result.isSuccess, isTrue);
            expect(result.value, isTrue);
            verify(
              () => mockPhotoService.isPermissionPermanentlyDeniedResult(),
            ).called(1);
          },
        );

        test('should return Failure when check fails', () async {
          // Arrange
          final mockError = PhotoAccessException('権限確認に失敗しました');
          when(
            () => mockPhotoService.isPermissionPermanentlyDeniedResult(),
          ).thenAnswer((_) async => Failure(mockError));

          // Act
          final result = await mockPhotoService
              .isPermissionPermanentlyDeniedResult();

          // Assert
          expect(result, isA<Result<bool>>());
          expect(result.isFailure, isTrue);
          expect(result.error, equals(mockError));
        });
      });

      group('isLimitedAccessResult', () {
        test('should return Success(true) when access is limited', () async {
          // Arrange
          when(
            () => mockPhotoService.isLimitedAccessResult(),
          ).thenAnswer((_) async => const Success(true));

          // Act
          final result = await mockPhotoService.isLimitedAccessResult();

          // Assert
          expect(result, isA<Result<bool>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, isTrue);
          verify(() => mockPhotoService.isLimitedAccessResult()).called(1);
        });

        test('should return Failure when limited access check fails', () async {
          // Arrange
          final mockError = PhotoAccessException('Limited Access確認に失敗しました');
          when(
            () => mockPhotoService.isLimitedAccessResult(),
          ).thenAnswer((_) async => Failure(mockError));

          // Act
          final result = await mockPhotoService.isLimitedAccessResult();

          // Assert
          expect(result, isA<Result<bool>>());
          expect(result.isFailure, isTrue);
          expect(result.error, equals(mockError));
        });
      });

      group('presentLimitedLibraryPickerResult', () {
        test('should return Success(true) when picker succeeds', () async {
          // Arrange
          when(
            () => mockPhotoService.presentLimitedLibraryPickerResult(),
          ).thenAnswer((_) async => const Success(true));

          // Act
          final result = await mockPhotoService
              .presentLimitedLibraryPickerResult();

          // Assert
          expect(result, isA<Result<bool>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, isTrue);
          verify(
            () => mockPhotoService.presentLimitedLibraryPickerResult(),
          ).called(1);
        });

        test('should return Failure when picker fails', () async {
          // Arrange
          final mockError = PhotoAccessException(
            'Limited Library Picker表示に失敗しました',
          );
          when(
            () => mockPhotoService.presentLimitedLibraryPickerResult(),
          ).thenAnswer((_) async => Failure(mockError));

          // Act
          final result = await mockPhotoService
              .presentLimitedLibraryPickerResult();

          // Assert
          expect(result, isA<Result<bool>>());
          expect(result.isFailure, isTrue);
          expect(result.error, equals(mockError));
        });
      });
    });

    group('Result<T> Mock Tests - Photo Retrieval Methods', () {
      group('getTodayPhotosResult', () {
        test('should return Success with photos list', () async {
          // Arrange
          final mockPhotos = [mockAssetEntity, mockAssetEntity];
          when(
            () => mockPhotoService.getTodayPhotosResult(
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Success(mockPhotos));

          // Act
          final result = await mockPhotoService.getTodayPhotosResult(limit: 10);

          // Assert
          expect(result, isA<Result<List<AssetEntity>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockPhotos));
          expect(result.value.length, equals(2));
          verify(
            () => mockPhotoService.getTodayPhotosResult(limit: 10),
          ).called(1);
        });

        test(
          'should return Failure when today photos retrieval fails',
          () async {
            // Arrange
            final mockError = PhotoAccessException('今日の写真取得に失敗しました');
            when(
              () => mockPhotoService.getTodayPhotosResult(
                limit: any(named: 'limit'),
              ),
            ).thenAnswer((_) async => Failure(mockError));

            // Act
            final result = await mockPhotoService.getTodayPhotosResult(
              limit: 10,
            );

            // Assert
            expect(result, isA<Result<List<AssetEntity>>>());
            expect(result.isFailure, isTrue);
            expect(result.error, equals(mockError));
          },
        );
      });

      group('getPhotosInDateRangeResult', () {
        test('should return Success with photos in range', () async {
          // Arrange
          final startDate = DateTime(2024, 1, 1);
          final endDate = DateTime(2024, 1, 31);
          final mockPhotos = [mockAssetEntity];
          when(
            () => mockPhotoService.getPhotosInDateRangeResult(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Success(mockPhotos));

          // Act
          final result = await mockPhotoService.getPhotosInDateRangeResult(
            startDate: startDate,
            endDate: endDate,
            limit: 50,
          );

          // Assert
          expect(result, isA<Result<List<AssetEntity>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockPhotos));
          verify(
            () => mockPhotoService.getPhotosInDateRangeResult(
              startDate: startDate,
              endDate: endDate,
              limit: 50,
            ),
          ).called(1);
        });

        test(
          'should return Failure when date range photos retrieval fails',
          () async {
            // Arrange
            final startDate = DateTime(2024, 1, 1);
            final endDate = DateTime(2024, 1, 31);
            final mockError = PhotoAccessException('日付範囲写真取得に失敗しました');
            when(
              () => mockPhotoService.getPhotosInDateRangeResult(
                startDate: any(named: 'startDate'),
                endDate: any(named: 'endDate'),
                limit: any(named: 'limit'),
              ),
            ).thenAnswer((_) async => Failure(mockError));

            // Act
            final result = await mockPhotoService.getPhotosInDateRangeResult(
              startDate: startDate,
              endDate: endDate,
            );

            // Assert
            expect(result, isA<Result<List<AssetEntity>>>());
            expect(result.isFailure, isTrue);
            expect(result.error, equals(mockError));
          },
        );
      });

      group('getPhotosForDateResult', () {
        test('should return Success with photos for date', () async {
          // Arrange
          final testDate = DateTime(2024, 7, 25);
          final mockPhotos = [mockAssetEntity];
          when(
            () => mockPhotoService.getPhotosForDateResult(
              any(),
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Success(mockPhotos));

          // Act
          final result = await mockPhotoService.getPhotosForDateResult(
            testDate,
            offset: 0,
            limit: 10,
          );

          // Assert
          expect(result, isA<Result<List<AssetEntity>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockPhotos));
          verify(
            () => mockPhotoService.getPhotosForDateResult(
              testDate,
              offset: 0,
              limit: 10,
            ),
          ).called(1);
        });

        test(
          'should return Failure when date photos retrieval fails',
          () async {
            // Arrange
            final testDate = DateTime(2024, 7, 25);
            final mockError = PhotoAccessException('指定日写真取得に失敗しました');
            when(
              () => mockPhotoService.getPhotosForDateResult(
                any(),
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
              ),
            ).thenAnswer((_) async => Failure(mockError));

            // Act
            final result = await mockPhotoService.getPhotosForDateResult(
              testDate,
              offset: 0,
              limit: 10,
            );

            // Assert
            expect(result, isA<Result<List<AssetEntity>>>());
            expect(result.isFailure, isTrue);
            expect(result.error, equals(mockError));
          },
        );
      });

      group('getPhotosEfficientResult', () {
        test('should return Success with efficient photos', () async {
          // Arrange
          final mockPhotos = List.generate(30, (index) => mockAssetEntity);
          when(
            () => mockPhotoService.getPhotosEfficientResult(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => Success(mockPhotos));

          // Act
          final result = await mockPhotoService.getPhotosEfficientResult(
            offset: 0,
            limit: 30,
          );

          // Assert
          expect(result, isA<Result<List<AssetEntity>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockPhotos));
          expect(result.value.length, equals(30));
        });

        test(
          'should return Failure when efficient photos retrieval fails',
          () async {
            // Arrange
            final mockError = PhotoAccessException('効率的写真取得に失敗しました');
            when(
              () => mockPhotoService.getPhotosEfficientResult(
                startDate: any(named: 'startDate'),
                endDate: any(named: 'endDate'),
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
              ),
            ).thenAnswer((_) async => Failure(mockError));

            // Act
            final result = await mockPhotoService.getPhotosEfficientResult(
              offset: 0,
              limit: 30,
            );

            // Assert
            expect(result, isA<Result<List<AssetEntity>>>());
            expect(result.isFailure, isTrue);
            expect(result.error, equals(mockError));
          },
        );
      });
    });

    group('Result<T> Mock Tests - Data Access Methods', () {
      group('getPhotoDataResult', () {
        test('should return Success with photo data', () async {
          // Arrange
          final mockData = [1, 2, 3, 4, 5];
          when(
            () => mockPhotoService.getPhotoDataResult(any()),
          ).thenAnswer((_) async => Success(mockData));

          // Act
          final result = await mockPhotoService.getPhotoDataResult(
            mockAssetEntity,
          );

          // Assert
          expect(result, isA<Result<List<int>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockData));
          verify(
            () => mockPhotoService.getPhotoDataResult(mockAssetEntity),
          ).called(1);
        });

        test('should return Failure when photo data retrieval fails', () async {
          // Arrange
          final mockError = PhotoAccessException('写真データ取得に失敗しました');
          when(
            () => mockPhotoService.getPhotoDataResult(any()),
          ).thenAnswer((_) async => Failure(mockError));

          // Act
          final result = await mockPhotoService.getPhotoDataResult(
            mockAssetEntity,
          );

          // Assert
          expect(result, isA<Result<List<int>>>());
          expect(result.isFailure, isTrue);
          expect(result.error, equals(mockError));
        });
      });

      group('getThumbnailDataResult', () {
        test('should return Success with thumbnail data', () async {
          // Arrange
          final mockThumbnailData = [10, 20, 30, 40];
          when(
            () => mockPhotoService.getThumbnailDataResult(any()),
          ).thenAnswer((_) async => Success(mockThumbnailData));

          // Act
          final result = await mockPhotoService.getThumbnailDataResult(
            mockAssetEntity,
          );

          // Assert
          expect(result, isA<Result<List<int>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockThumbnailData));
          verify(
            () => mockPhotoService.getThumbnailDataResult(mockAssetEntity),
          ).called(1);
        });

        test(
          'should return Failure when thumbnail data retrieval fails',
          () async {
            // Arrange
            final mockError = PhotoAccessException('サムネイルデータ取得に失敗しました');
            when(
              () => mockPhotoService.getThumbnailDataResult(any()),
            ).thenAnswer((_) async => Failure(mockError));

            // Act
            final result = await mockPhotoService.getThumbnailDataResult(
              mockAssetEntity,
            );

            // Assert
            expect(result, isA<Result<List<int>>>());
            expect(result.isFailure, isTrue);
            expect(result.error, equals(mockError));
          },
        );
      });

      group('getThumbnailResult', () {
        test('should return Success with thumbnail', () async {
          // Arrange
          final mockThumbnail = Uint8List.fromList([1, 2, 3, 4, 5]);
          when(
            () => mockPhotoService.getThumbnailResult(
              any(),
              width: any(named: 'width'),
              height: any(named: 'height'),
            ),
          ).thenAnswer((_) async => Success(mockThumbnail));

          // Act
          final result = await mockPhotoService.getThumbnailResult(
            mockAssetEntity,
            width: 200,
            height: 200,
          );

          // Assert
          expect(result, isA<Result<Uint8List>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, equals(mockThumbnail));
          verify(
            () => mockPhotoService.getThumbnailResult(
              mockAssetEntity,
              width: 200,
              height: 200,
            ),
          ).called(1);
        });

        test('should return Failure when thumbnail retrieval fails', () async {
          // Arrange
          final mockError = PhotoAccessException('サムネイル取得に失敗しました');
          when(
            () => mockPhotoService.getThumbnailResult(
              any(),
              width: any(named: 'width'),
              height: any(named: 'height'),
            ),
          ).thenAnswer((_) async => Failure(mockError));

          // Act
          final result = await mockPhotoService.getThumbnailResult(
            mockAssetEntity,
            width: 300,
            height: 300,
          );

          // Assert
          expect(result, isA<Result<Uint8List>>());
          expect(result.isFailure, isTrue);
          expect(result.error, equals(mockError));
        });
      });

      // getOriginalFileResultのテストは既存なので維持
    });

    group('Interface Compliance', () {
      test('should implement PhotoServiceInterface', () {
        expect(mockPhotoService, isA<PhotoServiceInterface>());
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

      test('should have all Result<T> interface methods', () {
        expect(mockPhotoService.requestPermissionResult, isA<Function>());
        expect(mockPhotoService.getTodayPhotosResult, isA<Function>());
        expect(mockPhotoService.getPhotosInDateRangeResult, isA<Function>());
        expect(mockPhotoService.getPhotosForDateResult, isA<Function>());
        expect(mockPhotoService.getPhotosEfficientResult, isA<Function>());
        expect(mockPhotoService.getPhotoDataResult, isA<Function>());
        expect(mockPhotoService.getThumbnailDataResult, isA<Function>());
        expect(mockPhotoService.getOriginalFileResult, isA<Function>());
        expect(mockPhotoService.getThumbnailResult, isA<Function>());
        expect(
          mockPhotoService.presentLimitedLibraryPickerResult,
          isA<Function>(),
        );
        expect(mockPhotoService.isLimitedAccessResult, isA<Function>());
        expect(
          mockPhotoService.isPermissionPermanentlyDeniedResult,
          isA<Function>(),
        );
      });
    });

    group('Performance', () {
      test('should handle multiple concurrent requests', () async {
        // Arrange
        when(
          () => mockPhotoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => [mockAssetEntity]);

        // Act
        final futures = List.generate(
          5,
          (_) => mockPhotoService.getTodayPhotos(),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, equals([mockAssetEntity]));
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

    group('Edge Cases and Boundary Value Mock Tests', () {
      group('Basic Mock Tests', () {
        test('requestPermissionResult returns expected results', () async {
          when(
            () => mockPhotoService.requestPermissionResult(),
          ).thenAnswer((_) async => const Success(true));

          final result = await mockPhotoService.requestPermissionResult();

          expect(result, isA<Result<bool>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, isTrue);
        });

        test('getTodayPhotosResult handles empty list', () async {
          when(
            () => mockPhotoService.getTodayPhotosResult(
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => const Success(<AssetEntity>[]));

          final result = await mockPhotoService.getTodayPhotosResult(limit: 10);

          expect(result, isA<Result<List<AssetEntity>>>());
          expect(result.isSuccess, isTrue);
          expect(result.value, isEmpty);
        });
      });
    });
  });
}
