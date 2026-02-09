import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../models/diary_change.dart';
import '../../models/diary_filter.dart';
import '../../core/result/result.dart';

/// 日記サービスのインターフェース
///
/// 全メソッドが Result<T> パターンで統一されています。
abstract class IDiaryService {
  /// 日記の変更ストリーム（作成/更新/削除）。broadcast。
  Stream<DiaryChange> get changes;

  /// 日記エントリーを保存
  Future<Result<DiaryEntry>> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 指定されたIDの日記エントリーを取得
  Future<Result<DiaryEntry?>> getDiaryEntry(String id);

  /// すべての日記エントリーを取得（日付順）
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries({
    bool descending = true,
  });

  /// フィルタに基づいて日記エントリーを取得
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(DiaryFilter filter);

  /// フィルタ + ページングで日記エントリーを取得
  /// offset は0始まり、limit は取得最大件数。
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesPage(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  });

  /// 日記エントリーを更新
  Future<Result<void>> updateDiaryEntry(DiaryEntry entry);

  /// 日記エントリーを削除
  Future<Result<void>> deleteDiaryEntry(String id);

  /// エントリーのタグを取得
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry);

  /// すべてのタグを取得
  Future<Result<Set<String>>> getAllTags();

  /// 人気のタグを取得
  Future<Result<List<String>>> getPopularTags({int limit = 10});

  /// 日記の総数を取得
  Future<Result<int>> getTotalDiaryCount();

  /// 指定期間の日記数を取得
  Future<Result<int>> getDiaryCountInPeriod(DateTime start, DateTime end);

  /// 写真付きで日記エントリーを保存（後方互換性）
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  });

  /// 過去の写真から日記エントリーを作成
  Future<Result<DiaryEntry>> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 写真の撮影日付で日記を検索
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDate(DateTime photoDate);

  /// 写真IDから日記エントリーを取得
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoId(String photoId);

  /// データベースの最適化（断片化を解消）
  Future<void> compactDatabase();
}
