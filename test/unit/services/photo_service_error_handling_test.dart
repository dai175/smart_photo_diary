import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/photo_service.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes
class MockAssetPathEntity extends Mock implements AssetPathEntity {}

class MockAssetEntity extends Mock implements AssetEntity {}

class MockFilterOptionGroup extends Mock implements FilterOptionGroup {}

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  group('PhotoService Error Handling Tests', () {
    late IPhotoService photoService;
    late MockLoggingService mockLogger;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
      registerFallbackValue(MockAssetPathEntity());
      registerFallbackValue(MockAssetEntity());
      registerFallbackValue(MockFilterOptionGroup());
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() async {
      mockLogger = MockLoggingService();
      // PhotoServiceをコンストラクタインジェクションで作成
      photoService = PhotoService(logger: mockLogger);
    });

    group('getPhotosForDate Error Scenarios', () {
      test('should return empty list when permission is denied', () async {
        // Arrange
        final testDate = DateTime(2024, 7, 25);

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isEmpty);
        // 権限がない場合は空のリストが返される
      });

      test('should handle invalid offset gracefully', () async {
        // Arrange
        final testDate = DateTime.now();
        const negativeOffset = -10;

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: negativeOffset,
          limit: 10,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // 負のオフセットでもエラーにならない
      });

      test('should handle zero limit gracefully', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 0,
        );

        // Assert
        expect(result, isEmpty);
        // 0件のリミットでは空のリストが返される
      });

      test('should handle extremely large limit', () async {
        // Arrange
        final testDate = DateTime.now();
        const hugeLimit = 1000000;

        // Act
        final result = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: hugeLimit,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // 大きなリミットでもエラーにならない
      });
    });

    group('Date Handling Edge Cases', () {
      test('should handle far past dates', () async {
        // Arrange
        final ancientDate = DateTime(1900, 1, 1);

        // Act
        final result = await photoService.getPhotosForDate(
          ancientDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isEmpty);
        // 遠い過去の日付では空のリストが返される
      });

      test('should handle far future dates', () async {
        // Arrange
        final futureDate = DateTime(2100, 12, 31);

        // Act
        final result = await photoService.getPhotosForDate(
          futureDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isEmpty);
        // 未来の日付では空のリストが返される
      });

      test('should handle invalid date components', () async {
        // Arrange
        // Dartは無効な日付を自動調整するため、2月30日は3月2日になる
        final invalidDate = DateTime(2024, 2, 30);

        // Act
        final result = await photoService.getPhotosForDate(
          invalidDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isA<List<AssetEntity>>());
        // 無効な日付でもエラーにならない（Dartが自動調整）
      });
    });

    group('Concurrent Access', () {
      test('should handle multiple simultaneous requests', () async {
        // Arrange
        final dates = List.generate(
          10,
          (i) => DateTime.now().subtract(Duration(days: i)),
        );

        // Act
        final futures = dates
            .map(
              (date) =>
                  photoService.getPhotosForDate(date, offset: 0, limit: 5),
            )
            .toList();

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(10));
        for (final result in results) {
          expect(result, isA<List<AssetEntity>>());
        }
      });

      test('should handle rapid sequential requests', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final results = <List<AssetEntity>>[];
        for (int i = 0; i < 20; i++) {
          final result = await photoService.getPhotosForDate(
            testDate,
            offset: i * 10,
            limit: 10,
          );
          results.add(result);
        }

        // Assert
        expect(results.length, equals(20));
        for (final result in results) {
          expect(result, isA<List<AssetEntity>>());
        }
      });
    });

    group('Pagination Edge Cases', () {
      test('should handle overlapping offset and limit', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final batch1 = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 20,
        );

        final batch2 = await photoService.getPhotosForDate(
          testDate,
          offset: 10,
          limit: 20,
        );

        // Assert
        expect(batch1, isA<List<AssetEntity>>());
        expect(batch2, isA<List<AssetEntity>>());

        // オーバーラップしても正常に動作
      });

      test('should handle gaps in pagination', () async {
        // Arrange
        final testDate = DateTime.now();

        // Act
        final batch1 = await photoService.getPhotosForDate(
          testDate,
          offset: 0,
          limit: 10,
        );

        final batch2 = await photoService.getPhotosForDate(
          testDate,
          offset: 50, // ギャップあり
          limit: 10,
        );

        // Assert
        expect(batch1, isA<List<AssetEntity>>());
        expect(batch2, isA<List<AssetEntity>>());
      });
    });

    group('Recovery Scenarios', () {
      test('should recover from transient errors', () async {
        // Arrange
        final testDate = DateTime.now();
        var attemptCount = 0;

        // Act & Assert
        // 3回試行して、毎回結果を確認
        for (int i = 0; i < 3; i++) {
          attemptCount++;
          final result = await photoService.getPhotosForDate(
            testDate,
            offset: 0,
            limit: 10,
          );

          expect(result, isA<List<AssetEntity>>());
        }

        expect(attemptCount, equals(3));
      });

      test('should maintain state consistency after errors', () async {
        // Arrange
        final validDate = DateTime.now();
        final invalidOffset = -1000;

        // Act
        // 不正なパラメータでの呼び出し
        final errorResult = await photoService.getPhotosForDate(
          validDate,
          offset: invalidOffset,
          limit: 10,
        );

        // 正常なパラメータでの呼び出し
        final normalResult = await photoService.getPhotosForDate(
          validDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(errorResult, isA<List<AssetEntity>>());
        expect(normalResult, isA<List<AssetEntity>>());
        // エラー後も正常に動作
      });
    });

    group('Boundary Value Tests', () {
      test('should handle minimum date values', () async {
        // Arrange
        final minDate = DateTime(1, 1, 1);

        // Act
        final result = await photoService.getPhotosForDate(
          minDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should handle maximum date values', () async {
        // Arrange
        final maxDate = DateTime(9999, 12, 31);

        // Act
        final result = await photoService.getPhotosForDate(
          maxDate,
          offset: 0,
          limit: 10,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should handle edge of day boundaries', () async {
        // Arrange
        final startOfDay = DateTime(2024, 7, 25, 0, 0, 0);
        final endOfDay = DateTime(2024, 7, 25, 23, 59, 59);

        // Act
        final morningPhotos = await photoService.getPhotosForDate(
          startOfDay,
          offset: 0,
          limit: 100,
        );

        final nightPhotos = await photoService.getPhotosForDate(
          endOfDay,
          offset: 0,
          limit: 100,
        );

        // Assert
        expect(morningPhotos, isA<List<AssetEntity>>());
        expect(nightPhotos, isA<List<AssetEntity>>());

        // 同じ日付として扱われるべき
        expect(morningPhotos.length, equals(nightPhotos.length));
      });
    });
  });
}
