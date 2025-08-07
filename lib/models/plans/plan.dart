/// サブスクリプションプランの抽象基底クラス
///
/// Smart Photo Diaryで利用可能なサブスクリプションプランの
/// 共通インターフェースを定義します。
///
/// ## 設計方針
/// - プラン固有のビジネスロジックをカプセル化
/// - 拡張性を考慮した抽象クラス設計
/// - 型安全性を保証しつつ柔軟な実装を可能に
///
/// ## 実装クラス
/// - [BasicPlan]: 無料プラン
/// - [PremiumMonthlyPlan]: Premium月額プラン
/// - [PremiumYearlyPlan]: Premium年額プラン
abstract class Plan {
  /// プランID（内部識別子）
  final String id;

  /// プラン表示名
  final String displayName;

  /// プラン説明文
  final String description;

  /// プラン価格（円）
  final int price;

  /// 月間AI生成制限回数
  final int monthlyAiGenerationLimit;

  /// プラン機能リスト
  final List<String> features;

  /// In-App Purchase商品ID
  final String productId;

  /// コンストラクタ
  const Plan({
    required this.id,
    required this.displayName,
    required this.description,
    required this.price,
    required this.monthlyAiGenerationLimit,
    required this.features,
    required this.productId,
  });

  // ========================================
  // 抽象プロパティ（各プランで実装必須）
  // ========================================

  /// プレミアムプランかどうか
  bool get isPremium;

  /// ライティングプロンプト機能アクセス権
  bool get hasWritingPrompts;

  /// 高度なフィルタ機能アクセス権
  bool get hasAdvancedFilters;

  /// 統計・分析ダッシュボードアクセス権
  bool get hasAdvancedAnalytics;

  /// 優先カスタマーサポートアクセス権
  bool get hasPrioritySupport;

  /// 過去の写真アクセス可能日数
  int get pastPhotoAccessDays;

  // ========================================
  // 共通プロパティ・メソッド
  // ========================================

  /// プランが有料かどうか
  bool get isPaid => price > 0;

  /// プランが無料かどうか
  bool get isFree => price == 0;

  /// 日平均生成回数目安
  double get dailyAverageGenerations => monthlyAiGenerationLimit / 30.0;

  /// 価格を表示用文字列に変換
  String get formattedPrice {
    if (price == 0) {
      return '無料';
    }
    return '¥${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// プランの期間タイプを判定
  bool get isMonthly => id.contains('monthly');

  /// プランの期間タイプを判定
  bool get isYearly => id.contains('yearly');

  /// 年額換算価格を取得（円）
  int get yearlyPrice {
    if (isYearly) {
      return price;
    } else if (isMonthly) {
      return price * 12;
    } else {
      // Basicプランなど
      return 0;
    }
  }

  /// プラン比較用のメソッド
  bool hasMoreFeaturesThan(Plan otherPlan) {
    return monthlyAiGenerationLimit > otherPlan.monthlyAiGenerationLimit;
  }

  /// デバッグ用の文字列表現
  @override
  String toString() {
    return 'Plan(id: $id, displayName: $displayName, price: $formattedPrice, '
        'monthlyLimit: $monthlyAiGenerationLimit, isPremium: $isPremium)';
  }

  /// 等価性の判定（IDベース）
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Plan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
