import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static SettingsService? _instance;
  static SharedPreferences? _preferences;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    _instance ??= SettingsService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // テーマ設定のキー
  static const String _themeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';

  // テーマモード
  ThemeMode get themeMode {
    final themeModeIndex = _preferences?.getInt(_themeKey) ?? 0;
    return ThemeMode.values[themeModeIndex];
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _preferences?.setInt(_themeKey, themeMode.index);
  }

  // アクセントカラー
  Color get accentColor {
    final colorValue = _preferences?.getInt(_accentColorKey) ?? 0xFF6C4AB6;
    return Color(colorValue);
  }

  Future<void> setAccentColor(Color color) async {
    final r = (color.r * 255.0).round() & 0xff;
    final g = (color.g * 255.0).round() & 0xff;
    final b = (color.b * 255.0).round() & 0xff;
    final a = (color.a * 255.0).round() & 0xff;
    await _preferences?.setInt(_accentColorKey, a << 24 | r << 16 | g << 8 | b);
  }

  // 利用可能なアクセントカラー
  static final List<Color> availableColors = [
    const Color(0xFF6C4AB6), // Purple (デフォルト)
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFE91E63), // Pink
    const Color(0xFFFF9800), // Orange
    const Color(0xFF00BCD4), // Cyan
  ];

  static final List<String> colorNames = [
    'パープル',
    'ブルー',
    'グリーン',
    'ピンク',
    'オレンジ',
    'シアン',
  ];
}