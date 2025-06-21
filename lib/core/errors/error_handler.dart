import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

/// アプリケーション全体のエラーハンドリングユーティリティ
class ErrorHandler {
  /// エラーをログに記録し、適切なAppExceptionに変換する
  static AppException handleError(dynamic error, {String? context}) {
    final contextMessage = context != null ? '[$context] ' : '';

    // 既にAppExceptionの場合はそのまま返す
    if (error is AppException) {
      debugPrint('${contextMessage}AppException: ${error.message}');
      return error;
    }

    // 一般的なエラーの場合は適切なAppExceptionに変換
    final message = '$contextMessage予期しないエラーが発生しました';
    final exception = ServiceException(message, originalError: error);

    debugPrint('${contextMessage}Error: $error');
    return exception;
  }

  /// エラーをログに記録する
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    final contextMessage = context != null ? '[$context] ' : '';
    debugPrint('${contextMessage}Error: $error');

    if (stackTrace != null && kDebugMode) {
      debugPrint('${contextMessage}StackTrace: $stackTrace');
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
