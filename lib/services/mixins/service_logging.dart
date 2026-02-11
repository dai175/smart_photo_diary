import 'package:flutter/foundation.dart';
import '../interfaces/logging_service_interface.dart';

/// サービス共通のログ出力Mixin
///
/// ILoggingServiceが利用可能な場合はそちらに委譲し、
/// 未登録の場合はdebugPrintにフォールバックする。
mixin ServiceLogging {
  /// ロギングサービス（ServiceLocator経由で解決、未登録時はnull）
  ILoggingService? get loggingService;

  /// ログ出力のデフォルトコンテキスト名
  String get logTag;

  /// 統一ログ出力メソッド
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final logContext = context ?? logTag;

    if (loggingService != null) {
      switch (level) {
        case LogLevel.debug:
          loggingService!.debug(message, context: logContext, data: data);
          break;
        case LogLevel.info:
          loggingService!.info(message, context: logContext, data: data);
          break;
        case LogLevel.warning:
          loggingService!.warning(message, context: logContext, data: data);
          break;
        case LogLevel.error:
          loggingService!.error(message, context: logContext, error: error);
          break;
      }

      if (error != null && level != LogLevel.error) {
        loggingService!.error('Error details: $error', context: logContext);
      }
    } else {
      final prefix = level == LogLevel.error
          ? 'ERROR'
          : level == LogLevel.warning
          ? 'WARNING'
          : level == LogLevel.debug
          ? 'DEBUG'
          : 'INFO';

      debugPrint('[$prefix] $logContext: $message');
      if (error != null) {
        debugPrint('[$prefix] $logContext: Error - $error');
      }
    }
  }
}
