import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';

/// スマートFABの状態
enum SmartFABState {
  camera, // カメラ撮影
  createDiary, // 日記作成
}

/// スマートFAB用のコントローラー
/// 写真選択状態に応じてFABのアイコンと機能を切り替える
class SmartFABController extends ChangeNotifier {
  final PhotoSelectionController _photoController;

  SmartFABController({required PhotoSelectionController photoController})
    : _photoController = photoController {
    _photoController.addListener(_onPhotoSelectionChanged);
  }

  @override
  void dispose() {
    _photoController.removeListener(_onPhotoSelectionChanged);
    super.dispose();
  }

  void _onPhotoSelectionChanged() {
    notifyListeners();
  }

  /// 現在のFAB状態を取得
  SmartFABState get currentState {
    return _photoController.selectedCount > 0
        ? SmartFABState.createDiary
        : SmartFABState.camera;
  }

  /// 現在の状態に応じたアイコンを取得
  IconData get icon {
    switch (currentState) {
      case SmartFABState.camera:
        return Icons.photo_camera_rounded;
      case SmartFABState.createDiary:
        return Icons.auto_awesome_rounded;
    }
  }

  /// 現在の状態に応じたtooltipテキストを取得
  @Deprecated('Use getLocalizedTooltip() or context.l10n in widget instead')
  String get tooltip {
    switch (currentState) {
      case SmartFABState.camera:
        return '写真を撮影';
      case SmartFABState.createDiary:
        return '${_photoController.selectedCount}枚で日記を作成';
    }
  }

  /// ローカライズ対応のtooltipテキストを取得
  String getLocalizedTooltip({
    required String cameraText,
    required String Function(int count) createDiaryText,
  }) {
    switch (currentState) {
      case SmartFABState.camera:
        return cameraText;
      case SmartFABState.createDiary:
        return createDiaryText(_photoController.selectedCount);
    }
  }

  /// 現在の状態に応じた背景色を取得
  Color getBackgroundColor(ColorScheme colorScheme) {
    switch (currentState) {
      case SmartFABState.camera:
        return colorScheme.primary;
      case SmartFABState.createDiary:
        return colorScheme.tertiary;
    }
  }

  /// 現在の状態に応じた前景色を取得
  Color getForegroundColor(ColorScheme colorScheme) {
    switch (currentState) {
      case SmartFABState.camera:
        return colorScheme.onPrimary;
      case SmartFABState.createDiary:
        return colorScheme.onTertiary;
    }
  }

  /// FAB表示の可視性を判定
  bool get shouldShow => true; // タイムライン統合後は常に表示

  /// 選択枚数を取得（テスト・デバッグ用）
  int get selectedCount => _photoController.selectedCount;
}
