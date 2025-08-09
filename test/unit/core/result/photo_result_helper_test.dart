import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/result/photo_result_helper.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

void main() {
  group('PhotoResultHelper', () {
    group('photoPermissionResult', () {
      test('権限が付与された場合はSuccessを返す', () {
        final result = PhotoResultHelper.photoPermissionResult(granted: true);

        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('制限付きアクセスの場合はSuccessを返す', () {
        final result = PhotoResultHelper.photoPermissionResult(
          granted: false,
          isLimited: true,
        );

        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('権限が拒否された場合はPhotoPermissionDeniedExceptionを返す', () {
        final result = PhotoResultHelper.photoPermissionResult(
          granted: false,
          isDenied: true,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoPermissionDeniedException>());
      });

      test('権限が永続的に拒否された場合はPhotoPermissionPermanentlyDeniedExceptionを返す', () {
        final result = PhotoResultHelper.photoPermissionResult(
          granted: false,
          isPermanentlyDenied: true,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoPermissionPermanentlyDeniedException>());
      });

      test('カスタムエラーメッセージが設定される', () {
        const customMessage = 'カスタムエラーメッセージ';
        final result = PhotoResultHelper.photoPermissionResult(
          granted: false,
          isDenied: true,
          errorMessage: customMessage,
        );

        expect(result.isFailure, true);
        expect(result.error.message, customMessage);
      });
    });

    group('photoAccessResult', () {
      test('写真が取得できた場合はSuccessを返す', () {
        final photos = <AssetEntity>[];
        final result = PhotoResultHelper.photoAccessResult(photos);

        expect(result.isSuccess, true);
        expect(result.value, photos);
      });

      test('権限がない場合はPhotoAccessExceptionを返す', () {
        final result = PhotoResultHelper.photoAccessResult(
          [],
          hasPermission: false,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
        expect(result.error.message, contains('権限がありません'));
      });

      test('写真がnullの場合はPhotoAccessExceptionを返す', () {
        final result = PhotoResultHelper.photoAccessResult(null);

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
        expect(result.error.message, contains('取得に失敗'));
      });
    });

    group('photoDataResult', () {
      test('データが正常な場合はSuccessを返す', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = PhotoResultHelper.photoDataResult(data);

        expect(result.isSuccess, true);
        expect(result.value, data);
      });

      test('データが破損している場合はPhotoDataCorruptedExceptionを返す', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = PhotoResultHelper.photoDataResult(
          data,
          isCorrupted: true,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoDataCorruptedException>());
      });

      test('データがnullの場合はPhotoAccessExceptionを返す', () {
        final result = PhotoResultHelper.photoDataResult(null);

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
      });

      test('データが空の場合はPhotoAccessExceptionを返す', () {
        final data = Uint8List.fromList([]);
        final result = PhotoResultHelper.photoDataResult(data);

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
      });
    });

    group('voidResult', () {
      test('成功時はSuccessを返す', () {
        final result = PhotoResultHelper.voidResult(success: true);

        expect(result.isSuccess, true);
      });

      test('失敗時はPhotoAccessExceptionを返す', () {
        final result = PhotoResultHelper.voidResult(success: false);

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
      });
    });

    group('limitedAccessResult', () {
      test('成功時はSuccessを返す', () {
        final result = PhotoResultHelper.limitedAccessResult(success: true);

        expect(result.isSuccess, true);
      });

      test('失敗時はPhotoLimitedAccessExceptionを返す', () {
        final result = PhotoResultHelper.limitedAccessResult(success: false);

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoLimitedAccessException>());
      });
    });

    group('validatePhotoList', () {
      test('写真がある場合はSuccessを返す', () {
        final photos = <AssetEntity>[];
        final result = PhotoResultHelper.validatePhotoList(photos);

        expect(result.isSuccess, true);
        expect(result.value, photos);
      });

      test('空を許可する場合は空リストでもSuccessを返す', () {
        final photos = <AssetEntity>[];
        final result = PhotoResultHelper.validatePhotoList(
          photos,
          allowEmpty: true,
        );

        expect(result.isSuccess, true);
        expect(result.value, photos);
      });

      test('空を許可しない場合は空リストでDataNotFoundExceptionを返す', () {
        final photos = <AssetEntity>[];
        final result = PhotoResultHelper.validatePhotoList(
          photos,
          allowEmpty: false,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<DataNotFoundException>());
      });
    });

    group('fromPermissionState', () {
      test('authorizedの場合はSuccessを返す', () {
        final result = PhotoResultHelper.fromPermissionState(
          PermissionState.authorized,
        );

        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('limitedの場合はSuccessを返す', () {
        final result = PhotoResultHelper.fromPermissionState(
          PermissionState.limited,
        );

        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('deniedの場合はPhotoPermissionDeniedExceptionを返す', () {
        final result = PhotoResultHelper.fromPermissionState(
          PermissionState.denied,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoPermissionDeniedException>());
      });

      test('restrictedの場合はPhotoPermissionDeniedExceptionを返す', () {
        final result = PhotoResultHelper.fromPermissionState(
          PermissionState.restricted,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoPermissionDeniedException>());
      });

      test('notDeterminedの場合はPhotoAccessExceptionを返す', () {
        final result = PhotoResultHelper.fromPermissionState(
          PermissionState.notDetermined,
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
      });
    });

    group('fromError', () {
      test('汎用エラーからPhotoAccessExceptionを生成', () {
        final originalError = Exception('テストエラー');
        final result = PhotoResultHelper.fromError<String>(
          originalError,
          context: 'test context',
          customMessage: 'カスタムメッセージ',
        );

        expect(result.isFailure, true);
        expect(result.error, isA<PhotoAccessException>());
        expect(result.error.message, contains('test context'));
        expect(result.error.message, contains('カスタムメッセージ'));
        expect(result.error.originalError, originalError);
      });
    });

    group('combineResults', () {
      test('すべて成功の場合はSuccessを返す', () {
        final results = <Result<String>>[
          const Success('a'),
          const Success('b'),
          const Success('c'),
        ];

        final combined = PhotoResultHelper.combineResults(results);

        expect(combined.isSuccess, true);
        expect(combined.value, ['a', 'b', 'c']);
      });

      test('すべて失敗の場合はFailureを返す', () {
        final results = <Result<String>>[
          Failure(PhotoAccessException('エラー1')),
          Failure(PhotoAccessException('エラー2')),
        ];

        final combined = PhotoResultHelper.combineResults(results);

        expect(combined.isFailure, true);
        expect(combined.error, isA<PhotoAccessException>());
      });

      test('部分的成功を許可する場合は成功した値のみを返す', () {
        final results = <Result<String>>[
          const Success('a'),
          Failure(PhotoAccessException('エラー')),
          const Success('c'),
        ];

        final combined = PhotoResultHelper.combineResults(
          results,
          allowPartialSuccess: true,
        );

        expect(combined.isSuccess, true);
        expect(combined.value, ['a', 'c']);
      });

      test('部分的成功を許可しない場合は失敗を返す', () {
        final results = <Result<String>>[
          const Success('a'),
          Failure(PhotoAccessException('エラー')),
          const Success('c'),
        ];

        final combined = PhotoResultHelper.combineResults(
          results,
          allowPartialSuccess: false,
        );

        expect(combined.isFailure, true);
        expect(combined.error, isA<PhotoAccessException>());
      });
    });
  });

  group('Photo Exception Classes', () {
    test('PhotoPermissionDeniedExceptionのuserMessageが正しい', () {
      const exception = PhotoPermissionDeniedException('テストメッセージ');
      expect(exception.userMessage, contains('権限が必要です'));
    });

    test('PhotoPermissionPermanentlyDeniedExceptionのuserMessageが正しい', () {
      const exception = PhotoPermissionPermanentlyDeniedException('テストメッセージ');
      expect(exception.userMessage, contains('設定アプリから権限を有効に'));
    });

    test('PhotoLimitedAccessExceptionのuserMessageが正しい', () {
      const exception = PhotoLimitedAccessException('テストメッセージ');
      expect(exception.userMessage, contains('制限付きの写真アクセス'));
    });

    test('PhotoDataCorruptedExceptionのuserMessageが正しい', () {
      const exception = PhotoDataCorruptedException('テストメッセージ');
      expect(exception.userMessage, contains('破損しているか読み取れません'));
    });
  });
}
