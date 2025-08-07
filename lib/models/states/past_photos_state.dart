import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// 過去の写真機能の状態を管理するクラス
@immutable
class PastPhotosState {
  /// 選択中の日付（nullの場合は全期間）
  final DateTime? selectedDate;

  /// 読み込み中の写真リスト
  final List<AssetEntity> photos;

  /// ページネーション用の現在のページ番号
  final int currentPage;

  /// 1ページあたりの写真数
  final int photosPerPage;

  /// さらに読み込み可能な写真があるか
  final bool hasMore;

  /// 読み込み中かどうか
  final bool isLoading;

  /// 初期読み込みかどうか（スピナー表示用）
  final bool isInitialLoading;

  /// エラーメッセージ
  final String? errorMessage;

  /// カレンダー表示モードかどうか
  final bool isCalendarView;

  /// 月別にグループ化された写真のマップ
  final Map<DateTime, List<AssetEntity>> photosByMonth;

  const PastPhotosState({
    this.selectedDate,
    this.photos = const [],
    this.currentPage = 0,
    this.photosPerPage = 50,
    this.hasMore = true,
    this.isLoading = false,
    this.isInitialLoading = true,
    this.errorMessage,
    this.isCalendarView = false,
    this.photosByMonth = const {},
  });

  /// 初期状態を作成
  factory PastPhotosState.initial() {
    return const PastPhotosState();
  }

  /// 状態をコピーして新しいインスタンスを作成
  PastPhotosState copyWith({
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    List<AssetEntity>? photos,
    int? currentPage,
    int? photosPerPage,
    bool? hasMore,
    bool? isLoading,
    bool? isInitialLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isCalendarView,
    Map<DateTime, List<AssetEntity>>? photosByMonth,
  }) {
    return PastPhotosState(
      selectedDate: clearSelectedDate
          ? null
          : (selectedDate ?? this.selectedDate),
      photos: photos ?? this.photos,
      currentPage: currentPage ?? this.currentPage,
      photosPerPage: photosPerPage ?? this.photosPerPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCalendarView: isCalendarView ?? this.isCalendarView,
      photosByMonth: photosByMonth ?? this.photosByMonth,
    );
  }

  /// 次のページ番号を取得
  int get nextPage => currentPage + 1;

  /// 現在表示している写真の総数
  int get totalPhotosLoaded => photos.length;

  /// 特定の月の写真を取得
  List<AssetEntity> getPhotosForMonth(DateTime month) {
    final key = DateTime(month.year, month.month);
    return photosByMonth[key] ?? [];
  }

  /// 写真を月別にグループ化
  Map<DateTime, List<AssetEntity>> groupPhotosByMonth(
    List<AssetEntity> photoList,
  ) {
    final grouped = <DateTime, List<AssetEntity>>{};

    for (final photo in photoList) {
      final date = photo.createDateTime;
      final monthKey = DateTime(date.year, date.month);

      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(photo);
    }

    // 各月の写真を日付順にソート
    grouped.forEach((month, photos) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    });

    return grouped;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PastPhotosState &&
        other.selectedDate == selectedDate &&
        listEquals(other.photos, photos) &&
        other.currentPage == currentPage &&
        other.photosPerPage == photosPerPage &&
        other.hasMore == hasMore &&
        other.isLoading == isLoading &&
        other.isInitialLoading == isInitialLoading &&
        other.errorMessage == errorMessage &&
        other.isCalendarView == isCalendarView &&
        mapEquals(other.photosByMonth, photosByMonth);
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedDate,
      photos,
      currentPage,
      photosPerPage,
      hasMore,
      isLoading,
      isInitialLoading,
      errorMessage,
      isCalendarView,
      photosByMonth,
    );
  }
}
