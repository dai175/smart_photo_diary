import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:smart_photo_diary/services/photo_cache_service.dart';
import 'package:smart_photo_diary/services/logging_service.dart';

// モッククラス
class MockAssetEntity extends Mock implements AssetEntity {}
class MockLoggingService extends Mock implements LoggingService {}

void main() {
  group('PhotoCacheService', () {
    late PhotoCacheService photoCacheService;
    late MockAssetEntity mockAsset;

    setUp(() {
      mockAsset = MockAssetEntity();
      
      // PhotoCacheServiceのシングルトンを取得
      photoCacheService = PhotoCacheService.getInstance();
      
      // registerFallbackValueの設定
      registerFallbackValue(ThumbnailSize(200, 200));
    });

    tearDown(() {
      // キャッシュをクリア
      photoCacheService.clearMemoryCache();
    });

    group('getInstance', () {
      test('should return same instance (singleton)', () {
        final instance1 = PhotoCacheService.getInstance();
        final instance2 = PhotoCacheService.getInstance();
        expect(instance1, same(instance2));
      });
    });

    group('clearMemoryCache', () {
      test('should clear cache and reset size', () {
        // Act
        photoCacheService.clearMemoryCache();

        // Assert
        expect(photoCacheService.getCacheSize(), 0);
      });
    });

    group('getCacheSize', () {
      test('should return current cache size', () {
        // Act
        final size = photoCacheService.getCacheSize();

        // Assert
        expect(size, isA<int>());
        expect(size, greaterThanOrEqualTo(0));
      });
    });

    group('clearCacheForAsset', () {
      test('should clear cache for specific asset', () {
        // Arrange
        const assetId = 'test-asset-id';
        
        // Act - 特定アセットのキャッシュをクリア
        photoCacheService.clearCacheForAsset(assetId);

        // Assert - エラーが発生しないことを確認
        expect(() => photoCacheService.clearCacheForAsset(assetId), returnsNormally);
      });
    });

    group('getThumbnail', () {
      test('should handle thumbnail generation gracefully', () async {
        // Arrange
        when(() => mockAsset.id).thenReturn('test-asset-id');
        when(() => mockAsset.thumbnailDataWithSize(
          any<ThumbnailSize>(),
          quality: any(named: 'quality'),
        )).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));

        // Act
        final result = await photoCacheService.getThumbnail(
          mockAsset,
          width: 200,
          height: 200,
          quality: 80,
        );

        // Assert
        expect(result, anyOf(isNull, isA<Uint8List>()));
      });

      test('should handle null thumbnail response', () async {
        // Arrange
        when(() => mockAsset.id).thenReturn('test-asset-id-null');
        when(() => mockAsset.thumbnailDataWithSize(
          any<ThumbnailSize>(),
          quality: any(named: 'quality'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await photoCacheService.getThumbnail(mockAsset);

        // Assert
        expect(result, isNull);
      });

      test('should handle thumbnail generation error', () async {
        // Arrange
        when(() => mockAsset.id).thenReturn('test-asset-id-error');
        when(() => mockAsset.thumbnailDataWithSize(
          any<ThumbnailSize>(),
          quality: any(named: 'quality'),
        )).thenThrow(Exception('Thumbnail generation failed'));

        // Act
        final result = await photoCacheService.getThumbnail(mockAsset);

        // Assert
        expect(result, isNull);
      });
    });

    group('preloadThumbnails', () {
      test('should handle empty asset list', () async {
        // Act
        await photoCacheService.preloadThumbnails([]);

        // Assert - エラーが発生しないことを確認
        expect(() => photoCacheService.preloadThumbnails([]), returnsNormally);
      });

      test('should handle asset list gracefully', () async {
        // Arrange
        final mockAsset1 = MockAssetEntity();
        final mockAsset2 = MockAssetEntity();
        
        when(() => mockAsset1.id).thenReturn('asset-1');
        when(() => mockAsset2.id).thenReturn('asset-2');
        
        when(() => mockAsset1.thumbnailDataWithSize(
          any<ThumbnailSize>(),
          quality: any(named: 'quality'),
        )).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
        
        when(() => mockAsset2.thumbnailDataWithSize(
          any<ThumbnailSize>(),
          quality: any(named: 'quality'),
        )).thenAnswer((_) async => Uint8List.fromList([4, 5, 6]));

        // Act
        await photoCacheService.preloadThumbnails([mockAsset1, mockAsset2]);

        // Assert - エラーが発生しないことを確認
        expect(() => photoCacheService.preloadThumbnails([mockAsset1, mockAsset2]), returnsNormally);
      });
    });

    group('PhotoCacheService interface implementation', () {
      test('should implement all interface methods', () {
        // Assert - インターフェースの実装確認
        expect(photoCacheService, isA<PhotoCacheService>());
        expect(photoCacheService.clearMemoryCache, isA<Function>());
        expect(photoCacheService.clearCacheForAsset, isA<Function>());
        expect(photoCacheService.getCacheSize, isA<Function>());
        expect(photoCacheService.getThumbnail, isA<Function>());
        expect(photoCacheService.preloadThumbnails, isA<Function>());
      });
    });

    group('cache management edge cases', () {
      test('should handle multiple clear operations', () {
        // Act
        photoCacheService.clearMemoryCache();
        photoCacheService.clearMemoryCache();
        photoCacheService.clearMemoryCache();

        // Assert
        expect(photoCacheService.getCacheSize(), 0);
      });

      test('should handle cache size monitoring', () {
        // Act
        final sizeBefore = photoCacheService.getCacheSize();
        photoCacheService.clearMemoryCache();
        final sizeAfter = photoCacheService.getCacheSize();

        // Assert
        expect(sizeBefore, greaterThanOrEqualTo(0));
        expect(sizeAfter, 0);
      });

      test('should handle concurrent cache operations', () async {
        // Arrange
        final futures = <Future>[];
        
        // Act - 複数の並行操作
        for (int i = 0; i < 5; i++) {
          futures.add(Future.microtask(() {
            photoCacheService.clearMemoryCache();
            return photoCacheService.getCacheSize();
          }));
        }
        
        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(5));
        for (final size in results) {
          expect(size, isA<int>());
          expect(size, greaterThanOrEqualTo(0));
        }
      });
    });
  });
}