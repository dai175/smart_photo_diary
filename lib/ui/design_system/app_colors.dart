import 'package:flutter/material.dart';

/// Smart Photo Diary アプリケーションのカラーパレット
/// Quiet Luxury デザイン — 温かみのあるニュートラル基調
class AppColors {
  AppColors._();

  // ============= PRIMARY COLORS =============
  /// Warm Slate — 写真を邪魔しない落ち着いたトーン
  static const Color primary = Color(0xFF6B7B8D);
  static const Color primaryLight = Color(0xFF95A5B4);
  static const Color primaryDark = Color(0xFF4A5968);

  /// Primary コンテナ — 温かみのあるクリーム
  static const Color primaryContainer = Color(0xFFE8E4DF);
  static const Color onPrimaryContainer = Color(0xFF2C3338);

  // ============= SECONDARY COLORS =============
  /// Warm Taupe — 極めて控えめなアクセント
  static const Color secondary = Color(0xFFA68B7B);
  static const Color secondaryLight = Color(0xFFC4AFA1);
  static const Color secondaryDark = Color(0xFF7D6758);

  /// Secondary コンテナ
  static const Color secondaryContainer = Color(0xFFF0EAE4);
  static const Color onSecondaryContainer = Color(0xFF3E322B);

  // ============= ACCENT COLORS =============
  /// Terracotta — ここぞのアクセントのみ使用
  static const Color accent = Color(0xFFB8856C);
  static const Color accentLight = Color(0xFFD4A68E);
  static const Color accentDark = Color(0xFF8E6450);

  // ============= NEUTRAL COLORS =============
  /// 背景色 — 温かみのあるオフホワイト / ウォームニアブラック
  static const Color background = Color(0xFFF8F6F3);
  static const Color backgroundDark = Color(0xFF1A1816);

  /// サーフェス色
  static const Color surface = Color(0xFFFAF8F5);
  static const Color surfaceDark = Color(0xFF221F1D);
  static const Color surfaceVariant = Color(0xFFF0EDE8);

  /// ダークモード用サーフェスコンテナ
  static const Color surfaceContainerHighestDark = Color(0xFF2E2A27);
  static const Color surfaceContainerHighDark = Color(0xFF3A3633);
  static const Color surfaceContainerDark = Color(0xFF2A2623);

  /// アウトライン — 温かみのあるグレー
  static const Color outline = Color(0xFFDDD8D2);
  static const Color outlineVariant = Color(0xFFEDE9E4);
  static const Color outlineDark = Color(0xFF3D3833);

  // ============= TEXT COLORS =============
  /// 温かみのあるダークトーン（純黒を避ける）
  static const Color onBackground = Color(0xFF2C2825);
  static const Color onBackgroundDark = Color(0xFFE8E2DC);
  static const Color onSurface = Color(0xFF2C2825);
  static const Color onSurfaceDark = Color(0xFFE8E2DC);
  static const Color onSurfaceVariant = Color(0xFF6B6560);

  // ============= STATE COLORS =============
  /// エラー色 — 落ち着いたレッド
  static const Color error = Color(0xFFB5453A);
  static const Color errorContainer = Color(0xFFFCE4E1);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF4A1510);

  /// 成功色 — セージグリーン
  static const Color success = Color(0xFF5C8A62);
  static const Color successContainer = Color(0xFFE4F0E5);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1E3B21);

  /// 警告色 — ウォームアンバー
  static const Color warning = Color(0xFFC4844A);
  static const Color warningContainer = Color(0xFFF8EDE0);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF4A2E12);

  /// 情報色 — ミューテッドブルー
  static const Color info = Color(0xFF5A7F96);
  static const Color infoContainer = Color(0xFFE0EEF5);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF1A3344);

  // ============= SHADOW COLORS =============
  /// 温かみのある影
  static const Color shadow = Color(0x14231E1A);
  static const Color shadowLight = Color(0x0A231E1A);
  static const Color shadowStrong = Color(0x28231E1A);

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
