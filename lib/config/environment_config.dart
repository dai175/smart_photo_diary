import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';

/// 環境変数を安全に管理するクラス
class EnvironmentConfig {
  static LoggingService get _logger => serviceLocator.get<LoggingService>();
  static bool _isInitialized = false;
  static String? _cachedGeminiApiKey;
  static String? _cachedForcePlan;

  /// 環境変数を初期化
  static Future<void> initialize() async {
    try {
      // 1. 本番環境：ビルド時定数（CI/CDシークレット）を優先
      _cachedGeminiApiKey = const String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: '',
      );

      _logger.info(
        'APIキー取得方法: ${_cachedGeminiApiKey!.isEmpty ? ".envファイル" : "build-time constants"}',
        context: 'EnvironmentConfig.initialize',
      );

      // 2. 開発環境：.envファイルから読み込み（デバッグビルドのみ）
      if (_cachedGeminiApiKey!.isEmpty && kDebugMode) {
        try {
          // プロジェクトルートから読み込み（セキュリティを考慮）
          await dotenv.load(fileName: '.env');
          _cachedGeminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
          _logger.info(
            '開発環境: .envファイルから読み込み完了',
            context: 'EnvironmentConfig.initialize',
          );
        } catch (e) {
          _logger.warning(
            '.envファイル読み込み失敗（開発環境）',
            context: 'EnvironmentConfig.initialize',
            data: {'error': e.toString()},
          );
        }
      }

      // プラン強制設定を読み込み（デバッグモードでのみ有効）
      if (kDebugMode) {
        _cachedForcePlan = const String.fromEnvironment(
          'FORCE_PLAN',
          defaultValue: '',
        );
        if (_cachedForcePlan!.isEmpty) {
          try {
            _cachedForcePlan = dotenv.env['FORCE_PLAN'] ?? '';
          } catch (e) {
            _cachedForcePlan = '';
          }
        }
        _cachedForcePlan = _cachedForcePlan!.isNotEmpty
            ? _cachedForcePlan!.toLowerCase()
            : null;
      } else {
        _cachedForcePlan = null; // 本番ビルドでは常にnull
      }

      _isInitialized = true;

      _logger.info(
        'EnvironmentConfig初期化完了',
        context: 'EnvironmentConfig.initialize',
      );
      _logger.info(
        'APIキー取得方法: ${_cachedGeminiApiKey!.isEmpty ? "未設定" : (kDebugMode ? "開発環境" : "本番環境")}',
        context: 'EnvironmentConfig.initialize',
      );
    } catch (e) {
      _logger.error(
        '環境変数初期化エラー',
        context: 'EnvironmentConfig.initialize',
        error: e,
      );
      _isInitialized = false;
    }
  }

  /// Gemini APIキーを取得
  static String get geminiApiKey {
    if (!_isInitialized) {
      _logger.warning(
        'EnvironmentConfigが初期化されていません',
        context: 'EnvironmentConfig.geminiApiKey',
      );
      // テスト環境の場合はダミーキーを返す
      if (kDebugMode &&
          const String.fromEnvironment('FLUTTER_TEST') == 'true') {
        return 'AIzaTest_dummy_key_for_testing';
      }
      return '';
    }

    final key = _cachedGeminiApiKey ?? '';
    if (key.isEmpty) {
      _logger.warning(
        'GEMINI_API_KEYが設定されていません',
        context: 'EnvironmentConfig.geminiApiKey',
      );
      // テスト環境の場合はダミーキーを返す
      if (kDebugMode &&
          const String.fromEnvironment('FLUTTER_TEST') == 'true') {
        return 'AIzaTest_dummy_key_for_testing';
      }
    }

    return key;
  }

  /// 初期化状態を確認
  static bool get isInitialized => _isInitialized;

  /// APIキーが有効かどうかを確認
  static bool get hasValidApiKey {
    // テスト環境の場合は常にtrueを返す
    if (kDebugMode && const String.fromEnvironment('FLUTTER_TEST') == 'true') {
      return true;
    }

    return _isInitialized &&
        _cachedGeminiApiKey != null &&
        _cachedGeminiApiKey!.isNotEmpty &&
        _cachedGeminiApiKey!.startsWith('AIza');
  }

  /// プラン強制設定を取得（デバッグモードでのみ有効）
  /// 有効な値: 'basic', 'premium', 'premium_monthly', 'premium_yearly'
  static String? get forcePlan {
    if (!kDebugMode) return null; // 本番ビルドでは常にnull
    if (!_isInitialized) return null;

    final plan = _cachedForcePlan;
    if (plan == null || plan.isEmpty) return null;

    // 有効なプラン名のみ許可
    const validPlans = [
      'basic',
      'premium',
      'premium_monthly',
      'premium_yearly',
    ];
    if (validPlans.contains(plan)) {
      return plan;
    }

    _logger.warning(
      '無効なFORCE_PLANが指定されました',
      context: 'EnvironmentConfig.forcePlan',
      data: {'invalidPlan': plan, 'validPlans': validPlans},
    );
    return null;
  }

  /// プレミアムプランが強制されているかどうか
  static bool get forcePremium {
    final plan = forcePlan;
    return plan != null && plan.startsWith('premium');
  }

  /// Basicプランが強制されているかどうか
  static bool get forceBasic {
    return forcePlan == 'basic';
  }

  /// デバッグモードかどうかを確認
  static bool get isDebugMode => kDebugMode;

  /// デバッグ情報を出力
  static void printDebugInfo() {
    _logger.debug(
      'Environment Config Debug Info',
      context: 'EnvironmentConfig.printDebugInfo',
      data: {
        '初期化状態': _isInitialized,
        'デバッグモード': kDebugMode,
        'APIキー設定': _cachedGeminiApiKey?.isNotEmpty == true ? '有効' : '無効',
        'APIキー形式': _cachedGeminiApiKey?.startsWith('AIza') == true
            ? '正常'
            : '異常',
        'プラン強制': _cachedForcePlan,
        'dotenv環境': '${dotenv.env.keys.length}個のキー',
      },
    );
  }

  /// 環境変数を再読み込み
  static Future<void> reload() async {
    _isInitialized = false;
    _cachedGeminiApiKey = null;
    _cachedForcePlan = null;
    await initialize();
  }
}
