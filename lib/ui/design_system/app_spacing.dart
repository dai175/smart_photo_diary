import 'package:flutter/material.dart';

/// Smart Photo Diary アプリケーションのスペーシングシステム
/// 8pt グリッドシステムに基づいて設計
class AppSpacing {
  AppSpacing._();

  // ============= BASE SPACING VALUES =============
  /// 基本単位（8pt）
  static const double base = 8.0;

  // ============= SPACING SCALE =============
  /// 極小スペース（2pt）
  static const double xxs = base * 0.25; // 2

  /// 極小スペース（4pt）
  static const double xs = base * 0.5;   // 4

  /// 小スペース（8pt）
  static const double sm = base * 1.0;   // 8

  /// 中スペース（12pt）
  static const double md = base * 1.5;   // 12

  /// 大スペース（16pt）
  static const double lg = base * 2.0;   // 16

  /// 特大スペース（24pt）
  static const double xl = base * 3.0;   // 24

  /// 超特大スペース（32pt）
  static const double xxl = base * 4.0;  // 32

  /// 巨大スペース（48pt）
  static const double xxxl = base * 6.0; // 48

  // ============= SPECIFIC USE CASES =============
  /// アイコンサイズ
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  /// ボタンの高さ
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;

  /// カードの角丸
  static const double borderRadiusXs = 4.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 20.0;
  static const double borderRadiusXxl = 24.0;

  /// 写真の角丸（特別なケース）
  static const double photoRadiusDefault = 12.0;
  static const double photoRadiusLarge = 16.0;

  /// シャドウの設定
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;
  static const double elevationXxl = 16.0;

  /// 最小タッチターゲットサイズ
  static const double minTouchTarget = 44.0;

  // ============= PADDING PRESETS =============
  /// 画面端のパディング
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: lg);

  /// カードのパディング
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);

  /// ボタンのパディング
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: lg,
  );

  /// リストアイテムのパディング
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// 入力フィールドのパディング
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// ダイアログのパディング
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl);

  /// アプリバーのパディング
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(horizontal: sm);

  // ============= MARGIN PRESETS =============
  /// セクション間のマージン
  static const EdgeInsets sectionMargin = EdgeInsets.only(bottom: xl);

  /// カード間のマージン
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: lg);

  /// 小さな要素間のマージン
  static const EdgeInsets elementMargin = EdgeInsets.only(bottom: sm);

  // ============= BORDER RADIUS PRESETS =============
  /// カード用の角丸
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(borderRadiusMd),
  );

  /// 大きなカード用の角丸
  static const BorderRadius cardRadiusLarge = BorderRadius.all(
    Radius.circular(borderRadiusLg),
  );

  /// ボタン用の角丸
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(borderRadiusSm),
  );

  /// 入力フィールド用の角丸
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(borderRadiusSm),
  );

  /// チップ/タグ用の角丸
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(borderRadiusXl),
  );

  /// 写真用の角丸
  static const BorderRadius photoRadius = BorderRadius.all(
    Radius.circular(photoRadiusDefault),
  );

  /// 写真用の大きな角丸
  static const BorderRadius photoRadiusLargeRadius = BorderRadius.all(
    Radius.circular(photoRadiusLarge),
  );

  /// モーダル/ダイアログ用の角丸
  static const BorderRadius modalRadius = BorderRadius.vertical(
    top: Radius.circular(borderRadiusXl),
  );

  // ============= SHADOW PRESETS =============
  /// カード用のシャドウ
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: elevationMd,
      offset: Offset(0, 2),
    ),
  ];

  /// 浮上したカード用のシャドウ
  static const List<BoxShadow> elevatedCardShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: elevationLg,
      offset: Offset(0, 4),
    ),
  ];

  /// ボタン用のシャドウ
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x15000000),
      blurRadius: elevationSm,
      offset: Offset(0, 1),
    ),
  ];

  /// 強いシャドウ
  static const List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: elevationXl,
      offset: Offset(0, 6),
    ),
  ];

  // ============= HELPER METHODS =============
  /// レスポンシブなスペーシングを取得
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return baseSpacing * 1.2; // タブレット/デスクトップで少し大きく
    }
    return baseSpacing;
  }

  /// 安全エリアを考慮したパディングを取得
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top + lg,
      bottom: mediaQuery.padding.bottom + lg,
      left: lg,
      right: lg,
    );
  }

  /// カスタムボックスシャドウを作成
  static List<BoxShadow> createShadow({
    Color color = const Color(0x1A000000),
    double blurRadius = elevationMd,
    Offset offset = const Offset(0, 2),
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }

  /// ボーダーラディウスを作成
  static BorderRadius createRadius(double radius) {
    return BorderRadius.all(Radius.circular(radius));
  }

  /// 非対称ボーダーラディウスを作成
  static BorderRadius createAsymmetricRadius({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
}