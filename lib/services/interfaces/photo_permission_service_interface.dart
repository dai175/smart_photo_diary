import '../../core/result/result.dart';

/// 写真アクセス権限管理サービスのインターフェース
abstract class IPhotoPermissionService {
  /// 写真アクセス権限をリクエストする
  ///
  /// iOS 14以降で Limited Access が付与された場合も true を返す。
  /// Limited Access かどうかの判定は [isLimitedAccess] で確認すること。
  ///
  /// Returns:
  /// - Success(true): 権限が付与された（Limited Access含む）
  /// - Success(false): 権限が拒否された
  /// - Failure: [PhotoAccessException] 権限リクエスト処理でエラーが発生した場合
  Future<Result<bool>> requestPermission();

  /// 権限が永続的に拒否されているかチェック
  ///
  /// Returns:
  /// - Success(true): 永続的に拒否されている
  /// - Success(false): 永続的に拒否されていない
  /// - Failure: [PhotoAccessException] 権限チェック処理でエラーが発生した場合
  Future<Result<bool>> isPermissionPermanentlyDenied();

  /// Limited Photo Access時に写真選択画面を表示
  ///
  /// iOS 14以降のLimited Photo Accessで追加の写真を選択するためのシステムUIを表示する。
  ///
  /// Returns:
  /// - Success(true): 選択画面の表示に成功
  /// - Success(false): 選択画面の表示に失敗
  /// - Failure: [PhotoAccessException] 表示処理でエラーが発生した場合
  Future<Result<bool>> presentLimitedLibraryPicker();

  /// 現在の権限状態が Limited Access かチェック
  ///
  /// Returns:
  /// - Success(true): Limited Accessである
  /// - Success(false): Limited Accessではない
  /// - Failure: [PhotoAccessException] 権限チェック処理でエラーが発生した場合
  Future<Result<bool>> isLimitedAccess();
}
