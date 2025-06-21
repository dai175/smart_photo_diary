import 'package:flutter/material.dart';

/// Smart Photo Diary アプリケーションのカラーパレット
/// Material Design 3 の原則に基づいて設計
class AppColors {
  AppColors._();

  // ============= PRIMARY COLORS =============
  /// メインブランドカラー（現在の青系を基調）
  static const Color primary = Color(0xFF5C8DAD);
  static const Color primaryLight = Color(0xFF8BB5D3);
  static const Color primaryDark = Color(0xFF3A5F7D);

  /// Primary コンテナ
  static const Color primaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimaryContainer = Color(0xFF1A237E);

  // ============= SECONDARY COLORS =============
  /// セカンダリーカラー（紫系アクセント）
  static const Color secondary = Color(0xFF9C27B0);
  static const Color secondaryLight = Color(0xFFBA68C8);
  static const Color secondaryDark = Color(0xFF7B1FA2);

  /// Secondary コンテナ
  static const Color secondaryContainer = Color(0xFFF3E5F5);
  static const Color onSecondaryContainer = Color(0xFF4A148C);

  // ============= ACCENT COLORS =============
  /// アクセントカラー（暖色系）
  static const Color accent = Color(0xFFFF7043);
  static const Color accentLight = Color(0xFFFF8A65);
  static const Color accentDark = Color(0xFFD84315);

  // ============= NEUTRAL COLORS =============
  /// 背景色
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);

  /// サーフェス色
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// アウトライン
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFF5F5F5);

  // ============= TEXT COLORS =============
  /// テキストカラー
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // ============= STATE COLORS =============
  /// エラー色
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);

  /// 成功色
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  /// 警告色
  static const Color warning = Color(0xFFEF6C00);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFBF360C);

  /// 情報色
  static const Color info = Color(0xFF0277BD);
  static const Color infoContainer = Color(0xFFE1F5FE);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF01579B);

  // ============= GRADIENT COLORS =============
  /// プライマリーグラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// セカンダリーグラデーション
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  /// アクセントグラデーション
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  /// ホーム画面用グラデーション（既存デザインとの互換性）
  static const LinearGradient homeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE1BEE7), // 薄紫
      Color(0xFFFFCDD2), // 薄ピンク
      Color(0xFFFFF9C4), // 薄黄
    ],
  );

  /// より複雑で美しいホームグラデーション
  static const LinearGradient modernHomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
    colors: [
      Color(0xFF667eea), // 青紫
      Color(0xFF764ba2), // 紫
      Color(0xFFf093fb), // ピンク
      Color(0xFFf5576c), // 赤ピンク
    ],
  );

  // ============= SHADOW COLORS =============
  /// 影の色
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowStrong = Color(0x33000000);

  // ============= HELPER METHODS =============
  /// 明度に基づいてテキスト色を決定
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? onBackground : onBackgroundDark;
  }

  /// カラーの透明度を調整
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }

  /// ホバー時のカラー
  static Color getHoverColor(Color baseColor) {
    return baseColor.withValues(alpha: 0.08);
  }

  /// フォーカス時のカラー
  static Color getFocusColor(Color baseColor) {
    return baseColor.withValues(alpha: 0.12);
  }

  /// プレス時のカラー
  static Color getPressedColor(Color baseColor) {
    return baseColor.withValues(alpha: 0.16);
  }
}
