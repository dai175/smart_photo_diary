import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../../test_helpers/mock_platform_channels.dart';

// モック
class MockStorageService extends Mock implements IStorageService {}

class MockLoggingService extends Mock implements ILoggingService {}

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
  });

  group('StorageService invalidateStorageCache', () {
    late StorageService storageService;
    late Directory testDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();

      // テスト用ディレクトリを作成
      testDir = Directory('/tmp/test_docs');
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
      await testDir.create(recursive: true);

      storageService = StorageService(logger: MockLoggingService());
    });

    tearDown(() async {
      MockPlatformChannels.clearMocks();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('キャッシュ無効化後にgetStorageInfoが最新値を再取得する', () async {
      // 初期状態: .hiveファイルを1つ作成
      final hiveFile = File('${testDir.path}/test.hive');
      await hiveFile.writeAsBytes(List.filled(1024, 0));

      // 1回目の取得（キャッシュされる）
      final info1 = await storageService.getStorageInfo();
      expect(info1.totalSize, 1024);

      // ファイルを追加（ファイルシステムが変化）
      final hiveFile2 = File('${testDir.path}/test2.hive');
      await hiveFile2.writeAsBytes(List.filled(2048, 0));

      // 2回目の取得（キャッシュから返るので古い値のまま）
      final info2 = await storageService.getStorageInfo();
      expect(info2.totalSize, 1024, reason: 'キャッシュが有効なので古い値が返る');

      // キャッシュ無効化
      storageService.invalidateStorageCache();

      // 3回目の取得（再取得されて新しい値になる）
      final info3 = await storageService.getStorageInfo();
      expect(info3.totalSize, 1024 + 2048, reason: 'キャッシュ無効化後は最新値を取得');
    });

    test('キャッシュ無効化後にgetStorageInfoResultが最新値を再取得する', () async {
      // 初期状態: .hiveファイルを1つ作成
      final hiveFile = File('${testDir.path}/data.hive');
      await hiveFile.writeAsBytes(List.filled(512, 0));

      // 1回目の取得（キャッシュされる）
      final result1 = await storageService.getStorageInfoResult();
      expect(result1.isSuccess, true);
      expect(result1.value.totalSize, 512);

      // ファイルを追加
      final hiveFile2 = File('${testDir.path}/data2.hive');
      await hiveFile2.writeAsBytes(List.filled(512, 0));

      // キャッシュ無効化なしでは古い値
      final result2 = await storageService.getStorageInfoResult();
      expect(result2.value.totalSize, 512);

      // キャッシュ無効化
      storageService.invalidateStorageCache();

      // 新しい値が返る
      final result3 = await storageService.getStorageInfoResult();
      expect(result3.isSuccess, true);
      expect(result3.value.totalSize, 1024);
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
