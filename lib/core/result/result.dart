import '../errors/app_exceptions.dart';

/// Result型 - 成功（Success）または失敗（Failure）を表現する型
///
/// 例外をスローする代わりに、成功・失敗を明示的に表現することで、
/// より安全で予測可能なエラーハンドリングを実現します。
sealed class Result<T> {
  const Result();

  /// 成功かどうかを判定
  bool get isSuccess => this is Success<T>;

  /// 失敗かどうかを判定
  bool get isFailure => this is Failure<T>;

  /// 成功時の値を取得（失敗時は例外をスロー）
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    throw StateError(
      'Result is not Success. Check isSuccess before accessing value.',
    );
  }

  /// 失敗時のエラーを取得（成功時は例外をスロー）
  AppException get error {
    if (this is Failure<T>) {
      return (this as Failure<T>).exception;
    }
    throw StateError(
      'Result is not Failure. Check isFailure before accessing error.',
    );
  }

  /// 成功時の値を安全に取得（失敗時はnullを返す）
  T? get valueOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  /// 失敗時のエラーを安全に取得（成功時はnullを返す）
  AppException? get errorOrNull {
    if (this is Failure<T>) {
      return (this as Failure<T>).exception;
    }
    return null;
  }

  /// 成功時の値またはデフォルト値を取得
  T getOrDefault(T defaultValue) {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return defaultValue;
  }

  /// Resultを別の型にマップ（成功時のみ実行）
  Result<R> map<R>(R Function(T value) mapper) {
    if (this is Success<T>) {
      try {
        return Success(mapper((this as Success<T>).data));
      } catch (e) {
        return Failure(
          ServiceException(
            'An error occurred during map processing',
            originalError: e,
          ),
        );
      }
    }
    return Failure((this as Failure<T>).exception);
  }

  /// 非同期Resultを別の型にマップ
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) mapper) async {
    if (this is Success<T>) {
      try {
        final result = await mapper((this as Success<T>).data);
        return Success(result);
      } catch (e) {
        return Failure(
          ServiceException(
            'An error occurred during async map processing',
            originalError: e,
          ),
        );
      }
    }
    return Failure((this as Failure<T>).exception);
  }

  /// 結果に応じて処理を分岐
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(AppException error) onFailure,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    }
    return onFailure((this as Failure<T>).exception);
  }

  /// 非同期版のfold
  Future<R> foldAsync<R>(
    Future<R> Function(T value) onSuccess,
    Future<R> Function(AppException error) onFailure,
  ) async {
    if (this is Success<T>) {
      return await onSuccess((this as Success<T>).data);
    }
    return await onFailure((this as Failure<T>).exception);
  }

  /// 成功時のみコールバックを実行
  Result<T> onSuccess(void Function(T value) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).data);
    }
    return this;
  }

  /// 失敗時のみコールバックを実行
  Result<T> onFailure(void Function(AppException error) callback) {
    if (this is Failure<T>) {
      callback((this as Failure<T>).exception);
    }
    return this;
  }

  @override
  String toString() {
    return fold((value) => 'Success($value)', (error) => 'Failure($error)');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Result<T> &&
        fold(
          (value) =>
              other.fold((otherValue) => value == otherValue, (_) => false),
          (error) => other.fold(
            (_) => false,
            (otherError) => error.toString() == otherError.toString(),
          ),
        );
  }

  @override
  int get hashCode {
    return fold(
      (value) => value.hashCode,
      (error) => error.toString().hashCode,
    );
  }
}

/// 成功を表すResult
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

/// 失敗を表すResult
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);
}
