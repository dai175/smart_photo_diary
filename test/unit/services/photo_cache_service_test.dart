import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/photo_cache_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late PhotoCacheService cacheService;
  late MockLoggingService mockLogger;

  setUp(() {
    mockLogger = MockLoggingService();
    cacheService = PhotoCacheService(logger: mockLogger);
  });

  group('PhotoCacheService', () {
    test('implements IPhotoCacheService', () {
      expect(cacheService, isA<IPhotoCacheService>());
    });

    test('初期状態でキャッシュサイズが0', () {
      expect(cacheService.getCacheSize(), equals(0));
    });

    test('clearMemoryCache() はエラーなく実行できキャッシュサイズが0になる', () {
      cacheService.clearMemoryCache();

      expect(cacheService.getCacheSize(), equals(0));
      verify(
        () => mockLogger.info(
          any(that: contains('クリア')),
          context: any(named: 'context'),
        ),
      ).called(1);
    });

    test('clearCacheForAsset() はエラーなく実行できる', () {
      cacheService.clearCacheForAsset('non-existent-asset-id');

      verify(
        () => mockLogger.info(
          any(that: contains('non-existent-asset-id')),
          context: any(named: 'context'),
        ),
      ).called(1);
    });

    test('clearCacheForAsset() はキャッシュが空でもエラーにならない', () {
      expect(
        () => cacheService.clearCacheForAsset('test-asset'),
        returnsNormally,
      );
    });

    test('getCacheSize() は初期状態で0を返す', () {
      final size = cacheService.getCacheSize();

      expect(size, isA<int>());
      expect(size, equals(0));
    });

    test('cleanupExpiredEntries() はキャッシュが空でもエラーにならない', () {
      expect(() => cacheService.cleanupExpiredEntries(), returnsNormally);
    });

    test('cleanupExpiredEntries() は空キャッシュでログを出力しない', () {
      cacheService.cleanupExpiredEntries();

      // 期限切れエントリーがないのでinfoログは呼ばれない
      verifyNever(
        () => mockLogger.info(
          any(that: contains('期限切れ')),
          context: any(named: 'context'),
        ),
      );
    });

    test('clearMemoryCache() を複数回呼んでもエラーにならない', () {
      cacheService.clearMemoryCache();
      cacheService.clearMemoryCache();
      cacheService.clearMemoryCache();

      expect(cacheService.getCacheSize(), equals(0));
    });
  });
}
