/// 写真アクセス権限管理サービスのインターフェース
abstract class IPhotoPermissionService {
  /// 写真アクセス権限をリクエストする
  Future<bool> requestPermission();

  /// 権限が永続的に拒否されているかチェック
  Future<bool> isPermissionPermanentlyDenied();

  /// Limited Photo Access時に写真選択画面を表示
  Future<bool> presentLimitedLibraryPicker();

  /// 現在の権限状態が Limited Access かチェック
  Future<bool> isLimitedAccess();
}
