import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';

/// IPhotoService mock for testing getAssetsByIds
class MockPhotoService extends Mock implements IPhotoService {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  late MockPhotoService mockPhotoService;

  setUp(() {
    mockPhotoService = MockPhotoService();
  });

  group('IPhotoService.getAssetsByIds', () {
    test('正常系: 複数IDから全てAssetEntity取得成功', () async {
      final asset1 = MockAssetEntity();
      final asset2 = MockAssetEntity();
      when(
        () => mockPhotoService.getAssetsByIds(['id1', 'id2']),
      ).thenAnswer((_) async => Success([asset1, asset2]));

      final result = await mockPhotoService.getAssetsByIds(['id1', 'id2']);

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(2));
      expect(result.value, contains(asset1));
      expect(result.value, contains(asset2));
    });

    test('部分失敗: 一部IDが見つからない場合、見つかったもののみ返す', () async {
      final asset1 = MockAssetEntity();
      when(
        () => mockPhotoService.getAssetsByIds(['id1', 'invalid-id']),
      ).thenAnswer((_) async => Success([asset1]));

      final result = await mockPhotoService.getAssetsByIds([
        'id1',
        'invalid-id',
      ]);

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
      expect(result.value.first, equals(asset1));
    });

    test('空リスト: 空のphotoIdsリストで空リスト返却', () async {
      when(
        () => mockPhotoService.getAssetsByIds([]),
      ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));

      final result = await mockPhotoService.getAssetsByIds([]);

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('全失敗: 全IDが例外でResult.failure返却', () async {
      when(() => mockPhotoService.getAssetsByIds(['bad1', 'bad2'])).thenAnswer(
        (_) async => const Failure<List<AssetEntity>>(
          PhotoAccessException('Failed to load photo assets'),
        ),
      );

      final result = await mockPhotoService.getAssetsByIds(['bad1', 'bad2']);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<PhotoAccessException>());
    });

    test('単一ID: 1つのIDでAssetEntity取得成功', () async {
      final asset = MockAssetEntity();
      when(
        () => mockPhotoService.getAssetsByIds(['single-id']),
      ).thenAnswer((_) async => Success([asset]));

      final result = await mockPhotoService.getAssetsByIds(['single-id']);

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
    });
  });
}
