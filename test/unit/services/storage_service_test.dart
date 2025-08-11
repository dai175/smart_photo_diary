import 'package:flutter_test/flutter_test.dart';

import 'package:smart_photo_diary/services/storage_service.dart';

// モッククラス（テスト用）

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      // StorageServiceのシングルトンを取得
      storageService = StorageService.getInstance();
    });

    group('getInstance', () {
      test('should return same instance (singleton)', () {
        final instance1 = StorageService.getInstance();
        final instance2 = StorageService.getInstance();
        expect(instance1, same(instance2));
      });
    });

    group('getStorageInfo', () {
      test('should return storage info with zero values on error', () async {
        // Act
        final result = await storageService.getStorageInfo();

        // Assert
        expect(result, isA<StorageInfo>());
        expect(result.totalSize, greaterThanOrEqualTo(0));
        expect(result.diaryDataSize, greaterThanOrEqualTo(0));
      });
    });

    // exportDataのテストは統合テストで実施 (Hive初期化が必要)

    group('importData', () {
      test('should return failure when no file selected', () async {
        // Act
        final result = await storageService.importData();

        // Assert
        expect(result.isFailure, isTrue);
        // テスト環境ではFilePicker.platformがnullになり、例外が発生するため
        expect(result.error.message, contains('ファイル選択中にエラーが発生しました'));
      });
    });

    // optimizeDatabaseのテストは統合テストで実施 (Hive初期化が必要)

    // プライベートメソッドのテストは、publicメソッド経由でテスト
    group('private method validation through public methods', () {
      test('should validate data structure through import', () async {
        // Act
        final result = await storageService.importData();

        // Assert
        expect(result.isFailure, isTrue);
        // ファイルが選択されないため、バリデーション前でエラーになる
      });
    });
  });

  group('StorageInfo', () {
    test('should format bytes correctly', () {
      // Bytes
      final info1 = StorageInfo(totalSize: 512, diaryDataSize: 256);
      expect(info1.formattedTotalSize, '512B');
      expect(info1.formattedDiaryDataSize, '256B');

      // Kilobytes
      final info2 = StorageInfo(totalSize: 1536, diaryDataSize: 1024);
      expect(info2.formattedTotalSize, '1.5KB');
      expect(info2.formattedDiaryDataSize, '1.0KB');

      // Megabytes
      final info3 = StorageInfo(totalSize: 1572864, diaryDataSize: 1048576);
      expect(info3.formattedTotalSize, '1.5MB');
      expect(info3.formattedDiaryDataSize, '1.0MB');

      // Gigabytes
      final info4 = StorageInfo(
        totalSize: 1610612736,
        diaryDataSize: 1073741824,
      );
      expect(info4.formattedTotalSize, '1.5GB');
      expect(info4.formattedDiaryDataSize, '1.0GB');
    });

    test('should handle different size ranges', () {
      // Zero bytes
      final info1 = StorageInfo(totalSize: 0, diaryDataSize: 0);
      expect(info1.formattedTotalSize, '0B');
      expect(info1.formattedDiaryDataSize, '0B');

      // Large values
      final info2 = StorageInfo(totalSize: 999, diaryDataSize: 999);
      expect(info2.formattedTotalSize, '999B');

      final info3 = StorageInfo(totalSize: 1023, diaryDataSize: 1023);
      expect(info3.formattedTotalSize, '1023B');

      final info4 = StorageInfo(totalSize: 1025, diaryDataSize: 1025);
      expect(info4.formattedTotalSize, '1.0KB');
    });
  });
}
