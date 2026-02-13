/// 写真アクセス権限管理サービスのインターフェース
abstract class IPhotoPermissionService {
  /// 写真アクセス権限をリクエストする
  ///
  /// 戻り値: 権限が付与されれば true。エラー時は false。
  Future<bool> requestPermission();

  /// 権限が永続的に拒否されているかチェック
  ///
  /// 戻り値: 永続的に拒否されていれば true。エラー時は false。
  Future<bool> isPermissionPermanentlyDenied();

  /// Limited Photo Access時に写真選択画面を表示
  ///
  /// iOS 14以降のLimited Photo Accessで追加の写真を選択するためのシステムUIを表示する。
  /// 戻り値: 選択画面の表示に成功すれば true。エラー時は false。
  Future<bool> presentLimitedLibraryPicker();

  /// 現在の権限状態が Limited Access かチェック
  ///
  /// 戻り値: Limited Accessであれば true。エラー時は false。
  Future<bool> isLimitedAccess();
}
