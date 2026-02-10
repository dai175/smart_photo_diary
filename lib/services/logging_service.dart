import 'package:flutter/foundation.dart';
import '../core/errors/error_handler.dart';
import 'interfaces/logging_service_interface.dart';

/// ログレベル定義
enum LogLevel { debug, info, warning, error }

/// アプリケーション全体のロギングサービス
class LoggingService implements ILoggingService {
  static LoggingService? _instance;

  LoggingService._();

  /// 非同期ファクトリメソッドでサービスインスタンスを取得
  static Future<LoggingService> getInstance() async {
    try {
      _instance ??= LoggingService._();
      return _instance!;
    } catch (error) {
      throw ErrorHandler.handleError(
        error,
        context: 'LoggingService.getInstance',
      );
    }
  }

  /// 同期的なサービスインスタンス取得（事前に初期化済みの場合のみ）
  static LoggingService get instance {
    if (_instance == null) {
      throw StateError(
        'LoggingService has not been initialized. Call getInstance() first.',
      );
    }
    return _instance!;
  }

  /// デバッグログ
  @override
  void debug(String message, {String? context, dynamic data}) {
    _log(LogLevel.debug, message, context: context, data: data);
  }

  /// 情報ログ
  @override
  void info(String message, {String? context, dynamic data}) {
    _log(LogLevel.info, message, context: context, data: data);
  }

  /// 警告ログ
  @override
  void warning(String message, {String? context, dynamic data}) {
    _log(LogLevel.warning, message, context: context, data: data);
  }

  /// エラーログ
  @override
  void error(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, context: context, data: error);
    if (stackTrace != null && kDebugMode) {
      _log(LogLevel.error, 'StackTrace: $stackTrace', context: context);
    }
  }

  /// 内部ログ出力メソッド
  void _log(LogLevel level, String message, {String? context, dynamic data}) {
    if (!kDebugMode && level == LogLevel.debug) {
      return; // リリースビルドではデバッグログを出力しない
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final contextStr = context != null ? '[$context] ' : '';

    var logMessage = '[$timestamp] $levelStr: $contextStr$message';

    if (data != null) {
      logMessage += ' | Data: $data';
    }

    debugPrint(logMessage);
  }

  /// パフォーマンス測定用のストップウォッチ機能
  @override
  Stopwatch startTimer(String operation, {String? context}) {
    final stopwatch = Stopwatch()..start();
    debug('Started: $operation', context: context);
    return stopwatch;
  }

  /// パフォーマンス測定終了
  @override
  void endTimer(Stopwatch stopwatch, String operation, {String? context}) {
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    info('Completed: $operation in ${elapsed}ms', context: context);
  }
}
