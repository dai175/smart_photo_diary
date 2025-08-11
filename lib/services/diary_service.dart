import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import '../models/import_result.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/photo_service_interface.dart';
import 'ai/ai_service_interface.dart';
import 'ai_service.dart';
import 'logging_service.dart';
import 'storage_service.dart';

class DiaryService implements DiaryServiceInterface {
  static const String _boxName = 'diary_entries';
  static DiaryService? _instance;
  Box<DiaryEntry>? _diaryBox;
  final _uuid = const Uuid();
  final AiServiceInterface _aiService;
  final PhotoServiceInterface? _photoService;
  late final LoggingService _loggingService;

  // プライベートコンストラクタ（依存性注入用）
  DiaryService._(this._aiService, [this._photoService]);

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
    return DiaryService._(aiService, photoService);
  }

  // 初期化メソッド（外部から呼び出し可能）
  Future<void> initialize() async {
    await _init();
  }

  // 初期化処理
  Future<void> _init() async {
    // LoggingServiceの初期化を最初に行う
    _loggingService = await LoggingService.getInstance();

    try {
      _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
      _loggingService.info('Hiveボックス初期化完了: ${_diaryBox?.length ?? 0}件のエントリー');
    } catch (e) {
      _loggingService.error('Hiveボックス初期化エラー', error: e);
      // スキーマ変更により既存データが読めない場合はボックスを削除して再作成
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _loggingService.warning('古いボックスを削除しました');
        _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
        _loggingService.info('新しいボックスを作成しました');
      } catch (deleteError) {
        _loggingService.error('ボックス削除エラー', error: deleteError);
        rethrow;
      }
    }
  }

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

      // バックグラウンドでタグを生成（非同期、エラーが起きても日記保存は成功）
      _generateTagsInBackground(entry);

      return Success(entry);
    } catch (e, stackTrace) {
      _loggingService.error('日記保存エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '日記エントリーの保存に失敗しました',
          details: 'ID: ${_uuid.v4()}, 日付: $date',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // 日記エントリーを更新
  @override
  Future<Result<DiaryEntry>> updateDiaryEntry(DiaryEntry entry) async {
    try {
      if (_diaryBox == null) await _init();

      // 更新日時を設定
      final updatedEntry = DiaryEntry(
        id: entry.id,
        date: entry.date,
        title: entry.title,
        content: entry.content,
        photoIds: entry.photoIds,
        location: entry.location,
        tags: entry.tags,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );

      await _diaryBox!.put(updatedEntry.id, updatedEntry);
      _loggingService.info('日記エントリー更新完了: ${updatedEntry.id}');
      return Success(updatedEntry);
    } catch (e, stackTrace) {
      _loggingService.error('日記更新エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '日記エントリーの更新に失敗しました',
          details: 'ID: ${entry.id}',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // 日記エントリーを削除
  @override
  Future<Result<void>> deleteDiaryEntry(String id) async {
    try {
      if (_diaryBox == null) await _init();

      // 削除前に存在確認
      if (!_diaryBox!.containsKey(id)) {
        return const Failure(DataNotFoundException('指定された日記エントリーが見つかりません'));
      }

      await _diaryBox!.delete(id);
      _loggingService.info('日記エントリー削除完了: $id');
      return const Success(null);
    } catch (e, stackTrace) {
      _loggingService.error('日記削除エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '日記エントリーの削除に失敗しました',
          details: 'ID: $id',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // すべての日記エントリーを取得
  Future<Result<List<DiaryEntry>>> getAllDiaryEntries() async {
    try {
      if (_diaryBox == null) await _init();
      final entries = _diaryBox!.values.toList();
      return Success(entries);
    } catch (e, stackTrace) {
      _loggingService.error('日記エントリー取得エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '日記エントリーの取得に失敗しました',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // 日付でソートされた日記エントリーを取得
  @override
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries({
    bool descending = true,
  }) async {
    final entriesResult = await getAllDiaryEntries();
    return entriesResult.map((entries) {
      final sortedEntries = List<DiaryEntry>.from(entries);
      sortedEntries.sort(
        (a, b) =>
            descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
      );
      return sortedEntries;
    });
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
  Future<Result<DiaryEntry?>> getDiaryEntry(String id) async {
    try {
      if (_diaryBox == null) await _init();
      final entry = _diaryBox!.get(id);
      return Success(entry);
    } catch (e, stackTrace) {
      _loggingService.error('日記エントリー取得エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '指定された日記エントリーの取得に失敗しました',
          details: 'ID: $id',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
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
          _loggingService.error('バックグラウンドタグ生成エラー');
        }
      } catch (e) {
        _loggingService.error('バックグラウンドタグ生成エラー');
      }
    });
  }

  // 日記エントリーのタグを取得（キャッシュ優先）
  @override
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry) async {
    try {
      // 有効なキャッシュがあればそれを返す
      if (entry.hasValidTags) {
        return Success(entry.cachedTags!);
      }

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
        return Success(tagsResult.value);
      } else {
        _loggingService.error('タグ生成エラー', error: tagsResult.error);
        // エラー時はフォールバックタグを返す
        return Success(_generateFallbackTags(entry));
      }
    } catch (e, stackTrace) {
      _loggingService.error('タグ生成エラー', error: e, stackTrace: stackTrace);
      // エラー時はフォールバックタグを返す
      return Success(_generateFallbackTags(entry));
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
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(
    DiaryFilter filter,
  ) async {
    final allEntriesResult = await getSortedDiaryEntries();
    return allEntriesResult.map((allEntries) {
      if (!filter.isActive) return allEntries;
      return allEntries.where((entry) => filter.matches(entry)).toList();
    });
  }

  // 全ての日記からユニークなタグを取得
  @override
  Future<Result<Set<String>>> getAllTags() async {
    try {
      if (_diaryBox == null) await _init();
      final allTags = <String>{};

      for (final entry in _diaryBox!.values) {
        if (entry.cachedTags != null) {
          allTags.addAll(entry.cachedTags!);
        }
      }

      return Success(allTags);
    } catch (e, stackTrace) {
      _loggingService.error('タグ取得エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          'タグの取得に失敗しました',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
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
  Future<Result<int>> getTotalDiaryCount() async {
    try {
      if (_diaryBox == null) await _init();
      return Success(_diaryBox!.length);
    } catch (e, stackTrace) {
      _loggingService.error('日記数取得エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '日記数の取得に失敗しました',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getDiaryCountInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      if (_diaryBox == null) await _init();
      final count = _diaryBox!.values
          .where(
            (entry) => entry.date.isAfter(start) && entry.date.isBefore(end),
          )
          .length;
      return Success(count);
    } catch (e, stackTrace) {
      _loggingService.error('期間内日記数取得エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '期間内の日記数の取得に失敗しました',
          details: '期間: $start - $end',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
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
      final existingDiariesResult = await getDiaryByPhotoDate(photoDate);
      if (existingDiariesResult.isFailure) {
        return Failure(existingDiariesResult.error);
      }
      if (existingDiariesResult.value.isNotEmpty) {
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

      // バックグラウンドでタグを生成（過去の日付コンテキストを含む）
      _generateTagsInBackgroundForPastPhoto(entry);

      return Success(entry);
    } catch (e, stackTrace) {
      _loggingService.error('過去写真日記作成エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '過去の写真からの日記作成に失敗しました',
          details: '撮影日: $photoDate',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 写真の撮影日付で日記を検索
  ///
  /// [photoDate]: 写真の撮影日時
  /// 戻り値: 該当する日記エントリーのリスト
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

      final entries = _diaryBox!.values.where(
        (entry) {
          final entryDate = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          return entryDate.isAtSameMomentAs(targetDate);
        },
      ).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 作成日時の降順

      return Success(entries);
    } catch (e, stackTrace) {
      _loggingService.error('写真日付日記検索エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '写真の撮影日付での日記検索に失敗しました',
          details: '撮影日: $photoDate',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
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

  /// 日記を検索
  @override
  Future<Result<List<DiaryEntry>>> searchDiaries({
    String? query,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allEntriesResult = await getSortedDiaryEntries();
      if (allEntriesResult.isFailure) {
        return Failure(allEntriesResult.error);
      }

      var filteredEntries = allEntriesResult.value;

      // テキスト検索
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filteredEntries = filteredEntries.where((entry) {
          return entry.title.toLowerCase().contains(lowerQuery) ||
              entry.content.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      // タグ検索
      if (tags != null && tags.isNotEmpty) {
        filteredEntries = filteredEntries.where((entry) {
          if (entry.cachedTags == null) return false;
          return tags.any((tag) => entry.cachedTags!.contains(tag));
        }).toList();
      }

      // 日付範囲検索
      if (startDate != null) {
        filteredEntries = filteredEntries.where((entry) {
          return entry.date.isAfter(startDate) ||
              entry.date.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        filteredEntries = filteredEntries.where((entry) {
          return entry.date.isBefore(endDate) ||
              entry.date.isAtSameMomentAs(endDate);
        }).toList();
      }

      return Success(filteredEntries);
    } catch (e, stackTrace) {
      _loggingService.error('日記検索エラー', error: e, stackTrace: stackTrace);
      return Failure(
        DatabaseException(
          '日記の検索に失敗しました',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 日記をエクスポート
  @override
  Future<Result<String>> exportDiaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final storageService = StorageService.getInstance();
      final result = await storageService.exportData(
        startDate: startDate,
        endDate: endDate,
      );

      if (result != null) {
        return Success(result);
      } else {
        return const Failure(ServiceException('エクスポートに失敗しました'));
      }
    } catch (e, stackTrace) {
      _loggingService.error('日記エクスポートエラー', error: e, stackTrace: stackTrace);
      return Failure(
        ServiceException(
          '日記のエクスポートに失敗しました',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 日記をインポート
  @override
  Future<Result<ImportResult>> importDiaries() async {
    try {
      final storageService = StorageService.getInstance();
      return await storageService.importData();
    } catch (e, stackTrace) {
      _loggingService.error('日記インポートエラー', error: e, stackTrace: stackTrace);
      return Failure(
        ServiceException(
          '日記のインポートに失敗しました',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// AI生成を使用して写真から日記エントリーを作成・保存
  @override
  Future<Result<DiaryEntry>> saveDiaryEntryWithAiGeneration({
    required List<AssetEntity> photos,
    DateTime? date,
    String? location,
    String? prompt,
    Function(String)? onProgress,
  }) async {
    try {
      // 初期化確認
      if (_diaryBox == null) {
        _loggingService.warning('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }

      // PhotoServiceが利用可能かチェック
      if (_photoService == null) {
        return Failure(
          ServiceException(
            'PhotoServiceが利用できません。統合フローを実行するにはPhotoServiceが必要です',
            details: 'createWithDependencies()を使用してPhotoServiceを注入してください',
          ),
        );
      }

      // 日付の設定（未指定の場合は現在時刻）
      final diaryDate = date ?? DateTime.now();

      // 写真の検証
      if (photos.isEmpty) {
        return Failure(
          ValidationException('日記作成には最低1枚の写真が必要です', details: 'photos配列が空です'),
        );
      }

      _loggingService.info(
        'AI日記生成開始: ${photos.length}枚の写真から日記を生成',
        context: 'saveDiaryEntryWithAiGeneration',
      );

      // Phase 1: 写真データの取得
      onProgress?.call('写真データを取得中...');
      final photoDataList = <({Uint8List imageData, DateTime time})>[];

      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        onProgress?.call('写真${i + 1}/${photos.length}を処理中...');

        final photoDataResult = await _photoService.getOriginalFileResult(
          photo,
        );
        if (photoDataResult.isFailure) {
          _loggingService.error(
            '写真データ取得エラー: ${photo.id}',
            error: photoDataResult.error,
          );
          return Failure(photoDataResult.error);
        }

        photoDataList.add((
          imageData: photoDataResult.value,
          time: photo.createDateTime,
        ));
      }

      // Phase 2: AI日記生成
      onProgress?.call('AIが日記を生成中...');
      final Result<DiaryGenerationResult> aiResult;

      if (photos.length == 1) {
        // 単一写真の場合
        aiResult = await _aiService.generateDiaryFromImage(
          imageData: photoDataList.first.imageData,
          date: diaryDate,
          location: location,
          photoTimes: photoDataList.map((p) => p.time).toList(),
          prompt: prompt,
        );
      } else {
        // 複数写真の場合
        aiResult = await _aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: photoDataList,
          location: location,
          prompt: prompt,
          onProgress: (current, total) {
            onProgress?.call('写真$current/$totalを分析中...');
          },
        );
      }

      if (aiResult.isFailure) {
        _loggingService.error('AI日記生成エラー', error: aiResult.error);
        return Failure(aiResult.error);
      }

      final diaryContent = aiResult.value;
      _loggingService.debug(
        'AI日記生成完了: タイトル="${diaryContent.title}", 内容長=${diaryContent.content.length}文字',
      );

      // Phase 3: タグ生成
      onProgress?.call('タグを生成中...');
      final tagsResult = await _aiService.generateTagsFromContent(
        title: diaryContent.title,
        content: diaryContent.content,
        date: diaryDate,
        photoCount: photos.length,
      );

      List<String> generatedTags = [];
      if (tagsResult.isSuccess) {
        generatedTags = tagsResult.value;
        _loggingService.debug('タグ生成完了: ${generatedTags.join(', ')}');
      } else {
        _loggingService.warning('タグ生成失敗、フォールバックタグを使用');
        generatedTags = _generateFallbackTags(
          DiaryEntry(
            id: 'temp',
            date: diaryDate,
            title: diaryContent.title,
            content: diaryContent.content,
            photoIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Phase 4: 日記エントリーの保存
      onProgress?.call('日記を保存中...');
      final photoIds = photos.map((photo) => photo.id).toList();

      final saveResult = await saveDiaryEntry(
        date: diaryDate,
        title: diaryContent.title,
        content: diaryContent.content,
        photoIds: photoIds,
        location: location,
        tags: generatedTags,
      );

      if (saveResult.isSuccess) {
        _loggingService.info(
          'AI日記生成・保存完了: ID=${saveResult.value.id}',
          context: 'saveDiaryEntryWithAiGeneration',
        );
        onProgress?.call('完了');
        return Success(saveResult.value);
      } else {
        return Failure(saveResult.error);
      }
    } catch (e, stackTrace) {
      _loggingService.error('AI日記生成統合フローエラー', error: e, stackTrace: stackTrace);
      return Failure(
        ServiceException(
          'AI日記生成中にエラーが発生しました',
          details: 'photos: ${photos.length}枚, location: $location',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
