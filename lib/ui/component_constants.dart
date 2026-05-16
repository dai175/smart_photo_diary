import 'package:flutter/material.dart';

/// Chip/Tag コンポーネントの規格値
class ChipConstants {
  // 高さ
  static const double heightSm = 24.0;
  static const double heightMd = 32.0;
  static const double heightLg = 40.0;

  // アイコンサイズ
  static const double iconSm = 14.0;
  static const double iconMd = 16.0;
  static const double iconLg = 18.0;

  // 枠線の太さ — 繊細なボーダー
  static const double borderWidth = 1.0;

  // ホバー時の影/オフセット
  static const double blurRadiusNormal = 2.0;
  static const double blurRadiusHover = 4.0;
  static const double offsetYNormal = 1.0;
  static const double offsetYHover = 2.0;
}

/// ダイアログ/モーダル用の規格値
class DialogConstants {
  static const double listMaxHeight = 300.0;
  static const double listMaxWidth = 400.0;
}

/// カレンダーマーカー（統計画面など）の規格値
class CalendarMarkerConstants {
  static const double size = 14.0;
  static const double dotSize = 6.0;
  static const double legendIndicatorSize = 10.0;
  static const double todayBorderWidth = 1.5;
}

/// 丸いタイル/アバターなどの共通サイズ
class TileConstants {
  static const double sizeMd = 40.0;
}

/// ボタンの規格値
class ButtonConstants {
  static const double borderWidth = 1.5;
  static const double heightSm = 46.0;
  static const double heightMd = 50.0;
}

/// 入力フィールドの規格値
class InputConstants {
  static const double borderWidth = 1.0;
  static const double borderWidthFocused = 2.0;
}

/// タブの規格値
class TabConstants {
  static const double indicatorThickness = 2.0;
}

/// ブラー/半透明背景の規格値
class BlurConstants {
  static const double defaultBlur = 10.0;
  static const double backgroundAlpha = 0.8; // 80% 不透明
}

/// 拡大ビューワ（画像プレビュー）規格値
class ViewerConstants {
  static const double minScale = 1.0;
  static const double maxScale = 4.0;
}

/// 写真プレビュー（大サイズ取得）規格値
class PhotoPreviewConstants {
  static const int previewSizePx = 1200;
  static const int previewQuality = 90;
  static const double progressStrokeWidth = 3.0;
}

/// ナビゲーションバーの規格値
class NavBarConstants {
  /// コンパクトな高さ（旧BottomNavigationBarに近い）
  static const double height = 64.0;

  /// 上端ヘアラインの太さ
  static const double hairlineThickness = 0.5;

  /// アイコンサイズ
  static const double iconSize = 24.0;
}

/// ラベル/アイコンの微調整用定数
class LabelConstants {
  /// 未選択アイテムの不透明度（ライト/ダーク共通）
  /// 基準色は Light: onSurfaceVariant / Dark: onSurfaceDark を使用
  static const double unselectedOpacity = 0.55;
}

/// カードの角丸半径
class CardConstants {
  static const double radiusHero = 20.0;
  static const double radiusMagazine = 18.0;
  static const double radiusEditorial = 22.0;
}

/// ボトムシートの規格値
class BottomSheetConstants {
  static const double radius = 28.0;
}

/// モーダルの規格値
class ModalConstants {
  static const double radius = 24.0;
  static const double iconSize = 44.0;
  static const double iconRadius = 12.0;
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x08231E1A),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x14231E1A),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A231E1A),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: 0,
    ),
  ];
}
