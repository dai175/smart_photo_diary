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
          // Hiveボックスから最新のエントリーを取得して更新
          if (_diaryBox != null && _diaryBox!.isOpen) {
            final latestEntry = _diaryBox!.get(entry.id);
            if (latestEntry != null) {
              await latestEntry.updateTags(tagsResult.value);
              debugPrint('タグ生成完了: ${entry.id} -> ${tagsResult.value}');
            } else {
              debugPrint('バックグラウンドタグ生成: エントリーが見つかりません: ${entry.id}');
            }
          } else {
            debugPrint('バックグラウンドタグ生成: Hiveボックスが利用できません');
          }
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
        // Hiveボックスから最新のエントリーを取得して更新
        if (_diaryBox != null && _diaryBox!.isOpen) {
          final latestEntry = _diaryBox!.get(entry.id);
          if (latestEntry != null) {
            await latestEntry.updateTags(tagsResult.value);
          }
        }
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
        debugPrint('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      // 既存の日記との重複チェック
      final existingDiaries = await getDiaryByPhotoDate(photoDate);
      if (existingDiaries.isNotEmpty) {
        debugPrint('警告: ${photoDate.toString().split(' ')[0]}の日記が既に存在します');
        // 重複がある場合でも作成を続行（ユーザーが複数の日記を作成したい場合もある）
      }

      final now = DateTime.now();
      final id = _uuid.v4();

      debugPrint('過去の写真から日記エントリー作成中...');
      debugPrint('ID: $id');
      debugPrint('写真撮影日: $photoDate');
      debugPrint('日記作成日時: $now');
      debugPrint('タイトル: $title');
      debugPrint('本文長: ${content.length}文字');
      debugPrint('写真ID数: ${photoIds.length}');

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

      debugPrint('Hiveに保存中...');
      await _diaryBox!.put(entry.id, entry);
      debugPrint('過去写真日記の保存完了');

      // バックグラウンドでタグを生成（過去の日付コンテキストを含む）
      _generateTagsInBackgroundForPastPhoto(entry);

      return entry;
    } catch (e, stackTrace) {
      debugPrint('過去写真日記作成エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
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
        debugPrint('過去写真日記のバックグラウンドタグ生成開始: ${entry.id}');

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
              debugPrint('過去写真日記のタグ生成完了: ${tagsResult.value}');
            }
          }
        } else {
          debugPrint('過去写真日記のタグ生成失敗: ${tagsResult.error}');
        }
      } catch (e) {
        debugPrint('過去写真日記のタグ生成エラー: $e');
      }
    });
  }
}
