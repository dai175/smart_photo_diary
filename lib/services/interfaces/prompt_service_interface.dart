// PromptServiceインターフェース
// 
// ライティングプロンプト管理の抽象化レイヤー
// テスト容易性とモックサポートを提供

import '../../models/writing_prompt.dart';
import '../analytics/prompt_usage_analytics.dart';
import '../analytics/category_popularity_reporter.dart';
import '../analytics/user_behavior_analyzer.dart';
import '../analytics/improvement_suggestion_tracker.dart';

/// PromptServiceの抽象インターフェース
/// 
/// ライティングプロンプトの読み込み、フィルタリング、
/// 検索機能を定義します。
abstract class IPromptService {
  /// サービスが初期化済みかどうか
  bool get isInitialized;
  
  /// 全プロンプトを取得
  /// 
  /// 戻り値: 全プロンプトのリスト
  List<WritingPrompt> getAllPrompts();
  
  /// プラン別にフィルタリングしたプロンプトを取得
  /// 
  /// [isPremium] Premiumプランかどうか
  /// 戻り値: プラン別にフィルタリングされたプロンプト
  List<WritingPrompt> getPromptsForPlan({required bool isPremium});
  
  /// カテゴリ別プロンプトを取得
  /// 
  /// [category] 対象カテゴリ
  /// [isPremium] Premiumプランかどうか（アクセス制御用）
  /// 戻り値: カテゴリ別プロンプトリスト
  List<WritingPrompt> getPromptsByCategory(
    PromptCategory category, {
    required bool isPremium,
  });
  
  /// ランダムプロンプトを取得
  /// 
  /// [isPremium] Premiumプランかどうか
  /// [category] 特定カテゴリから選択（省略可）
  /// [excludeIds] 除外するプロンプトIDリスト（重複回避用）
  /// 戻り値: ランダム選択されたプロンプト（なければnull）
  WritingPrompt? getRandomPrompt({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
  });
  
  /// プロンプトを検索
  /// 
  /// [query] 検索クエリ（テキスト、タグ、説明を対象）
  /// [isPremium] Premiumプランかどうか
  /// 戻り値: 検索にマッチしたプロンプトリスト
  List<WritingPrompt> searchPrompts(
    String query, {
    required bool isPremium,
  });
  
  /// 特定のプロンプトをIDで取得
  /// 
  /// [id] プロンプトID
  /// 戻り値: 該当するプロンプト（なければnull）
  WritingPrompt? getPromptById(String id);
  
  /// プロンプトの統計情報を取得
  /// 
  /// [isPremium] Premiumプランかどうか
  /// 戻り値: カテゴリ別統計マップ
  Map<PromptCategory, int> getPromptStatistics({required bool isPremium});
  
  /// サービスを初期化
  /// 
  /// JSON読み込みとキャッシュ生成を実行
  /// 戻り値: 初期化成功の可否
  Future<bool> initialize();
  
  /// キャッシュをクリア
  /// 
  /// メモリ使用量削減やテスト時のクリーンアップ用
  void clearCache();
  
  /// サービスをリセット
  /// 
  /// 初期化状態に戻し、再初期化を可能にする
  void reset();
  
  /// 重複回避を考慮したランダムプロンプトシーケンスを取得
  /// 
  /// [count] 取得する数量
  /// [isPremium] Premiumプランかどうか
  /// [category] 特定カテゴリから選択（省略可）
  /// 戻り値: 重複しないランダムプロンプトリスト
  List<WritingPrompt> getRandomPromptSequence({
    required int count,
    required bool isPremium,
    PromptCategory? category,
  });
  
  /// プロンプト使用履歴を記録
  /// 
  /// [promptId] 使用したプロンプトID
  /// [diaryEntryId] 関連する日記エントリID（省略可）
  /// [wasHelpful] プロンプトが役に立ったかどうか
  /// 戻り値: 記録成功の可否
  Future<bool> recordPromptUsage({
    required String promptId,
    String? diaryEntryId,
    bool wasHelpful = true,
  });
  
  /// プロンプト使用履歴を取得
  /// 
  /// [limit] 取得件数制限（省略時は全件）
  /// [promptId] 特定プロンプトの履歴のみ取得（省略可）
  /// 戻り値: 使用履歴リスト（新しい順）
  List<PromptUsageHistory> getUsageHistory({
    int? limit,
    String? promptId,
  });
  
