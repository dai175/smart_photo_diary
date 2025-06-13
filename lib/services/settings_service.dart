import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';

/// 日記生成方式の列挙型
enum DiaryGenerationMode {
  /// ラベル抽出方式（TensorFlow Lite → ラベル → Gemini Text API）
  labels,
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
  static const String _generationModeKey = 'diary_generation_mode';

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


  // 日記生成モード
  DiaryGenerationMode get generationMode {
    final modeIndex = _preferences?.getInt(_generationModeKey) ?? 0;
    return DiaryGenerationMode.values[modeIndex];
  }

  Future<Result<void>> setGenerationMode(DiaryGenerationMode mode) async {
    return ResultHelper.tryExecuteAsync(
      () async {
        await _preferences?.setInt(_generationModeKey, mode.index);
      },
      context: 'SettingsService.setGenerationMode',
    );
  }

  // 利用可能な生成モード
  static final List<DiaryGenerationMode> availableModes = [
    DiaryGenerationMode.labels,
    DiaryGenerationMode.vision,
  ];

  static final List<String> modeNames = [
    'プライバシー重視',
    '精度重視',
  ];

  static final List<String> modeDescriptions = [
    '写真をサーバーに送らず端末内で分析・精度は控えめ',
    '写真をサーバーに送って分析・精度は高め',
  ];
}