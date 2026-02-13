import 'package:flutter/material.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import 'error_display_service.dart';
import 'error_severity.dart';

/// BuildContextのエラー表示拡張
extension ErrorDisplayExtensions on BuildContext {
  /// エラーを表示
  Future<void> showError(
    AppException error, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final errorDisplay = ErrorDisplayService();
    await errorDisplay.showError(
      this,
      error,
      config: config,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
  }

  /// Result型からエラーを表示
  Future<void> showResultError<T>(
    Result<T> result, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    if (result.isFailure) {
      await showError(
        result.error,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }

  /// 成功メッセージを表示
  void showSuccess(String message, {Duration? duration}) {
    final errorDisplay = ErrorDisplayService();
    errorDisplay.showSuccessMessage(this, message, duration: duration);
  }

  /// 情報メッセージを表示
  void showInfo(String message, {Duration? duration}) {
    final errorDisplay = ErrorDisplayService();
    errorDisplay.showInfoMessage(this, message, duration: duration);
  }

  /// 警告メッセージを表示
  void showWarning(
    String message, {
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    showError(
      ValidationException(message),
      config: ErrorDisplayConfig.warning,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
  }

  /// 簡単なエラーメッセージを表示
  void showSimpleError(
    String message, {
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    showError(
      ServiceException(message),
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
  }

  /// ネットワークエラーを表示
  void showNetworkError(
    String message, {
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    showError(
      NetworkException(message),
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
  }

  /// 権限エラーを表示
  void showPermissionError(
    String message, {
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    showError(
      PermissionException(message),
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
  }
}

/// Future Result型のエラー表示拡張
extension FutureResultErrorExtensions<T> on Future<Result<T>> {
  /// Resultのエラーを自動表示
  Future<Result<T>> showErrorsOn(
    BuildContext context, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final result = await this;
    if (result.isFailure && context.mounted) {
      await context.showError(
        result.error,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
    return result;
  }

  /// 成功時のメッセージを表示
  Future<Result<T>> showSuccessOn(
    BuildContext context,
    String Function(T value) messageBuilder, {
    Duration? duration,
  }) async {
    final result = await this;
    if (result.isSuccess && context.mounted) {
      context.showSuccess(messageBuilder(result.value), duration: duration);
    }
    return result;
  }

  /// 結果に関わらずメッセージを表示
  Future<Result<T>> showMessagesOn(
    BuildContext context, {
    String Function(T value)? onSuccess,
    String Function(AppException error)? onFailure,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
    Duration? successDuration,
  }) async {
    final result = await this;
    if (!context.mounted) return result;

    if (result.isSuccess && onSuccess != null) {
      context.showSuccess(onSuccess(result.value), duration: successDuration);
    } else if (result.isFailure) {
      await context.showError(
        result.error,
        config: errorConfig,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
    return result;
  }
}

/// Result型のエラー表示拡張
extension ResultErrorExtensions<T> on Result<T> {
  /// エラーを表示
  Future<void> showErrorOn(
    BuildContext context, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    if (isFailure && context.mounted) {
      await context.showError(
        error,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }

  /// 成功メッセージを表示
  void showSuccessOn(
    BuildContext context,
    String Function(T value) messageBuilder, {
    Duration? duration,
  }) {
    if (isSuccess && context.mounted) {
      context.showSuccess(messageBuilder(value), duration: duration);
    }
  }
}

/// アクション実行用ヘルパー
class ErrorHandledAction {
  final BuildContext context;

  const ErrorHandledAction(this.context);

  /// エラーハンドリング付きで非同期処理を実行
  Future<void> execute(
    Future<void> Function() action, {
    String? loadingMessage,
    String? successMessage,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    try {
      if (loadingMessage != null && context.mounted) {
        context.showInfo(loadingMessage);
      }

      await action();

      if (successMessage != null && context.mounted) {
        context.showSuccess(successMessage);
      }
    } catch (e) {
      if (context.mounted) {
        final exception = e is AppException
            ? e
            : ServiceException(
                'An error occurred during processing',
                originalError: e,
              );

        await context.showError(
          exception,
          config: errorConfig,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
        );
      }
    }
  }

  /// Result型を返す非同期処理を実行
  Future<Result<T>> executeWithResult<T>(
    Future<Result<T>> Function() action, {
    String? loadingMessage,
    String Function(T value)? successMessage,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
    bool showErrors = true,
  }) async {
    try {
      if (loadingMessage != null && context.mounted) {
        context.showInfo(loadingMessage);
      }

      final result = await action();

      if (!context.mounted) return result;

      if (result.isSuccess && successMessage != null) {
        context.showSuccess(successMessage(result.value));
      } else if (result.isFailure && showErrors) {
        await context.showError(
          result.error,
          config: errorConfig,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
        );
      }

      return result;
    } catch (e) {
      final exception = e is AppException
          ? e
          : ServiceException(
              'An error occurred during processing',
              originalError: e,
            );

      if (context.mounted && showErrors) {
        await context.showError(
          exception,
          config: errorConfig,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
        );
      }

      return Failure(exception);
    }
  }
}
