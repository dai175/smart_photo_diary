import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/result/photo_result_helper.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

void main() {
  group('PhotoAccessException専用例外クラステスト', () {
    group('PhotoPermissionDeniedException', () {
      test('基本的なプロパティが正しく設定される', () {
        const exception = PhotoPermissionDeniedException(
          'テストメッセージ',
          details: 'テスト詳細',
          originalError: 'オリジナルエラー',
        );

        expect(exception.message, equals('テストメッセージ'));
        expect(exception.details, equals('テスト詳細'));
        expect(exception.originalError, equals('オリジナルエラー'));
        expect(exception, isA<PhotoAccessException>());
        expect(exception, isA<AppException>());
      });

      test('userMessageが適切に設定される', () {
        const exception = PhotoPermissionDeniedException('テストメッセージ');
        expect(exception.userMessage, equals('写真アクセス権限が必要です。設定から権限を許可してください。'));
      });

      test('toString()が正しい文字列を返す', () {
        const exception = PhotoPermissionDeniedException(
          'テストメッセージ',
          details: 'テスト詳細',
        );
        final result = exception.toString();

        expect(result, contains('PhotoPermissionDeniedException'));
        expect(result, contains('テストメッセージ'));
        expect(result, contains('テスト詳細'));
      });

      test('最小限のパラメータで作成できる', () {
        const exception = PhotoPermissionDeniedException('最小メッセージ');

        expect(exception.message, equals('最小メッセージ'));
        expect(exception.details, isNull);
        expect(exception.originalError, isNull);
        expect(exception.stackTrace, isNull);
      });
    });

    group('PhotoPermissionPermanentlyDeniedException', () {
      test('基本的なプロパティが正しく設定される', () {
        const exception = PhotoPermissionPermanentlyDeniedException(
          '永続拒否メッセージ',
          details: '永続拒否詳細',
          originalError: '永続拒否エラー',
        );

        expect(exception.message, equals('永続拒否メッセージ'));
        expect(exception.details, equals('永続拒否詳細'));
        expect(exception.originalError, equals('永続拒否エラー'));
        expect(exception, isA<PhotoAccessException>());
      });

      test('userMessageが永続拒否用メッセージを返す', () {
        const exception = PhotoPermissionPermanentlyDeniedException('テスト');
        expect(
          exception.userMessage,
          equals('写真アクセス権限が拒否されています。設定アプリから権限を有効にしてください。'),
        );
      });

      test('toString()に正しいクラス名が含まれる', () {
        const exception = PhotoPermissionPermanentlyDeniedException('テスト');
        expect(
          exception.toString(),
          contains('PhotoPermissionPermanentlyDeniedException'),
        );
      });
    });

    group('PhotoLimitedAccessException', () {
      test('基本的なプロパティが正しく設定される', () {
        const exception = PhotoLimitedAccessException(
          '制限アクセスメッセージ',
          details: '制限アクセス詳細',
          originalError: '制限アクセスエラー',
        );

        expect(exception.message, equals('制限アクセスメッセージ'));
        expect(exception.details, equals('制限アクセス詳細'));
        expect(exception.originalError, equals('制限アクセスエラー'));
        expect(exception, isA<PhotoAccessException>());
      });

      test('userMessageが制限アクセス用メッセージを返す', () {
        const exception = PhotoLimitedAccessException('テスト');
        expect(
          exception.userMessage,
          equals('制限付きの写真アクセスです。より多くの写真にアクセスするには設定を変更してください。'),
        );
      });

      test('継承関係が正しく設定されている', () {
        const exception = PhotoLimitedAccessException('テスト');
        expect(exception, isA<PhotoAccessException>());
        expect(exception, isA<AppException>());
        expect(exception, isA<Exception>());
      });
    });

    group('PhotoDataCorruptedException', () {
      test('基本的なプロパティが正しく設定される', () {
        const exception = PhotoDataCorruptedException(
          'データ破損メッセージ',
          details: 'データ破損詳細',
          originalError: 'データ破損エラー',
        );

        expect(exception.message, equals('データ破損メッセージ'));
        expect(exception.details, equals('データ破損詳細'));
        expect(exception.originalError, equals('データ破損エラー'));
        expect(exception, isA<PhotoAccessException>());
      });

      test('userMessageがデータ破損用メッセージを返す', () {
        const exception = PhotoDataCorruptedException('テスト');
        expect(exception.userMessage, equals('写真データが破損しているか読み取れません。'));
      });

      test('stackTraceが正しく設定される', () {
        final stackTrace = StackTrace.current;
        final exception = PhotoDataCorruptedException(
          'テスト',
          stackTrace: stackTrace,
        );

        expect(exception.stackTrace, equals(stackTrace));
      });

      test('複数パラメータでの作成が正しく動作する', () {
        const originalError = 'IOエラー';
        const exception = PhotoDataCorruptedException(
          'ファイル読み取りエラー',
          details: 'ファイルが破損している可能性があります',
          originalError: originalError,
        );

        expect(exception.message, equals('ファイル読み取りエラー'));
        expect(exception.details, equals('ファイルが破損している可能性があります'));
        expect(exception.originalError, equals(originalError));
      });
    });

    group('例外クラス間の関係性テスト', () {
      test('全ての専用例外がPhotoAccessExceptionを継承している', () {
        const permission = PhotoPermissionDeniedException('test');
        const permanently = PhotoPermissionPermanentlyDeniedException('test');
        const limited = PhotoLimitedAccessException('test');
        const corrupted = PhotoDataCorruptedException('test');

        expect(permission, isA<PhotoAccessException>());
        expect(permanently, isA<PhotoAccessException>());
        expect(limited, isA<PhotoAccessException>());
        expect(corrupted, isA<PhotoAccessException>());
      });

      test('全ての専用例外がAppExceptionを継承している', () {
        const permission = PhotoPermissionDeniedException('test');
        const permanently = PhotoPermissionPermanentlyDeniedException('test');
        const limited = PhotoLimitedAccessException('test');
        const corrupted = PhotoDataCorruptedException('test');

        expect(permission, isA<AppException>());
        expect(permanently, isA<AppException>());
        expect(limited, isA<AppException>());
        expect(corrupted, isA<AppException>());
      });

      test('各例外のuserMessageが異なる', () {
        const permission = PhotoPermissionDeniedException('test');
        const permanently = PhotoPermissionPermanentlyDeniedException('test');
        const limited = PhotoLimitedAccessException('test');
        const corrupted = PhotoDataCorruptedException('test');

        final messages = {
          permission.userMessage,
          permanently.userMessage,
          limited.userMessage,
          corrupted.userMessage,
        };

        // 全てのuserMessageが異なることを確認
        expect(messages.length, equals(4));
      });
    });
  });
}
