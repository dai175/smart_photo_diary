import 'package:photo_manager/photo_manager.dart';
import '../../core/result/result.dart';

/// 写真サービスのインターフェース
abstract class IPhotoService {
  /// 写真アクセス権限をリクエストする
  Future<bool> requestPermission();

  /// 権限が永続的に拒否されているかチェック
  Future<bool> isPermissionPermanentlyDenied();

  /// 今日撮影された写真を取得する
  Future<List<AssetEntity>> getTodayPhotos({int limit = 20});

  /// 指定された日付範囲の写真を取得する
  Future<List<AssetEntity>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  });

  /// 指定された日付の写真を取得する
  Future<List<AssetEntity>> getPhotosForDate(
    DateTime date, {
    required int offset,
    required int limit,
  });

  /// 写真のバイナリデータを取得する
  Future<List<int>?> getPhotoData(AssetEntity asset);

  /// 写真のサムネイルデータを取得する
  Future<List<int>?> getThumbnailData(AssetEntity asset);

  /// 写真の元画像を取得する（後方互換性）
  Future<dynamic> getOriginalFile(AssetEntity asset);

  /// 写真のサムネイルを取得する（後方互換性）
  Future<dynamic> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  });

  /// Limited Photo Access時に写真選択画面を表示
  Future<bool> presentLimitedLibraryPicker();

  /// 現在の権限状態が Limited Access かチェック
  Future<bool> isLimitedAccess();

  /// 効率的な写真取得（ページネーション対応）
  Future<List<AssetEntity>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  });

  // ========================================
  // Result<T>パターン版のメソッド
  // ========================================

  /// 効率的な写真取得（Result版）
  Future<Result<List<AssetEntity>>> getPhotosEfficientResult({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  });

  // ========================================
  // カメラ撮影機能（新規追加）
  // ========================================

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
