import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/diary_change.dart';
import '../models/diary_filter.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/diary_tag_service_interface.dart';
import 'interfaces/diary_statistics_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';

/// フォールバック用の無操作ロガー（テスト環境等でServiceLocator未設定時に使用）
class _NoOpLoggingService implements ILoggingService {
  @override
  void debug(String message, {String? context, dynamic data}) {}
  @override
  void info(String message, {String? context, dynamic data}) {}
  @override
  void warning(String message, {String? context, dynamic data}) {}
  @override
  void error(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {}
  @override
  Stopwatch startTimer(String operation, {String? context}) => Stopwatch();
  @override
  void endTimer(Stopwatch stopwatch, String operation, {String? context}) {}
}

/// 日記の管理を担当するサービスクラス（Facade）
///
/// コアCRUD・クエリ・インデックス管理は本クラスに保持。
/// タグ管理はIDiaryTagServiceに、統計はIDiaryStatisticsServiceに委譲。
class DiaryService implements IDiaryService {
  static const String _boxName = 'diary_entries';
  Box<DiaryEntry>? _diaryBox;
  final _uuid = const Uuid();
  ILoggingService _loggingService = _NoOpLoggingService();
  final _diaryChangeController = StreamController<DiaryChange>.broadcast();

  // 日付降順のインメモリインデックス（エントリーIDの配列）
  List<String> _sortedIdsByDateDesc = [];
  bool _indexBuilt = false;

  // 検索用インデックス（id -> 検索対象文字列（小文字化済み））
  final Map<String, String> _searchTextIndex = {};
  // 日付（年月日）だけを保持した並行配列（_sortedIdsByDateDesc と同じ順）
  final List<DateTime> _sortedDatesByDayDesc = [];

  // プライベートコンストラクタ（依存性注入用）
  DiaryService._();

  // 依存性注入用のファクトリメソッド
  static DiaryService createWithDependencies() {
    return DiaryService._();
  }

  // 初期化メソッド（外部から呼び出し可能）
  Future<void> initialize() async {
    await _init();
  }

  // 変更ストリーム
  @override
  Stream<DiaryChange> get changes => _diaryChangeController.stream;

  // =================================================================
  // タグ管理メソッド（IDiaryTagServiceへの委譲）
  // =================================================================

  /// タグサービス（遅延解決）
  IDiaryTagService get _tagService => serviceLocator.get<IDiaryTagService>();

  @override
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry) =>
      _tagService.getTagsForEntry(entry);

  @override
  Future<Result<Set<String>>> getAllTags() => _tagService.getAllTags();

  @override
  Future<Result<List<String>>> getPopularTags({int limit = 10}) =>
      _tagService.getPopularTags(limit: limit);

  // =================================================================
  // 統計メソッド（IDiaryStatisticsServiceへの委譲）
  // =================================================================

  /// 統計サービス（遅延解決）
  IDiaryStatisticsService get _statisticsService =>
      serviceLocator.get<IDiaryStatisticsService>();

  @override
  Future<Result<int>> getTotalDiaryCount() =>
      _statisticsService.getTotalDiaryCount();

  @override
  Future<Result<int>> getDiaryCountInPeriod(DateTime start, DateTime end) =>
      _statisticsService.getDiaryCountInPeriod(start, end);

  // =================================================================
  // 初期化・インデックス管理（本クラスに保持）
  // =================================================================

  // 初期化処理
  Future<void> _init() async {
    // LoggingServiceの初期化（ServiceLocator経由、未登録時はフォールバック）
    try {
      _loggingService = ServiceLocator().get<ILoggingService>();
    } catch (_) {
      // テスト環境など、LoggingServiceが未登録の場合
      _loggingService = _NoOpLoggingService();
    }

    try {
      _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
      _loggingService.info('Hiveボックス初期化完了: ${_diaryBox?.length ?? 0}件のエントリー');
      await _buildIndex();
    } on HiveError catch (e) {
      _loggingService.error('Hiveスキーマエラー、ボックスを再作成します', error: e);
      await _recreateBox();
    } on TypeError catch (e) {
      _loggingService.error('Hive型不整合エラー、ボックスを再作成します', error: e);
      await _recreateBox();
    }
  }

