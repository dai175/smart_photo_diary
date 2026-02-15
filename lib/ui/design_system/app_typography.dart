import 'package:flutter/material.dart';

/// Smart Photo Diary アプリケーションのタイポグラフィシステム
/// Quiet Luxury — 軽やかなウェイトとゆとりのあるレタースペーシング
/// Google Fontsによる日本語フォント対応はAppThemeで実装
class AppTypography {
  AppTypography._();

  // ============= DISPLAY STYLES =============
  /// Display Large - 最大の見出し（57sp）
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.25,
    height: 1.12,
  );

  /// Display Medium - 大きな見出し（45sp）
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w300,
    letterSpacing: 0,
    height: 1.16,
  );

  /// Display Small - 中程度の見出し（36sp）
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w300,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============= HEADLINE STYLES =============
  /// Headline Large - 主要見出し（32sp）
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.25,
  );

  /// Headline Medium - セカンダリ見出し（28sp）
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.29,
  );

  /// Headline Small - 小見出し（24sp）
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.33,
  );

  // ============= TITLE STYLES =============
  /// Title Large - 大きなタイトル（22sp）
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  /// Title Medium - 中程度のタイトル（16sp）
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  /// Title Small - 小さなタイトル（14sp）
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============= LABEL STYLES =============
  /// Label Large - 大きなラベル（14sp）
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// Label Medium - 中程度のラベル（12sp）
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.33,
  );

  /// Label Small - 小さなラベル（11sp）
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.45,
  );

  // ============= BODY STYLES =============
  /// Body Large - 大きな本文（16sp）
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  /// Body Medium - 標準本文（14sp）
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Body Small - 小さな本文（12sp）
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============= JAPANESE TEXT STYLES =============
  /// 日本語用の見出しスタイル
  static const TextStyle japaneseHeadline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.40,
  );

  /// 日本語用の本文スタイル
  static const TextStyle japaneseBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.60,
  );

  /// 日本語用の小さな本文スタイル
  static const TextStyle japaneseBodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.50,
  );

  // ============= SPECIAL STYLES =============
  /// アプリタイトル用スタイル — ゆとりのあるスペーシング
  static const TextStyle appTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.8,
    height: 1.20,
  );

  /// 日記タイトル用スタイル
  static const TextStyle diaryTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.40,
  );

  /// 日記内容用スタイル
  static const TextStyle diaryContent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.70,
  );

  /// タグ用スタイル — 広めのスペーシング
  static const TextStyle tag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.20,
  );

  /// 統計数値用スタイル — エディトリアルな軽さ
  static const TextStyle statisticsNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.00,
  );

  /// 統計ラベル用スタイル
  static const TextStyle statisticsLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.30,
  );

  /// ボタンテキスト用スタイル
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// キャプション用スタイル
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============= HELPER METHODS =============
  /// 指定されたカラーでテキストスタイルを作成
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 指定されたフォントウェイトでテキストスタイルを作成
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// 指定されたフォントサイズでテキストスタイルを作成
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// テキストに影を追加
  static TextStyle withShadow(
    TextStyle style, {
    Color shadowColor = Colors.black26,
    double blurRadius = 2.0,
    Offset offset = const Offset(0, 1),
  }) {
    return style.copyWith(
      shadows: [
        Shadow(color: shadowColor, blurRadius: blurRadius, offset: offset),
      ],
    );
  }

  /// レスポンシブなフォントサイズを取得
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return baseSize * 1.1; // タブレット/デスクトップで少し大きく
    }
    return baseSize;
  }
}
