import 'package:flutter/material.dart';
import '../errors/app_exceptions.dart';
import '../../ui/error_display/error_display_extensions.dart';
import '../../ui/error_display/error_severity.dart';
import '../../ui/error_display/error_display_widgets.dart';
import 'result.dart';

/// Result型のUI統合拡張
extension ResultUIExtensions<T> on Result<T> {
  /// エラーを画面に表示
  Future<void> showErrorOnUI(
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

  /// 成功時にメッセージを表示
  void showSuccessOnUI(
    BuildContext context,
    String Function(T value) messageBuilder, {
    Duration? duration,
  }) {
    if (isSuccess && context.mounted) {
      context.showSuccess(messageBuilder(value), duration: duration);
    }
  }

  /// 結果に応じてUIメッセージを表示
  Future<void> showResultOnUI(
    BuildContext context, {
    String Function(T value)? onSuccess,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
    Duration? successDuration,
  }) async {
    if (!context.mounted) return;

    if (isSuccess && onSuccess != null) {
      context.showSuccess(onSuccess(value), duration: successDuration);
    } else if (isFailure) {
      await context.showError(
        error,
        config: errorConfig,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }

  /// 条件付きエラー表示
  Future<void> showErrorOnUIIf(
    BuildContext context,
    bool Function(AppException error) condition, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    if (isFailure && condition(error) && context.mounted) {
      await showErrorOnUI(
        context,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }

  /// 特定のエラータイプのみ表示
  Future<void> showErrorOnUIOfType<E extends AppException>(
    BuildContext context, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    if (isFailure && error is E && context.mounted) {
      await showErrorOnUI(
        context,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }
}

/// Future Result型のUI統合拡張
extension FutureResultUIExtensions<T> on Future<Result<T>> {
  /// 非同期結果のエラーを表示
  Future<Result<T>> showErrorsOnUI(
    BuildContext context, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final result = await this;
    if (!context.mounted) return result;

    await result.showErrorOnUI(
      context,
      config: config,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
    return result;
  }

  /// 非同期結果の成功メッセージを表示
  Future<Result<T>> showSuccessOnUI(
    BuildContext context,
    String Function(T value) messageBuilder, {
    Duration? duration,
  }) async {
    final result = await this;
    if (!context.mounted) return result;

    result.showSuccessOnUI(context, messageBuilder, duration: duration);
    return result;
  }

  /// 非同期結果のメッセージを表示
  Future<Result<T>> showResultOnUI(
    BuildContext context, {
    String Function(T value)? onSuccess,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
    Duration? successDuration,
  }) async {
    final result = await this;
    if (!context.mounted) return result;

    await result.showResultOnUI(
      context,
      onSuccess: onSuccess,
      errorConfig: errorConfig,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
      successDuration: successDuration,
    );
    return result;
  }

  /// 条件付きエラー表示
  Future<Result<T>> showErrorsOnUIIf(
    BuildContext context,
    bool Function(AppException error) condition, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final result = await this;
    if (!context.mounted) return result;

    await result.showErrorOnUIIf(
      context,
      condition,
      config: config,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
    return result;
  }

  /// 特定のエラータイプのみ表示
  Future<Result<T>> showErrorsOnUIOfType<E extends AppException>(
    BuildContext context, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final result = await this;
    if (!context.mounted) return result;

    await result.showErrorOnUIOfType<E>(
      context,
      config: config,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
    return result;
  }
}

/// Result型用のUIビルダー
class ResultUIBuilder<T> extends StatelessWidget {
  final Result<T> result;
  final Widget Function(T value) onSuccess;
  final Widget Function(AppException error, VoidCallback? retry)? onError;
  final Widget? onLoading;
  final VoidCallback? onRetry;
  final ErrorDisplayConfig? errorConfig;
  final bool showInlineErrors;

  const ResultUIBuilder({
    super.key,
    required this.result,
    required this.onSuccess,
    this.onError,
    this.onLoading,
    this.onRetry,
    this.errorConfig,
    this.showInlineErrors = true,
  });

  @override
  Widget build(BuildContext context) {
    if (result.isSuccess) {
      return onSuccess(result.value);
    } else {
      if (onError != null) {
        return onError!(result.error, onRetry);
      } else if (showInlineErrors) {
        return ErrorInlineWidget(
          error: result.error,
          config: errorConfig ?? ErrorDisplayConfig.inline,
          onRetry: onRetry,
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }
}

/// Future Result型用のUIビルダー
class FutureResultUIBuilder<T> extends StatelessWidget {
  final Future<Result<T>> future;
  final Widget Function(T value) onSuccess;
  final Widget Function(AppException error, VoidCallback? retry)? onError;
  final Widget? onLoading;
  final VoidCallback? onRetry;
  final ErrorDisplayConfig? errorConfig;
  final bool showInlineErrors;
  final bool showDialogErrors;

  const FutureResultUIBuilder({
    super.key,
    required this.future,
    required this.onSuccess,
    this.onError,
    this.onLoading,
    this.onRetry,
    this.errorConfig,
    this.showInlineErrors = true,
    this.showDialogErrors = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return onLoading ?? const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final result = snapshot.data!;

          // ダイアログエラー表示が有効な場合
          if (showDialogErrors && result.isFailure) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              result.showErrorOnUI(
                context,
                config: errorConfig,
                onRetry: onRetry,
              );
            });
          }

          return ResultUIBuilder<T>(
            result: result,
            onSuccess: onSuccess,
            onError: onError,
            onRetry: onRetry,
            errorConfig: errorConfig,
            showInlineErrors: showInlineErrors && !showDialogErrors,
          );
        } else {
          // snapshot.hasError の場合
          final error = snapshot.error is AppException
              ? snapshot.error as AppException
              : ServiceException(
                  'データの読み込み中にエラーが発生しました',
                  originalError: snapshot.error,
                );

          if (onError != null) {
            return onError!(error, onRetry);
          } else {
            return ErrorInlineWidget(
              error: error,
              config: errorConfig ?? ErrorDisplayConfig.error,
              onRetry: onRetry,
            );
          }
        }
      },
    );
  }
}
