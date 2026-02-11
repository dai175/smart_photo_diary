import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_colors.dart';
import 'app_spacing.dart';
import '../component_constants.dart';
import 'app_theme_light.dart';
import 'app_theme_dark.dart';

/// Smart Photo Diary アプリケーションのテーマ設定
/// Material Design 3 に基づいたライト・ダークテーマを提供
class AppTheme {
  AppTheme._();

  // テスト環境かどうか
  static bool get _isTestEnv {
    try {
      // Flutter test runner sets FLUTTER_TEST=true
      return !kIsWeb && (Platform.environment['FLUTTER_TEST'] == 'true');
    } catch (_) {
      return false;
    }
  }

  // ============= LIGHT THEME =============
  static ThemeData get lightTheme => buildLightTheme(isTestEnv: _isTestEnv);

  // ============= DARK THEME =============
  static ThemeData get darkTheme => buildDarkTheme(isTestEnv: _isTestEnv);

  // ============= HELPER METHODS =============
  /// 現在のテーマがダークかどうかを判定
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// カスタムテーマデータを作成
  static ThemeData createCustomTheme({
    required Color primaryColor,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: brightness == Brightness.light
          ? lightTheme.textTheme
          : darkTheme.textTheme,
    );
  }

  /// グラデーション背景を作成
  static Widget createGradientBackground({
    required Widget child,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.modernHomeGradient,
      ),
      child: child,
    );
  }

  /// ブラー効果付きコンテナを作成
  static Widget createBlurContainer({
    required Widget child,
    double blurAmount = BlurConstants.defaultBlur,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            AppColors.surface.withValues(alpha: BlurConstants.backgroundAlpha),
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: child,
    );
  }
}
