import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/diary_change.dart';
import '../models/diary_filter.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/photo_service_interface.dart';
import 'ai/ai_service_interface.dart';
import 'ai_service.dart';
import 'logging_service.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';

class DiaryService implements IDiaryService {
  static const String _boxName = 'diary_entries';
  static DiaryService? _instance;
  Box<DiaryEntry>? _diaryBox;
  final _uuid = const Uuid();
  final IAiService _aiService;
  late final LoggingService _loggingService;
  final _diaryChangeController = StreamController<DiaryChange>.broadcast();

  // 日付降順のインメモリインデックス（エントリーIDの配列）
  List<String> _sortedIdsByDateDesc = [];
  bool _indexBuilt = false;

  // プライベートコンストラクタ（依存性注入用）
  DiaryService._(this._aiService);

  // 従来のシングルトンパターン（後方互換性のため保持）
  static Future<DiaryService> getInstance() async {
    if (_instance == null) {
      final aiService = AiService();
      _instance = DiaryService._(aiService);
      await _instance!._init();
    }
    return _instance!;
  }

  // 依存性注入用のファクトリメソッド
  static DiaryService createWithDependencies({
    required IAiService aiService,
    required IPhotoService photoService,
  }) {
    return DiaryService._(aiService);
  }

  // 初期化メソッド（外部から呼び出し可能）
  Future<void> initialize() async {
    await _init();
  }

  // 変更ストリーム
  @override
  Stream<DiaryChange> get changes => _diaryChangeController.stream;

