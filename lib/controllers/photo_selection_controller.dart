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
  DateTime? _selectedDate; // 選択された写真の日付を保持

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
    // 境界チェック
    if (index < 0 ||
        index >= _photoAssets.length ||
        index >= _selected.length) {
      return;
    }

    // 使用済み写真かどうかをチェック
    final photoId = _photoAssets[index].id;
    if (_usedPhotoIds.contains(photoId)) {
      // 使用済み写真の選択を試みた場合の処理は呼び出し側で実装
      return;
    }

    if (_selected[index]) {
      // 選択解除の場合はそのまま実行
      _selected[index] = false;

      // 選択された写真がなくなった場合は日付制限をクリア
      if (selectedCount == 0) {
        _selectedDate = null;
      }
    } else {
      // 選択の場合は上限チェック
      if (selectedCount < AppConstants.maxPhotosSelection) {
        // 日付制限のチェック（日付制限が有効な場合のみ）
        if (_enableDateRestriction && _selectedDate != null) {
          final photoDate = _photoAssets[index].createDateTime;
          if (!_isSameDate(_selectedDate!, photoDate)) {
            // 異なる日付の写真は選択できない
            return;
          }
        }

        _selected[index] = true;

        // 初めての選択の場合は、その写真の日付を記録
        if (_enableDateRestriction && _selectedDate == null) {
          _selectedDate = _photoAssets[index].createDateTime;
        }
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
    _selectedDate = null;
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
    _usedPhotoIds = Set.from(usedIds);
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
    if (index < 0 || index >= _photoAssets.length) return false;
    return _usedPhotoIds.contains(_photoAssets[index].id);
  }

  /// 選択可能かどうかをチェック
  bool canSelectPhoto(int index) {
    if (index < 0 ||
        index >= _photoAssets.length ||
        index >= _selected.length) {
      return false;
    }

    // 使用済み写真はNG
    if (isPhotoUsed(index)) return false;

    // 既に選択されている場合はOK（選択解除のため）
    if (_selected[index]) return true;

    // 選択上限チェック
    if (selectedCount >= AppConstants.maxPhotosSelection) return false;

    // 日付制限チェック（日付制限が有効な場合のみ）
    if (_enableDateRestriction && _selectedDate != null) {
      final photoDate = _photoAssets[index].createDateTime;
      if (!_isSameDate(_selectedDate!, photoDate)) {
        return false;
      }
    }

    return true;
  }

  /// 同じ日付かどうかをチェック
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 日付制限を有効にするかどうか
  bool _enableDateRestriction = false;

  /// 日付制限を設定
  void setDateRestrictionEnabled(bool enabled) {
    _enableDateRestriction = enabled;
    if (!enabled) {
      _selectedDate = null;
    }
    notifyListeners();
  }

  /// リソースのクリーンアップ
  @override
  void dispose() {
    // 大量の写真リストをクリア
    _photoAssets.clear();
    _selected.clear();
    _usedPhotoIds.clear();
    super.dispose();
  }
}
