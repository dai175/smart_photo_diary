/// ログレベル定義
enum LogLevel { debug, info, warning, error }

/// ロギングサービスのインターフェース
///
/// アプリケーション全体のログ出力を統一するための抽象インターフェース。
/// テスト時にモックに差し替えることで、ログ出力に依存しないテストが可能。
abstract class ILoggingService {
  /// デバッグログ
  void debug(String message, {String? context, dynamic data});

  /// 情報ログ
  void info(String message, {String? context, dynamic data});

  /// 警告ログ
  void warning(String message, {String? context, dynamic data});

  /// エラーログ
  void error(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  });

  /// パフォーマンス測定用のストップウォッチ機能
  Stopwatch startTimer(String operation, {String? context});

  /// パフォーマンス測定終了
  void endTimer(Stopwatch stopwatch, String operation, {String? context});
}
