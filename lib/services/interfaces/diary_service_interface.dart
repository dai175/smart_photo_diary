import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../models/diary_change.dart';
import '../../models/diary_filter.dart';
import '../../core/result/result.dart';

/// 日記サービスのインターフェース
abstract class IDiaryService {
  /// 日記の変更ストリーム（作成/更新/削除）。broadcast。
  Stream<DiaryChange> get changes;

  /// 日記エントリーを保存
  Future<DiaryEntry> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 指定されたIDの日記エントリーを取得
  Future<DiaryEntry?> getDiaryEntry(String id);

  /// すべての日記エントリーを取得（日付順）
  Future<List<DiaryEntry>> getSortedDiaryEntries();

  /// フィルタに基づいて日記エントリーを取得
  Future<List<DiaryEntry>> getFilteredDiaryEntries(DiaryFilter filter);

  /// 日記エントリーを更新
  Future<void> updateDiaryEntry(DiaryEntry entry);

  /// 日記エントリーを削除
  Future<void> deleteDiaryEntry(String id);

  /// エントリーのタグを取得
  Future<List<String>> getTagsForEntry(DiaryEntry entry);

  /// すべてのタグを取得
  Future<Set<String>> getAllTags();

  /// 人気のタグを取得
  Future<List<String>> getPopularTags({int limit = 10});

  /// 日記の総数を取得
  Future<int> getTotalDiaryCount();

  /// 指定期間の日記数を取得
  Future<int> getDiaryCountInPeriod(DateTime start, DateTime end);

  /// 写真付きで日記エントリーを保存（後方互換性）
  Future<DiaryEntry> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  });

  /// 過去の写真から日記エントリーを作成
  Future<DiaryEntry> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 写真の撮影日付で日記を検索
  Future<List<DiaryEntry>> getDiaryByPhotoDate(DateTime photoDate);

  // ========================================
  // Result<T>パターン版のメソッド（新規追加）
  // ========================================

  /// 日記エントリーを保存（Result版）
  Future<Result<DiaryEntry>> saveDiaryEntryResult({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 指定されたIDの日記エントリーを取得（Result版）
  Future<Result<DiaryEntry?>> getDiaryEntryResult(String id);

  /// すべての日記エントリーを取得（Result版）
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntriesResult({
    bool descending = true,
  });

  /// フィルタに基づいて日記エントリーを取得（Result版）
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesResult(
    DiaryFilter filter,
  );

  /// 日記エントリーを更新（Result版）
  Future<Result<void>> updateDiaryEntryResult(DiaryEntry entry);

  /// 日記エントリーを削除（Result版）
  Future<Result<void>> deleteDiaryEntryResult(String id);

  /// エントリーのタグを取得（Result版）
  Future<Result<List<String>>> getTagsForEntryResult(DiaryEntry entry);

  /// すべてのタグを取得（Result版）
  Future<Result<Set<String>>> getAllTagsResult();

  /// 日記の総数を取得（Result版）
  Future<Result<int>> getTotalDiaryCountResult();

  /// 指定期間の日記数を取得（Result版）
  Future<Result<int>> getDiaryCountInPeriodResult(DateTime start, DateTime end);

  /// 写真付きで日記エントリーを保存（Result版）
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotosResult({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  });

  /// 過去の写真から日記エントリーを作成（Result版）
  Future<Result<DiaryEntry>> createDiaryForPastPhotoResult({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 写真の撮影日付で日記を検索（Result版）
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDateResult(
    DateTime photoDate,
  );

  /// 写真IDから日記エントリーを取得
  Future<DiaryEntry?> getDiaryEntryByPhotoId(String photoId);

  /// 写真IDから日記エントリーを取得（Result版）
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoIdResult(String photoId);

  /// データベースの最適化（断片化を解消）
  Future<void> compactDatabase();
}
