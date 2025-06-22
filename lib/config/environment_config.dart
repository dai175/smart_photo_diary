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
      await dotenv.load(fileName: ".env");
      _cachedGeminiApiKey = dotenv.env['GEMINI_API_KEY'];

      // プラン強制設定を読み込み（デバッグモードでのみ有効）
      if (kDebugMode) {
        final forcePlanValue =
            dotenv.env['FORCE_PLAN'] ??
            const String.fromEnvironment('FORCE_PLAN', defaultValue: '');
        _cachedForcePlan = forcePlanValue.toLowerCase();
      } else {
        _cachedForcePlan = null; // 本番ビルドでは常にnull
      }

      _isInitialized = true;

      debugPrint('EnvironmentConfig初期化完了');
      debugPrint(
        'GEMINI_API_KEY: ${_cachedGeminiApiKey?.isNotEmpty == true ? "設定済み" : "未設定"}',
      );
      debugPrint('FORCE_PLAN: $_cachedForcePlan');

      if (_cachedGeminiApiKey?.isNotEmpty == true) {
        debugPrint('APIキープレビュー: ${_cachedGeminiApiKey!.substring(0, 8)}...');
      }
    } catch (e) {
      debugPrint('環境変数読み込みエラー: $e');
      _isInitialized = false;
    }
  }

  /// Gemini APIキーを取得
  static String get geminiApiKey {
    if (!_isInitialized) {
      debugPrint('警告: EnvironmentConfigが初期化されていません');
      return '';
    }

    final key = _cachedGeminiApiKey ?? '';
    if (key.isEmpty) {
      debugPrint('警告: GEMINI_API_KEYが設定されていません');
    }

    return key;
  }

  /// 初期化状態を確認
  static bool get isInitialized => _isInitialized;

  /// APIキーが有効かどうかを確認
  static bool get hasValidApiKey =>
      _isInitialized &&
      _cachedGeminiApiKey != null &&
      _cachedGeminiApiKey!.isNotEmpty &&
      _cachedGeminiApiKey!.startsWith('AIza');

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
