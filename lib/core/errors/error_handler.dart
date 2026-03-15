import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../result/result.dart';

/// アプリケーション全体のエラーハンドリングユーティリティ
class ErrorHandler {
  static ILoggingService? _logger;

  /// ロガーを注入する（ServiceRegistration初期化時に呼び出す）
  static void configure({required ILoggingService logger}) {
    _logger = logger;
  }

  /// エラーをログに記録し、適切なAppExceptionに変換する
  static AppException handleError(dynamic error, {String? context}) {
    // 既にAppExceptionの場合はそのまま返す
    if (error is AppException) {
      _log(
        'AppException: ${error.message}',
        context: context ?? 'ErrorHandler.handleError',
        error: error,
      );
      return error;
    }

    // 一般的なエラーの場合は適切なAppExceptionに変換
    final message = 'An unexpected error occurred';
    final exception = ServiceException(message, originalError: error);

    _log(message, context: context ?? 'ErrorHandler.handleError', error: error);

    return exception;
  }

  /// エラーをログに記録する
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    _log(
      'Error: $error',
      context: context ?? 'ErrorHandler.logError',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// ロガーがあればロガーへ、なければ debugPrint にフォールバック
  static void _log(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final logger = _logger;
    if (logger != null) {
      logger.error(
        message,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('$prefix$message');

      if (stackTrace != null && kDebugMode) {
        debugPrint('${prefix}StackTrace: $stackTrace');
      }
    }
  }

  /// エラーをハンドリングし、`Result<T>` の `Failure` として返す。
  ///
  /// [handleError] でエラーをログ記録・AppExceptionに変換した上で
  /// `Failure<T>` にラップして返す。catch ブロック内での使用を想定。
  static Failure<T> toFailure<T>(dynamic error, {String? context}) {
    final appError = handleError(error, context: context);
    return Failure(appError);
  }

  /// 安全にFutureを実行し、エラーをハンドリングする
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      logError(error, context: context, stackTrace: stackTrace);
      return fallbackValue;
    }
  }

  /// 安全に同期処理を実行し、エラーをハンドリングする
  static T? safeExecuteSync<T>(
    T Function() operation, {
    String? context,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      logError(error, context: context, stackTrace: stackTrace);
      return fallbackValue;
    }
  }

  /// テスト用: ロガーをリセットする
  @visibleForTesting
  static void resetForTesting() {
    _logger = null;
  }
}
