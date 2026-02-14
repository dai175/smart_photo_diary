import '../../models/diary_entry.dart';
import '../../models/diary_filter.dart';
import '../../core/result/result.dart';

/// 日記のクエリ操作を担当するインターフェース
abstract class IDiaryQueryService {
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
}
