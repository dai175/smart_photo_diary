import '../../models/diary_entry.dart';
import '../../core/result/result.dart';

/// 日記タグ管理サービスのインターフェース
///
/// タグの生成・取得・集計を担当。
/// バックグラウンドタグ生成はonSearchIndexUpdateコールバックで
/// 呼び出し元のインデックスを更新可能。
abstract class IDiaryTagService {
  /// 日記エントリーのタグを取得（キャッシュ優先、なければAI生成）
  ///
  /// AI生成が失敗した場合やその他の例外が発生した場合でも、
  /// 時間帯ベースのフォールバックタグを生成してSuccessとして返す。
  /// そのため、このメソッドは常にSuccessを返し、Failureを返すことはない。
  ///
  /// Returns:
  /// - Success: タグ文字列のリスト（AI生成失敗時はフォールバックタグを返す）
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry);

  /// 全ての日記からユニークなタグを取得
  ///
  /// Returns:
  /// - Success: 全日記で使用されているユニークなタグのセット
  /// - Failure: [ServiceException] 日記データの読み込みに失敗した場合
  Future<Result<Set<String>>> getAllTags();

  /// よく使われるタグを取得（使用頻度順）
  ///
  /// [limit] 取得件数の上限（デフォルト: 10件）
  ///
  /// Returns:
  /// - Success: 使用頻度の高い順に並んだタグリスト
  /// - Failure: [ServiceException] 日記データの読み込みに失敗した場合
  Future<Result<List<String>>> getPopularTags({int limit = 10});

  /// バックグラウンドでタグを生成（今日の日記用）
  ///
  /// Fire-and-forgetで非同期実行される。エラーはログに記録され、例外はスローされない。
  /// [onSearchIndexUpdate] タグ生成完了後に検索インデックスを更新するためのコールバック
  void generateTagsInBackground(
    DiaryEntry entry, {
    void Function(String id, String searchableText)? onSearchIndexUpdate,
  });

  /// バックグラウンドでタグを生成（過去の写真日記用）
  ///
  /// Fire-and-forgetで非同期実行される。エラーはログに記録され、例外はスローされない。
  /// [onSearchIndexUpdate] タグ生成完了後に検索インデックスを更新するためのコールバック
  void generateTagsInBackgroundForPastPhoto(
    DiaryEntry entry, {
    void Function(String id, String searchableText)? onSearchIndexUpdate,
  });
}
