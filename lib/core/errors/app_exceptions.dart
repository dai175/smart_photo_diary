/// アプリケーション全体で使用する標準化されたエラー
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.details,
    this.originalError,
    this.stackTrace,
  });

  /// ユーザーに表示する用のメッセージ
  String get userMessage => message;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// サービス関連エラー
class ServiceException extends AppException {
  const ServiceException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// 写真アクセス関連エラー
class PhotoAccessException extends AppException {
  const PhotoAccessException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// AI処理関連エラー
class AiProcessingException extends AppException {
  const AiProcessingException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// データベース関連エラー
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// 設定関連エラー
class SettingsException extends AppException {
  const SettingsException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// ネットワーク関連エラー
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// 権限関連エラー
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// バリデーション関連エラー
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// データが見つからない場合のエラー
class DataNotFoundException extends AppException {
  const DataNotFoundException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}

/// ストレージ関連エラー
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}
