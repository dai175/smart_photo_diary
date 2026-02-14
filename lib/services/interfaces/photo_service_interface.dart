import 'package:photo_manager/photo_manager.dart';
import '../../core/result/result.dart';

/// 写真サービスのインターフェース
///
/// 写真アクセス権限管理、写真クエリ、バイナリデータ取得、カメラ撮影を統合するFacade。
/// 内部的にはIPhotoPermissionService、PhotoQueryService、PhotoDataService、
/// ICameraServiceに委譲される。
abstract class IPhotoService {
  /// 写真アクセス権限をリクエストする
  ///
  /// iOS 14以降で Limited Access が付与された場合も true を返す。
  /// Limited Access かどうかの判定は [isLimitedAccess] で確認すること。
  ///
  /// 戻り値: 権限が許可された場合 true（Limited Access含む）、拒否された場合 false。
  /// エラー時は false を返す（例外をスローしない）。
  Future<bool> requestPermission();

  /// 権限が永続的に拒否されているかチェック
  ///
  /// 戻り値: 永続的に拒否されている場合 true。
  /// エラー時は false を返す（例外をスローしない）。
  Future<bool> isPermissionPermanentlyDenied();

  /// 今日撮影された写真を取得する
  ///
  /// Limited Access（iOS 14+）の場合、ユーザーが選択した写真のみ返される。
  /// 日付範囲によるアクセス制限（プレミアム: 365日）は
  /// [IPhotoAccessControlService] の責務であり、このメソッドでは適用されない。
  ///
  /// Returns:
  /// - Success: [AssetEntity] リスト
  /// - Failure: [PhotoAccessException] 権限なし・写真取得失敗時
  Future<Result<List<AssetEntity>>> getTodayPhotos({int limit = 20});

  /// 指定された日付範囲の写真を取得する
  ///
  /// Returns:
  /// - Success: [AssetEntity] リスト
  /// - Failure: [PhotoAccessException] 権限なし・写真取得失敗時
  Future<Result<List<AssetEntity>>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  });

  /// 指定された日付の写真を取得する
  ///
  /// Returns:
  /// - Success: [AssetEntity] リスト
  /// - Failure: [PhotoAccessException] 権限なし・写真取得失敗時
  Future<Result<List<AssetEntity>>> getPhotosForDate(
    DateTime date, {
    required int offset,
    required int limit,
  });

  /// 写真のバイナリデータを取得する
  ///
  /// 戻り値: バイトデータ。取得失敗時は null（ログ記録済み）。
  Future<List<int>?> getPhotoData(AssetEntity asset);

  /// 写真のサムネイルデータを取得する
  ///
  /// 戻り値: バイトデータ。取得失敗時は null（ログ記録済み）。
  Future<List<int>?> getThumbnailData(AssetEntity asset);

  /// 写真の元画像を取得する（後方互換性）
  ///
  /// 戻り値型は後方互換性のため dynamic だが、実際には Uint8List? を返す。
  /// 取得失敗時は null（ログ記録済み）。
  Future<dynamic> getOriginalFile(AssetEntity asset);

  /// 写真のサムネイルを取得する（後方互換性）
  ///
  /// 戻り値型は後方互換性のため dynamic だが、実際には Uint8List? を返す。
  /// 取得失敗時は null（ログ記録済み）。
  Future<dynamic> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  });

  /// Limited Photo Access時に写真選択画面を表示
  ///
  /// 戻り値: 選択が行われた場合 true。エラー時は false。
  Future<bool> presentLimitedLibraryPicker();

  /// 現在の権限状態が Limited Access かチェック
  ///
  /// 戻り値: Limited Access の場合 true。エラー時は false。
  Future<bool> isLimitedAccess();

  /// 効率的な写真取得（ページネーション対応）
  ///
  /// Returns:
  /// - Success: [AssetEntity] リスト
  /// - Failure: [PhotoAccessException] 権限なし・写真取得失敗時
  Future<Result<List<AssetEntity>>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  });

  /// 写真IDリストからAssetEntityを取得する
  ///
  /// 個別IDの取得失敗はスキップされ、取得成功したもののみ返す。
  ///
  /// Returns:
  /// - Success: 取得成功した [AssetEntity] リスト（一部失敗時は部分リスト）
  /// - Failure: [PhotoAccessException] 全体的な処理失敗時
  Future<Result<List<AssetEntity>>> getAssetsByIds(List<String> photoIds);

  // ========================================
  // カメラ撮影機能
  // ========================================

  /// カメラから写真を撮影する
  ///
  /// Returns:
  /// - Success: 撮影成功時はAssetEntityを返す、キャンセル時はnullを返す
  /// - Failure: [PermissionException] カメラアクセス拒否時
  /// - Failure: [AppException] デバイス利用不可、アセット保存失敗時
  Future<Result<AssetEntity?>> capturePhoto();

  /// カメラ権限をリクエストする
  ///
  /// Returns:
  /// - Success: 権限許可の場合true、拒否の場合false
  /// - Failure: [AppException] 権限チェック処理でエラーが発生した場合
  Future<Result<bool>> requestCameraPermission();

  /// カメラ権限が拒否されているかチェック
  ///
  /// Returns:
  /// - Success: 拒否されている場合true、許可されている場合false
  /// - Failure: [AppException] 権限チェック処理でエラーが発生した場合
  Future<Result<bool>> isCameraPermissionDenied();
}
