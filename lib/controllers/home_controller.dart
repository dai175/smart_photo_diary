import 'package:flutter/material.dart';

/// HomeScreen のタブナビゲーション・画面キー管理コントローラー
class HomeController extends ChangeNotifier {
  int _currentIndex = 0;
  Key _diaryScreenKey = UniqueKey();
  Key _statsScreenKey = UniqueKey();

  int get currentIndex => _currentIndex;
  Key get diaryScreenKey => _diaryScreenKey;
  Key get statsScreenKey => _statsScreenKey;

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// 日記一覧と統計画面を再構築
  void refreshDiaryAndStats() {
    _diaryScreenKey = UniqueKey();
    _statsScreenKey = UniqueKey();
    notifyListeners();
  }

  /// 統計画面を再構築しつつタブを切り替え（通知は1回）
  void refreshStatsAndSwitchTab(int index) {
    _statsScreenKey = UniqueKey();
    _currentIndex = index;
    notifyListeners();
  }
}
