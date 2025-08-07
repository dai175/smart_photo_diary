import 'package:flutter/foundation.dart';

/// 写真のページネーション情報を管理するクラス
@immutable
class PhotoPagination {
  /// 現在のページ番号（0始まり）
  final int currentPage;

  /// 1ページあたりのアイテム数
  final int itemsPerPage;

  /// 総アイテム数（既知の場合）
  final int? totalItems;

  /// さらに読み込み可能なアイテムがあるか
  final bool hasMore;

  /// 現在読み込み中かどうか
  final bool isLoading;

  const PhotoPagination({
    this.currentPage = 0,
    this.itemsPerPage = 50,
    this.totalItems,
    this.hasMore = true,
    this.isLoading = false,
  });

  /// 次のページ番号を取得
  int get nextPage => currentPage + 1;

  /// 現在のオフセットを取得
  int get currentOffset => currentPage * itemsPerPage;

  /// 次のオフセットを取得
  int get nextOffset => nextPage * itemsPerPage;

  /// 現在読み込み済みのアイテム数を推定
  int get loadedItemsCount {
    if (!hasMore && totalItems != null) {
      return totalItems!;
    }
    return (currentPage + 1) * itemsPerPage;
  }

  /// 総ページ数を取得（totalItemsが設定されている場合）
  int? get totalPages {
    if (totalItems == null) return null;
    return (totalItems! / itemsPerPage).ceil();
  }

  /// 最後のページかどうかをチェック
  bool get isLastPage {
    if (totalPages == null) return !hasMore;
    return currentPage >= totalPages! - 1;
  }

  /// ページネーション情報をコピーして更新
  PhotoPagination copyWith({
    int? currentPage,
    int? itemsPerPage,
    int? totalItems,
    bool? hasMore,
    bool? isLoading,
  }) {
    return PhotoPagination(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 次のページに進む
  PhotoPagination nextPageLoaded({required int itemsLoaded, int? totalItems}) {
    return copyWith(
      currentPage: nextPage,
      hasMore: itemsLoaded >= itemsPerPage,
      totalItems: totalItems,
      isLoading: false,
    );
  }

  /// ローディング開始
  PhotoPagination startLoading() {
    return copyWith(isLoading: true);
  }

  /// ローディング終了
  PhotoPagination endLoading({bool? hasMore}) {
    return copyWith(isLoading: false, hasMore: hasMore);
  }

  /// リセット
  PhotoPagination reset() {
    return const PhotoPagination();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhotoPagination &&
        other.currentPage == currentPage &&
        other.itemsPerPage == itemsPerPage &&
        other.totalItems == totalItems &&
        other.hasMore == hasMore &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPage,
      itemsPerPage,
      totalItems,
      hasMore,
      isLoading,
    );
  }

  @override
  String toString() {
    return 'PhotoPagination('
        'currentPage: $currentPage, '
        'itemsPerPage: $itemsPerPage, '
        'totalItems: $totalItems, '
        'hasMore: $hasMore, '
        'isLoading: $isLoading'
        ')';
  }
}

/// ページネーション付きの写真リスト
@immutable
class PaginatedPhotos<T> {
  /// 写真のリスト
  final List<T> items;

  /// ページネーション情報
  final PhotoPagination pagination;

  const PaginatedPhotos({required this.items, required this.pagination});

  /// 空のインスタンスを作成
  factory PaginatedPhotos.empty() {
    return const PaginatedPhotos(items: [], pagination: PhotoPagination());
  }

  /// アイテムを追加
  PaginatedPhotos<T> appendItems(List<T> newItems) {
    return PaginatedPhotos(
      items: [...items, ...newItems],
      pagination: pagination.nextPageLoaded(itemsLoaded: newItems.length),
    );
  }

  /// ローディング状態を更新
  PaginatedPhotos<T> withLoading(bool isLoading) {
    return PaginatedPhotos(
      items: items,
      pagination: isLoading
          ? pagination.startLoading()
          : pagination.endLoading(),
    );
  }

  /// リセット
  PaginatedPhotos<T> reset() {
    return PaginatedPhotos.empty();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaginatedPhotos<T> &&
        listEquals(other.items, items) &&
        other.pagination == pagination;
  }

  @override
  int get hashCode => Object.hash(items, pagination);
}
