import 'package:photo_manager/photo_manager.dart';
import 'photo_selection_controller.dart';

/// 拡張された写真選択コントローラー（過去の写真機能対応）
class ExtendedPhotoSelectionController extends PhotoSelectionController {
  /// ページネーション用の現在のオフセット
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  /// 1ページあたりの写真数
  static const int photosPerPage = 50;

  /// 追加読み込みが可能かどうか
  bool _hasMorePhotos = true;
  bool get hasMorePhotos => _hasMorePhotos;

  /// 月別にグループ化された写真
  final Map<DateTime, List<AssetEntity>> _photosByMonth = {};
  Map<DateTime, List<AssetEntity>> get photosByMonth =>
      Map.unmodifiable(_photosByMonth);

  /// 表示モード（グリッド or カレンダー）
  bool _isCalendarView = false;
  bool get isCalendarView => _isCalendarView;

  /// カレンダー表示モードの切り替え
  void toggleCalendarView() {
    _isCalendarView = !_isCalendarView;
    notifyListeners();
  }

  /// 写真を月別にグループ化
  void groupPhotosByMonth() {
    _photosByMonth.clear();

    for (final photo in photoAssets) {
      final date = photo.createDateTime;
      final monthKey = DateTime(date.year, date.month);

      _photosByMonth.putIfAbsent(monthKey, () => []);
      _photosByMonth[monthKey]!.add(photo);
    }

    // 各月の写真を日付順にソート
    _photosByMonth.forEach((month, photos) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    });
  }

  /// ページネーションをリセット
  void resetPagination() {
    _currentOffset = 0;
    _hasMorePhotos = true;
  }

  /// 写真アセットを設定（オーバーライド）
  @override
  void setPhotoAssets(List<AssetEntity> assets) {
    super.setPhotoAssets(assets);
    groupPhotosByMonth();
  }

  /// 追加の写真を設定（ページネーション用）
  void appendPhotoAssets(List<AssetEntity> newAssets) {
    if (newAssets.isEmpty) {
      _hasMorePhotos = false;
      notifyListeners();
      return;
    }

    // 既存の写真に追加
    final allAssets = [...photoAssets, ...newAssets];
    _currentOffset = allAssets.length;

    // 追加分の選択状態を初期化
    final newSelected = [
      ...selected,
      ...List.generate(newAssets.length, (_) => false),
    ];

    // 内部状態を直接更新
    super.setPhotoAssets(allAssets);
    selected.clear();
    selected.addAll(newSelected);

    // 月別グループを更新
    groupPhotosByMonth();

    // ページネーション継続可能かチェック
    _hasMorePhotos = newAssets.length >= photosPerPage;

    notifyListeners();
  }

  /// 特定の月の写真を取得
  List<AssetEntity> getPhotosForMonth(DateTime month) {
    final key = DateTime(month.year, month.month);
    return _photosByMonth[key] ?? [];
  }

  /// 月のリストを取得（新しい順）
  List<DateTime> getMonthKeys() {
    final keys = _photosByMonth.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  /// クリーンアップ（オーバーライド）
  @override
  void dispose() {
    _photosByMonth.clear();
    super.dispose();
  }
}
