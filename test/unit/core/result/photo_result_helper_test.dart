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

  group('Complex Error Scenarios and Integration Tests', () {
    group('Mixed Error Type Combinations', () {
      test(
        'should handle mixed permission and data errors in combineResults',
        () {
          final results = [
            Failure(PhotoPermissionDeniedException('権限エラー')),
            Failure(PhotoDataCorruptedException('データエラー')),
            Failure(PhotoLimitedAccessException('アクセスエラー')),
          ];

          final combined = PhotoResultHelper.combineResults(results);

          expect(combined.isFailure, isTrue);
          expect(combined.error, isA<PhotoAccessException>());
          expect(combined.error.details, contains('権限エラー'));
          expect(combined.error.details, contains('データエラー'));
          expect(combined.error.details, contains('アクセスエラー'));
        },
      );

      test(
        'should preserve first error as originalError in combined failure',
        () {
          const firstError = PhotoPermissionDeniedException('最初のエラー');
          final results = [
            const Failure(firstError),
            Failure(PhotoDataCorruptedException('2番目のエラー')),
          ];

          final combined = PhotoResultHelper.combineResults(results);

          expect(combined.isFailure, isTrue);
          expect(combined.error.originalError, equals(firstError));
        },
      );
    });

    group('Edge Case Data Handling', () {
      test(
        'should handle null data appropriately across different methods',
        () {
          final nullDataResult = PhotoResultHelper.photoDataResult(null);
          final nullAccessResult = PhotoResultHelper.photoAccessResult(null);

          expect(nullDataResult.isFailure, isTrue);
          expect(nullAccessResult.isFailure, isTrue);
          expect(nullDataResult.error, isA<PhotoAccessException>());
          expect(nullAccessResult.error, isA<PhotoAccessException>());
        },
      );

      test('should handle empty data consistently', () {
        final emptyByteData = PhotoResultHelper.photoDataResult(Uint8List(0));
        final emptyListData = PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
        );

        expect(emptyByteData.isFailure, isTrue);
        expect(
          emptyListData.isSuccess,
          isTrue,
        ); // Empty list is valid for photos
      });

      test('should handle large data sets in combineResults', () {
        final largeResultSet = List<Result<String>>.generate(
          1000,
          (index) => index.isEven
              ? Success('data$index')
              : Failure(PhotoAccessException('error$index')),
        );

        final combined = PhotoResultHelper.combineResults(
          largeResultSet,
          allowPartialSuccess: true,
        );

        expect(combined.isSuccess, isTrue);
        expect(combined.value.length, equals(500)); // Half should be successful
      });
    });

    group('Permission State Edge Cases', () {
      test('should handle all PermissionState values correctly', () {
        final stateTests = {
          PermissionState.authorized: (isSuccess: true, expectedValue: true),
          PermissionState.limited: (isSuccess: true, expectedValue: true),
          PermissionState.denied: (isSuccess: false, expectedValue: null),
          PermissionState.restricted: (isSuccess: false, expectedValue: null),
          PermissionState.notDetermined: (
            isSuccess: false,
            expectedValue: null,
          ),
        };

        for (final entry in stateTests.entries) {
          final result = PhotoResultHelper.fromPermissionState(entry.key);
          final expected = entry.value;

          expect(
            result.isSuccess,
            equals(expected.isSuccess),
            reason: 'Failed for ${entry.key}',
          );

          if (expected.isSuccess) {
            expect(
              result.value,
              equals(expected.expectedValue),
              reason: 'Failed value for ${entry.key}',
            );
          } else {
            expect(
              result.isFailure,
              isTrue,
              reason: 'Should be failure for ${entry.key}',
            );
          }
        }
      });
    });

    group('Error Message and Context Handling', () {
      test('should properly format complex error contexts', () {
        final complexError = Exception('Complex nested error with details');
        final result = PhotoResultHelper.fromError<String>(
          complexError,
          context: 'Multiple photo operation batch processing',
          customMessage: '写真の一括処理中にエラーが発生しました',
        );

        expect(result.isFailure, isTrue);
        expect(result.error.message, contains('Multiple photo operation'));
        expect(result.error.message, contains('写真の一括処理中に'));
        expect(result.error.originalError, equals(complexError));
        expect(result.error.details, contains('Complex nested error'));
      });

      test('should handle custom error messages across all helper methods', () {
        const customMessage = 'カスタムエラーメッセージ';

        final permissionResult = PhotoResultHelper.photoPermissionResult(
          granted: false,
          isDenied: true,
          errorMessage: customMessage,
        );

        final dataResult = PhotoResultHelper.photoDataResult(
          null,
          errorMessage: customMessage,
        );

        final voidResult = PhotoResultHelper.voidResult(
          success: false,
          errorMessage: customMessage,
        );

        expect(permissionResult.error.message, equals(customMessage));
        expect(dataResult.error.message, equals(customMessage));
        expect(voidResult.error.message, equals(customMessage));
      });
    });

    group('Performance and Concurrent Operation Simulation', () {
      test('should handle concurrent error scenarios efficiently', () {
        final concurrentResults = List<Result<String>>.generate(100, (index) {
          switch (index % 4) {
            case 0:
              return Success('success$index');
            case 1:
              return Failure(
                PhotoPermissionDeniedException('permission$index'),
              );
            case 2:
              return Failure(PhotoDataCorruptedException('data$index'));
            default:
              return Failure(PhotoLimitedAccessException('limited$index'));
          }
        });

        final combined = PhotoResultHelper.combineResults(
          concurrentResults,
          allowPartialSuccess: true,
        );

        expect(combined.isSuccess, isTrue);
        expect(combined.value.length, equals(25)); // 1/4 should be successful

        final combinedFailure = PhotoResultHelper.combineResults(
          concurrentResults,
          allowPartialSuccess: false,
        );

        expect(combinedFailure.isFailure, isTrue);
        expect(combinedFailure.error.details, contains('75件のエラー'));
      });

      test('should maintain error type information in complex scenarios', () {
        final mixedErrors = [
          Failure(PhotoPermissionDeniedException('権限なし')),
          Failure(PhotoPermissionPermanentlyDeniedException('永続拒否')),
          Failure(PhotoLimitedAccessException('制限付き')),
          Failure(PhotoDataCorruptedException('データ破損')),
        ];

        final combined = PhotoResultHelper.combineResults(mixedErrors);

        expect(combined.isFailure, isTrue);
        final errorMessage = combined.error.details!;
        expect(errorMessage, contains('権限なし'));
        expect(errorMessage, contains('永続拒否'));
        expect(errorMessage, contains('制限付き'));
        expect(errorMessage, contains('データ破損'));
      });
    });
  });
}
