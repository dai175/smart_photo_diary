import 'package:flutter/foundation.dart';

/// シンプルなスクロール指示用のシグナル
///
/// 例: 既にホームタブ表示中にタブを再タップしたら先頭へスクロール
class ScrollSignal extends ChangeNotifier {
  void trigger() => notifyListeners();
}
