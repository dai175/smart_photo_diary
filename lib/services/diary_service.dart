import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/photo_service_interface.dart';
import 'ai/ai_service_interface.dart';
import 'ai_service.dart';

class DiaryService implements DiaryServiceInterface {
  static const String _boxName = 'diary_entries';
  static DiaryService? _instance;
  Box<DiaryEntry>? _diaryBox;
  final _uuid = const Uuid();
  final AiServiceInterface _aiService;

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
    required AiServiceInterface aiService,
    required PhotoServiceInterface photoService,
  }) {
    return DiaryService._(aiService);
  }

  // 初期化メソッド（外部から呼び出し可能）
  Future<void> initialize() async {
    await _init();
  }

  // 初期化処理
  Future<void> _init() async {
    try {
      _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
      debugPrint('Hiveボックス初期化完了: ${_diaryBox?.length ?? 0}件のエントリー');
    } catch (e) {
      debugPrint('Hiveボックス初期化エラー: $e');
      // スキーマ変更により既存データが読めない場合はボックスを削除して再作成
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        debugPrint('古いボックスを削除しました');
        _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
        debugPrint('新しいボックスを作成しました');
      } catch (deleteError) {
        debugPrint('ボックス削除エラー: $deleteError');
        rethrow;
      }
    }
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
        debugPrint('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      // 新しい日記エントリーを作成
      final now = DateTime.now();
      final id = _uuid.v4();

      debugPrint('DiaryEntry作成中...');
      debugPrint('ID: $id');
      debugPrint('日付: $date');
      debugPrint('タイトル: $title');
      debugPrint('本文長: ${content.length}文字');
      debugPrint('写真ID数: ${photoIds.length}');

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

      debugPrint('Hiveに保存中...');
      // Hiveに保存
      await _diaryBox!.put(entry.id, entry);
      debugPrint('Hive保存完了');

      // バックグラウンドでタグを生成（非同期、エラーが起きても日記保存は成功）
      _generateTagsInBackground(entry);

      return entry;
    } catch (e, stackTrace) {
      debugPrint('日記保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  // 日記エントリーを更新
  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    if (_diaryBox == null) await _init();
    await _diaryBox!.put(entry.id, entry);
  }

  // 日記エントリーを削除
  @override
  Future<void> deleteDiaryEntry(String id) async {
    if (_diaryBox == null) await _init();
    await _diaryBox!.delete(id);
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
        debugPrint('バックグラウンドでタグ生成開始: ${entry.id}');
        final tagsResult = await _aiService.generateTagsFromContent(
          title: entry.title,
          content: entry.content,
          date: entry.date,
          photoCount: entry.photoIds.length,
        );

        if (tagsResult.isSuccess) {
          await entry.updateTags(tagsResult.value);
          debugPrint('タグ生成完了: ${entry.id} -> ${tagsResult.value}');
        } else {
          debugPrint('バックグラウンドタグ生成エラー: ${tagsResult.error}');
        }
      } catch (e) {
        debugPrint('バックグラウンドタグ生成エラー: $e');
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
      debugPrint('新しいタグを生成中: ${entry.id}');
      final tagsResult = await _aiService.generateTagsFromContent(
        title: entry.title,
        content: entry.content,
        date: entry.date,
        photoCount: entry.photoIds.length,
      );

      if (tagsResult.isSuccess) {
        // データベースに保存
        await entry.updateTags(tagsResult.value);
        return tagsResult.value;
      } else {
        debugPrint('タグ生成エラー: ${tagsResult.error}');
        // エラー時はフォールバックタグを返す
        return _generateFallbackTags(entry);
      }
    } catch (e) {
      debugPrint('タグ生成エラー: $e');
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
    final allEntries = await getSortedDiaryEntries();
    if (!filter.isActive) return allEntries;

    return allEntries.where((entry) => filter.matches(entry)).toList();
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
  Future<void> compactDatabase() async {
    if (_diaryBox == null) await _init();
    if (_diaryBox != null) {
      await _diaryBox!.compact();
    }
  }
}
