import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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
}
