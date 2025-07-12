import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境変数を安全に管理するクラス
class EnvironmentConfig {
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

      // 2. 開発環境：.envファイルから読み込み（デバッグビルドのみ）
      if (_cachedGeminiApiKey!.isEmpty && kDebugMode) {
        try {
          await dotenv.load(); // assetsから読み込み
          _cachedGeminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
        } catch (e) {
          // .envファイル読み込み失敗
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

      debugPrint('🚀 EnvironmentConfig初期化完了');
    } catch (e) {
      debugPrint('❌ 環境変数初期化エラー: $e');
      _isInitialized = false;
    }
  }

  /// Gemini APIキーを取得
  static String get geminiApiKey {
    if (!_isInitialized) {
      debugPrint('警告: EnvironmentConfigが初期化されていません');
      // テスト環境の場合はダミーキーを返す
      if (kDebugMode &&
          const String.fromEnvironment('FLUTTER_TEST') == 'true') {
        return 'AIzaTest_dummy_key_for_testing';
      }
      return '';
    }

    final key = _cachedGeminiApiKey ?? '';
    if (key.isEmpty) {
      debugPrint('警告: GEMINI_API_KEYが設定されていません');
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

    debugPrint('警告: 無効なFORCE_PLANが指定されました: $plan');
    debugPrint('有効な値: ${validPlans.join(', ')}');
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
    debugPrint('=== Environment Config Debug ===');
    debugPrint('初期化状態: $_isInitialized');
    debugPrint('デバッグモード: $kDebugMode');
    debugPrint(
      'APIキー設定: ${_cachedGeminiApiKey?.isNotEmpty == true ? "有効" : "無効"}',
    );
    debugPrint(
      'APIキー形式: ${_cachedGeminiApiKey?.startsWith('AIza') == true ? "正常" : "異常"}',
    );
    debugPrint('プラン強制: $_cachedForcePlan');
    debugPrint('dotenv環境: ${dotenv.env.keys.length}個のキー');
    debugPrint('================================');
  }

  /// 環境変数を再読み込み
  static Future<void> reload() async {
    _isInitialized = false;
    _cachedGeminiApiKey = null;
    _cachedForcePlan = null;
    await initialize();
  }
}
