import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../../core/result/result.dart';

/// 写真サービスのインターフェース
abstract class PhotoServiceInterface {
  /// 写真アクセス権限をリクエストする
  Future<bool> requestPermission();

  /// 写真アクセス権限をリクエストする（Result<T>版・推奨）
  ///
  /// 従来の[requestPermission]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<bool>> requestPermissionResult();

  /// 権限が永続的に拒否されているかチェック
  Future<bool> isPermissionPermanentlyDenied();

  /// 権限が永続的に拒否されているかチェック（Result<T>版・推奨）
  ///
  /// 従来の[isPermissionPermanentlyDenied]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<bool>> isPermissionPermanentlyDeniedResult();

  /// 今日撮影された写真を取得する
  Future<List<AssetEntity>> getTodayPhotos({int limit = 20});

  /// 今日撮影された写真を取得する（Result<T>版・推奨）
  ///
  /// 従来の[getTodayPhotos]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<List<AssetEntity>>> getTodayPhotosResult({int limit = 20});

  /// 指定された日付範囲の写真を取得する
  Future<List<AssetEntity>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  });

  /// 指定された日付範囲の写真を取得する（Result<T>版・推奨）
  ///
  /// 従来の[getPhotosInDateRange]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<List<AssetEntity>>> getPhotosInDateRangeResult({
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

  /// 指定された日付の写真を取得する（Result<T>版・推奨）
  ///
  /// 従来の[getPhotosForDate]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<List<AssetEntity>>> getPhotosForDateResult(
    DateTime date, {
    required int offset,
    required int limit,
  });

  /// 写真のバイナリデータを取得する
  Future<List<int>?> getPhotoData(AssetEntity asset);

  /// 写真のバイナリデータを取得する（Result<T>版・推奨）
  ///
  /// 従来の[getPhotoData]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<List<int>>> getPhotoDataResult(AssetEntity asset);

  /// 写真のサムネイルデータを取得する
  Future<List<int>?> getThumbnailData(AssetEntity asset);

  /// 写真のサムネイルデータを取得する（Result<T>版・推奨）
  ///
  /// 従来の[getThumbnailData]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<List<int>>> getThumbnailDataResult(AssetEntity asset);

  /// 写真の元画像を取得する（後方互換性）
  Future<dynamic> getOriginalFile(AssetEntity asset);

  /// 写真の元画像を取得する（Result<T>版・推奨）
  ///
  /// 従来の[getOriginalFile]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<Uint8List>> getOriginalFileResult(AssetEntity asset);

  /// 写真のサムネイルを取得する（後方互換性）
  Future<dynamic> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  });

  /// 写真のサムネイルを取得する（Result<T>版・推奨）
  ///
  /// 従来の[getThumbnail]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<Uint8List>> getThumbnailResult(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  });

  /// Limited Photo Access時に写真選択画面を表示
  Future<bool> presentLimitedLibraryPicker();

  /// Limited Photo Access時に写真選択画面を表示（Result<T>版・推奨）
  ///
  /// 従来の[presentLimitedLibraryPicker]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<bool>> presentLimitedLibraryPickerResult();

  /// 現在の権限状態が Limited Access かチェック
  Future<bool> isLimitedAccess();

  /// 現在の権限状態が Limited Access かチェック（Result<T>版・推奨）
  ///
  /// 従来の[isLimitedAccess]より型安全で詳細なエラー情報を提供します。
  /// 新規実装では必ずこちらを使用してください。
  Future<Result<bool>> isLimitedAccessResult();

  /// 効率的な写真取得（ページネーション対応）
  Future<List<AssetEntity>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  });

  /// 効率的な写真取得（ページネーション対応）
  ///
  /// Result<T>版は既に追加済み。従来の[getPhotosEfficient]と併用可能です。

  /// 効率的な写真取得（Result<T>版・ページネーション対応）
  Future<Result<List<AssetEntity>>> getPhotosEfficientResult({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  });
}
