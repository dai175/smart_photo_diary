import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

// モック
class MockStorageService extends Mock implements IStorageService {}

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
  });

  group('StorageService Result<T> Pattern Tests', () {
    group('getStorageInfoResult', () {
      test('成功時にResult<StorageInfo>を返す', () async {
        // Arrange
        const storageInfo = StorageInfo(totalSize: 1024, diaryDataSize: 512);
        when(
          () => mockStorageService.getStorageInfoResult(),
        ).thenAnswer((_) async => const Success(storageInfo));

        // Act
        final result = await mockStorageService.getStorageInfoResult();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.totalSize, 1024);
        expect(result.value.diaryDataSize, 512);
      });

      test('失敗時にResult<StorageInfo>を返す', () async {
        // Arrange
        when(() => mockStorageService.getStorageInfoResult()).thenAnswer(
          (_) async => const Failure(ServiceException('ストレージ情報取得エラー')),
        );

        // Act
        final result = await mockStorageService.getStorageInfoResult();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, 'ストレージ情報取得エラー');
      });
    });

    group('exportDataResult', () {
      test('成功時にResult<String?>を返す', () async {
        // Arrange
        const filePath = '/path/to/export.json';
        when(
          () => mockStorageService.exportDataResult(),
        ).thenAnswer((_) async => const Success(filePath));

        // Act
        final result = await mockStorageService.exportDataResult();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, filePath);
      });

      test('キャンセル時にnullを返す', () async {
        // Arrange
        when(
          () => mockStorageService.exportDataResult(),
        ).thenAnswer((_) async => const Success(null));

        // Act
        final result = await mockStorageService.exportDataResult();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, null);
      });

      test('失敗時にResult<String?>を返す', () async {
        // Arrange
        when(
          () => mockStorageService.exportDataResult(),
        ).thenAnswer((_) async => const Failure(ServiceException('エクスポートエラー')));

        // Act
        final result = await mockStorageService.exportDataResult();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, 'エクスポートエラー');
      });
    });

    group('optimizeDatabaseResult', () {
      test('成功時にResult<bool>を返す', () async {
        // Arrange
        when(
          () => mockStorageService.optimizeDatabaseResult(),
        ).thenAnswer((_) async => const Success(true));

        // Act
        final result = await mockStorageService.optimizeDatabaseResult();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('失敗時にResult<bool>を返す', () async {
        // Arrange
        when(
          () => mockStorageService.optimizeDatabaseResult(),
        ).thenAnswer((_) async => const Failure(ServiceException('最適化エラー')));

        // Act
        final result = await mockStorageService.optimizeDatabaseResult();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, '最適化エラー');
      });
    });

    group('インターフェース互換性テスト', () {
      test('新旧メソッドが正しく実装されている', () {
        // Arrange & Act & Assert
        expect(mockStorageService, isA<IStorageService>());

        // モックが作成された後、何も呼び出されていないことを確認
        verifyNever(() => mockStorageService.getStorageInfo());
        verifyNever(() => mockStorageService.exportData());
        verifyNever(() => mockStorageService.optimizeDatabase());

        // 新メソッド（Result版）
        verifyNever(() => mockStorageService.getStorageInfoResult());
        verifyNever(() => mockStorageService.exportDataResult());
        verifyNever(() => mockStorageService.optimizeDatabaseResult());
      });
    });

    group('invalidateStorageCache', () {
      test('キャッシュ無効化後にgetStorageInfoResultが再取得する', () async {
        const info1 = StorageInfo(totalSize: 1024, diaryDataSize: 512);
        const info2 = StorageInfo(totalSize: 2048, diaryDataSize: 1024);

        var callCount = 0;
        when(() => mockStorageService.getStorageInfoResult()).thenAnswer((
          _,
        ) async {
          callCount++;
          return callCount == 1 ? const Success(info1) : const Success(info2);
        });
        when(
          () => mockStorageService.invalidateStorageCache(),
        ).thenReturn(null);

        // 1回目の取得
        final result1 = await mockStorageService.getStorageInfoResult();
        expect(result1.value.totalSize, 1024);

        // キャッシュ無効化
        mockStorageService.invalidateStorageCache();

        // 2回目の取得（再取得されるべき）
        final result2 = await mockStorageService.getStorageInfoResult();
        expect(result2.value.totalSize, 2048);

        verify(() => mockStorageService.getStorageInfoResult()).called(2);
        verify(() => mockStorageService.invalidateStorageCache()).called(1);
      });
    });
  });

  group('StorageInfo', () {
    test('フォーマットされたサイズ文字列を返す', () {
      const info = StorageInfo(totalSize: 1536, diaryDataSize: 1536);
      expect(info.formattedTotalSize, '1.5KB');
      expect(info.formattedDiaryDataSize, '1.5KB');
    });

    test('バイト単位のサイズ文字列を返す', () {
      const info = StorageInfo(totalSize: 512, diaryDataSize: 512);
      expect(info.formattedTotalSize, '512B');
    });

    test('MB単位のサイズ文字列を返す', () {
      const info = StorageInfo(
        totalSize: 1024 * 1024 * 2,
        diaryDataSize: 1024 * 1024 * 2,
      );
      expect(info.formattedTotalSize, '2.0MB');
    });
  });
}
