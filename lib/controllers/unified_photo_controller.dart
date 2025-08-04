import 'package:flutter/material.dart';
import 'extended_photo_selection_controller.dart';
import 'past_photos_notifier.dart';
import '../models/plans/plan.dart';

/// 今日の写真と過去の写真を統合管理するコントローラー
class UnifiedPhotoController extends ChangeNotifier {
  /// 今日の写真用コントローラー
  final ExtendedPhotoSelectionController todayController;

  /// 過去の写真用コントローラー
  final ExtendedPhotoSelectionController pastController;

  /// 過去の写真状態管理
  final PastPhotosNotifier pastPhotosNotifier;

  /// 現在のタブインデックス
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  /// アクティブなコントローラーを取得
  ExtendedPhotoSelectionController get activeController {
    return _currentTabIndex == 0 ? todayController : pastController;
  }

  UnifiedPhotoController({
    required this.todayController,
    required this.pastController,
    required this.pastPhotosNotifier,
  }) {
    // 子コントローラーの変更を監視
    todayController.addListener(_onControllerChanged);
    pastController.addListener(_onControllerChanged);
    pastPhotosNotifier.addListener(_onControllerChanged);

    // 過去の写真は同じ日付のみ選択可能に制限
    pastController.setDateRestrictionEnabled(true);
  }

  /// 工場メソッド
  factory UnifiedPhotoController.create() {
    return UnifiedPhotoController(
      todayController: ExtendedPhotoSelectionController(),
      pastController: ExtendedPhotoSelectionController(),
      pastPhotosNotifier: PastPhotosNotifier.create(),
    );
  }

  /// タブを切り替え
  void switchTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// 過去の写真を読み込み
  Future<void> loadPastPhotos(Plan currentPlan) async {
    await pastPhotosNotifier.loadInitialPhotos(currentPlan);

    // 読み込んだ写真をコントローラーに設定
    if (pastPhotosNotifier.state.photos.isNotEmpty) {
      pastController.setPhotoAssets(pastPhotosNotifier.state.photos);
    }
  }

  /// 追加の過去写真を読み込み（ページネーション）
  Future<void> loadMorePastPhotos(Plan currentPlan) async {
    if (!pastPhotosNotifier.state.hasMore ||
        pastPhotosNotifier.state.isLoading) {
      return;
    }

    await pastPhotosNotifier.loadMorePhotos(currentPlan);

    // 新しく読み込んだ写真をコントローラーに追加
    final startIndex = pastController.photoAssets.length;
    final newPhotos = pastPhotosNotifier.state.photos.skip(startIndex).toList();

    if (newPhotos.isNotEmpty) {
      pastController.appendPhotoAssets(newPhotos);
    }
  }

  /// 特定の日付の写真を読み込み
  Future<void> loadPhotosForDate(DateTime date) async {
    await pastPhotosNotifier.loadPhotosForDate(date);

    // 読み込んだ写真をコントローラーに設定
    if (pastPhotosNotifier.state.photos.isNotEmpty) {
      pastController.setPhotoAssets(pastPhotosNotifier.state.photos);
    }
  }

  /// 日付選択をクリア
  void clearDateSelection(Plan currentPlan) {
    pastPhotosNotifier.clearDateSelection(currentPlan);
  }

  /// カレンダー表示を切り替え
  void toggleCalendarView() {
    pastPhotosNotifier.toggleCalendarView();
    pastController.toggleCalendarView();
  }

  /// 選択をクリア
  void clearAllSelections() {
    todayController.clearSelection();
    pastController.clearSelection();
    pastPhotosNotifier.clearSelection();
  }

  /// 使用済み写真IDを設定
  void setUsedPhotoIds(Set<String> usedIds) {
    todayController.setUsedPhotoIds(usedIds);
    pastController.setUsedPhotoIds(usedIds);
    pastPhotosNotifier.setUsedPhotoIds(usedIds);
  }

  /// 子コントローラーの変更通知を受け取る
  void _onControllerChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    todayController.removeListener(_onControllerChanged);
    pastController.removeListener(_onControllerChanged);
    pastPhotosNotifier.removeListener(_onControllerChanged);

    todayController.dispose();
    pastController.dispose();
    pastPhotosNotifier.dispose();

    super.dispose();
  }
}
