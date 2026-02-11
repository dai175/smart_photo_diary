import '../../constants/app_constants.dart';

/// タイムラインレイアウト関連の定数
class TimelineLayoutConstants {
  TimelineLayoutConstants._();

  // グリッドレイアウト
  static const double crossAxisSpacing = 2.0;
  static const double mainAxisSpacing = 2.0;
  static const int crossAxisCount = 4;
  static const double childAspectRatio = 1.0;

  // スティッキーヘッダー
  static const double stickyHeaderHeight = 48.0;

  // 空状態
  static const double emptyStateHeight = 100.0;

  // ローディングインジケーター
  static const double loadingIndicatorSize = 24.0;
  static const double loadingIndicatorStrokeWidth = 2.0;

  // アニメーション
  static const int animationDurationMs = 150;

  // 選択インジケーター
  static const double selectionIndicatorSize = 20.0;
  static const double selectionIconSize = 19.0;
  static const double selectionBorderWidth = 2.0;

  // サムネイル（AppConstantsに集約）
  static const int thumbnailSize = AppConstants.timelineThumbnailSizePx;
  static const int thumbnailQuality = AppConstants.timelineThumbnailQuality;

  // レイアウト位置
  static const double borderRadius = 4.0;
  static const double selectionIndicatorTop = 8.0;
  static const double selectionIndicatorRight = 8.0;
  static const double usedLabelBottom = 4.0;
  static const double usedLabelLeft = 4.0;
  static const double usedLabelHorizontalPadding = 4.0;
  static const double usedLabelVerticalPadding = 2.0;
}

/// タイムラインスクロール関連の定数
class TimelineScrollConstants {
  TimelineScrollConstants._();

  // 先読み閾値
  static const double preloadThreshold =
      AppConstants.timelinePreloadThresholdPx;
  static const double loadMoreThreshold =
      AppConstants.timelineLoadMoreThresholdPx;
  static const double scrollCheckThreshold = 200.0;

  // デバウンス/タイミング
  static const int scrollCheckIntervalMs =
      AppConstants.timelineScrollCheckIntervalMs;
  static const int layoutCompleteDelayMs = 100;
  static const int initializationCompleteDelayMs = 500;

  // 自動読み込み
  static const int maxPhotosForAutoLoad = 60;

  // スケルトン制御
  static const int placeholderIncreaseDebounceMs = 500;
  static const int initialLoadPlaceholderLimit = 2;
  static const int bulkLoadThreshold = 20;
  static const int scrollTopPlaceholderLimit = 1;
}
