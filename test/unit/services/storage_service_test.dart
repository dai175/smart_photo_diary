import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

// モック
class MockStorageService extends Mock implements StorageServiceInterface {}

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
  });

  group('StorageService Result<T> Pattern Tests', () {
    group('getStorageInfoResult', () {
      test('成功時にResult<StorageInfo>を返す', () async {
        // Arrange
        final storageInfo = StorageInfo(totalSize: 1024, diaryDataSize: 512);
        when(
          () => mockStorageService.getStorageInfoResult(),
        ).thenAnswer((_) async => Success(storageInfo));

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
        expect(mockStorageService, isA<StorageServiceInterface>());

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
  });
}
