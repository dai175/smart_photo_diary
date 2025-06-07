import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';

class DiaryService {
  static const String _boxName = 'diary_entries';
  static DiaryService? _instance;
  Box<DiaryEntry>? _diaryBox;
  final _uuid = const Uuid();

  // シングルトンパターン
  DiaryService._();

  static Future<DiaryService> getInstance() async {
    if (_instance == null) {
      _instance = DiaryService._();
      await _instance!._init();
    }
    return _instance!;
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
  Future<DiaryEntry> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  }) async {
    try {
      // _diaryBoxが初期化されているかチェック
      if (_diaryBox == null) {
        debugPrint('_diaryBoxが未初期化です。再初期化します...');
        await _init();
      }
      
      // 写真のIDリストを作成
      final List<String> photoIds = photos.map((photo) => photo.id).toList();

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
        createdAt: now,
        updatedAt: now,
      );

      debugPrint('Hiveに保存中...');
      // Hiveに保存
      await _diaryBox!.put(entry.id, entry);
      debugPrint('Hive保存完了');

      return entry;
    } catch (e, stackTrace) {
      debugPrint('日記保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  // 日記エントリーを更新
  Future<void> updateDiaryEntry({
    required String id, 
    String? title, 
    String? content
  }) async {
    if (_diaryBox == null) await _init();
    
    final entry = _diaryBox!.get(id);
    if (entry != null && (title != null || content != null)) {
      entry.updateContent(
        title ?? entry.title, 
        content ?? entry.content
      );
    }
  }

  // 日記エントリーを削除
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
  Future<List<DiaryEntry>> getSortedDiaryEntries({bool descending = true}) async {
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
  Future<DiaryEntry?> getDiaryEntryById(String id) async {
    if (_diaryBox == null) await _init();
    return _diaryBox!.get(id);
  }
}
