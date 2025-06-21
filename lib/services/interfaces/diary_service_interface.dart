import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../models/diary_filter.dart';

/// 日記サービスのインターフェース
abstract class DiaryServiceInterface {
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
}
