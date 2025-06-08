/// アプリケーション全体で使用する標準化されたエラー
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  const AppException(this.message, {this.details, this.originalError});

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
  const ServiceException(super.message, {super.details, super.originalError});
}

/// 写真アクセス関連エラー
class PhotoAccessException extends AppException {
  const PhotoAccessException(super.message, {super.details, super.originalError});
}

/// AI処理関連エラー
class AiProcessingException extends AppException {
  const AiProcessingException(super.message, {super.details, super.originalError});
}

/// データベース関連エラー
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.details, super.originalError});
}

/// 設定関連エラー
class SettingsException extends AppException {
  const SettingsException(super.message, {super.details, super.originalError});
}

/// ネットワーク関連エラー
class NetworkException extends AppException {
  const NetworkException(super.message, {super.details, super.originalError});
}

/// 権限関連エラー
class PermissionException extends AppException {
  const PermissionException(super.message, {super.details, super.originalError});
}

/// バリデーション関連エラー
class ValidationException extends AppException {
  const ValidationException(super.message, {super.details, super.originalError});
}