import 'app_exceptions.dart';

/// 写真関連の特定エラークラス
class PhotoError {
  /// カメラ権限が拒否された
  static PhotoAccessException cameraPermissionDenied() {
    return const PhotoAccessException(
      'カメラの権限が拒否されています。設定からカメラアクセスを許可してください。',
      details: 'Camera permission denied',
    );
  }

  /// カメラが利用できない
  static PhotoAccessException cameraNotAvailable() {
    return const PhotoAccessException(
      'カメラが利用できません。デバイスにカメラが搭載されているか確認してください。',
      details: 'Camera not available on device',
    );
  }

  /// 撮影後のAssetEntity取得に失敗
  static PhotoAccessException cameraAssetNotFound() {
    return const PhotoAccessException(
      '撮影した写真の取得に失敗しました。しばらく待ってから再度お試しください。',
      details: 'Failed to retrieve captured photo asset',
    );
  }

  /// カメラ撮影中にエラーが発生
  static PhotoAccessException cameraCaptureFailed({String? details}) {
    return PhotoAccessException(
      'カメラ撮影中にエラーが発生しました。',
      details: details ?? 'Camera capture failed',
    );
  }
}
