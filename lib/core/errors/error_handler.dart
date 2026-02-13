import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../service_locator.dart';

/// アプリケーション全体のエラーハンドリングユーティリティ
class ErrorHandler {
  /// エラーをログに記録し、適切なAppExceptionに変換する
  static AppException handleError(dynamic error, {String? context}) {
    // 既にAppExceptionの場合はそのまま返す
    if (error is AppException) {
      try {
        final logger = serviceLocator.get<ILoggingService>();
        logger.error(
          'AppException: ${error.message}',
          context: context ?? 'ErrorHandler.handleError',
          error: error,
        );
      } catch (_) {
        // LoggingServiceが利用できない場合はdebugPrintにフォールバック
        final contextMessage = context != null ? '[$context] ' : '';
        debugPrint('${contextMessage}AppException: ${error.message}');
      }
      return error;
    }

    // 一般的なエラーの場合は適切なAppExceptionに変換
    final message = 'An unexpected error occurred';
    final exception = ServiceException(message, originalError: error);

    try {
      final logger = serviceLocator.get<ILoggingService>();
      logger.error(
        message,
        context: context ?? 'ErrorHandler.handleError',
        error: error,
      );
    } catch (_) {
      // LoggingServiceが利用できない場合はdebugPrintにフォールバック
      final contextMessage = context != null ? '[$context] ' : '';
      debugPrint('${contextMessage}Error: $error');
    }

    return exception;
  }

  /// エラーをログに記録する
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    try {
      final logger = serviceLocator.get<ILoggingService>();
      logger.error(
        'Error: $error',
        context: context ?? 'ErrorHandler.logError',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (_) {
      // LoggingServiceが利用できない場合はdebugPrintにフォールバック
      final contextMessage = context != null ? '[$context] ' : '';
      debugPrint('${contextMessage}Error: $error');

      if (stackTrace != null && kDebugMode) {
        debugPrint('${contextMessage}StackTrace: $stackTrace');
      }
    }
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
}
