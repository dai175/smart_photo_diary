import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';

/// 日記生成方式の列挙型
enum DiaryGenerationMode {
  /// 画像直接解析方式（画像 → Gemini Vision API）
  vision,
}

class SettingsService {
  static SettingsService? _instance;
  static SharedPreferences? _preferences;

  SettingsService._();

  /// 非同期ファクトリメソッドでサービスインスタンスを取得
  static Future<SettingsService> getInstance() async {
    try {
      _instance ??= SettingsService._();
      _preferences ??= await SharedPreferences.getInstance();
      return _instance!;
    } catch (error) {
      throw ErrorHandler.handleError(error, context: 'SettingsService.getInstance');
    }
  }

  /// 同期的なサービスインスタンス取得（事前に初期化済みの場合のみ）
  static SettingsService get instance {
    if (_instance == null) {
      throw StateError('SettingsService has not been initialized. Call getInstance() first.');
    }
    return _instance!;
  }

  // テーマ設定のキー
  static const String _themeKey = 'theme_mode';

  // テーマモード
  ThemeMode get themeMode {
    return ErrorHandler.safeExecuteSync(
      () {
        final themeModeIndex = _preferences?.getInt(_themeKey) ?? 0;
        if (themeModeIndex < 0 || themeModeIndex >= ThemeMode.values.length) {
          return ThemeMode.system;
        }
        return ThemeMode.values[themeModeIndex];
      },
      context: 'SettingsService.themeMode',
      fallbackValue: ThemeMode.system,
    ) ?? ThemeMode.system;
  }

  Future<Result<void>> setThemeMode(ThemeMode themeMode) async {
    return ResultHelper.tryExecuteAsync(
      () async {
        await _preferences?.setInt(_themeKey, themeMode.index);
      },
      context: 'SettingsService.setThemeMode',
    );
  }


  // 日記生成モード（常にvision固定）
  static const DiaryGenerationMode generationMode = DiaryGenerationMode.vision;
}