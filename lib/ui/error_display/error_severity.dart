/// エラー表示の重要度レベル
enum ErrorSeverity {
  /// 情報レベル - ユーザーが知っておくべき情報
  info,

  /// 警告レベル - 注意が必要だが操作は継続可能
  warning,

  /// エラーレベル - 操作が失敗したが回復可能
  error,

  /// 重大レベル - アプリの機能に大きな影響がある
  critical,
}

/// エラー表示方法の種類
enum ErrorDisplayMethod {
  /// SnackBar - 軽微な情報やエラー
  snackBar,

  /// インラインエラー - 画面内に表示される継続的なエラー状態
  inline,

  /// ダイアログ - 重要なエラーでユーザーの確認が必要
  dialog,

  /// フルスクリーンエラー - アプリ全体に影響する重大なエラー
  fullScreen,
}

/// エラー表示設定
class ErrorDisplayConfig {
  final ErrorSeverity severity;
  final ErrorDisplayMethod method;
  final Duration? duration;
  final bool dismissible;
  final bool showRetryButton;
  final String? retryButtonText;
  final bool logError;

  const ErrorDisplayConfig({
    required this.severity,
    required this.method,
    this.duration,
    this.dismissible = true,
    this.showRetryButton = false,
    this.retryButtonText,
    this.logError = true,
  });

  /// 情報レベルのSnackBar設定
  static const ErrorDisplayConfig info = ErrorDisplayConfig(
    severity: ErrorSeverity.info,
    method: ErrorDisplayMethod.snackBar,
    duration: Duration(seconds: 3),
    logError: false,
  );

  /// 警告レベルのSnackBar設定
  static const ErrorDisplayConfig warning = ErrorDisplayConfig(
    severity: ErrorSeverity.warning,
    method: ErrorDisplayMethod.snackBar,
    duration: Duration(seconds: 4),
  );

  /// エラーレベルのダイアログ設定
  static const ErrorDisplayConfig error = ErrorDisplayConfig(
    severity: ErrorSeverity.error,
    method: ErrorDisplayMethod.dialog,
  );

  /// 重大エラーのダイアログ設定（リトライ付き）
  static const ErrorDisplayConfig criticalWithRetry = ErrorDisplayConfig(
    severity: ErrorSeverity.critical,
    method: ErrorDisplayMethod.dialog,
    dismissible: false,
    showRetryButton: true,
  );

  /// インラインエラー設定
  static const ErrorDisplayConfig inline = ErrorDisplayConfig(
    severity: ErrorSeverity.error,
    method: ErrorDisplayMethod.inline,
    showRetryButton: true,
  );
}
