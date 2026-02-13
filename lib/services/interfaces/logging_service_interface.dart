/// ログレベル定義
enum LogLevel { debug, info, warning, error }

/// ロギングサービスのインターフェース
///
/// アプリケーション全体のログ出力を統一するための抽象インターフェース。
/// テスト時にモックに差し替えることで、ログ出力に依存しないテストが可能。
abstract class ILoggingService {
  /// デバッグログを出力する
  ///
  /// [message]: ログメッセージ
  /// [context]: ログ発生元のコンテキスト情報（クラス名等）
  /// [data]: 追加データ（任意の型）
  void debug(String message, {String? context, dynamic data});

  /// 情報ログを出力する
  ///
  /// [message]: ログメッセージ
  /// [context]: ログ発生元のコンテキスト情報（クラス名等）
  /// [data]: 追加データ（任意の型）
  void info(String message, {String? context, dynamic data});

  /// 警告ログを出力する
  ///
  /// [message]: ログメッセージ
  /// [context]: ログ発生元のコンテキスト情報（クラス名等）
  /// [data]: 追加データ（任意の型）
  void warning(String message, {String? context, dynamic data});

  /// エラーログを出力する
  ///
  /// [message]: ログメッセージ
  /// [context]: ログ発生元のコンテキスト情報（クラス名等）
  /// [error]: エラーオブジェクト
  /// [stackTrace]: スタックトレース
  void error(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  });

  /// パフォーマンス測定用のストップウォッチを開始する
  ///
  /// [operation]: 測定対象の操作名
  /// [context]: ログ発生元のコンテキスト情報（クラス名等）
  /// 戻り値: 開始済みのStopwatchインスタンス
  Stopwatch startTimer(String operation, {String? context});

  /// パフォーマンス測定を終了し、経過時間をログ出力する
  ///
  /// [stopwatch]: startTimerで取得したStopwatchインスタンス
  /// [operation]: 測定対象の操作名
  /// [context]: ログ発生元のコンテキスト情報（クラス名等）
  void endTimer(Stopwatch stopwatch, String operation, {String? context});
}
