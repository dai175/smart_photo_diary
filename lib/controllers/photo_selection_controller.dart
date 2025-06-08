import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';

/// 写真選択の状態とロジックを管理するコントローラー
class PhotoSelectionController extends ChangeNotifier {
  List<AssetEntity> _photoAssets = [];
  List<bool> _selected = [];
  Set<String> _usedPhotoIds = {};
  bool _isLoading = true;
  bool _hasPermission = false;

  // ゲッター
  List<AssetEntity> get photoAssets => _photoAssets;
  List<bool> get selected => _selected;
  Set<String> get usedPhotoIds => _usedPhotoIds;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  
  /// 選択された写真の数を取得
  int get selectedCount => _selected.where((s) => s).length;
  
  /// 選択された写真のリストを取得
  List<AssetEntity> get selectedPhotos {
    final List<AssetEntity> result = [];
    for (int i = 0; i < _photoAssets.length; i++) {
      if (_selected[i]) {
        result.add(_photoAssets[i]);
      }
    }
    return result;
  }
  
  /// 写真選択の切り替え
  void toggleSelect(int index) {
    // 使用済み写真かどうかをチェック
    final photoId = _photoAssets[index].id;
    if (_usedPhotoIds.contains(photoId)) {
      // 使用済み写真の選択を試みた場合の処理は呼び出し側で実装
      return;
    }
    
    if (_selected[index]) {
      // 選択解除の場合はそのまま実行
      _selected[index] = false;
    } else {
      // 選択の場合は上限チェック
      if (selectedCount < AppConstants.maxPhotosSelection) {
        _selected[index] = true;
      } else {
        // 上限に達している場合の処理は呼び出し側で実装
        return;
      }
    }
    
    notifyListeners();
  }
  
  /// 写真選択をクリア
  void clearSelection() {
    _selected = List.generate(_photoAssets.length, (index) => false);
    notifyListeners();
  }
  
  /// 写真アセットを設定
  void setPhotoAssets(List<AssetEntity> assets) {
    _photoAssets = assets;
    _selected = List.generate(assets.length, (index) => false);
    notifyListeners();
  }
  
  /// 使用済み写真IDを設定
  void setUsedPhotoIds(Set<String> usedIds) {
    _usedPhotoIds = usedIds;
    notifyListeners();
  }
  
  /// ローディング状態を設定
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 権限状態を設定
  void setPermission(bool permission) {
    _hasPermission = permission;
    notifyListeners();
  }
  
  /// 写真が使用済みかどうかをチェック
  bool isPhotoUsed(int index) {
    if (index >= _photoAssets.length) return false;
    return _usedPhotoIds.contains(_photoAssets[index].id);
  }
  
  /// 選択可能かどうかをチェック
  bool canSelectPhoto(int index) {
    return !isPhotoUsed(index) && 
           (selectedCount < AppConstants.maxPhotosSelection || _selected[index]);
  }
}