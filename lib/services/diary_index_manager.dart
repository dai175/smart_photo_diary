import 'package:hive/hive.dart';
import '../models/diary_entry.dart';

/// 日記エントリーのインメモリインデックス管理
///
/// 日付降順インデックス、二分探索、テキスト検索インデックスを管理する。
class DiaryIndexManager {
  // 日付降順のインメモリインデックス（エントリーIDの配列）
  List<String> sortedIdsByDateDesc = [];
  bool indexBuilt = false;

  // 検索用インデックス（id -> 検索対象文字列（小文字化済み））
  final Map<String, String> searchTextIndex = {};
  // 日付（年月日）だけを保持した並行配列（sortedIdsByDateDesc と同じ順）
  final List<DateTime> sortedDatesByDayDesc = [];

  /// インデックス構築（起動時/再初期化時）
  Future<void> buildIndex(Box<DiaryEntry> diaryBox) async {
    final entries = diaryBox.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    sortedIdsByDateDesc = entries.map((e) => e.id).toList(growable: true);
    sortedDatesByDayDesc
      ..clear()
      ..addAll(
        entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)),
      );
    // 検索インデックス
    searchTextIndex.clear();
    for (final e in entries) {
      searchTextIndex[e.id] = buildSearchableText(e);
    }
    indexBuilt = true;
  }

  /// インデックスが未構築なら構築する
  Future<void> ensureIndex(Box<DiaryEntry> diaryBox) async {
    if (!indexBuilt) {
      await buildIndex(diaryBox);
    }
  }

  /// 挿入位置を二分探索で見つける（降順リスト）
  int findInsertIndex(Box<DiaryEntry> diaryBox, DateTime date) {
    int low = 0;
    int high = sortedIdsByDateDesc.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      final midId = sortedIdsByDateDesc[mid];
      final midEntry = diaryBox.get(midId);
      if (midEntry == null) {
        high = mid;
        continue;
      }
      if (date.isAfter(midEntry.date)) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }

  /// 日付範囲に一致するインデックス範囲を二分探索で求める（降順リスト）
  /// 戻り値は [startIndex, endExclusive]
  List<int> findRangeByDateRange(DateTime startDay, DateTime endDay) {
    final n = sortedDatesByDayDesc.length;
    if (n == 0) return const [0, 0];

    // end側（新しい方）の左端: 最初に date <= endDay となる位置
    int low = 0, high = n;
    while (low < high) {
      final mid = (low + high) >> 1;
      final d = sortedDatesByDayDesc[mid];
      if (d.isAfter(endDay)) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    final startIndex = low.clamp(0, n);

    // start側（古い方）の右端の次: 最初に date < startDay となる位置
    low = startIndex;
    high = n;
    while (low < high) {
      final mid = (low + high) >> 1;
      final d = sortedDatesByDayDesc[mid];
      if (d.isBefore(startDay)) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    final endExclusive = low.clamp(startIndex, n);
    return [startIndex, endExclusive];
  }

  /// 検索用テキストを作成
  String buildSearchableText(DiaryEntry entry) {
    final tags = entry.effectiveTags.join(' ');
    final location = entry.location ?? '';
    final text = '${entry.title} ${entry.content} $tags $location';
    return text.toLowerCase();
  }

  /// 検索インデックスを更新するコールバック（タグサービスから呼ばれる）
  void updateSearchIndex(String id, String searchableText) {
    searchTextIndex[id] = searchableText;
  }

  /// エントリーをインデックスに挿入
  void insertEntry(Box<DiaryEntry> diaryBox, DiaryEntry entry) {
    final insertAt = findInsertIndex(diaryBox, entry.date);
    sortedIdsByDateDesc.insert(insertAt, entry.id);
    sortedDatesByDayDesc.insert(
      insertAt,
      DateTime(entry.date.year, entry.date.month, entry.date.day),
    );
    searchTextIndex[entry.id] = buildSearchableText(entry);
  }

  /// エントリーの日付変更時にインデックスを更新
  void updateEntryDate(Box<DiaryEntry> diaryBox, DiaryEntry entry) {
    final oldIdx = sortedIdsByDateDesc.indexOf(entry.id);
    if (oldIdx != -1) {
      if (sortedIdsByDateDesc.length > oldIdx) {
        sortedIdsByDateDesc.removeAt(oldIdx);
      }
      if (sortedDatesByDayDesc.length > oldIdx) {
        sortedDatesByDayDesc.removeAt(oldIdx);
      }
    }
    final insertAt = findInsertIndex(diaryBox, entry.date);
    sortedIdsByDateDesc.insert(insertAt, entry.id);
    sortedDatesByDayDesc.insert(
      insertAt,
      DateTime(entry.date.year, entry.date.month, entry.date.day),
    );
  }

  /// エントリーの検索インデックスを更新
  void updateEntrySearchText(DiaryEntry entry) {
    searchTextIndex[entry.id] = buildSearchableText(entry);
  }

  /// エントリーをインデックスから削除
  void removeEntry(String id) {
    final idx = sortedIdsByDateDesc.indexOf(id);
    if (idx != -1) {
      if (sortedIdsByDateDesc.length > idx) {
        sortedIdsByDateDesc.removeAt(idx);
      }
      if (sortedDatesByDayDesc.length > idx) {
        sortedDatesByDayDesc.removeAt(idx);
      }
    }
    searchTextIndex.remove(id);
  }
}
