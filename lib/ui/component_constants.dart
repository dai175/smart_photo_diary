/// UIコンポーネント固有のサイズ/太さなどのトークン
/// デザインシステム（AppSpacing/AppTypography/AppColors）に属さない
/// “部品の規格値” をここで管理します。
class ComponentConstants {
  ComponentConstants._();
}

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

  // 枠線の太さ
  static const double borderWidth = 1.5;

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
  static const double size = 22.0; // 直径
}

/// 丸いタイル/アバターなどの共通サイズ
class TileConstants {
  static const double sizeMd = 40.0;
}

/// ボタンの規格値
class ButtonConstants {
  static const double borderWidth = 1.5;
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
