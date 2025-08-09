import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'result.dart';
import '../errors/app_exceptions.dart';

/// PhotoService専用のResult型作成ヘルパーユーティリティ
///
/// PhotoServiceで使用される一般的なResult型の作成を簡素化し、
/// 一貫したエラーハンドリングを提供します。
class PhotoResultHelper {
  PhotoResultHelper._();

  /// 写真権限の結果を作成
  ///
  /// [granted] 権限が付与されたかどうか
  /// [isDenied] 権限が拒否されたか
  /// [isPermanentlyDenied] 権限が永続的に拒否されたか
  /// [isLimited] 制限付きアクセスか（iOS）
  static Result<bool> photoPermissionResult({
    required bool granted,
    bool isDenied = false,
    bool isPermanentlyDenied = false,
    bool isLimited = false,
    String? errorMessage,
  }) {
    if (granted || isLimited) {
      return Success(granted);
    }

    if (isPermanentlyDenied) {
      return Failure(
        PhotoPermissionPermanentlyDeniedException(
          errorMessage ?? '写真アクセス権限が永続的に拒否されています。設定から権限を有効にしてください。',
        ),
      );
    }

    if (isDenied) {
      return Failure(
        PhotoPermissionDeniedException(errorMessage ?? '写真アクセス権限が拒否されました。'),
      );
    }

    return Failure(PhotoAccessException(errorMessage ?? '写真アクセス権限の取得に失敗しました。'));
  }

  /// 写真アクセスの結果を作成
  ///
  /// [photos] 取得した写真のリスト
  /// [hasPermission] 権限があるか
  /// [errorMessage] エラーメッセージ
  /// [originalError] 元のエラー
  static Result<List<AssetEntity>> photoAccessResult(
    List<AssetEntity>? photos, {
    bool hasPermission = true,
    String? errorMessage,
    dynamic originalError,
  }) {
    if (!hasPermission) {
      return Failure(
        PhotoAccessException(
          errorMessage ?? '写真アクセス権限がありません。',
          originalError: originalError,
        ),
      );
    }

    if (photos == null) {
      return Failure(
        PhotoAccessException(
          errorMessage ?? '写真の取得に失敗しました。',
          originalError: originalError,
        ),
      );
    }

    return Success(photos);
  }

  /// 写真データの結果を作成
  ///
  /// [data] 写真のバイナリデータ
  /// [isCorrupted] データが破損しているか
  /// [errorMessage] エラーメッセージ
  /// [originalError] 元のエラー
  static Result<Uint8List?> photoDataResult(
    Uint8List? data, {
    bool isCorrupted = false,
    String? errorMessage,
    dynamic originalError,
  }) {
    if (isCorrupted) {
      return Failure(
        PhotoDataCorruptedException(
          errorMessage ?? '写真データが破損しています。',
          originalError: originalError,
        ),
      );
    }

    if (data == null || data.isEmpty) {
      return Failure(
        PhotoAccessException(
          errorMessage ?? '写真データの取得に失敗しました。',
          originalError: originalError,
        ),
      );
    }

    return Success(data);
  }

  /// void操作の結果を作成
  ///
  /// [success] 操作が成功したか
  /// [errorMessage] エラーメッセージ
  /// [originalError] 元のエラー
  static Result<void> voidResult({
    bool success = true,
    String? errorMessage,
    dynamic originalError,
  }) {
    if (success) {
      return const Success(null);
    }

    return Failure(
      PhotoAccessException(
        errorMessage ?? '写真操作に失敗しました。',
        originalError: originalError,
      ),
    );
  }

  /// Limited Access処理の結果を作成
  ///
  /// [success] 処理が成功したか
  /// [errorMessage] エラーメッセージ
  /// [originalError] 元のエラー
  static Result<void> limitedAccessResult({
    bool success = true,
    String? errorMessage,
    dynamic originalError,
  }) {
    if (success) {
      return const Success(null);
    }

    return Failure(
      PhotoLimitedAccessException(
        errorMessage ?? '制限付き写真アクセスの処理に失敗しました。',
        originalError: originalError,
      ),
    );
  }

