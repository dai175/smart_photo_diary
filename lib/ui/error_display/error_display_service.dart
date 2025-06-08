import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import '../../services/logging_service.dart';
import 'error_severity.dart';
import 'error_display_widgets.dart';

/// 統一されたエラー表示サービス
class ErrorDisplayService {
  static final ErrorDisplayService _instance = ErrorDisplayService._internal();
  factory ErrorDisplayService() => _instance;
  ErrorDisplayService._internal();

  LoggingService? _loggingService;

  LoggingService get loggingService {
    _loggingService ??= LoggingService.instance;
    return _loggingService!;
  }

  /// エラーを表示する
  Future<void> showError(
    BuildContext context,
    AppException error, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final displayConfig = config ?? _getDefaultConfigForError(error);
    
    // ログ出力
    if (displayConfig.logError) {
      try {
        loggingService.error(
          error.message,
          context: 'ErrorDisplayService',
          error: error.originalError,
          stackTrace: error.stackTrace,
        );
      } catch (e) {
        // LoggingService初期化エラーの場合はログ出力をスキップ
        debugPrint('ErrorDisplayService: Failed to log error - $e');
      }
    }

    // 表示方法に応じて適切なウィジェットで表示
    switch (displayConfig.method) {
      case ErrorDisplayMethod.snackBar:
        await _showSnackBarError(context, error, displayConfig, onRetry, retryButtonText);
        break;
      case ErrorDisplayMethod.dialog:
        await _showDialogError(context, error, displayConfig, onRetry, retryButtonText);
        break;
      case ErrorDisplayMethod.inline:
        // インラインエラーは直接ウィジェットで表示されるため、ここでは何もしない
        break;
      case ErrorDisplayMethod.fullScreen:
        await _showFullScreenError(context, error, displayConfig, onRetry, retryButtonText);
        break;
    }
  }

  /// Result<T>からエラーを表示
  Future<void> showResultError<T>(
    BuildContext context,
    Result<T> result, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    if (result.isFailure) {
      await showError(
        context,
        result.error,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }

  /// SnackBarでエラーを表示
  Future<void> _showSnackBarError(
    BuildContext context,
    AppException error,
    ErrorDisplayConfig config,
    VoidCallback? onRetry,
    String? retryButtonText,
  ) async {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: ErrorSnackBarContent(
        error: error,
        severity: config.severity,
      ),
      duration: config.duration ?? AppConstants.defaultAnimationDuration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: _getColorForSeverity(context, config.severity),
      action: config.showRetryButton && onRetry != null
          ? SnackBarAction(
              label: retryButtonText ?? config.retryButtonText ?? '再試行',
              onPressed: onRetry,
              textColor: Colors.white,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// ダイアログでエラーを表示
  Future<void> _showDialogError(
    BuildContext context,
    AppException error,
    ErrorDisplayConfig config,
    VoidCallback? onRetry,
    String? retryButtonText,
  ) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: config.dismissible,
      builder: (context) => ErrorDialogWidget(
        error: error,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText ?? config.retryButtonText,
      ),
    );
  }

  /// フルスクリーンでエラーを表示
  Future<void> _showFullScreenError(
    BuildContext context,
    AppException error,
    ErrorDisplayConfig config,
    VoidCallback? onRetry,
    String? retryButtonText,
  ) async {
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ErrorFullScreenWidget(
          error: error,
          config: config,
          onRetry: onRetry,
          retryButtonText: retryButtonText ?? config.retryButtonText,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// エラーに応じたデフォルト設定を取得
  ErrorDisplayConfig _getDefaultConfigForError(AppException error) {
    switch (error.runtimeType) {
      case ValidationException:
        return ErrorDisplayConfig.warning;
      case NetworkException:
        return ErrorDisplayConfig.criticalWithRetry;
      case PermissionException:
        return ErrorDisplayConfig.error;
      case ServiceException:
        return ErrorDisplayConfig.error;
      case DataNotFoundException:
        return ErrorDisplayConfig.warning;
      case StorageException:
        return ErrorDisplayConfig.criticalWithRetry;
      default:
        return ErrorDisplayConfig.error;
    }
  }

  /// 重要度に応じた色を取得
  Color _getColorForSeverity(BuildContext context, ErrorSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primary;
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800); // オレンジ
      case ErrorSeverity.error:
        return colorScheme.error;
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F); // 濃い赤
    }
  }

  /// 重要度に応じたアイコンを取得
  IconData getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  /// 成功メッセージを表示
  void showSuccessMessage(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 情報メッセージを表示
  void showInfoMessage(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}