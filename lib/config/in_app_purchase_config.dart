import 'package:intl/intl.dart';

import '../constants/subscription_constants.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../utils/locale_format_utils.dart';

/// In-App Purchase設定管理クラス
///
/// App Store Connect/Google Play Console用の商品設定、
/// 価格設定、地域別設定等を一元管理します。
///
/// ## 主な機能
/// - プラットフォーム別商品ID管理
/// - 地域別価格設定
/// - 商品メタデータ管理
/// - テスト環境設定
class InAppPurchaseConfig {
  // プライベートコンストラクタでインスタンス化を防ぐ
  InAppPurchaseConfig._();

  // ========================================
  // プラットフォーム識別
  // ========================================

  /// 現在のプラットフォームがiOSかどうか
  static bool get isIOS =>
      const bool.fromEnvironment('dart.library.io') &&
      identical(1, 1.0); // iOS固有の判定（実際の実装ではPlatform.isIOSを使用）

  /// 現在のプラットフォームがAndroidかどうか
  static bool get isAndroid => !isIOS;

  // ========================================
  // 商品ID設定
  // ========================================

  /// Premium月額プランの商品ID
  static String get premiumMonthlyProductId =>
      SubscriptionConstants.premiumMonthlyProductId;

  /// Premium年額プランの商品ID
  static String get premiumYearlyProductId =>
      SubscriptionConstants.premiumYearlyProductId;

  /// 全商品IDのリスト
  static List<String> get allProductIds => [
    premiumMonthlyProductId,
    premiumYearlyProductId,
  ];

  /// プランから商品IDを取得（メイン実装 - Planクラス版）
  static String getProductIdFromPlan(Plan plan) {
    if (plan is BasicPlan) {
      throw ArgumentError('Basic plan does not have a product ID');
    }
    return plan.productId;
  }

  /// 商品IDからプランを取得（メイン実装 - Planクラス版）
  static Plan getPlanFromProductId(String productId) {
    // 全プランから商品IDが一致するものを検索
    for (final plan in PlanFactory.getAllPlans()) {
      if (plan.productId == productId) {
        return plan;
      }
    }
    throw ArgumentError('Unknown product ID: $productId');
  }

  // ========================================
  // 価格設定
  // ========================================

  /// Premium月額プランの価格（円）
  static int get premiumMonthlyPrice =>
      SubscriptionConstants.premiumMonthlyPrice;

  /// Premium年額プランの価格（円）
  static int get premiumYearlyPrice => SubscriptionConstants.premiumYearlyPrice;

  /// 年額割引額を計算
  static int get yearlyDiscountAmount =>
      SubscriptionConstants.calculateYearlyDiscount();

  /// 年額割引率を計算
  static double get yearlyDiscountPercentage =>
      SubscriptionConstants.calculateDiscountPercentage();

  // ========================================
  // 地域別価格設定（削除済み）
  // ========================================

  /// 注意: 地域別の固定価格設定は削除されました。
  /// App Storeの動的価格取得（DynamicPricingUtils）を使用してください。
  ///
  /// 各地域での価格と通貨は、App Store ConnectまたはGoogle Play Console
  /// で設定された価格階層に基づいて自動的に決定されます。

  // ========================================
  // 商品メタデータ
  // ========================================

  /// Premium月額プランの表示名
  static String get premiumMonthlyDisplayName => 'Premium Monthly Plan';

  /// Premium年額プランの表示名
  static String get premiumYearlyDisplayName => 'Premium Yearly Plan';

  /// Premium月額プランの説明文
  static String get premiumMonthlyDescription =>
      'Access 100 AI diary generations per month and premium features.';

  /// Premium年額プランの説明文
  static String get premiumYearlyDescription =>
      'Access 100 AI diary generations per month and premium features with yearly billing. Save 22% compared to monthly plan.';

  /// プランの表示名を取得（メイン実装 - Planクラス版）
  static String getDisplayNameFromPlan(Plan plan) {
    return plan.displayName;
  }

  /// プランの説明文を取得（メイン実装 - Planクラス版）
  static String getDescriptionFromPlan(Plan plan) {
    return plan.description;
  }

  // ========================================
  // 無料トライアル設定
  // ========================================

  /// 無料トライアル期間（日数）
  static int get freeTrialDays => SubscriptionConstants.freeTrialDays;

  /// 無料トライアル対象商品ID
  static List<String> get freeTrialEligibleProductIds => [
    premiumMonthlyProductId,
    premiumYearlyProductId,
  ];

  /// 指定商品が無料トライアル対象かどうか
  static bool isEligibleForFreeTrial(String productId) {
    return freeTrialEligibleProductIds.contains(productId);
  }

  // ========================================
  // テスト環境設定
  // ========================================

  /// サンドボックス環境かどうか
  static bool get isSandboxEnvironment =>
      const bool.fromEnvironment('SANDBOX_TESTING', defaultValue: false);

