import 'package:photo_manager/photo_manager.dart';
import '../../core/result/result.dart';

/// カメラ撮影サービスのインターフェース
abstract class ICameraService {
  /// カメラから写真を撮影する
  ///
  /// Returns:
  /// - Success: 撮影成功時はAssetEntityを返す、キャンセル時はnullを返す
  /// - Failure: カメラアクセス拒否、デバイス利用不可、その他のエラー
  Future<Result<AssetEntity?>> capturePhoto();

  /// カメラ権限をリクエストする
  ///
  /// Returns:
  /// - Success: 権限許可の場合true、拒否の場合false
  /// - Failure: 権限チェック処理でエラーが発生した場合
  Future<Result<bool>> requestCameraPermission();

  /// カメラ権限が拒否されているかチェック
  ///
  /// Returns:
  /// - Success: 拒否されている場合true、許可されている場合false
  /// - Failure: 権限チェック処理でエラーが発生した場合
  Future<Result<bool>> isCameraPermissionDenied();
}