  /// 最近使用したプロンプトIDリストを取得（重複回避用）
  /// 
  /// [days] 過去何日分を対象とするか（デフォルト: 7日）
  /// [limit] 最大取得件数（デフォルト: 10件）
  /// 戻り値: 最近使用したプロンプトIDリスト
  List<String> getRecentlyUsedPromptIds({
    int days = 7,
    int limit = 10,
  });
  
  /// 使用履歴をクリア
  /// 
  /// [olderThanDays] 指定日数より古い履歴のみ削除（省略時は全削除）
  /// 戻り値: クリア成功の可否
  Future<bool> clearUsageHistory({int? olderThanDays});
  
  /// プロンプト使用頻度統計を取得
  /// 
  /// [days] 集計対象期間（デフォルト: 30日）
  /// 戻り値: プロンプトID別使用回数マップ
  Map<String, int> getUsageFrequencyStats({int days = 30});
  
  /// プロンプト使用頻度分析を実行
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// 戻り値: 使用頻度分析結果
  PromptFrequencyAnalysis analyzePromptFrequency({int days = 30});
  
  /// カテゴリ別人気度分析を実行
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// [isPremium] プラン別分析（デフォルト: false）
  /// [comparePreviousPeriod] 前期間比較（デフォルト: true）
  /// 戻り値: カテゴリ別人気度分析結果
  CategoryPopularityAnalysis analyzeCategoryPopularity({
    int days = 30,
    bool isPremium = false,
    bool comparePreviousPeriod = true,
  });
  
  /// ユーザー行動分析を実行
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// 戻り値: ユーザー行動分析結果
  UserBehaviorAnalysis analyzeUserBehavior({int days = 30});
  
  /// 改善提案を生成
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// [isPremium] プラン別分析（デフォルト: false）
  /// 戻り値: 改善提案リスト
  List<PromptImprovementSuggestion> generateImprovementSuggestions({
    int days = 30,
    bool isPremium = false,
  });
  
  /// カテゴリ人気度レポートを生成
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// [isPremium] プラン別分析（デフォルト: false）
  /// 戻り値: 詳細レポート
  CategoryPopularityReport generateCategoryReport({
    int days = 30,
    bool isPremium = false,
  });
  
  /// カテゴリ使用状況の簡易サマリーを取得
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// [isPremium] プラン別分析（デフォルト: false）
  /// 戻り値: サマリーテキスト
  String getCategoryUsageSummary({
    int days = 30,
    bool isPremium = false,
  });
  
  /// カテゴリランキングを取得
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// [isPremium] プラン別分析（デフォルト: false）
  /// [topN] 上位何位まで取得するか（デフォルト: 5）
  /// 戻り値: ランキングリスト
  List<CategoryRankingItem> getCategoryRanking({
    int days = 30,
    bool isPremium = false,
    int topN = 5,
  });
  
  /// 詳細ユーザー行動分析を実行
  /// 
  /// [days] 分析対象期間（デフォルト: 30日）
  /// [isPremium] プラン別分析（デフォルト: false）
  /// 戻り値: 詳細行動分析結果
  DetailedBehaviorAnalysis analyzeDetailedUserBehavior({
    int days = 30,
    bool isPremium = false,
  });
  
  /// 改善提案実装記録を保存
  /// 
  /// [record] 実装記録
  /// 戻り値: 保存成功の可否
  Future<bool> saveSuggestionImplementation(SuggestionImplementationRecord record);
  
  /// 改善提案実装記録を取得
  /// 
  /// [limit] 取得件数制限（省略時は全件）
  /// [suggestionType] 特定提案タイプの記録のみ取得（省略可）
  /// 戻り値: 実装記録リスト
  List<SuggestionImplementationRecord> getSuggestionImplementations({
    int? limit,
    PersonalizationType? suggestionType,
  });
  
  /// 提案効果分析を実行
  /// 
  /// [days] 分析対象期間（デフォルト: 90日）
  /// 戻り値: 提案効果分析結果
  SuggestionEffectivenessAnalysis analyzeSuggestionEffectiveness({int days = 90});
  
  /// ユーザーフィードバック分析を実行
  /// 
  /// [days] 分析対象期間（デフォルト: 90日）
  /// 戻り値: フィードバック分析結果
  UserFeedbackAnalysis analyzeUserFeedback({int days = 90});
  
  /// 継続的改善データを生成
  /// 
  /// [days] 分析対象期間（デフォルト: 90日）
  /// 戻り値: 継続的改善データ
  ContinuousImprovementData generateContinuousImprovementData({int days = 90});
}