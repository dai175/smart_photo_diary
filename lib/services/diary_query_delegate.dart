import 'package:hive/hive.dart';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import 'interfaces/logging_service_interface.dart';
import 'diary_index_manager.dart';

/// 日記のクエリ操作を担当する内部委譲クラス
class DiaryQueryDelegate {
  final Box<DiaryEntry> Function() _getBox;
  final Future<void> Function() _ensureInitialized;
  final DiaryIndexManager _indexManager;
  final ILoggingService _loggingService;

  DiaryQueryDelegate({
    required Box<DiaryEntry> Function() getBox,
    required Future<void> Function() ensureInitialized,
    required DiaryIndexManager indexManager,
    required ILoggingService loggingService,
  }) : _getBox = getBox,
       _ensureInitialized = ensureInitialized,
       _indexManager = indexManager,
       _loggingService = loggingService;

  /// 日付でソートされた日記エントリーを取得
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries({
    bool descending = true,
  }) async {
    try {
      await _ensureInitialized();
      final entries = _getBox().values.toList();
      entries.sort(
        (a, b) =>
            descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
      );
      return Success(entries);
    } catch (e) {
      _loggingService.error('Diary list retrieval error', error: e);
      return Failure(
        ServiceException('Failed to retrieve diary list', originalError: e),
      );
    }
  }

  /// IDで日記エントリーを取得
  Future<Result<DiaryEntry?>> getDiaryEntry(String id) async {
    try {
      await _ensureInitialized();
      return Success(_getBox().get(id));
    } catch (e) {
      _loggingService.error('Diary retrieval error', error: e);
      return Failure(
        ServiceException('Failed to retrieve diary', originalError: e),
      );
    }
  }

  /// フィルタを適用して日記エントリーを取得
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(
    DiaryFilter filter,
  ) async {
    try {
      final box = _getBox();
      await _indexManager.ensureIndex(box);
      final result = <DiaryEntry>[];
      if (!filter.isActive) {
        for (final id in _indexManager.sortedIdsByDateDesc) {
          final e = box.get(id);
          if (e != null) result.add(e);
        }
        return Success(result);
      }
      // 日付範囲があれば二分探索で範囲を絞る
      Iterable<String> idIterable = _indexManager.sortedIdsByDateDesc;
      if (filter.dateRange != null) {
        final r = filter.dateRange!;
        final s = DateTime(r.start.year, r.start.month, r.start.day);
        final e = DateTime(r.end.year, r.end.month, r.end.day);
        final range = _indexManager.findRangeByDateRange(s, e);
        idIterable = _indexManager.sortedIdsByDateDesc.sublist(
          range[0],
          range[1],
        );
      }
      // 検索語があれば検索インデックスで候補を絞り込み
      final q = (filter.searchText ?? '').trim().toLowerCase();
      if (q.isNotEmpty) {
        idIterable = idIterable.where((id) {
          final text = _indexManager.searchTextIndex[id];
          return text != null && text.contains(q);
        });
      }
      for (final id in idIterable) {
        final e = box.get(id);
        if (e != null && filter.matches(e)) {
          result.add(e);
        }
      }
      return Success(result);
    } catch (e) {
      _loggingService.error('Filtered retrieval error', error: e);
      return Failure(
        ServiceException(
          'Failed to retrieve filtered diaries',
          originalError: e,
        ),
      );
    }
  }

  /// フィルタ + ページングで日記エントリーを取得
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesPage(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    try {
      final box = _getBox();
      await _indexManager.ensureIndex(box);
      if (!filter.isActive) {
        final total = _indexManager.sortedIdsByDateDesc.length;
        if (total == 0) return const Success([]);
        final start = offset.clamp(0, total);
        final end = (offset + limit).clamp(0, total);
        if (start >= end) return const Success([]);
        final ids = _indexManager.sortedIdsByDateDesc.sublist(start, end);
        final entries = <DiaryEntry>[];
        for (final id in ids) {
          final e = box.get(id);
          if (e != null) entries.add(e);
        }
        return Success(entries);
      }

      final page = <DiaryEntry>[];
      int skipped = 0;

      // 日付範囲があれば先に範囲を絞る
      Iterable<String> idIterable = _indexManager.sortedIdsByDateDesc;
      if (filter.dateRange != null) {
        final r = filter.dateRange!;
        final s = DateTime(r.start.year, r.start.month, r.start.day);
        final e = DateTime(r.end.year, r.end.month, r.end.day);
        final range = _indexManager.findRangeByDateRange(s, e);
        idIterable = _indexManager.sortedIdsByDateDesc.sublist(
          range[0],
          range[1],
        );
      }
      // 検索語があれば候補を先に絞る
      final q = (filter.searchText ?? '').trim().toLowerCase();
      if (q.isNotEmpty) {
        idIterable = idIterable.where((id) {
          final text = _indexManager.searchTextIndex[id];
          return text != null && text.contains(q);
        });
      }

      for (final id in idIterable) {
        final e = box.get(id);
        if (e == null) continue;
        if (!filter.matches(e)) continue;
        if (skipped < offset) {
          skipped++;
          continue;
        }
        page.add(e);
        if (page.length >= limit) break;
      }
      return Success(page);
    } catch (e) {
      _loggingService.error('Paginated retrieval error', error: e);
      return Failure(
        ServiceException(
          'Failed to retrieve paginated diaries',
          originalError: e,
        ),
      );
    }
  }

  /// 写真の撮影日付で日記を検索
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDate(
    DateTime photoDate,
  ) async {
    try {
      await _ensureInitialized();

      final targetDate = DateTime(
        photoDate.year,
        photoDate.month,
        photoDate.day,
      );

      final entries = _getBox().values.where((entry) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        return entryDate.isAtSameMomentAs(targetDate);
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(entries);
    } catch (e) {
      _loggingService.error('Diary search by capture date error', error: e);
      return Failure(
        ServiceException(
          'Failed to search diaries by capture date',
          originalError: e,
        ),
      );
    }
  }

  /// 写真IDから日記エントリーを取得
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoId(String photoId) async {
    try {
      await _ensureInitialized();

      final allEntries = _getBox().values;
      for (final entry in allEntries) {
        if (entry.photoIds.contains(photoId)) {
          _loggingService.info(
            'Diary found for photoId: $photoId, diaryId: ${entry.id}',
          );
          return Success(entry);
        }
      }

      _loggingService.info('No diary found for photoId: $photoId');
      return const Success(null);
    } catch (e) {
      _loggingService.error(
        'Error retrieving diary entry by photo ID',
        error: e,
      );
      return Failure(
        ServiceException(
          'Failed to retrieve diary by photo ID',
          originalError: e,
        ),
      );
    }
  }
}
