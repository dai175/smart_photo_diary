import 'package:flutter/material.dart';
import 'app_icons.dart';

/// Smart Photo Diary アプリケーション定数
class AppConstants {
  // 写真選択関連
  static const int maxPhotosSelection = 3;
  static const int photoGridCrossAxisCount = 3;
  static const double photoGridSpacing = 8.0;
  static const double photoThumbnailSize = 90.0;
  static const double photoCornerRadius = 16.0;
  // タイムライン用（内部グリッドと差別化する場合）
  static const int timelineThumbnailSizePx = 120; // 表示安定性優先の固定ピクセル
  static const int timelineThumbnailQuality = 50; // 品質を下げて負荷を軽減
  static const int thumbnailFutureCachePruneThreshold = 800; // Futureキャッシュの簡易上限

  // UI関連
  static const double defaultPadding = 16.0;
  static const double largePadding = 20.0;
  static const double smallPadding = 8.0;
  static const double buttonHeight = 48.0;
  static const double bottomNavPadding = 80.0;

  // ダイアログ・ボトムシート
  static const double bottomSheetHeightRatio = 0.75;

  // 写真サムネイル
  static const double diaryThumbnailSize = 120.0;
  static const double detailImageSize = 200.0;
  static const double previewImageSize = 200.0;
  static const double largeImageSize = 400.0;

  // レイアウト
  static const double headerTopPadding = 50.0;
  static const double headerBottomPadding = 16.0;
  static const double photoGridHeight = 250.0;
  static const double recentDiaryCardHeight = 120.0;

  // テキストサイズ
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 16.0;
  static const double sectionTitleFontSize = 20.0;
  static const double cardTitleFontSize = 18.0;
  static const double bodyFontSize = 15.0;
  static const double captionFontSize = 14.0;
  static const double smallCaptionFontSize = 10.0;

  // 空状態表示
  static const double emptyStateIconSize = 64.0;

  // アイコン（AppIconsから参照）
  static const List<IconData> navigationIcons = AppIcons.navigationIcons;

  // アニメーション
  static const Duration shortAnimationDuration = Duration(milliseconds: 180);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 350);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration slowAnimationDuration = Duration(milliseconds: 450);
  static const Duration xSlowAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 1500);
  static const Duration xLongAnimationDuration = Duration(milliseconds: 2000);
  static const Duration microFastAnimationDuration = Duration(milliseconds: 80);
  static const Duration microBaseAnimationDuration = Duration(
    milliseconds: 100,
  );
  static const Duration microStaggerUnit = Duration(milliseconds: 100);
  static const Duration quickAnimationDuration = Duration(milliseconds: 200);
  static const Duration standardTransitionDuration = Duration(
    milliseconds: 300,
  );

  // ナビゲーションタブインデックス
  static const int homeTabIndex = 0;
  static const int diaryTabIndex = 1;
  static const int statisticsTabIndex = 2;
  static const int settingsTabIndex = 3;

  // エフェクト/透明度（withValues(alpha: ...) 用）
  static const double opacityHigh = 0.8;
  static const double opacityMedium = 0.7;
  static const double opacityLow = 0.5;
  static const double opacityXLow = 0.3;

  // レイアウト比率
  static const double loadingCenterHeightRatio = 0.3;
  static const double opacityXXLow = 0.1;
  static const double opacitySubtle = 0.2;

  // スケール（タップ・エントランスなど）
  static const double scaleTapSmall = 0.98;
  static const double scalePressed = 0.97;
  static const double scaleEntranceStart = 0.92;

  // 写真サービス関連
  static const int defaultPhotoLimit = 20;
  static const int maxPhotoLimit = 100;
  static const int defaultThumbnailWidth = 200;
  static const int defaultThumbnailHeight = 200;
  // タイムラインの1回あたり取得枚数と先読み倍率
  static const int timelinePageSize = 60; // 一度に増やす写真枚数
  static const int timelinePreloadPages = 2; // 先読み時はページ数×この倍率で取得

  // 日記一覧（Diary）関連
  static const int diaryPageSize = 20; // 一度に取得する日記件数
  static const double diaryListLoadMoreThresholdRatio = 0.85; // 末尾手前での追加読込閾値
  static const int diaryListInitialShimmerCount = 6; // 初期ローディングのプレースホルダー件数
  static const int diaryListAnimationStaggerLimit = 10; // 遅延アニメーションを付与する先頭件数
  static const int diaryListAnimationStaggerMs = 50; // 各アイテムの遅延間隔(ms)
  static const double diaryListFooterSpinnerSize = 24.0; // 追加読込スピナーのサイズ
  static const int diaryThumbnailQuality = 70; // 日記カードのサムネ品質
  static const int diaryPrefetchAheadCount = 12; // 一覧用の先読み件数（カード数）

  // タイムライン先読み・プリフェッチ（基本設定）
  static const double timelinePreloadThresholdPx = 1200.0; // 先読み開始のスクロール余白
  static const double timelineLoadMoreThresholdPx = 600.0; // 追加読み込みのスクロール余白
  static const int timelineScrollCheckIntervalMs = 800; // 連続判定の間隔
  static const int timelinePrefetchAheadCount = 64; // 先読みするアイテム数（4列×16行）
  static const int timelinePrefetchBatchSize = 32; // 1バッチのプリロード数
  static const int thumbnailPreloadConcurrency = 4; // 同時プリロード数の上限（負荷軽減）

  // タイムライン・プレースホルダー
  // 追加読み込み中/先読み中に末尾へ表示するスケルトン行数（4列×行）
  static const int timelinePlaceholderRows = 8; // 4列×8行=32タイル分
  static const int timelinePlaceholderMaxPages = 30; // 高速スクロールでも追いつかれない十分な余裕

  // 影
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
  ];
}
