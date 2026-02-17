import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/subscription_constants.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';

/// 環境変数を安全に管理するクラス
class EnvironmentConfig {
  static ILoggingService get _logger => serviceLocator.get<ILoggingService>();
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
        'API key source: ${_cachedGeminiApiKey!.isEmpty ? ".env file" : "build-time constants"}',
        context: 'EnvironmentConfig.initialize',
      );

      // 2. 開発環境：.envファイルから読み込み（デバッグビルドのみ）
      if (_cachedGeminiApiKey!.isEmpty && kDebugMode) {
        try {
          // プロジェクトルートから読み込み（セキュリティを考慮）
          await dotenv.load(fileName: '.env');
          _cachedGeminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
          _logger.info(
            'Development: loaded from .env file',
            context: 'EnvironmentConfig.initialize',
          );
        } catch (e) {
          _logger.warning(
            'Failed to load .env file (development)',
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
        'EnvironmentConfig initialization completed',
        context: 'EnvironmentConfig.initialize',
      );
      _logger.info(
        'API key source: ${_cachedGeminiApiKey!.isEmpty ? "not set" : (kDebugMode ? "development" : "production")}',
        context: 'EnvironmentConfig.initialize',
      );
    } catch (e) {
      _logger.error(
        'Environment config initialization error',
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
        'EnvironmentConfig is not initialized',
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
        'GEMINI_API_KEY is not set',
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
      'Invalid FORCE_PLAN specified',
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
    return forcePlan == SubscriptionConstants.basicPlanId;
  }

  /// デバッグモードかどうかを確認
  static bool get isDebugMode => kDebugMode;

  /// デバッグ情報を出力
  static void printDebugInfo() {
    _logger.debug(
      'Environment Config Debug Info',
      context: 'EnvironmentConfig.printDebugInfo',
      data: {
        'initialized': _isInitialized,
        'debugMode': kDebugMode,
        'apiKeySet': _cachedGeminiApiKey?.isNotEmpty == true
            ? 'valid'
            : 'invalid',
        'apiKeyFormat': _cachedGeminiApiKey?.startsWith('AIza') == true
            ? 'valid'
            : 'invalid',
        'forcePlan': _cachedForcePlan,
        'dotenvKeys': '${dotenv.env.keys.length} keys',
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