  /// 写真リストが空の場合の処理
  ///
  /// [photos] 写真リスト
  /// [allowEmpty] 空リストを許可するか
  /// [emptyMessage] 空の場合のメッセージ
  static Result<List<AssetEntity>> validatePhotoList(
    List<AssetEntity> photos, {
    bool allowEmpty = true,
    String? emptyMessage,
  }) {
    if (photos.isEmpty && !allowEmpty) {
      return Failure(DataNotFoundException(emptyMessage ?? '写真が見つかりません。'));
    }

    return Success(photos);
  }

  /// 写真権限の状態から結果を作成
  ///
  /// [state] PhotoManagerの権限状態
  static Result<bool> fromPermissionState(PermissionState state) {
    switch (state) {
      case PermissionState.authorized:
        return const Success(true);
      case PermissionState.limited:
        return const Success(true); // Limited Accessも部分的に許可とみなす
      case PermissionState.denied:
        return Failure(PhotoPermissionDeniedException('写真アクセス権限が拒否されました。'));
      case PermissionState.restricted:
        return Failure(PhotoPermissionDeniedException('写真アクセスが制限されています。'));
      // PhotoManagerにはpermanentlyDeniedが存在しないため、
      // この処理は他の権限チェック（permission_handler）で使用
      case PermissionState.notDetermined:
        return Failure(PhotoAccessException('写真アクセス権限が未確定です。'));
    }
  }

  /// エラーから適切なPhotoAccessExceptionを生成
  ///
  /// [error] 元のエラー
  /// [context] エラーのコンテキスト
  static Result<T> fromError<T>(
    dynamic error, {
    String? context,
    String? customMessage,
  }) {
    String message = customMessage ?? '写真操作でエラーが発生しました。';

    if (context != null) {
      message = '$context: $message';
    }

    return Failure(
      PhotoAccessException(
        message,
        originalError: error,
        details: error.toString(),
      ),
    );
  }

  /// 複数の写真操作結果をまとめる
  ///
  /// [results] 複数のResult
  /// [allowPartialSuccess] 部分的な成功を許可するか
  static Result<List<T>> combineResults<T>(
    List<Result<T>> results, {
    bool allowPartialSuccess = false,
  }) {
    final List<T> successValues = [];
    final List<AppException> errors = [];

    for (final result in results) {
      result.fold(
        (value) => successValues.add(value),
        (error) => errors.add(error),
      );
    }

    // すべて成功
    if (errors.isEmpty) {
      return Success(successValues);
    }

    // 部分的成功を許可し、成功した値がある場合
    if (allowPartialSuccess && successValues.isNotEmpty) {
      return Success(successValues);
    }

    // すべて失敗またはすべて失敗で部分的成功を許可しない場合
    return Failure(
      PhotoAccessException(
        '複数の写真操作中にエラーが発生しました。',
        details:
            '${errors.length}件のエラー: ${errors.map((e) => e.message).join(', ')}',
        originalError: errors.first,
      ),
    );
  }
}

/// PhotoService専用の例外クラス（詳細化されたエラー情報）
class PhotoPermissionDeniedException extends PhotoAccessException {
  const PhotoPermissionDeniedException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => '写真アクセス権限が必要です。設定から権限を許可してください。';
}

class PhotoPermissionPermanentlyDeniedException extends PhotoAccessException {
  const PhotoPermissionPermanentlyDeniedException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => '写真アクセス権限が拒否されています。設定アプリから権限を有効にしてください。';
}

class PhotoLimitedAccessException extends PhotoAccessException {
  const PhotoLimitedAccessException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => '制限付きの写真アクセスです。より多くの写真にアクセスするには設定を変更してください。';
}

class PhotoDataCorruptedException extends PhotoAccessException {
  const PhotoDataCorruptedException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => '写真データが破損しているか読み取れません。';
}
