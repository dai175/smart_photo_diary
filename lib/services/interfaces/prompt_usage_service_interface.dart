// PromptUsageServiceインターフェース
//
// プロンプト使用履歴管理の抽象化レイヤー

import '../../models/writing_prompt.dart';

/// プロンプト使用履歴管理サービスのインターフェース
///
/// 使用履歴の記録、取得、クリア、統計機能を定義
abstract class IPromptUsageService {
  /// 使用履歴機能が利用可能かどうか
  ///
  /// 戻り値: 初期化済みでBoxが開いている場合true、それ以外はfalse。
  bool get isAvailable;

  /// 使用履歴Boxを初期化
  ///
  /// Hiveの使用履歴用Boxを開く。既に初期化済みの場合は何もしない。
  Future<void> initialize();

  /// プロンプト使用履歴を記録
  ///
  /// [promptId] 使用したプロンプトID
  /// [diaryEntryId] 関連する日記エントリID（省略可）
  /// [wasHelpful] プロンプトが役に立ったかどうか
  /// 戻り値: 記録成功の場合true。エラー時はfalse。
  Future<bool> recordPromptUsage({
    required String promptId,
    String? diaryEntryId,
    bool wasHelpful = true,
  });

  /// プロンプト使用履歴を取得
  ///
  /// [limit] 取得件数制限（省略時は全件）
  /// [promptId] 特定プロンプトの履歴のみ取得（省略可）
  /// 戻り値: 使用履歴リスト（新しい順）。エラー時は空リスト。
  List<PromptUsageHistory> getUsageHistory({int? limit, String? promptId});

  /// 最近使用したプロンプトIDリストを取得（重複回避用）
  ///
  /// [days] 過去何日分を対象とするか（デフォルト: 7日）
  /// [limit] 最大取得件数（デフォルト: 10件）
  /// 戻り値: 最近使用したプロンプトIDリスト。エラー時は空リスト。
  List<String> getRecentlyUsedPromptIds({int days = 7, int limit = 10});

  /// 使用履歴をクリア
  ///
  /// [olderThanDays] 指定日数より古い履歴のみ削除（省略時は全削除）
  /// 戻り値: クリア成功の場合true。エラー時はfalse。
  Future<bool> clearUsageHistory({int? olderThanDays});

  /// プロンプト使用頻度統計を取得
  ///
  /// [days] 集計対象期間（デフォルト: 30日）
  /// 戻り値: プロンプトID別使用回数マップ。エラー時は空マップ。
  Map<String, int> getUsageFrequencyStats({int days = 30});

  /// リセット（初期化前の状態に戻す）
  ///
  /// Boxを閉じて内部状態をクリアする。再利用にはinitializeの再呼び出しが必要。
  void reset();
}
