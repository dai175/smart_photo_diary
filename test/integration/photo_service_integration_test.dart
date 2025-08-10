import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/photo_service.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

void main() {
  group('PhotoService Integration Tests', () {
    late PhotoServiceInterface photoService;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    setUp(() async {
      // Initialize PhotoService with real implementation
      photoService = PhotoService.getInstance();
    });

    group('getPhotosForDate - Real Implementation', () {
      test('should handle date filtering correctly', () async {
        // Arrange
        final testDate = DateTime.now();
        const offset = 0;
        const limit = 10;

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: offset,
          limit: limit,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // 実際の写真が存在するかはデバイスに依存するため、型チェックのみ
      });

      test('should respect pagination parameters', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act - 最初の5枚を取得
        final firstBatch = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 5,
        );

        // 次の5枚を取得
        final secondBatch = await photoService.getPhotosForDate(
          testDate,
          offset: 5,
          limit: 5,
        );

        // Assert
        expect(firstBatch, isA<List<AssetEntity>>());
        expect(secondBatch, isA<List<AssetEntity>>());

        // 両バッチに同じ写真が含まれていないことを確認
        if (firstBatch.isNotEmpty && secondBatch.isNotEmpty) {
          final firstIds = firstBatch.map((e) => e.id).toSet();
          final secondIds = secondBatch.map((e) => e.id).toSet();
          expect(firstIds.intersection(secondIds), isEmpty);
        }
      });

      test('should handle empty results gracefully', () async {
        // Arrange - 遠い過去の日付を使用
        final oldDate = DateTime(1990, 1, 1);

        // Act
        final result = await photoService.getPhotosForDate(
          oldDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result, isEmpty);
      });

      test('should filter photos by exact date', () async {
        // Arrange
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final today = DateTime.now();

        // Act
        final yesterdayPhotos = await photoService.getPhotosForDate(
          yesterday,
          offset: 0,
          limit: 100,
        );

        final todayPhotos = await photoService.getPhotosForDate(
          today,
          offset: 0,
          limit: 100,
        );

        // Assert
        expect(yesterdayPhotos, isA<List<AssetEntity>>());
        expect(todayPhotos, isA<List<AssetEntity>>());

        // 異なる日付の写真が混在していないことを確認
        for (final photo in yesterdayPhotos) {
          final createDate = photo.createDateSecond;
          if (createDate != null) {
            final photoDate = DateTime.fromMillisecondsSinceEpoch(
              createDate * 1000,
            );
            expect(photoDate.year, equals(yesterday.year));
            expect(photoDate.month, equals(yesterday.month));
            expect(photoDate.day, equals(yesterday.day));
          }
        }
      });

      test('should handle timezone correctly', () async {
        // Arrange
        final testDate = DateTime(2024, 7, 25, 23, 59, 59); // 深夜近く

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 50,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());

        // 取得した写真が正しい日付であることを確認
        for (final photo in result) {
          final createDate = photo.createDateSecond;
          if (createDate != null) {
            final photoDate = DateTime.fromMillisecondsSinceEpoch(
              createDate * 1000,
            );
            // 日付部分のみ比較（時刻は無視）
            expect(photoDate.year, equals(testDate.year));
            expect(photoDate.month, equals(testDate.month));
            expect(photoDate.day, equals(testDate.day));
          }
        }
      });

      test('should handle large offset correctly', () async {
        // Arrange
        final testDate = DateTime.now();
        const largeOffset = 10000;
        const limit = 10;

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: largeOffset,
          limit: limit,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result, isEmpty); // 大きなオフセットでは結果が空になるはず
      });
    });

    group('Error Handling', () {
      test('should handle permission denied gracefully', () async {
        // Note: 実際の権限テストは難しいため、結果の型チェックのみ
        final testDate = DateTime.now();

        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 10,
        );

        expect(result, isA<List<AssetEntity>>());
        // 権限がない場合は空のリストが返される
      });

      test('should handle invalid date gracefully', () async {
        // Arrange - 未来の日付
        final futureDate = DateTime.now().add(const Duration(days: 365));

        // Act
        final result = await photoService.getPhotosForDate(
          futureDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        expect(result, isEmpty); // 未来の写真は存在しないはず
      });

      test('should handle concurrent requests', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act - 複数の同時リクエスト
        final futures = List.generate(5, (index) {
          return photoService.getPhotosForDate(
            testDate,
            offset: index * 10,
            limit: 10,
          );
        });

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isA<List<AssetEntity>>());
        }
      });
    });

    group('Performance', () {
      test('should retrieve photos efficiently', () async {
        // Arrange
        final testDate = DateTime.now();
        final stopwatch = Stopwatch()..start();

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 50,
        );

        stopwatch.stop();

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // パフォーマンス: 50枚の取得は5秒以内に完了すべき
        expect(stopwatch.elapsed.inSeconds, lessThan(5));
      });

      test('should handle memory efficiently with large batches', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act - 大量の写真を段階的に取得
        const batchSize = 100;
        const batches = 5;

        for (int i = 0; i < batches; i++) {
          final result = await photoService.getPhotosForDate(
            testDate,
            offset: i * batchSize,
            limit: batchSize,
          );

          // Assert
          expect(result, isA<List<AssetEntity>>());
          expect(result.length, lessThanOrEqualTo(batchSize));
        }

        // メモリリークがないことを間接的に確認
        // （実際のメモリ使用量測定は難しいため、エラーなく完了することを確認）
      });
    });

    group('Edge Cases', () {
      test('should handle leap year dates correctly', () async {
        // Arrange
        final leapYearDate = DateTime(2024, 2, 29);

        // Act
        final result = await photoService.getPhotosForDate(
          leapYearDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // うるう年の2月29日でもエラーにならないことを確認
      });

      test('should handle year boundary correctly', () async {
        // Arrange
        final newYearEve = DateTime(2023, 12, 31);
        final newYear = DateTime(2024, 1, 1);

        // Act
        final evePhotos = await photoService.getPhotosForDate(
          newYearEve,
          offset: 0,
          limit: 10,
        );

        final newYearPhotos = await photoService.getPhotosForDate(
          newYear,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(evePhotos, isA<List<AssetEntity>>());
        expect(newYearPhotos, isA<List<AssetEntity>>());

        // 異なる年の写真が正しく分離されることを確認
        if (evePhotos.isNotEmpty && newYearPhotos.isNotEmpty) {
          final eveIds = evePhotos.map((e) => e.id).toSet();
          final newYearIds = newYearPhotos.map((e) => e.id).toSet();
          expect(eveIds.intersection(newYearIds), isEmpty);
        }
      });

      test('should handle photos without EXIF data', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 100,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // EXIF情報がない写真も含めて処理できることを確認
        // （エラーが発生せずに完了することを確認）
      });

      test('should handle different photo types', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 100,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());

        // 異なるタイプの写真（JPEG、PNG、HEIF等）が混在していても処理できることを確認
        for (final photo in result) {
          expect(
            photo.type,
            anyOf([
              AssetType.image,
              AssetType.video,
              AssetType.audio,
              AssetType.other,
            ]),
          );
        }
      });
    });

    group('Result<T> Pattern Integration Tests', () {
      test('requestPermissionResult should integrate with real permission system', () async {
        // Act
        final result = await photoService.requestPermissionResult();

        // Assert
        expect(result, isA<Result<bool>>());
        result.fold(
          (granted) {
            expect(granted, isA<bool>());
            // 権限の状態は実行環境に依存するため、型チェックのみ
          },
          (error) {
            expect(error, isA<AppException>());
          },
        );
      });

      test('getTodayPhotosResult should integrate with real photo library', () async {
        // Act
        final result = await photoService.getTodayPhotosResult(limit: 10);

        // Assert
        expect(result, isA<Result<List<AssetEntity>>>());
        result.fold(
          (photos) {
            expect(photos, isA<List<AssetEntity>>());
            expect(photos.length, lessThanOrEqualTo(10));
          },
          (error) {
            expect(error, isA<AppException>());
            // 権限がない場合はエラーが返される可能性がある
          },
        );
      });

      test('getPhotosForDateResult should handle Result<T> pattern correctly', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final result = await photoService.getPhotosForDateResult(
          testDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isA<Result<List<AssetEntity>>>());
        result.fold(
          (photos) {
            expect(photos, isA<List<AssetEntity>>());
            expect(photos.length, lessThanOrEqualTo(10));
          },
          (error) {
            expect(error, isA<AppException>());
          },
        );
      });

      test('getPhotosEfficientResult should integrate with pagination', () async {
        // Act - First page
        final firstPageResult = await photoService.getPhotosEfficientResult(
          offset: 0,
          limit: 5,
        );

        // Second page  
        final secondPageResult = await photoService.getPhotosEfficientResult(
          offset: 5,
          limit: 5,
        );

        // Assert
        expect(firstPageResult, isA<Result<List<AssetEntity>>>());
        expect(secondPageResult, isA<Result<List<AssetEntity>>>());

        firstPageResult.fold(
          (firstPhotos) {
            expect(firstPhotos, isA<List<AssetEntity>>());
            
            secondPageResult.fold(
              (secondPhotos) {
                expect(secondPhotos, isA<List<AssetEntity>>());
                
                // ページネーションが正しく動作することを確認
                if (firstPhotos.isNotEmpty && secondPhotos.isNotEmpty) {
                  final firstIds = firstPhotos.map((e) => e.id).toSet();
                  final secondIds = secondPhotos.map((e) => e.id).toSet();
                  expect(firstIds.intersection(secondIds), isEmpty);
                }
              },
              (error) {
                // 2ページ目でエラーが発生する可能性もある（写真数が少ない場合）
                expect(error, isA<AppException>());
              },
            );
          },
          (error) {
            expect(error, isA<AppException>());
          },
        );
      });

      test('isPermissionPermanentlyDeniedResult should check real permission state', () async {
        // Act
        final result = await photoService.isPermissionPermanentlyDeniedResult();

        // Assert
        expect(result, isA<Result<bool>>());
        result.fold(
          (isPermanentlyDenied) {
            expect(isPermanentlyDenied, isA<bool>());
          },
          (error) {
            expect(error, isA<AppException>());
          },
        );
      });

      test('Result<T> error handling should propagate correctly', () async {
        // Arrange - 過去の日付で権限エラーが発生する可能性をテスト
        final oldDate = DateTime(1990, 1, 1);

        // Act
        final result = await photoService.getPhotosForDateResult(
          oldDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isA<Result<List<AssetEntity>>>());
        // 古い日付でも正常に処理されることを確認
        result.fold(
          (photos) {
            expect(photos, isA<List<AssetEntity>>());
            // 古い日付では写真は空のリストになるはず
            expect(photos, isEmpty);
          },
          (error) {
            // エラーが発生した場合も適切な例外型であることを確認
            expect(error, isA<AppException>());
          },
        );
      });
    });

    group('End-to-End Result<T> Integration', () {
      test('should handle full Result<T> flow from permission to photo retrieval', () async {
        // Step 1: Check permission
        final permissionResult = await photoService.requestPermissionResult();
        
        await permissionResult.fold(
          (granted) async {
            if (granted) {
              // Step 2: Get today's photos if permission is granted
              final photosResult = await photoService.getTodayPhotosResult(limit: 5);
              
              await photosResult.fold(
                (photos) async {
                  expect(photos, isA<List<AssetEntity>>());
                  
                  // Step 3: Try to get photo data if photos exist
                  if (photos.isNotEmpty) {
                    final firstPhoto = photos.first;
                    final photoDataResult = await photoService.getPhotoDataResult(firstPhoto);
                    
                    photoDataResult.fold(
                      (data) {
                        expect(data, isA<List<int>>());
                        expect(data, isNotEmpty);
                      },
                      (error) {
                        expect(error, isA<AppException>());
                      },
                    );
                  }
                },
                (error) {
                  expect(error, isA<AppException>());
                },
              );
            } else {
              // Permission denied - this is also a valid state
              expect(granted, isFalse);
            }
          },
          (error) {
            expect(error, isA<AppException>());
          },
        );
      });

      test('should handle concurrent Result<T> requests properly', () async {
        // Arrange
        final futures = List.generate(3, (index) {
          return photoService.requestPermissionResult();
        });

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isA<Result<bool>>());
          result.fold(
            (granted) => expect(granted, isA<bool>()),
            (error) => expect(error, isA<AppException>()),
          );
        }

        // All results should be consistent
        bool? firstResult;
        for (final result in results) {
          result.fold(
            (granted) {
              firstResult ??= granted;
              expect(granted, equals(firstResult));
            },
            (error) {
              // If error occurred, it should be consistent
              expect(error, isA<AppException>());
            },
          );
        }
      });
    });
  });
}
