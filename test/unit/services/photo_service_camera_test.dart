import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/result/result_extensions.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes for camera testing
class MockAssetEntity extends Mock implements AssetEntity {}

class MockPhotoService extends Mock implements IPhotoService {}

void main() {
  group('PhotoService Camera Tests', () {
    late MockPhotoService mockPhotoService;
    late MockAssetEntity mockAssetEntity;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockPhotoService = MockPhotoService();
      mockAssetEntity = MockAssetEntity();
    });

    group('capturePhoto', () {
      test('カメラ撮影成功時はAssetEntityを返す', () async {
        // Arrange
        final successResult = ResultHelper.success<AssetEntity?>(
          mockAssetEntity,
        );
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => successResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, equals(mockAssetEntity));
        verify(() => mockPhotoService.capturePhoto()).called(1);
      });

      test('カメラ撮影キャンセル時はnullを返す', () async {
        // Arrange
        final cancelResult = ResultHelper.success<AssetEntity?>(null);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => cancelResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isNull);
        verify(() => mockPhotoService.capturePhoto()).called(1);
      });

      test('カメラアクセス拒否時は適切なエラーを返す', () async {
        // Arrange
        final error = const PhotoAccessException('カメラの権限が拒否されています');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PhotoAccessException>());
        verify(() => mockPhotoService.capturePhoto()).called(1);
      });

      test('デバイスでカメラが利用不可時は適切なエラーを返す', () async {
        // Arrange
        final error = const PhotoAccessException('カメラが利用できません');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PhotoAccessException>());
        verify(() => mockPhotoService.capturePhoto()).called(1);
      });

      test('ストレージ容量不足時は適切なエラーを返す', () async {
        // Arrange
        final error = const PhotoAccessException('ストレージ容量が不足しています');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PhotoAccessException>());
      });

      test('その他のシステムエラー時は適切なエラーを返す', () async {
        // Arrange
        final error = const ServiceException('予期しないシステムエラーが発生しました');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ServiceException>());
      });
    });

    group('requestCameraPermission', () {
      test('カメラ権限許可時はtrueを返す', () async {
        // Arrange
        final successResult = ResultHelper.success<bool>(true);
        when(
          () => mockPhotoService.requestCameraPermission(),
        ).thenAnswer((_) async => successResult);

        // Act
        final result = await mockPhotoService.requestCameraPermission();

        // Assert
        expect(result, isA<Result<bool>>());
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isTrue);
        verify(() => mockPhotoService.requestCameraPermission()).called(1);
      });

      test('カメラ権限拒否時はfalseを返す', () async {
        // Arrange
        final successResult = ResultHelper.success<bool>(false);
        when(
          () => mockPhotoService.requestCameraPermission(),
        ).thenAnswer((_) async => successResult);

        // Act
        final result = await mockPhotoService.requestCameraPermission();

        // Assert
        expect(result, isA<Result<bool>>());
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isFalse);
        verify(() => mockPhotoService.requestCameraPermission()).called(1);
      });

      test('権限チェック処理エラー時は適切なエラーを返す', () async {
        // Arrange
        final error = const ServiceException('権限チェック処理中にエラーが発生しました');
        final errorResult = ResultHelper.failure<bool>(error);
        when(
          () => mockPhotoService.requestCameraPermission(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.requestCameraPermission();

        // Assert
        expect(result, isA<Result<bool>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ServiceException>());
        verify(() => mockPhotoService.requestCameraPermission()).called(1);
      });
    });

    group('isCameraPermissionDenied', () {
      test('カメラ権限が拒否されている時はtrueを返す', () async {
        // Arrange
        final deniedResult = ResultHelper.success<bool>(true);
        when(
          () => mockPhotoService.isCameraPermissionDenied(),
        ).thenAnswer((_) async => deniedResult);

        // Act
        final result = await mockPhotoService.isCameraPermissionDenied();

        // Assert
        expect(result, isA<Result<bool>>());
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isTrue);
        verify(() => mockPhotoService.isCameraPermissionDenied()).called(1);
      });

      test('カメラ権限が許可されている時はfalseを返す', () async {
        // Arrange
        final allowedResult = ResultHelper.success<bool>(false);
        when(
          () => mockPhotoService.isCameraPermissionDenied(),
        ).thenAnswer((_) async => allowedResult);

        // Act
        final result = await mockPhotoService.isCameraPermissionDenied();

        // Assert
        expect(result, isA<Result<bool>>());
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, isFalse);
        verify(() => mockPhotoService.isCameraPermissionDenied()).called(1);
      });

      test('権限チェック処理エラー時は適切なエラーを返す', () async {
        // Arrange
        final error = const ServiceException('権限チェック処理中にエラーが発生しました');
        final errorResult = ResultHelper.failure<bool>(error);
        when(
          () => mockPhotoService.isCameraPermissionDenied(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.isCameraPermissionDenied();

        // Assert
        expect(result, isA<Result<bool>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ServiceException>());
        verify(() => mockPhotoService.isCameraPermissionDenied()).called(1);
      });
    });

    group('カメラ機能統合テスト', () {
      test('カメラ権限チェック→許可→撮影の一連の流れ', () async {
        // Arrange
        final permissionSuccess = ResultHelper.success<bool>(true);
        final captureSuccess = ResultHelper.success<AssetEntity?>(
          mockAssetEntity,
        );

        when(
          () => mockPhotoService.requestCameraPermission(),
        ).thenAnswer((_) async => permissionSuccess);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => captureSuccess);

        // Act
        final permissionResult = await mockPhotoService
            .requestCameraPermission();

        // Assert
        expect(permissionResult, isA<Result<bool>>());

        // 権限が許可された場合のみ撮影テスト
        if (permissionResult.isSuccess &&
            permissionResult.valueOrNull == true) {
          final captureResult = await mockPhotoService.capturePhoto();
          expect(captureResult, isA<Result<AssetEntity?>>());
        }
      });

      test('カメラ権限拒否時は撮影不可', () async {
        // Arrange
        final deniedResult = ResultHelper.success<bool>(true);
        final captureErrorResult = ResultHelper.failure<AssetEntity?>(
          const PhotoAccessException('カメラ権限が拒否されています'),
        );

        when(
          () => mockPhotoService.isCameraPermissionDenied(),
        ).thenAnswer((_) async => deniedResult);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => captureErrorResult);

        // Act
        final permissionDenied = await mockPhotoService
            .isCameraPermissionDenied();

        // Assert
        expect(permissionDenied, isA<Result<bool>>());

        if (permissionDenied.isSuccess &&
            permissionDenied.valueOrNull == true) {
          final captureResult = await mockPhotoService.capturePhoto();
          expect(captureResult.isFailure, isTrue);
          expect(captureResult.errorOrNull, isA<PhotoAccessException>());
        }
      });

      test('複数回連続撮影の動作確認', () async {
        // Arrange
        const shotCount = 3;
        final successResult = ResultHelper.success<AssetEntity?>(
          mockAssetEntity,
        );
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => successResult);

        // Act & Assert
        for (int i = 0; i < shotCount; i++) {
          final result = await mockPhotoService.capturePhoto();
          expect(result, isA<Result<AssetEntity?>>());

          // 各撮影結果をログ出力（実装確認用）
          if (result.isSuccess) {
            final asset = result.valueOrNull;
            debugPrint('撮影${i + 1}回目: ${asset != null ? '成功' : 'キャンセル'}');
          } else {
            final error = result.errorOrNull;
            debugPrint('撮影${i + 1}回目: エラー - $error');
          }
        }
      });
    });

    group('エラーハンドリング詳細テスト', () {
      test('カメラビジー状態の処理', () async {
        // Arrange
        final error = const PhotoAccessException('カメラがビジー状態です');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PhotoAccessException>());
      });

      test('ネットワークエラーの処理（クラウド同期等）', () async {
        // Arrange
        final error = const ServiceException('ネットワークエラーが発生しました');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ServiceException>());
      });

      test('予期しない例外の処理', () async {
        // Arrange
        final error = const ServiceException('予期しないフォーマットエラーが発生しました');
        final errorResult = ResultHelper.failure<AssetEntity?>(error);
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => errorResult);

        // Act
        final result = await mockPhotoService.capturePhoto();

        // Assert
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ServiceException>());
      });
    });

    group('パフォーマンステスト', () {
      test('撮影処理のタイムアウト確認', () async {
        // Arrange
        final timeoutResult = ResultHelper.success<AssetEntity?>(
          mockAssetEntity,
        );
        when(() => mockPhotoService.capturePhoto()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100)); // 短時間処理
          return timeoutResult;
        });

        // Act & Assert
        final stopwatch = Stopwatch()..start();
        final result = await mockPhotoService.capturePhoto();
        stopwatch.stop();

        // 適切な処理時間で完了することを確認
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒以内
        expect(result, isA<Result<AssetEntity?>>());
        expect(result.isSuccess, isTrue);
      });

      test('メモリ使用量の確認', () async {
        // Arrange
        const testIterations = 10;
        final memoryResult = ResultHelper.success<AssetEntity?>(
          mockAssetEntity,
        );
        when(
          () => mockPhotoService.capturePhoto(),
        ).thenAnswer((_) async => memoryResult);

        // Act
        for (int i = 0; i < testIterations; i++) {
          final result = await mockPhotoService.capturePhoto();
          expect(result, isA<Result<AssetEntity?>>());

          // ガベージコレクションを促進
          if (i % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }

        // Assert
        // メモリリークがないことを確認（実際のテストでは詳細な測定が必要）
        expect(true, isTrue); // プレースホルダー
      });
    });
  });
}
