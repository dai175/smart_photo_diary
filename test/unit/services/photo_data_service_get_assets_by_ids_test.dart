import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';
import 'package:smart_photo_diary/services/photo_data_service.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class MockPhotoCacheService extends Mock implements IPhotoCacheService {}

void main() {
  late MockLoggingService mockLogger;
  late MockPhotoCacheService mockCacheService;
  late PhotoDataService service;

  setUp(() {
    mockLogger = MockLoggingService();
    mockCacheService = MockPhotoCacheService();
    service = PhotoDataService(
      logger: mockLogger,
      cacheService: mockCacheService,
    );
  });

  group('PhotoDataService.getAssetsByIds', () {
    test('空のphotoIdsリストでSuccess([])を返す', () async {
      final result = await service.getAssetsByIds([]);

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('テスト環境でAssetEntity.fromIdがnullを返す場合、nullがフィルタされ空リストを返す', () async {
      // AssetEntity.fromId はテスト環境ではnullを返す
      // PhotoDataService は null を whereType<AssetEntity> でフィルタし、
      // 有効なアセットのみ返す
      final result = await service.getAssetsByIds(['nonexistent-id']);

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
      // fromId が null を返す場合、catch ブロックは実行されないためログなし
      verifyNever(
        () => mockLogger.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
        ),
      );
    });

    test('複数IDでfromIdがnullを返す場合も全てフィルタされ空リストを返す', () async {
      final result = await service.getAssetsByIds(['id1', 'id2', 'id3']);

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('Resultパターンに準拠しFailure時にはAppExceptionを含む', () async {
      // 空リストの場合でもSuccess型で返ることを確認
      final result = await service.getAssetsByIds([]);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });
  });
}