  // 初期化処理
  Future<void> _init() async {
    // LoggingServiceの初期化を最初に行う
    _loggingService = await LoggingService.getInstance();

    try {
      _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
      _loggingService.info('Hiveボックス初期化完了: ${_diaryBox?.length ?? 0}件のエントリー');
      await _buildIndex();
    } catch (e) {
      _loggingService.error('Hiveボックス初期化エラー', error: e);
      // スキーマ変更により既存データが読めない場合はボックスを削除して再作成
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _loggingService.warning('古いボックスを削除しました');
        _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
        _loggingService.info('新しいボックスを作成しました');
        await _buildIndex();
      } catch (deleteError) {
        _loggingService.error('ボックス削除エラー', error: deleteError);
        rethrow;
      }
    }
  }

  // インデックス構築（起動時/再初期化時）
  Future<void> _buildIndex() async {
    if (_diaryBox == null) return;
    final entries = _diaryBox!.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    _sortedIdsByDateDesc = entries.map((e) => e.id).toList(growable: true);
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

  // 日記エントリーを保存
  @override
  Future<DiaryEntry> saveDiaryEntry({
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

      // 変更イベント（作成）を通知
      _diaryChangeController.add(
        DiaryChange(
          type: DiaryChangeType.created,
          entryId: entry.id,
          addedPhotoIds: List<String>.from(photoIds),
        ),
      );

      // バックグラウンドでタグを生成（非同期、エラーが起きても日記保存は成功）
      _generateTagsInBackground(entry);

      return entry;
    } catch (e, stackTrace) {
      _loggingService.error('日記保存エラー', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // 日記エントリーを更新
  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    if (_diaryBox == null) await _init();
    // 旧エントリーを取得し、写真IDの差分を計算
    final old = _diaryBox!.get(entry.id);
    await _diaryBox!.put(entry.id, entry);
    if (old != null) {
      // 日付変更時はインデックスを更新
      if (old.date != entry.date) {
        await _ensureIndex();
        _sortedIdsByDateDesc.remove(entry.id);
        final insertAt = _findInsertIndex(entry.date);
        _sortedIdsByDateDesc.insert(insertAt, entry.id);
      }
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
  }

  // 日記エントリーを削除
  @override
  Future<void> deleteDiaryEntry(String id) async {
    if (_diaryBox == null) await _init();
    final existing = _diaryBox!.get(id);
    await _diaryBox!.delete(id);
    if (_indexBuilt) {
      _sortedIdsByDateDesc.remove(id);
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
  }

  // すべての日記エントリーを取得
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.values.toList();
  }

  // 日付でソートされた日記エントリーを取得
  @override
  Future<List<DiaryEntry>> getSortedDiaryEntries({
    bool descending = true,
  }) async {
    final entries = await getAllDiaryEntries();
    entries.sort(
      (a, b) =>
          descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return entries;
  }

  // 特定の日付の日記エントリーを取得
  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.values
        .where(
          (entry) =>
              entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day,
        )
        .toList();
  }

  // 特定の月の日記エントリーを取得
  Future<List<DiaryEntry>> getDiaryEntriesByMonth(int year, int month) async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.values
        .where((entry) => entry.date.year == year && entry.date.month == month)
        .toList();
  }

  // IDで日記エントリーを取得
  @override
  Future<DiaryEntry?> getDiaryEntry(String id) async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.get(id);
  }

  // バックグラウンドでタグを生成
  void _generateTagsInBackground(DiaryEntry entry) {
    // 非同期でタグ生成を実行（UI をブロックしない）
    Future.delayed(Duration.zero, () async {
      try {
        _loggingService.debug('バックグラウンドでタグ生成開始: ${entry.id}');
        final tagsResult = await _aiService.generateTagsFromContent(
          title: entry.title,
          content: entry.content,
          date: entry.date,
          photoCount: entry.photoIds.length,
        );

        if (tagsResult.isSuccess) {
          // Hiveボックスから最新のエントリーを取得して更新
          if (_diaryBox != null && _diaryBox!.isOpen) {
            final latestEntry = _diaryBox!.get(entry.id);
            if (latestEntry != null) {
              await latestEntry.updateTags(tagsResult.value);
              _loggingService.debug(
                'タグ生成完了: ${entry.id} -> ${tagsResult.value}',
              );
            } else {
              _loggingService.warning(
                'バックグラウンドタグ生成: エントリーが見つかりません: ${entry.id}',
              );
            }
          } else {
            _loggingService.warning('バックグラウンドタグ生成: Hiveボックスが利用できません');
          }
        } else {
          _loggingService.error('バックグラウンドタグ生成エラー', error: tagsResult.error);
        }
      } catch (e) {
        _loggingService.error('バックグラウンドタグ生成エラー', error: e);
      }
    });
  }

  // 日記エントリーのタグを取得（キャッシュ優先）
  @override
  Future<List<String>> getTagsForEntry(DiaryEntry entry) async {
    // 有効なキャッシュがあればそれを返す
    if (entry.hasValidTags) {
      return entry.cachedTags!;
    }

    try {
      // キャッシュが無効または存在しない場合は新しく生成
      _loggingService.debug('新しいタグを生成中: ${entry.id}');
      final tagsResult = await _aiService.generateTagsFromContent(
        title: entry.title,
        content: entry.content,
        date: entry.date,
        photoCount: entry.photoIds.length,
      );

      if (tagsResult.isSuccess) {
        // Hiveボックスから最新のエントリーを取得して更新
        if (_diaryBox != null && _diaryBox!.isOpen) {
          final latestEntry = _diaryBox!.get(entry.id);
          if (latestEntry != null) {
            await latestEntry.updateTags(tagsResult.value);
          }
        }
        return tagsResult.value;
      } else {
        _loggingService.error('タグ生成エラー', error: tagsResult.error);
        // エラー時はフォールバックタグを返す
        return _generateFallbackTags(entry);
      }
    } catch (e) {
      _loggingService.error('タグ生成エラー', error: e);
      // エラー時はフォールバックタグを返す
      return _generateFallbackTags(entry);
    }
  }

  // フォールバックタグを生成
  List<String> _generateFallbackTags(DiaryEntry entry) {
    final tags = <String>[];

    // 時間帯タグのみ
    final hour = entry.date.hour;
    if (hour >= 5 && hour < 12) {
      tags.add('朝');
    } else if (hour >= 12 && hour < 18) {
      tags.add('昼');
    } else if (hour >= 18 && hour < 22) {
      tags.add('夕方');
    } else {
      tags.add('夜');
    }

    return tags;
  }

  // フィルタを適用して日記エントリーを取得
  @override
  Future<List<DiaryEntry>> getFilteredDiaryEntries(DiaryFilter filter) async {
    await _ensureIndex();
    final result = <DiaryEntry>[];
    if (!filter.isActive) {
      for (final id in _sortedIdsByDateDesc) {
        final e = _diaryBox!.get(id);
        if (e != null) result.add(e);
      }
      return result;
    }
    for (final id in _sortedIdsByDateDesc) {
      final e = _diaryBox!.get(id);
      if (e != null && filter.matches(e)) {
        result.add(e);
      }
    }
    return result;
  }

  // フィルタ + ページングで日記エントリーを取得
  // 現段階ではまず全件を取得してからスライス（後続タスクで最適化予定）
  @override
  Future<List<DiaryEntry>> getFilteredDiaryEntriesPage(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    await _ensureIndex();
    if (!filter.isActive) {
      final total = _sortedIdsByDateDesc.length;
      if (total == 0) return const [];
      final start = offset.clamp(0, total);
      final end = (offset + limit).clamp(0, total);
      if (start >= end) return const [];
      final ids = _sortedIdsByDateDesc.sublist(start, end);
      final entries = <DiaryEntry>[];
      for (final id in ids) {
        final e = _diaryBox!.get(id);
        if (e != null) entries.add(e);
      }
      return entries;
    }

    final page = <DiaryEntry>[];
    int skipped = 0;
    for (final id in _sortedIdsByDateDesc) {
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
    return page;
  }

  // 全ての日記からユニークなタグを取得
  @override
  Future<Set<String>> getAllTags() async {
    if (_diaryBox == null) await _init();
    final allTags = <String>{};

    for (final entry in _diaryBox!.values) {
      if (entry.cachedTags != null) {
        allTags.addAll(entry.cachedTags!);
      }
    }

    return allTags;
  }

  // よく使われるタグを取得（使用頻度順）
  @override
  Future<List<String>> getPopularTags({int limit = 10}) async {
    if (_diaryBox == null) await _init();
    final tagCounts = <String, int>{};

    for (final entry in _diaryBox!.values) {
      if (entry.cachedTags != null) {
        for (final tag in entry.cachedTags!) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(limit).map((e) => e.key).toList();
  }

  // インターフェース実装のための追加メソッド
  @override
  Future<int> getTotalDiaryCount() async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.length;
  }

  @override
  Future<int> getDiaryCountInPeriod(DateTime start, DateTime end) async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.values
        .where((entry) => entry.date.isAfter(start) && entry.date.isBefore(end))
        .length;
  }

  // 写真付きで日記エントリーを保存（後方互換性）
  @override
  Future<DiaryEntry> saveDiaryEntryWithPhotos({
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
  ///
  /// [photoDate]: 写真の撮影日時
  /// [title]: 日記のタイトル
  /// [content]: 日記の内容
  /// [photoIds]: 写真のIDリスト
  /// [location]: 場所（オプション）
  /// [tags]: タグリスト（オプション）
  /// 戻り値: 作成された日記エントリー
  @override
  Future<DiaryEntry> createDiaryForPastPhoto({
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
      final existingDiaries = await getDiaryByPhotoDate(photoDate);
      if (existingDiaries.isNotEmpty) {
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

      // 変更イベント（作成）を通知
      _diaryChangeController.add(
        DiaryChange(
          type: DiaryChangeType.created,
          entryId: entry.id,
          addedPhotoIds: List<String>.from(photoIds),
        ),
      );

      // バックグラウンドでタグを生成（過去の日付コンテキストを含む）
      _generateTagsInBackgroundForPastPhoto(entry);

      return entry;
    } catch (e, stackTrace) {
      _loggingService.error('過去写真日記作成エラー', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 写真の撮影日付で日記を検索
  ///
  /// [photoDate]: 写真の撮影日時
  /// 戻り値: 該当する日記エントリーのリスト
  @override
  Future<List<DiaryEntry>> getDiaryByPhotoDate(DateTime photoDate) async {
    if (_diaryBox == null) await _init();

    final targetDate = DateTime(photoDate.year, photoDate.month, photoDate.day);

    return _diaryBox!.values.where((entry) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      return entryDate.isAtSameMomentAs(targetDate);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 作成日時の降順
  }

  /// 過去の写真用のバックグラウンドタグ生成
  ///
  /// 通常のタグ生成と異なり、過去の日付であることを考慮してタグを生成
  void _generateTagsInBackgroundForPastPhoto(DiaryEntry entry) {
    Future.delayed(Duration.zero, () async {
      try {
        _loggingService.debug('過去写真日記のバックグラウンドタグ生成開始: ${entry.id}');

        // 過去の日付であることを示すメタデータを追加
        final daysDifference = DateTime.now().difference(entry.date).inDays;
        String pastContext = '';

        if (daysDifference == 1) {
          pastContext = '昨日の思い出';
        } else if (daysDifference <= 7) {
          pastContext = '$daysDifference日前の思い出';
        } else if (daysDifference <= 30) {
          pastContext = '約${(daysDifference / 7).round()}週間前の思い出';
        } else if (daysDifference <= 365) {
          pastContext = '約${(daysDifference / 30).round()}ヶ月前の思い出';
        } else {
          pastContext = '約${(daysDifference / 365).round()}年前の思い出';
        }

        final tagsResult = await _aiService.generateTagsFromContent(
          title: entry.title,
          content: '$pastContext: ${entry.content}', // 過去のコンテキストを含める
          date: entry.date,
          photoCount: entry.photoIds.length,
        );

        if (tagsResult.isSuccess) {
          if (_diaryBox != null && _diaryBox!.isOpen) {
            final latestEntry = _diaryBox!.get(entry.id);
            if (latestEntry != null) {
              final updatedEntry = DiaryEntry(
                id: latestEntry.id,
                date: latestEntry.date,
                title: latestEntry.title,
                content: latestEntry.content,
                photoIds: latestEntry.photoIds,
                location: latestEntry.location,
                tags: tagsResult.value,
                createdAt: latestEntry.createdAt,
                updatedAt: DateTime.now(),
              );
              await _diaryBox!.put(entry.id, updatedEntry);
              _loggingService.debug('過去写真日記のタグ生成完了: ${tagsResult.value}');
            }
          }
        } else {
          _loggingService.error('過去写真日記のタグ生成失敗', error: tagsResult.error);
        }
      } catch (e) {
        _loggingService.error('過去写真日記のタグ生成エラー', error: e);
      }
    });
  }

  // ========================================
  // Result<T>パターン版のメソッド実装
  // ========================================

  /// 日記エントリーを保存（Result版）
  @override
  Future<Result<DiaryEntry>> saveDiaryEntryResult({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await saveDiaryEntry(
        date: date,
        title: title,
        content: content,
        photoIds: photoIds,
        location: location,
        tags: tags,
      );
    }, context: 'DiaryService.saveDiaryEntryResult');
  }

  /// 指定されたIDの日記エントリーを取得（Result版）
  @override
  Future<Result<DiaryEntry?>> getDiaryEntryResult(String id) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getDiaryEntry(id);
    }, context: 'DiaryService.getDiaryEntryResult');
  }

  /// すべての日記エントリーを取得（Result版）
  @override
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntriesResult({
    bool descending = true,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getSortedDiaryEntries(descending: descending);
    }, context: 'DiaryService.getSortedDiaryEntriesResult');
  }

  /// フィルタに基づいて日記エントリーを取得（Result版）
  @override
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesResult(
    DiaryFilter filter,
  ) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getFilteredDiaryEntries(filter);
    }, context: 'DiaryService.getFilteredDiaryEntriesResult');
  }

  /// フィルタ + ページングで日記エントリーを取得（Result版）
  @override
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesPageResult(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getFilteredDiaryEntriesPage(
        filter,
        offset: offset,
        limit: limit,
      );
    }, context: 'DiaryService.getFilteredDiaryEntriesPageResult');
  }

  /// 日記エントリーを更新（Result版）
  @override
  Future<Result<void>> updateDiaryEntryResult(DiaryEntry entry) async {
    return ResultHelper.tryExecuteAsync(() async {
      await updateDiaryEntry(entry);
    }, context: 'DiaryService.updateDiaryEntryResult');
  }

  /// 日記エントリーを削除（Result版）
  @override
  Future<Result<void>> deleteDiaryEntryResult(String id) async {
    return ResultHelper.tryExecuteAsync(() async {
      await deleteDiaryEntry(id);
    }, context: 'DiaryService.deleteDiaryEntryResult');
  }

  /// エントリーのタグを取得（Result版）
  @override
  Future<Result<List<String>>> getTagsForEntryResult(DiaryEntry entry) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getTagsForEntry(entry);
    }, context: 'DiaryService.getTagsForEntryResult');
  }

  /// すべてのタグを取得（Result版）
  @override
  Future<Result<Set<String>>> getAllTagsResult() async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getAllTags();
    }, context: 'DiaryService.getAllTagsResult');
  }

  /// 日記の総数を取得（Result版）
  @override
  Future<Result<int>> getTotalDiaryCountResult() async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getTotalDiaryCount();
    }, context: 'DiaryService.getTotalDiaryCountResult');
  }

  /// 指定期間の日記数を取得（Result版）
  @override
  Future<Result<int>> getDiaryCountInPeriodResult(
    DateTime start,
    DateTime end,
  ) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getDiaryCountInPeriod(start, end);
    }, context: 'DiaryService.getDiaryCountInPeriodResult');
  }

  /// 写真付きで日記エントリーを保存（Result版）
  @override
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotosResult({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await saveDiaryEntryWithPhotos(
        date: date,
        title: title,
        content: content,
        photos: photos,
      );
    }, context: 'DiaryService.saveDiaryEntryWithPhotosResult');
  }

  /// 過去の写真から日記エントリーを作成（Result版）
  @override
  Future<Result<DiaryEntry>> createDiaryForPastPhotoResult({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await createDiaryForPastPhoto(
        photoDate: photoDate,
        title: title,
        content: content,
        photoIds: photoIds,
        location: location,
        tags: tags,
      );
    }, context: 'DiaryService.createDiaryForPastPhotoResult');
  }

  /// 写真の撮影日付で日記を検索（Result版）
  @override
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDateResult(
    DateTime photoDate,
  ) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getDiaryByPhotoDate(photoDate);
    }, context: 'DiaryService.getDiaryByPhotoDateResult');
  }

  /// 写真IDから日記エントリーを取得
  @override
  Future<DiaryEntry?> getDiaryEntryByPhotoId(String photoId) async {
    try {
      if (_diaryBox == null) {
        _loggingService.warning('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      final allEntries = _diaryBox!.values;
      for (final entry in allEntries) {
        if (entry.photoIds.contains(photoId)) {
          _loggingService.info('写真ID: $photoId の日記を発見: ${entry.id}');
          return entry;
        }
      }

      _loggingService.info('写真ID: $photoId に対応する日記は見つかりませんでした');
      return null;
    } catch (e) {
      _loggingService.error('写真IDから日記エントリー取得エラー', error: e);
      rethrow;
    }
  }

  /// 写真IDから日記エントリーを取得（Result版）
  @override
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoIdResult(
    String photoId,
  ) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getDiaryEntryByPhotoId(photoId);
    }, context: 'DiaryService.getDiaryEntryByPhotoIdResult');
  }
}
