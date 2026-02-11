import '../../models/diary_entry.dart';
import '../../core/result/result.dart';

/// 日記タグ管理サービスのインターフェース
///
/// タグの生成・取得・集計を担当。
/// バックグラウンドタグ生成はonSearchIndexUpdateコールバックで
/// 呼び出し元のインデックスを更新可能。
abstract class IDiaryTagService {
  /// 日記エントリーのタグを取得（キャッシュ優先、なければAI生成）
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry);

  /// 全ての日記からユニークなタグを取得
  Future<Result<Set<String>>> getAllTags();

  /// よく使われるタグを取得（使用頻度順）
  Future<Result<List<String>>> getPopularTags({int limit = 10});

  /// バックグラウンドでタグを生成（今日の日記用）
  void generateTagsInBackground(
    DiaryEntry entry, {
    void Function(String id, String searchableText)? onSearchIndexUpdate,
  });

  /// バックグラウンドでタグを生成（過去の写真日記用）
  void generateTagsInBackgroundForPastPhoto(
    DiaryEntry entry, {
    void Function(String id, String searchableText)? onSearchIndexUpdate,
  });
}