  /// テスト用商品IDプレフィックス
  static String get testProductIdPrefix => isSandboxEnvironment ? 'test_' : '';

  /// テスト環境用の商品ID取得
  static String getTestProductId(String productId) {
    return isSandboxEnvironment ? '$testProductIdPrefix$productId' : productId;
  }

  /// テスト用アカウント設定
  static const Map<String, String> testAccounts = {
    'ios': 'test@smartphotodiary.app',
    'android': 'test.android@smartphotodiary.app',
  };

  // ========================================
  // プラットフォーム固有設定
  // ========================================

  /// iOS App Store Connect設定
  static const Map<String, dynamic> iosConfig = {
    'appStoreConnectKeyId': 'YOUR_APP_STORE_CONNECT_KEY_ID',
    'appStoreConnectIssuerId': 'YOUR_ISSUER_ID',
    'bundleId': 'com.focuswave.dev.smartPhotoDiary',
    'sandboxEnabled': true,
  };

  /// Android Google Play Console設定
  static const Map<String, dynamic> androidConfig = {
    'packageName': 'com.focuswave.dev.smartPhotoDiary',
    'playConsoleProjectId': 'YOUR_PLAY_CONSOLE_PROJECT_ID',
    'serviceAccountEmail': 'YOUR_SERVICE_ACCOUNT@developer.gserviceaccount.com',
    'licenseTestingEnabled': true,
  };

  /// 現在のプラットフォーム設定を取得
  static Map<String, dynamic> get currentPlatformConfig {
    return isIOS ? iosConfig : androidConfig;
  }

  // ========================================
  // 検証・セキュリティ設定
  // ========================================

  /// サーバーサイド検証が有効かどうか
  static bool get serverSideValidationEnabled => false; // Phase 1では無効

  /// レシート検証エンドポイント
  static String get receiptValidationEndpoint =>
      'https://api.smartphotodiary.app/validate-receipt';

  /// 不正購入検知が有効かどうか
  static bool get fraudDetectionEnabled => true;

  /// 購入検証タイムアウト（秒）
  static int get purchaseValidationTimeoutSeconds => 30;

  // ========================================
  // ヘルパーメソッド
  // ========================================

  /// 価格を表示用文字列に変換
  static String formatPrice(double price, String currencyCode) {
    final locale = Intl.getCurrentLocale().isEmpty
        ? 'ja'
        : Intl.getCurrentLocale();

    return LocaleFormatUtils.formatCurrency(
      price,
      locale: locale,
      currencyCode: currencyCode,
    );
  }

  /// 商品IDの妥当性をチェック
  static bool isValidProductId(String productId) {
    return allProductIds.contains(productId);
  }

  /// プランが購入可能かどうかをチェック（メイン実装 - Planクラス版）
  static bool isPurchasableFromPlan(Plan plan) {
    return plan.isPaid;
  }

  /// デバッグ情報を出力
  static Map<String, dynamic> getDebugInfo() {
    return {
      'platform': isIOS ? 'iOS' : 'Android',
      'productIds': allProductIds,
      'sandboxMode': isSandboxEnvironment,
      'freeTrialDays': freeTrialDays,
      'serverValidation': serverSideValidationEnabled,
      'note': '価格情報は動的価格取得システム（DynamicPricingUtils）から取得されます',
    };
  }

  // ========================================
  // 機能フラグ
  // ========================================

  /// In-App Purchase機能が有効かどうか
  static bool get inAppPurchaseEnabled => true;

  /// 無料トライアル機能が有効かどうか
  static bool get freeTrialEnabled => true;

  /// 購入復元機能が有効かどうか
  static bool get restorePurchasesEnabled => true;

  /// プラン変更機能が有効かどうか
  static bool get planChangeEnabled => true;

  /// 購入履歴表示機能が有効かどうか
  static bool get purchaseHistoryEnabled => true;
}

/// In-App Purchase関連のエラー定義
class InAppPurchaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const InAppPurchaseException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('InAppPurchaseException: $message');
    if (code != null) {
      buffer.write(' [Code: $code]');
    }
    return buffer.toString();
  }
}

/// 購入設定検証ユーティリティ
class InAppPurchaseConfigValidator {
  /// 設定の妥当性をチェック
  static List<String> validateConfig() {
    final errors = <String>[];

    // 商品ID検証
    if (InAppPurchaseConfig.allProductIds.isEmpty) {
      errors.add('No product IDs configured');
    }

    // 価格検証
    if (InAppPurchaseConfig.premiumMonthlyPrice <= 0) {
      errors.add('Invalid monthly price');
    }

    if (InAppPurchaseConfig.premiumYearlyPrice <= 0) {
      errors.add('Invalid yearly price');
    }

    // 地域価格検証は削除（動的価格取得システムを使用）

    return errors;
  }

  /// 設定が有効かどうか
  static bool isConfigValid() {
    return validateConfig().isEmpty;
  }
}
