import '../constants/subscription_constants.dart';

/// サブスクリプションプラン定義
///
/// Smart Photo Diaryで利用可能なサブスクリプションプランを定義します。
/// このenumは価格、機能制限、機能フラグを管理します。
enum SubscriptionPlan {
  /// Basic プラン（無料）
  /// - 基本機能のみ
  /// - 制限値はSubscriptionConstantsで管理
  basic,
  
  /// Premium 月額プラン（有料）
  /// - ライティングプロンプト機能
  /// - 高度なフィルタ・検索機能
  /// - 制限値はSubscriptionConstantsで管理
  premiumMonthly,
  
  /// Premium 年額プラン（有料・お得）
  /// - ライティングプロンプト機能
  /// - 高度なフィルタ・検索機能
  /// - 年額割引（22%OFF）
  /// - 制限値はSubscriptionConstantsで管理
  premiumYearly;

  /// プランID（文字列識別子）
  String get id {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicPlanId;
      case SubscriptionPlan.premiumMonthly:
        return SubscriptionConstants.premiumMonthlyPlanId;
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumYearlyPlanId;
    }
  }

  /// プラン表示名
  String get displayName {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicDisplayName;
      case SubscriptionPlan.premiumMonthly:
        return '${SubscriptionConstants.premiumDisplayName} (月額)';
      case SubscriptionPlan.premiumYearly:
        return '${SubscriptionConstants.premiumDisplayName} (年額)';
    }
  }

  /// プラン価格（円）
  int get price {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicYearlyPrice;
      case SubscriptionPlan.premiumMonthly:
        return SubscriptionConstants.premiumMonthlyPrice;
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumYearlyPrice;
    }
  }

  /// プラン価格（年額換算、円）
  int get yearlyPrice {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicYearlyPrice;
      case SubscriptionPlan.premiumMonthly:
        return SubscriptionConstants.premiumMonthlyPrice * 12;
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumYearlyPrice;
    }
  }

  /// 月額AI生成制限回数
  int get monthlyAiGenerationLimit {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicMonthlyAiLimit;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumMonthlyAiLimit;
    }
  }

  /// ライティングプロンプト機能アクセス権
  bool get hasWritingPrompts {
    switch (this) {
      case SubscriptionPlan.basic:
        return false;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return true;
    }
  }

  /// 高度なフィルタ機能アクセス権
  bool get hasAdvancedFilters {
    switch (this) {
      case SubscriptionPlan.basic:
        return false;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return true;
    }
  }

  /// 統計・分析ダッシュボードアクセス権
  bool get hasAdvancedAnalytics {
    switch (this) {
      case SubscriptionPlan.basic:
        return false;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return true;
    }
  }

  /// 優先カスタマーサポートアクセス権
  bool get hasPrioritySupport {
    switch (this) {
      case SubscriptionPlan.basic:
        return false;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return true;
    }
  }

  /// プラン機能リスト
  List<String> get features {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicFeatures;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumFeatures;
    }
  }

  /// プランIDから対応するSubscriptionPlanを取得
  static SubscriptionPlan fromId(String planId) {
    switch (planId.toLowerCase()) {
      case SubscriptionConstants.basicPlanId:
        return SubscriptionPlan.basic;
      case SubscriptionConstants.premiumMonthlyPlanId:
        return SubscriptionPlan.premiumMonthly;
      case SubscriptionConstants.premiumYearlyPlanId:
        return SubscriptionPlan.premiumYearly;
      default:
        throw ArgumentError('Unknown plan ID: $planId');
    }
  }

  /// プランIDを取得
  String get planId {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicPlanId;
      case SubscriptionPlan.premiumMonthly:
        return SubscriptionConstants.premiumMonthlyPlanId;
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumYearlyPlanId;
    }
  }

  /// In-App Purchase商品IDを取得
  String get productId {
    switch (this) {
      case SubscriptionPlan.basic:
        return ''; // 無料プランは商品IDなし
      case SubscriptionPlan.premiumMonthly:
        return SubscriptionConstants.premiumMonthlyProductId;
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumYearlyProductId;
    }
  }

  /// プランが有料かどうか
  bool get isPaid {
    return price > 0;
  }

  /// プランが無料かどうか
  bool get isFree {
    return price == 0;
  }

  /// 日平均生成回数目安
  double get dailyAverageGenerations {
    return SubscriptionConstants.calculateDailyAverage(monthlyAiGenerationLimit);
  }

  /// プラン説明文
  String get description {
    switch (this) {
      case SubscriptionPlan.basic:
        return SubscriptionConstants.basicDescription;
      case SubscriptionPlan.premiumMonthly:
      case SubscriptionPlan.premiumYearly:
        return SubscriptionConstants.premiumDescription;
    }
  }

  /// プランの期間タイプ
  bool get isMonthly {
    return this == SubscriptionPlan.premiumMonthly;
  }

  /// プランの期間タイプ
  bool get isYearly {
    return this == SubscriptionPlan.premiumYearly;
  }

  /// プレミアムプランかどうか
  bool get isPremium {
    return this == SubscriptionPlan.premiumMonthly || this == SubscriptionPlan.premiumYearly;
  }
}