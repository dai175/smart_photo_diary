import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';

class DiaryService {
  static const String _boxName = 'diary_entries';
  static DiaryService? _instance;
  late Box<DiaryEntry> _diaryBox;
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
    _diaryBox = await Hive.openBox<DiaryEntry>(_boxName);
  }

  // 日記エントリーを保存
  Future<DiaryEntry> saveDiaryEntry({
    required DateTime date,
    required String content,
    required List<AssetEntity> photos,
  }) async {
    // 写真のIDリストを作成
    final List<String> photoIds = photos.map((photo) => photo.id).toList();

    // 新しい日記エントリーを作成
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: _uuid.v4(),
      date: date,
      content: content,
      photoIds: photoIds,
      createdAt: now,
      updatedAt: now,
    );

    // Hiveに保存
    await _diaryBox.put(entry.id, entry);

    return entry;
  }

  // 日記エントリーを更新
  Future<void> updateDiaryEntry({required String id, String? content}) async {
    final entry = _diaryBox.get(id);
    if (entry != null && content != null) {
      entry.updateContent(content);
    }
  }

  // 日記エントリーを削除
  Future<void> deleteDiaryEntry(String id) async {
    await _diaryBox.delete(id);
  }

  // すべての日記エントリーを取得
  List<DiaryEntry> getAllDiaryEntries() {
    return _diaryBox.values.toList();
  }

  // 日付でソートされた日記エントリーを取得
  List<DiaryEntry> getSortedDiaryEntries({bool descending = true}) {
    final entries = getAllDiaryEntries();
    entries.sort(
      (a, b) =>
          descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return entries;
  }

  // 特定の日付の日記エントリーを取得
  List<DiaryEntry> getDiaryEntriesByDate(DateTime date) {
    return _diaryBox.values
        .where(
          (entry) =>
              entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day,
        )
        .toList();
  }

  // 特定の月の日記エントリーを取得
  List<DiaryEntry> getDiaryEntriesByMonth(int year, int month) {
    return _diaryBox.values
        .where((entry) => entry.date.year == year && entry.date.month == month)
        .toList();
  }

  // IDで日記エントリーを取得
  DiaryEntry? getDiaryEntryById(String id) {
    return _diaryBox.get(id);
  }
}