  /// スキーマ不整合時のみボックスを削除して再作成する
  Future<void> _recreateBox() async {
    try {
      await Hive.deleteBoxFromDisk(_boxName);
      _loggingService.warning('古いボックスを削除しました');
      _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
      _loggingService.info('新しいボックスを作成しました');
      await _buildIndex();
    } catch (deleteError) {
      _loggingService.error('ボックス再作成エラー', error: deleteError);
      rethrow;
    }
  }

  // インデックス構築（起動時/再初期化時）
  Future<void> _buildIndex() async {
    if (_diaryBox == null) return;
    final entries = _diaryBox!.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    _sortedIdsByDateDesc = entries.map((e) => e.id).toList(growable: true);
    _sortedDatesByDayDesc
      ..clear()
      ..addAll(
        entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)),
      );
    // 検索インデックス
    _searchTextIndex.clear();
    for (final e in entries) {
      _searchTextIndex[e.id] = _buildSearchableText(e);
    }
    _indexBuilt = true;
  }

  Future<void> _ensureIndex() async {
    if (!_indexBuilt) {
      await _buildIndex();
    }
  }

  int _findInsertIndex(DateTime date) {
    int low = 0;
    int high = _sortedIdsByDateDesc.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      final midId = _sortedIdsByDateDesc[mid];
      final midEntry = _diaryBox!.get(midId);
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

  // 検索用テキストを作成
  String _buildSearchableText(DiaryEntry entry) {
    final tags = entry.effectiveTags.join(' ');
    final location = entry.location ?? '';
    final text = '${entry.title} ${entry.content} $tags $location';
    return text.toLowerCase();
  }

  // 日付範囲に一致するインデックス範囲を二分探索で求める（降順リスト）
  // 戻り値は [startIndex, endExclusive]
  List<int> _findRangeByDateRangeInternal(DateTime startDay, DateTime endDay) {
    final n = _sortedDatesByDayDesc.length;
    if (n == 0) return const [0, 0];

    // end側（新しい方）の左端: 最初に date <= endDay となる位置
    int low = 0, high = n;
    while (low < high) {
      final mid = (low + high) >> 1;
      final d = _sortedDatesByDayDesc[mid];
      if (d.isAfter(endDay)) {
        // d > endDay → まだ左（新しい）側に進む
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
      final d = _sortedDatesByDayDesc[mid];
      if (d.isBefore(startDay)) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    final endExclusive = low.clamp(startIndex, n);
    return [startIndex, endExclusive];
  }

  /// 検索インデックスを更新するコールバック（タグサービスから呼ばれる）
  void _updateSearchIndex(String id, String searchableText) {
    _searchTextIndex[id] = searchableText;
  }

  // =================================================================
  // CRUD メソッド（本クラスに保持）
  // =================================================================

  // 日記エントリーを保存
  @override
  Future<Result<DiaryEntry>> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) async {
    try {
      // _diaryBoxが初期化されているかチェック
      if (_diaryBox == null) {
        _loggingService.warning('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      // 新しい日記エントリーを作成
      final now = DateTime.now();
      final id = _uuid.v4();

      _loggingService.debug(
        'DiaryEntry作成中 - ID: $id, 日付: $date, 写真数: ${photoIds.length}',
      );

      final entry = DiaryEntry(
        id: id,
        date: date,
        title: title,
        content: content,
        photoIds: photoIds,
        location: location,
        tags: tags,
        createdAt: now,
        updatedAt: now,
      );

      _loggingService.debug('Hiveに保存中...');
      // Hiveに保存
      await _diaryBox!.put(entry.id, entry);
      _loggingService.info('日記エントリー保存完了: ${entry.id}');

      // インデックスに挿入
      await _ensureIndex();
      final insertAt = _findInsertIndex(entry.date);
      _sortedIdsByDateDesc.insert(insertAt, entry.id);
      _sortedDatesByDayDesc.insert(
        insertAt,
        DateTime(entry.date.year, entry.date.month, entry.date.day),
      );
      _searchTextIndex[entry.id] = _buildSearchableText(entry);

      // 変更イベント（作成）を通知
      _diaryChangeController.add(
        DiaryChange(
          type: DiaryChangeType.created,
          entryId: entry.id,
          addedPhotoIds: List<String>.from(photoIds),
        ),
      );

      // バックグラウンドでタグを生成（非同期、エラーが起きても日記保存は成功）
      _tagService.generateTagsInBackground(
        entry,
        onSearchIndexUpdate: _updateSearchIndex,
      );

      return Success(entry);
    } catch (e, stackTrace) {
      _loggingService.error('日記保存エラー', error: e, stackTrace: stackTrace);
      return Failure(ServiceException('日記の保存に失敗しました', originalError: e));
    }
  }

  // 日記エントリーを更新
  @override
  Future<Result<void>> updateDiaryEntry(DiaryEntry entry) async {
    try {
      if (_diaryBox == null) await _init();
      // 旧エントリーを取得し、写真IDの差分を計算
      final old = _diaryBox!.get(entry.id);
      await _diaryBox!.put(entry.id, entry);
      if (old != null) {
        // 日付変更時はインデックスを更新
        if (old.date != entry.date) {
          await _ensureIndex();
          final oldIdx = _sortedIdsByDateDesc.indexOf(entry.id);
          if (oldIdx != -1) {
            if (_sortedIdsByDateDesc.length > oldIdx) {
              _sortedIdsByDateDesc.removeAt(oldIdx);
            }
            if (_sortedDatesByDayDesc.length > oldIdx) {
              _sortedDatesByDayDesc.removeAt(oldIdx);
            }
          }
          final insertAt = _findInsertIndex(entry.date);
          _sortedIdsByDateDesc.insert(insertAt, entry.id);
          _sortedDatesByDayDesc.insert(
            insertAt,
            DateTime(entry.date.year, entry.date.month, entry.date.day),
          );
        }
        // 検索インデックス更新
        _searchTextIndex[entry.id] = _buildSearchableText(entry);
        final oldIds = Set<String>.from(old.photoIds);
        final newIds = Set<String>.from(entry.photoIds);
        final removed = oldIds.difference(newIds).toList();
        final added = newIds.difference(oldIds).toList();
        _diaryChangeController.add(
          DiaryChange(
            type: DiaryChangeType.updated,
            entryId: entry.id,
            addedPhotoIds: added,
            removedPhotoIds: removed,
          ),
        );
      }
      return const Success(null);
    } catch (e) {
      _loggingService.error('日記更新エラー', error: e);
      return Failure(ServiceException('日記の更新に失敗しました', originalError: e));
    }
  }

  // 日記エントリーを削除
  @override
  Future<Result<void>> deleteDiaryEntry(String id) async {
    try {
      if (_diaryBox == null) await _init();
      final existing = _diaryBox!.get(id);
      await _diaryBox!.delete(id);
      if (_indexBuilt) {
        final idx = _sortedIdsByDateDesc.indexOf(id);
        if (idx != -1) {
          if (_sortedIdsByDateDesc.length > idx) {
            _sortedIdsByDateDesc.removeAt(idx);
          }
          if (_sortedDatesByDayDesc.length > idx) {
            _sortedDatesByDayDesc.removeAt(idx);
          }
        }
        _searchTextIndex.remove(id);
      }
      if (existing != null) {
        _diaryChangeController.add(
          DiaryChange(
            type: DiaryChangeType.deleted,
            entryId: id,
            removedPhotoIds: List<String>.from(existing.photoIds),
          ),
        );
      }
      return const Success(null);
    } catch (e) {
      _loggingService.error('日記削除エラー', error: e);
      return Failure(ServiceException('日記の削除に失敗しました', originalError: e));
    }
  }

  // =================================================================
  // クエリメソッド（本クラスに保持）
  // =================================================================

  // すべての日記エントリーを取得
  Future<List<DiaryEntry>> _getAllDiaryEntries() async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.values.toList();
  }

  // 日付でソートされた日記エントリーを取得
  @override
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries({
    bool descending = true,
  }) async {
    try {
      final entries = await _getAllDiaryEntries();
      entries.sort(
        (a, b) =>
            descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
      );
      return Success(entries);
    } catch (e) {
      _loggingService.error('日記一覧取得エラー', error: e);
      return Failure(ServiceException('日記一覧の取得に失敗しました', originalError: e));
    }
  }

  // IDで日記エントリーを取得
  @override
  Future<Result<DiaryEntry?>> getDiaryEntry(String id) async {
    try {
      if (_diaryBox == null) await _init();
      return Success(_diaryBox!.get(id));
    } catch (e) {
      _loggingService.error('日記取得エラー', error: e);
      return Failure(ServiceException('日記の取得に失敗しました', originalError: e));
    }
  }

  // フィルタを適用して日記エントリーを取得
  @override
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(
    DiaryFilter filter,
  ) async {
    try {
      await _ensureIndex();
      final result = <DiaryEntry>[];
      if (!filter.isActive) {
        for (final id in _sortedIdsByDateDesc) {
          final e = _diaryBox!.get(id);
          if (e != null) result.add(e);
        }
        return Success(result);
      }
      // 日付範囲があれば二分探索で範囲を絞る
      Iterable<String> idIterable = _sortedIdsByDateDesc;
      if (filter.dateRange != null) {
        final r = filter.dateRange!;
        final s = DateTime(r.start.year, r.start.month, r.start.day);
        final e = DateTime(r.end.year, r.end.month, r.end.day);
        final range = _findRangeByDateRangeInternal(s, e);
        idIterable = _sortedIdsByDateDesc.sublist(range[0], range[1]);
      }
      // 検索語があれば検索インデックスで候補を絞り込み
      final q = (filter.searchText ?? '').trim().toLowerCase();
      if (q.isNotEmpty) {
        idIterable = idIterable.where((id) {
          final text = _searchTextIndex[id];
          return text != null && text.contains(q);
        });
      }
      for (final id in idIterable) {
        final e = _diaryBox!.get(id);
        if (e != null && filter.matches(e)) {
          result.add(e);
        }
      }
      return Success(result);
    } catch (e) {
      _loggingService.error('フィルタ取得エラー', error: e);
      return Failure(ServiceException('フィルタ付き日記の取得に失敗しました', originalError: e));
    }
  }

  // フィルタ + ページングで日記エントリーを取得
  @override
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesPage(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    try {
      await _ensureIndex();
      if (!filter.isActive) {
        final total = _sortedIdsByDateDesc.length;
        if (total == 0) return const Success([]);
        final start = offset.clamp(0, total);
        final end = (offset + limit).clamp(0, total);
        if (start >= end) return const Success([]);
        final ids = _sortedIdsByDateDesc.sublist(start, end);
        final entries = <DiaryEntry>[];
        for (final id in ids) {
          final e = _diaryBox!.get(id);
          if (e != null) entries.add(e);
        }
        return Success(entries);
      }

      final page = <DiaryEntry>[];
      int skipped = 0;

      // 日付範囲があれば先に範囲を絞る
      Iterable<String> idIterable = _sortedIdsByDateDesc;
      if (filter.dateRange != null) {
        final r = filter.dateRange!;
        final s = DateTime(r.start.year, r.start.month, r.start.day);
        final e = DateTime(r.end.year, r.end.month, r.end.day);
        final range = _findRangeByDateRangeInternal(s, e);
        idIterable = _sortedIdsByDateDesc.sublist(range[0], range[1]);
      }
      // 検索語があれば候補を先に絞る
      final q = (filter.searchText ?? '').trim().toLowerCase();
      if (q.isNotEmpty) {
        idIterable = idIterable.where((id) {
          final text = _searchTextIndex[id];
          return text != null && text.contains(q);
        });
      }

      for (final id in idIterable) {
        final e = _diaryBox!.get(id);
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
      _loggingService.error('ページ取得エラー', error: e);
      return Failure(ServiceException('ページ付き日記の取得に失敗しました', originalError: e));
    }
  }

  // 写真付きで日記エントリーを保存（後方互換性）
  @override
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  }) async {
    final List<String> photoIds = photos.map((photo) => photo.id).toList();
    return await saveDiaryEntry(
      date: date,
      title: title,
      content: content,
      photoIds: photoIds,
    );
  }

  // データベースの最適化（StorageServiceから呼び出し用）
  @override
  Future<void> compactDatabase() async {
    if (_diaryBox == null) await _init();
    if (_diaryBox != null) {
      await _diaryBox!.compact();
    }
  }

  /// 過去の写真から日記エントリーを作成
  @override
  Future<Result<DiaryEntry>> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) async {
    try {
      if (_diaryBox == null) {
        _loggingService.warning('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      // 既存の日記との重複チェック
      final existingResult = await getDiaryByPhotoDate(photoDate);
      if (existingResult.isSuccess && existingResult.value.isNotEmpty) {
        _loggingService.warning(
          '${photoDate.toString().split(' ')[0]}の日記が既に存在します',
        );
        // 重複がある場合でも作成を続行（ユーザーが複数の日記を作成したい場合もある）
      }

      final now = DateTime.now();
      final id = _uuid.v4();

      _loggingService.debug(
        '過去の写真から日記エントリー作成中 - ID: $id, 撮影日: $photoDate, 写真数: ${photoIds.length}',
      );

      final entry = DiaryEntry(
        id: id,
        date: photoDate, // 写真の撮影日を日記の日付として使用
        title: title,
        content: content,
        photoIds: photoIds,
        location: location,
        tags: tags,
        createdAt: now, // 実際の作成日時
        updatedAt: now,
      );

      _loggingService.debug('Hiveに保存中...');
      await _diaryBox!.put(entry.id, entry);
      _loggingService.info('過去写真日記の保存完了: ${entry.id}');

      // インデックスに挿入
      await _ensureIndex();
      final insertAt = _findInsertIndex(entry.date);
      _sortedIdsByDateDesc.insert(insertAt, entry.id);
      _sortedDatesByDayDesc.insert(
        insertAt,
        DateTime(entry.date.year, entry.date.month, entry.date.day),
      );
      _searchTextIndex[entry.id] = _buildSearchableText(entry);

      // 変更イベント（作成）を通知
      _diaryChangeController.add(
        DiaryChange(
          type: DiaryChangeType.created,
          entryId: entry.id,
          addedPhotoIds: List<String>.from(photoIds),
        ),
      );

      // バックグラウンドでタグを生成（過去の日付コンテキストを含む）
      _tagService.generateTagsInBackgroundForPastPhoto(
        entry,
        onSearchIndexUpdate: _updateSearchIndex,
      );

      return Success(entry);
    } catch (e, stackTrace) {
      _loggingService.error('過去写真日記作成エラー', error: e, stackTrace: stackTrace);
      return Failure(ServiceException('過去写真日記の作成に失敗しました', originalError: e));
    }
  }

  /// 写真の撮影日付で日記を検索
  @override
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDate(
    DateTime photoDate,
  ) async {
    try {
      if (_diaryBox == null) await _init();

      final targetDate = DateTime(
        photoDate.year,
        photoDate.month,
        photoDate.day,
      );

      final entries = _diaryBox!.values.where((entry) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        return entryDate.isAtSameMomentAs(targetDate);
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(entries);
    } catch (e) {
      _loggingService.error('撮影日別日記検索エラー', error: e);
      return Failure(ServiceException('撮影日別日記の検索に失敗しました', originalError: e));
    }
  }

  /// 写真IDから日記エントリーを取得
  @override
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoId(String photoId) async {
    try {
      if (_diaryBox == null) {
        _loggingService.warning('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      final allEntries = _diaryBox!.values;
      for (final entry in allEntries) {
        if (entry.photoIds.contains(photoId)) {
          _loggingService.info('写真ID: $photoId の日記を発見: ${entry.id}');
          return Success(entry);
        }
      }

      _loggingService.info('写真ID: $photoId に対応する日記は見つかりませんでした');
      return const Success(null);
    } catch (e) {
      _loggingService.error('写真IDから日記エントリー取得エラー', error: e);
      return Failure(ServiceException('写真IDから日記の取得に失敗しました', originalError: e));
    }
  }
}
