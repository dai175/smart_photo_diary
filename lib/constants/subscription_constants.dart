import '../utils/locale_format_utils.dart';

/// サブスクリプション関連の定数定義
///
/// 価格、制限値、商品IDなどのサブスクリプション関連の
/// 設定値を一元管理するための定数クラスです。
class SubscriptionConstants {
  // プライベートコンストラクタでインスタンス化を防ぐ
  SubscriptionConstants._();

  // ========================================
  // 価格設定
  // ========================================

  /// Basic プランの年額料金（円）
  static const int basicYearlyPrice = 0;

  /// Premium プランの年額料金（円）
  static const int premiumYearlyPriceJPY = 2800;

  /// Premium プランの月額料金（円）
  static const int premiumMonthlyPriceJPY = 300;

  // USD価格定数は削除（動的価格取得を使用）

  // 後方互換性のため
  static const int premiumYearlyPrice = premiumYearlyPriceJPY;
  static const int premiumMonthlyPrice = premiumMonthlyPriceJPY;

  // ========================================
  // AI生成制限
  // ========================================

  /// Basic プランの月間AI生成制限回数
  static const int basicMonthlyAiLimit = 10;

  /// Premium プランの月間AI生成制限回数
  static const int premiumMonthlyAiLimit = 100;

  /// 日平均生成回数計算用の月日数
  static const double averageMonthDays = 30.0;

  // ========================================
  // 商品ID（In-App Purchase用）
  // ========================================

  /// Premium プラン年額の商品ID
  static const String premiumYearlyProductId =
      'smart_photo_diary_premium_yearly_plan';

  /// Premium プラン月額の商品ID
  static const String premiumMonthlyProductId =
      'smart_photo_diary_premium_monthly_plan';

  // ========================================
  // Hive設定
  // ========================================

  /// サブスクリプション状態管理用のHiveボックス名
  static const String hiveBoxName = 'subscription_box';

  /// サブスクリプション状態のキー
  static const String statusKey = 'subscription_status';

  /// デフォルト通貨設定
  static const String defaultCurrency = 'JPY';

  // ========================================
  // プラン識別子
  // ========================================

  /// Basic プランのID
  static const String basicPlanId = 'basic';

  /// Premium 月額プランのID
  static const String premiumMonthlyPlanId = 'premium_monthly';

  /// Premium 年額プランのID
  static const String premiumYearlyPlanId = 'premium_yearly';

  // ========================================
  // サブスクリプション期間設定
  // ========================================

  /// 年間サブスクリプションの日数
  static const int subscriptionYearDays = 365;

  /// 月間サブスクリプションの日数
  static const int subscriptionMonthDays = 30;

  /// 無料トライアル期間（日数）
  static const int freeTrialDays = 7;

  // ========================================
  // 機能制限設定
  // ========================================

  /// タグの有効期限（日数）
  static const int tagsValidityDays = 7;

  // ========================================
  // UI表示用設定
  // ========================================

  /// 年額割引率の表示用パーセンテージ
  static const int yearlyDiscountPercentage =
      22; // (300*12 - 2800) / (300*12) * 100

  /// デフォルト通貨記号
  static const String defaultCurrencySymbol = '¥';

  /// デフォルト通貨コード
  static const String defaultCurrencyCode = 'JPY';

  // ========================================
  // プラン表示名
  // ========================================

  /// Basic プランの表示名
  static const String basicDisplayName = 'Basic';

  /// Premium プランの表示名
  static const String premiumDisplayName = 'Premium';

  // ========================================
  // プラン説明文
  // ========================================

  /// Basic プランの説明文
  static const String basicDescription = '日記を試してみたい新規ユーザー、軽いユーザー向け';

  /// Premium プランの説明文
  static const String premiumDescription = '日常的に日記を書くユーザー、デジタル手帳として活用したいユーザー向け';

  // ========================================
  // 機能リスト
  // ========================================

