import '../constants/subscription_constants.dart';
import '../models/subscription_plan.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';

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

  /// プランから商品IDを取得（互換性レイヤー）
  @Deprecated('Use getProductIdFromPlan() instead')
  static String getProductId(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.premiumMonthly:
        return premiumMonthlyProductId;
      case SubscriptionPlan.premiumYearly:
        return premiumYearlyProductId;
      case SubscriptionPlan.basic:
        throw ArgumentError('Basic plan does not have a product ID');
    }
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

  /// 商品IDからプランを取得（互換性レイヤー）
  @Deprecated('Use getPlanFromProductId() instead')
  static SubscriptionPlan getSubscriptionPlan(String productId) {
    switch (productId) {
      case 'smart_photo_diary_premium_monthly_plan':
        return SubscriptionPlan.premiumMonthly;
      case 'smart_photo_diary_premium_yearly_plan':
        return SubscriptionPlan.premiumYearly;
      default:
        throw ArgumentError('Unknown product ID: $productId');
    }
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
  // 地域別価格設定
  // ========================================

  /// 地域別価格マップ
  static const Map<String, Map<String, dynamic>> regionalPricing = {
    'JP': {
      'currency': 'JPY',
      'symbol': '¥',
      'monthlyPrice': 300,
      'yearlyPrice': 2800,
    },
    'US': {
      'currency': 'USD',
      'symbol': '\$',
      'monthlyPrice': 2.99,
      'yearlyPrice': 28.99,
    },
    'GB': {
      'currency': 'GBP',
      'symbol': '£',
      'monthlyPrice': 2.99,
      'yearlyPrice': 28.99,
    },
    'EU': {
      'currency': 'EUR',
      'symbol': '€',
      'monthlyPrice': 2.99,
      'yearlyPrice': 28.99,
    },
    'CA': {
      'currency': 'CAD',
      'symbol': 'CAD\$',
      'monthlyPrice': 3.99,
      'yearlyPrice': 38.99,
    },
    'AU': {
      'currency': 'AUD',
      'symbol': 'AUD\$',
      'monthlyPrice': 4.49,
      'yearlyPrice': 44.99,
    },
  };

  /// 指定地域の価格情報を取得
  static Map<String, dynamic>? getPricingForRegion(String regionCode) {
    return regionalPricing[regionCode.toUpperCase()];
  }

  /// デフォルト地域（日本）の価格情報を取得
  static Map<String, dynamic> get defaultPricing => regionalPricing['JP']!;

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

  /// プランの表示名を取得（互換性レイヤー）
  @Deprecated('Use getDisplayNameFromPlan() instead')
  static String getDisplayName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.premiumMonthly:
        return premiumMonthlyDisplayName;
      case SubscriptionPlan.premiumYearly:
        return premiumYearlyDisplayName;
      case SubscriptionPlan.basic:
        return 'Basic Plan';
    }
  }

  /// プランの説明文を取得（メイン実装 - Planクラス版）
  static String getDescriptionFromPlan(Plan plan) {
    return plan.description;
  }

  /// プランの説明文を取得（互換性レイヤー）
  @Deprecated('Use getDescriptionFromPlan() instead')
  static String getDescription(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.premiumMonthly:
        return premiumMonthlyDescription;
      case SubscriptionPlan.premiumYearly:
        return premiumYearlyDescription;
      case SubscriptionPlan.basic:
        return 'Free plan with basic features and 10 AI generations per month.';
    }
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
    final pricing = regionalPricing.values.firstWhere(
      (region) => region['currency'] == currencyCode,
      orElse: () => defaultPricing,
    );

    final symbol = pricing['symbol'] as String;

    if (currencyCode == 'JPY') {
      return '$symbol${price.toInt()}';
    } else {
      return '$symbol${price.toStringAsFixed(2)}';
    }
  }

  /// 商品IDの妥当性をチェック
  static bool isValidProductId(String productId) {
    return allProductIds.contains(productId);
  }

  /// プランが購入可能かどうかをチェック（メイン実装 - Planクラス版）
  static bool isPurchasableFromPlan(Plan plan) {
    return plan.isPaid;
  }

  /// プランが購入可能かどうかをチェック（互換性レイヤー）
  @Deprecated('Use isPurchasableFromPlan() instead')
  static bool isPurchasable(SubscriptionPlan plan) {
    return plan != SubscriptionPlan.basic;
  }

  /// デバッグ情報を出力
  static Map<String, dynamic> getDebugInfo() {
    return {
      'platform': isIOS ? 'iOS' : 'Android',
      'productIds': allProductIds,
      'pricing': defaultPricing,
      'sandboxMode': isSandboxEnvironment,
      'freeTrialDays': freeTrialDays,
      'serverValidation': serverSideValidationEnabled,
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

    // 地域価格検証
    if (InAppPurchaseConfig.regionalPricing.isEmpty) {
      errors.add('No regional pricing configured');
    }

    return errors;
  }

  /// 設定が有効かどうか
  static bool isConfigValid() {
    return validateConfig().isEmpty;
  }
}
