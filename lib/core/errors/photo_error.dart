import 'app_exceptions.dart';

/// 写真関連の特定エラークラス
class PhotoError {
  /// カメラ権限が拒否された
  static PhotoAccessException cameraPermissionDenied() {
    return const PhotoAccessException(
      'Camera permission denied. Please allow camera access in Settings.',
      details: 'Camera permission denied',
    );
  }

  /// カメラが利用できない
  static PhotoAccessException cameraNotAvailable() {
    return const PhotoAccessException(
      'Camera is not available. Please check if your device has a camera.',
      details: 'Camera not available on device',
    );
  }

  /// 撮影後のAssetEntity取得に失敗
  static PhotoAccessException cameraAssetNotFound() {
    return const PhotoAccessException(
      'Failed to retrieve captured photo. Please wait and try again.',
      details: 'Failed to retrieve captured photo asset',
    );
  }

  /// カメラ撮影中にエラーが発生
  static PhotoAccessException cameraCaptureFailed({String? details}) {
    return PhotoAccessException(
      'An error occurred during camera capture.',
      details: details ?? 'Camera capture failed',
    );
  }
}