  /// Basic プランの機能リスト
  static final List<String> basicFeatures = [
    '月$basicMonthlyAiLimit回までのAI日記生成',
    '写真選択・保存機能（最大3枚）',
    '基本的な検索・フィルタ',
    'ローカルストレージ',
    'ライト・ダークテーマ',
    'データエクスポート（JSON形式）',
  ];

  /// Premium プランの機能リスト
  static final List<String> premiumFeatures = [
    '月$premiumMonthlyAiLimit回までのAI日記生成',
    'ライティングプロンプト機能',
    '高度なフィルタ・検索機能',
    'タグベース検索',
    '日付範囲指定検索',
    '時間帯フィルタ',
    'データエクスポート（複数形式）',
    '優先カスタマーサポート',
    '統計・分析ダッシュボード',
  ];

  // ========================================
  // ヘルパーメソッド
  // ========================================

  /// 日平均生成回数を計算
  static double calculateDailyAverage(int monthlyLimit) {
    return monthlyLimit / averageMonthDays;
  }

  /// 年額割引額を計算
  static int calculateYearlyDiscount() {
    return (premiumMonthlyPrice * 12) - premiumYearlyPrice;
  }

  /// 年額割引率を計算
  static double calculateDiscountPercentage() {
    final yearlyTotal = premiumMonthlyPrice * 12;
    return ((yearlyTotal - premiumYearlyPrice) / yearlyTotal) * 100;
  }

  /// 言語に応じた価格と通貨コードを取得
  /// 注意: このメソッドは後方互換性のために残していますが、
  /// 動的価格取得（DynamicPricingUtils）の使用を推奨します
  static (int price, String currencyCode) getPriceForLocale(
    String planId,
    String locale,
  ) {
    // 動的価格取得システムでは、すべての地域でフォールバック価格として
    // 日本の価格設定を使用し、通貨はJPYを返します
    switch (planId.toLowerCase()) {
      case basicPlanId:
        return (basicYearlyPrice, defaultCurrencyCode);
      case premiumMonthlyPlanId:
        return (premiumMonthlyPriceJPY, defaultCurrencyCode);
      case premiumYearlyPlanId:
        return (premiumYearlyPriceJPY, defaultCurrencyCode);
      default:
        throw ArgumentError('Unknown plan ID: $planId');
    }
  }

  /// 価格を表示用文字列に変換（ロケール対応）
  /// 注意: このメソッドは後方互換性のために残していますが、
  /// 動的価格取得（DynamicPricingUtils）の使用を推奨します
  static String formatPrice(
    int price, {
    String locale = 'ja',
    String? currencyCode,
  }) {
    final currency = currencyCode ?? defaultCurrencyCode;
    final actualPrice = price.toDouble();

    return LocaleFormatUtils.formatCurrency(
      actualPrice,
      locale: locale,
      currencyCode: currency,
    );
  }

  /// プラン用の価格表示文字列を取得
  static String formatPriceForPlan(String planId, String locale) {
    final (price, currencyCode) = getPriceForLocale(planId, locale);
    return formatPrice(price, locale: locale, currencyCode: currencyCode);
  }

  /// プランIDから価格を取得
  static int getPriceByPlanId(String planId) {
    switch (planId.toLowerCase()) {
      case basicPlanId:
        return basicYearlyPrice;
      case premiumMonthlyPlanId:
        return premiumMonthlyPrice;
      case premiumYearlyPlanId:
        return premiumYearlyPrice;
      default:
        throw ArgumentError('Unknown plan ID: $planId');
    }
  }

  /// プランIDから制限回数を取得
  static int getLimitByPlanId(String planId) {
    switch (planId.toLowerCase()) {
      case basicPlanId:
        return basicMonthlyAiLimit;
      case premiumMonthlyPlanId:
      case premiumYearlyPlanId:
        return premiumMonthlyAiLimit;
      default:
        throw ArgumentError('Unknown plan ID: $planId');
    }
  }
}
