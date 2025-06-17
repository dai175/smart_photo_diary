// PromptServiceインターフェース
// 
// ライティングプロンプト管理の抽象化レイヤー
// テスト容易性とモックサポートを提供

import '../../models/writing_prompt.dart';

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
}