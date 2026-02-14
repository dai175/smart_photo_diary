import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../models/diary_change.dart';
import '../../models/diary_filter.dart';
import '../../core/result/result.dart';

/// 日記サービスのインターフェース
///
/// compactDatabase を除く全メソッドが Result<T> パターンで統一されています。
abstract class IDiaryService {
  /// 日記の変更ストリーム（作成/更新/削除）。broadcast。
  Stream<DiaryChange> get changes;

  /// 日記エントリーを保存
  ///
  /// Returns:
  /// - Success: 保存された [DiaryEntry]（IDが自動生成される）
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<DiaryEntry>> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 指定されたIDの日記エントリーを取得
  ///
  /// Returns:
  /// - Success: 該当する [DiaryEntry]。IDが存在しない場合は null
  /// - Failure: [ServiceException] データベース読み取り失敗時
  Future<Result<DiaryEntry?>> getDiaryEntry(String id);

  /// すべての日記エントリーを取得（日付順）
  ///
  /// [descending] true の場合は新しい順、false の場合は古い順
  ///
  /// Returns:
  /// - Success: 日付順にソートされた [DiaryEntry] リスト
  /// - Failure: [ServiceException] データベース読み取り失敗時
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries({
    bool descending = true,
  });

  /// フィルタに基づいて日記エントリーを取得
  ///
  /// Returns:
  /// - Success: フィルタ条件に合致する [DiaryEntry] リスト
  /// - Failure: [ServiceException] データベース読み取り・フィルタ処理失敗時
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(DiaryFilter filter);

  /// フィルタ + ページングで日記エントリーを取得
  ///
  /// [offset] は0始まり、[limit] は取得最大件数。
  ///
  /// Returns:
  /// - Success: ページング済みの [DiaryEntry] リスト
  /// - Failure: [ServiceException] データベース読み取り・フィルタ処理失敗時
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesPage(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  });

  /// 日記エントリーを更新
  ///
  /// Returns:
  /// - Success: void（更新完了）
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<void>> updateDiaryEntry(DiaryEntry entry);

  /// 日記エントリーを削除
  ///
  /// Returns:
  /// - Success: void（削除完了）
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<void>> deleteDiaryEntry(String id);

  /// エントリーのタグを取得
  ///
  /// キャッシュ済みタグを優先し、なければAI生成を試みる。
  /// AI生成失敗時はフォールバックタグ（時間帯ベース）を返す。
  ///
  /// Returns:
  /// - Success: タグ文字列リスト（常にSuccessを返す）
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry);

  /// すべてのタグを取得
  ///
  /// Returns:
  /// - Success: 全エントリーのタグの集合
  /// - Failure: [ServiceException] タグ一覧の取得失敗時
  Future<Result<Set<String>>> getAllTags();

  /// 人気のタグを取得
  ///
  /// Returns:
  /// - Success: 使用頻度順のタグリスト（最大 [limit] 件）
  /// - Failure: [ServiceException] タグ集計の取得失敗時
  Future<Result<List<String>>> getPopularTags({int limit = 10});

  /// 日記の総数を取得
  ///
  /// Returns:
  /// - Success: 日記エントリーの総数
  /// - Failure: [ServiceException] カウント取得失敗時
  Future<Result<int>> getTotalDiaryCount();

  /// 指定期間の日記数を取得
  ///
  /// Returns:
  /// - Success: [start]〜[end] 期間の日記数
  /// - Failure: [ServiceException] カウント取得失敗時
  Future<Result<int>> getDiaryCountInPeriod(DateTime start, DateTime end);

  /// 写真付きで日記エントリーを保存（後方互換性）
  ///
  /// Returns:
  /// - Success: 保存された [DiaryEntry]
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  });

  /// 過去の写真から日記エントリーを作成
  ///
  /// Returns:
  /// - Success: 作成された [DiaryEntry]
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<DiaryEntry>> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 写真の撮影日付で日記を検索
  ///
  /// Returns:
  /// - Success: 該当日の [DiaryEntry] リスト
  /// - Failure: [ServiceException] 検索失敗時
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDate(DateTime photoDate);

  /// 写真IDから日記エントリーを取得
  ///
  /// Returns:
  /// - Success: 該当する [DiaryEntry]。見つからない場合は null
  /// - Failure: [ServiceException] 検索失敗時
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoId(String photoId);

  /// データベースの最適化（断片化を解消）
  Future<void> compactDatabase();

  /// リソースを解放する
  void dispose();
}
