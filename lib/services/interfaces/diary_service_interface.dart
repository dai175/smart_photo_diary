import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../models/diary_filter.dart';
import '../../models/import_result.dart';
import '../../core/result/result.dart';

/// 日記サービスのインターフェース
abstract class DiaryServiceInterface {
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
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries();

  /// フィルタに基づいて日記エントリーを取得
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(DiaryFilter filter);

  /// 日記エントリーを更新
  Future<Result<DiaryEntry>> updateDiaryEntry(DiaryEntry entry);

  /// 日記エントリーを削除
  Future<Result<void>> deleteDiaryEntry(String id);

  /// エントリーのタグを取得
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry);

  /// すべてのタグを取得
  Future<Result<Set<String>>> getAllTags();

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

  /// 日記を検索
  Future<Result<List<DiaryEntry>>> searchDiaries({
    String? query,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 日記をエクスポート
  Future<Result<String>> exportDiaries({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 日記をインポート
  Future<Result<ImportResult>> importDiaries();
}
