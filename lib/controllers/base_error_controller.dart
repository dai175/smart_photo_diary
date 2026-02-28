import 'package:flutter/material.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../ui/error_display/error_display_extensions.dart';
import '../ui/error_display/error_severity.dart';

/// エラーハンドリング機能を持つベースController
abstract class BaseErrorController extends ChangeNotifier {
  bool _isLoading = false;
  AppException? _lastError;

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// 最後のエラー
  AppException? get lastError => _lastError;

  /// エラーがあるか
  bool get hasError => _lastError != null;

  /// ローディング状態を設定
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (loading) {
        _lastError = null; // ローディング開始時にエラーをクリア
      }
      notifyListeners();
    }
  }

  /// エラーを設定
  void setError(AppException? error) {
    if (_lastError != error) {
      _lastError = error;
      _isLoading = false; // エラー時はローディングを停止
      notifyListeners();
    }
  }

  /// エラーをクリア
  void clearError() {
    setError(null);
  }

  /// 安全な非同期処理実行
  Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    bool setLoadingState = true,
    String? context,
  }) async {
    try {
      if (setLoadingState) setLoading(true);
      final result = await operation();
      if (setLoadingState) setLoading(false);
      clearError();
      return result;
    } catch (e) {
      final exception = e is AppException
          ? e
          : ServiceException(
              context != null
                  ? '[$context] An error occurred during processing'
                  : 'An error occurred during processing',
              originalError: e,
            );
      setError(exception);
      return null;
    }
  }

  /// Result型を返す安全な非同期処理実行
  Future<Result<T>> safeExecuteResult<T>(
    Future<Result<T>> Function() operation, {
    bool setLoadingState = true,
    String? context,
  }) async {
    try {
      if (setLoadingState) setLoading(true);
      final result = await operation();
      if (setLoadingState) setLoading(false);

      if (result.isSuccess) {
        clearError();
      } else {
        setError(result.error);
      }

      return result;
    } catch (e) {
      final exception = e is AppException
          ? e
          : ServiceException(
              context != null
                  ? '[$context] An error occurred during processing'
                  : 'An error occurred during processing',
              originalError: e,
            );
      setError(exception);
      return Failure(exception);
    }
  }

  /// UIにエラーを表示
  Future<void> showErrorInUI(
    BuildContext context, {
    ErrorDisplayConfig? config,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    if (_lastError != null && context.mounted) {
      await context.showError(
        _lastError!,
        config: config,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }
  }

  /// エラーハンドリング付きで処理を実行しUIに表示
  Future<T?> executeWithErrorDisplay<T>(
    BuildContext context,
    Future<T> Function() operation, {
    bool setLoadingState = true,
    String? operationContext,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) async {
    final result = await safeExecute(
      operation,
      setLoadingState: setLoadingState,
      context: operationContext,
    );

    if (result == null && _lastError != null && context.mounted) {
      await showErrorInUI(
        context,
        config: errorConfig,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      );
    }

    return result;
  }

  /// Result型を返すエラーハンドリング付き処理
  Future<Result<T>> executeResultWithErrorDisplay<T>(
    BuildContext context,
    Future<Result<T>> Function() operation, {
    bool setLoadingState = true,
    String? operationContext,
    ErrorDisplayConfig? errorConfig,
    VoidCallback? onRetry,
    String? retryButtonText,
    bool showErrors = true,
  }) async {
    final result = await safeExecuteResult(
      operation,
      setLoadingState: setLoadingState,
      context: operationContext,
    );

    if (result.isFailure && showErrors) {
      if (context.mounted) {
        await showErrorInUI(
          context,
          config: errorConfig,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
        );
      }
    }

    return result;
  }

  /// リトライ機能付きで処理を実行
  Future<T?> executeWithRetry<T>(
    BuildContext context,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool setLoadingState = true,
    String? operationContext,
    ErrorDisplayConfig? errorConfig,
    String? retryButtonText,
  }) async {
    int attempts = 0;

    Future<T?> attemptOperation() async {
      attempts++;
      return await safeExecute(
        operation,
        setLoadingState: attempts == 1 ? setLoadingState : false,
        context: operationContext,
      );
    }

    final result = await attemptOperation();

    VoidCallback? onRetry;
    if (attempts < maxRetries) {
      onRetry = () async {
        await Future.delayed(retryDelay);
        if (context.mounted) {
          await executeWithRetry(
            context,
            operation,
            maxRetries: maxRetries - attempts,
            retryDelay: retryDelay,
            setLoadingState: false,
            operationContext: operationContext,
            errorConfig: errorConfig,
            retryButtonText: retryButtonText,
          );
        }
      };
    }

    if (result == null && _lastError != null) {
      if (context.mounted) {
        await showErrorInUI(
          context,
          config: errorConfig,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
        );
      }
    }

    return result;
  }
}

/// エラー状態を扱うMixin
mixin ErrorStateMixin on ChangeNotifier {
  AppException? _error;
  bool _isLoading = false;

  AppException? get error => _error;
  bool get hasError => _error != null;
  bool get isLoading => _isLoading;

  void setError(AppException? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
