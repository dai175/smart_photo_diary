import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/controllers/base_error_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';

/// テスト用の具象コントローラー
class TestController extends BaseErrorController {}

/// テスト用のMixinコントローラー
class TestMixinController extends ChangeNotifier with ErrorStateMixin {}

void main() {
  group('BaseErrorController', () {
    late TestController controller;

    setUp(() {
      controller = TestController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('初期状態', () {
      test('isLoadingはfalse、lastErrorはnull、hasErrorはfalse', () {
        expect(controller.isLoading, false);
        expect(controller.lastError, isNull);
        expect(controller.hasError, false);
      });
    });

    group('setLoading', () {
      test('trueを設定するとisLoadingがtrueになりlastErrorがクリアされる', () {
        // Arrange - まずエラーを設定
        controller.setError(const ServiceException('テストエラー'));
        expect(controller.hasError, true);

        // Act
        controller.setLoading(true);

        // Assert
        expect(controller.isLoading, true);
        expect(controller.lastError, isNull);
        expect(controller.hasError, false);
      });

      test('同じ値を設定してもリスナーに通知されない（ガードチェック）', () {
        int notifyCount = 0;
        controller.addListener(() {
          notifyCount++;
        });

        // isLoadingはデフォルトでfalse
        // Act - falseを再度設定
        controller.setLoading(false);

        // Assert - 通知されない
        expect(notifyCount, 0);

        // Act - trueを設定（値が変わるので通知される）
        controller.setLoading(true);
        expect(notifyCount, 1);

        // Act - trueを再度設定（同じ値なので通知されない）
        controller.setLoading(true);
        expect(notifyCount, 1);
      });
    });

    group('setError', () {
      test('エラーを設定するとhasErrorがtrueになりisLoadingがfalseになる', () {
        // Arrange
        controller.setLoading(true);

        // Act
        const error = ServiceException('テストエラー');
        controller.setError(error);

        // Assert
        expect(controller.lastError, error);
        expect(controller.hasError, true);
        expect(controller.isLoading, false);
      });
    });

    group('clearError', () {
      test('エラーをクリアするとlastErrorがnullになる', () {
        // Arrange
        controller.setError(const ServiceException('テストエラー'));
        expect(controller.hasError, true);

        // Act
        controller.clearError();

        // Assert
        expect(controller.lastError, isNull);
        expect(controller.hasError, false);
      });
    });

    group('safeExecute', () {
      test('成功時は結果を返す', () async {
        // Act
        final result = await controller.safeExecute(() async => 42);

        // Assert
        expect(result, 42);
        expect(controller.isLoading, false);
        expect(controller.hasError, false);
      });

      test('失敗時は例外をキャッチしServiceExceptionとしてエラーに設定する', () async {
        // Act
        final result = await controller.safeExecute<String>(() async {
          throw Exception('何かのエラー');
        });

        // Assert
        expect(result, isNull);
        expect(controller.hasError, true);
        expect(controller.lastError, isA<ServiceException>());
        expect(controller.isLoading, false);
      });

      test('AppExceptionはそのまま保持される（ラップされない）', () async {
        // Arrange
        const originalException = PhotoAccessException('写真アクセスエラー');

        // Act
        final result = await controller.safeExecute<String>(() async {
          throw originalException;
        });

        // Assert
        expect(result, isNull);
        expect(controller.lastError, isA<PhotoAccessException>());
        expect(controller.lastError?.message, '写真アクセスエラー');
      });
    });

    group('safeExecuteResult', () {
      test('成功のResult返却時はSuccessを返しエラーをクリアする', () async {
        // Act
        final result = await controller.safeExecuteResult(
          () async => const Success(100),
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, 100);
        expect(controller.hasError, false);
        expect(controller.isLoading, false);
      });

      test('失敗のResult返却時はFailureを返しエラーを設定する', () async {
        // Arrange
        const error = ServiceException('処理失敗');

        // Act
        final result = await controller.safeExecuteResult<String>(
          () async => const Failure(error),
        );

        // Assert
        expect(result.isFailure, true);
        expect(controller.hasError, true);
        expect(controller.lastError, isA<ServiceException>());
        expect(controller.lastError?.message, '処理失敗');
      });
    });
  });

  group('ErrorStateMixin', () {
    late TestMixinController controller;

    setUp(() {
      controller = TestMixinController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('初期状態: isLoadingはfalse、errorはnull、hasErrorはfalse', () {
      expect(controller.isLoading, false);
      expect(controller.error, isNull);
      expect(controller.hasError, false);
    });

    test('setErrorでエラーを設定しisLoadingがfalseになる', () {
      // Arrange
      controller.setLoading(true);

      // Act
      const error = ServiceException('Mixinエラー');
      controller.setError(error);

      // Assert
      expect(controller.error, error);
      expect(controller.hasError, true);
      expect(controller.isLoading, false);
    });

    test('setLoadingでローディング状態を設定しエラーがクリアされる', () {
      // Arrange
      controller.setError(const ServiceException('エラー'));

      // Act
      controller.setLoading(true);

      // Assert
      expect(controller.isLoading, true);
      expect(controller.error, isNull);
      expect(controller.hasError, false);
    });

    test('clearErrorでエラーがnullになる', () {
      // Arrange
      controller.setError(const ServiceException('エラー'));
      expect(controller.hasError, true);

      // Act
      controller.clearError();

      // Assert
      expect(controller.error, isNull);
      expect(controller.hasError, false);
    });
  });
}
