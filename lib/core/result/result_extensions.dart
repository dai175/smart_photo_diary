import 'dart:async';
import '../errors/app_exceptions.dart';
import 'result.dart';

/// Resultを簡単に作成するためのヘルパー関数群
class ResultHelper {
  /// 成功Resultを作成
  static Result<T> success<T>(T value) => Success(value);

  /// 失敗Resultを作成
  static Result<T> failure<T>(AppException exception) => Failure(exception);

  /// try-catchブロックをResultに変換
  static Result<T> tryExecute<T>(T Function() operation, {String? context}) {
    try {
      return Success(operation());
    } catch (e) {
      final exception = e is AppException
          ? e
          : ServiceException(
              context != null
                  ? '[$context] An error occurred during processing'
                  : 'An error occurred during processing',
              originalError: e,
            );
      return Failure(exception);
    }
  }

  /// 非同期try-catchブロックをResultに変換
  static Future<Result<T>> tryExecuteAsync<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e) {
      final exception = e is AppException
          ? e
          : ServiceException(
              context != null
                  ? '[$context] An error occurred during async processing'
                  : 'An error occurred during async processing',
              originalError: e,
            );
      return Failure(exception);
    }
  }

  /// 複数のResultを組み合わせて、全て成功時のみ成功を返す
  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final values = <T>[];

    for (final result in results) {
      if (result.isFailure) {
        return Failure(result.error);
      }
      values.add(result.value);
    }

    return Success(values);
  }

  /// 複数の非同期Resultを組み合わせる
  static Future<Result<List<T>>> combineAsync<T>(
    List<Future<Result<T>>> futures,
  ) async {
    final results = await Future.wait(futures);
    return combine(results);
  }

  /// 条件に基づいてResultを作成
  static Result<T> fromCondition<T>(
    bool condition,
    T Function() onTrue,
    AppException Function() onFalse,
  ) {
    if (condition) {
      return tryExecute(onTrue);
    }
    return Failure(onFalse());
  }

  /// null許可型からResultを作成
  static Result<T> fromNullable<T>(T? value, AppException Function() onNull) {
    if (value != null) {
      return Success(value);
    }
    return Failure(onNull());
  }
}

/// Future Result型の拡張メソッド
extension FutureResultExtensions<T> on Future<Result<T>> {
  /// 非同期Resultをマップ
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) mapper) async {
    final result = await this;
    return result.mapAsync(mapper);
  }

  /// 非同期Resultをチェーン
  Future<Result<R>> chainAsync<R>(
    Future<Result<R>> Function(T value) mapper,
  ) async {
    final result = await this;
    if (result.isSuccess) {
      return await mapper(result.value);
    }
    return Failure(result.error);
  }

  /// 非同期Resultの値を安全に取得
  Future<T?> getValueOrNull() async {
    final result = await this;
    return result.valueOrNull;
  }

  /// 非同期Resultの値またはデフォルト値を取得
  Future<T> getOrDefault(T defaultValue) async {
    final result = await this;
    return result.getOrDefault(defaultValue);
  }
}

/// Listの拡張メソッド
extension ListResultExtensions<T> on List<Result<T>> {
  /// 成功したResultのみを抽出
  List<T> getSuccessValues() {
    return where(
      (result) => result.isSuccess,
    ).map((result) => result.value).toList();
  }

  /// 失敗したResultのみを抽出
  List<AppException> getFailureErrors() {
    return where(
      (result) => result.isFailure,
    ).map((result) => result.error).toList();
  }

  /// 全て成功かどうかを判定
  bool get allSuccess => every((result) => result.isSuccess);

  /// 全て失敗かどうかを判定
  bool get allFailure => every((result) => result.isFailure);

  /// 最初の失敗を取得
  Result<T>? get firstFailure => cast<Result<T>?>().firstWhere(
    (result) => result?.isFailure == true,
    orElse: () => null,
  );
}
