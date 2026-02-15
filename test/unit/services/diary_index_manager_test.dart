import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_index_manager.dart';
import '../helpers/hive_test_helpers.dart';

void main() {
  late DiaryIndexManager indexManager;
  late Box<DiaryEntry> diaryBox;

  DiaryEntry createEntry({
    required String id,
    required DateTime date,
    String title = 'Test Title',
    String content = 'Test Content',
    List<String>? tags,
    String? location,
    List<String>? legacyTags,
  }) {
    return DiaryEntry(
      id: id,
      date: date,
      title: title,
      content: content,
      photoIds: ['photo1'],
      createdAt: date,
      updatedAt: date,
      tags: tags,
      location: location,
      legacyTags: legacyTags,
    );
  }

  setUpAll(() async {
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearDiaryBox();
    diaryBox = await Hive.openBox<DiaryEntry>('diary_entries');
    indexManager = DiaryIndexManager();
  });

  tearDown(() async {
    if (diaryBox.isOpen) {
      await diaryBox.close();
    }
  });

  tearDownAll(() async {
    await HiveTestHelpers.closeHive();
  });

  group('buildIndex', () {
    test('空のBoxでインデックス構築 → リスト空、indexBuilt=true', () async {
      await indexManager.buildIndex(diaryBox);

      expect(indexManager.sortedIdsByDateDesc, isEmpty);
      expect(indexManager.sortedDatesByDayDesc, isEmpty);
      expect(indexManager.searchTextIndex, isEmpty);
      expect(indexManager.indexBuilt, isTrue);
    });

    test('複数エントリーのBoxで構築 → 日付降順にソート', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 3, 1));
      final entry3 = createEntry(id: 'c', date: DateTime(2025, 2, 1));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);
      await diaryBox.put('c', entry3);

      await indexManager.buildIndex(diaryBox);

      // 降順: b(3/1), c(2/1), a(1/1)
      expect(indexManager.sortedIdsByDateDesc, ['b', 'c', 'a']);
    });

    test('構築後にsearchTextIndexが全エントリー分作られる', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 2, 1));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);

      await indexManager.buildIndex(diaryBox);

      expect(indexManager.searchTextIndex.length, 2);
      expect(indexManager.searchTextIndex.containsKey('a'), isTrue);
      expect(indexManager.searchTextIndex.containsKey('b'), isTrue);
    });

    test('sortedDatesByDayDescが時刻なしの日付のみ保持する', () async {
      final entry = createEntry(
        id: 'a',
        date: DateTime(2025, 3, 15, 14, 30, 45),
      );
      await diaryBox.put('a', entry);

      await indexManager.buildIndex(diaryBox);

      expect(indexManager.sortedDatesByDayDesc.first, DateTime(2025, 3, 15));
    });
  });

  group('ensureIndex', () {
    test('indexBuilt=false → buildIndexを実行', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);

      expect(indexManager.indexBuilt, isFalse);
      await indexManager.ensureIndex(diaryBox);
      expect(indexManager.indexBuilt, isTrue);
      expect(indexManager.sortedIdsByDateDesc, ['a']);
    });

    test('indexBuilt=true → 再構築しない', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);

      await indexManager.buildIndex(diaryBox);
      expect(indexManager.sortedIdsByDateDesc, ['a']);

      // 新しいエントリーを追加しても再構築しない
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 2, 1));
      await diaryBox.put('b', entry2);

      await indexManager.ensureIndex(diaryBox);
      // buildIndexが再実行されないのでbは含まれない
      expect(indexManager.sortedIdsByDateDesc, ['a']);
    });
  });

  group('findInsertIndex', () {
    test('空リスト → 0を返す', () async {
      await indexManager.buildIndex(diaryBox);
      final idx = indexManager.findInsertIndex(diaryBox, DateTime(2025, 1, 1));
      expect(idx, 0);
    });

    test('最新日付より新しい → 0を返す', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);
      await indexManager.buildIndex(diaryBox);

      final idx = indexManager.findInsertIndex(diaryBox, DateTime(2025, 6, 1));
      expect(idx, 0);
    });

    test('最古日付より古い → リスト末尾を返す', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 6, 1));
      await diaryBox.put('a', entry);
      await indexManager.buildIndex(diaryBox);

      final idx = indexManager.findInsertIndex(diaryBox, DateTime(2025, 1, 1));
      expect(idx, 1);
    });

    test('中間の日付 → 正しい挿入位置を返す', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 3, 1));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);
      await indexManager.buildIndex(diaryBox);

      // 降順: b(3/1), a(1/1)
      final idx = indexManager.findInsertIndex(diaryBox, DateTime(2025, 2, 1));
      expect(idx, 1); // b と a の間
    });
  });

  group('findRangeByDateRange', () {
    test('空リスト → [0, 0]', () async {
      await indexManager.buildIndex(diaryBox);
      final range = indexManager.findRangeByDateRange(
        DateTime(2025, 1, 1),
        DateTime(2025, 12, 31),
      );
      expect(range, [0, 0]);
    });

    test('全エントリーが範囲内 → [0, length]', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 15));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 2, 15));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);
      await indexManager.buildIndex(diaryBox);

      final range = indexManager.findRangeByDateRange(
        DateTime(2025, 1, 1),
        DateTime(2025, 3, 1),
      );
      expect(range, [0, 2]);
    });

    test('範囲外のエントリーのみ → 空範囲', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 6, 15));
      await diaryBox.put('a', entry);
      await indexManager.buildIndex(diaryBox);

      final range = indexManager.findRangeByDateRange(
        DateTime(2025, 1, 1),
        DateTime(2025, 3, 1),
      );
      expect(range[0], range[1]); // 空範囲
    });

    test('部分一致 → 正しいstart/endインデックス', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 15));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 2, 15));
      final entry3 = createEntry(id: 'c', date: DateTime(2025, 3, 15));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);
      await diaryBox.put('c', entry3);
      await indexManager.buildIndex(diaryBox);

      // 降順: c(3/15), b(2/15), a(1/15)
      // 2月のみを検索
      final range = indexManager.findRangeByDateRange(
        DateTime(2025, 2, 1),
        DateTime(2025, 2, 28),
      );
      expect(range[1] - range[0], 1); // 1エントリーのみ
    });
  });

  group('buildSearchableText', () {
    test('タイトル+本文+タグ+場所を結合して小文字化', () {
      final entry = createEntry(
        id: 'a',
        date: DateTime(2025, 1, 1),
        title: 'My Title',
        content: 'My Content',
        tags: ['Tag1', 'Tag2'],
        location: 'Tokyo',
      );

      final text = indexManager.buildSearchableText(entry);
      expect(text, contains('my title'));
      expect(text, contains('my content'));
      expect(text, contains('tag1'));
      expect(text, contains('tag2'));
      expect(text, contains('tokyo'));
    });

    test('locationがnull → 空文字で結合', () {
      final entry = createEntry(
        id: 'a',
        date: DateTime(2025, 1, 1),
        title: 'Title',
        content: 'Content',
      );

      final text = indexManager.buildSearchableText(entry);
      expect(text, contains('title'));
      expect(text, contains('content'));
    });

    test('tagsが空 → タグ部分空', () {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1), tags: []);

      final text = indexManager.buildSearchableText(entry);
      expect(text, isNotEmpty);
    });

    test('legacyTags経由のeffectiveTagsが含まれる', () {
      final entry = createEntry(
        id: 'a',
        date: DateTime(2025, 1, 1),
        legacyTags: ['LegacyTag'],
      );

      final text = indexManager.buildSearchableText(entry);
      expect(text, contains('legacytag'));
    });
  });

  group('updateSearchIndex', () {
    test('IDに対応する検索テキストを更新', () {
      indexManager.updateSearchIndex('a', 'new search text');
      expect(indexManager.searchTextIndex['a'], 'new search text');
    });
  });

  group('insertEntry', () {
    test('空インデックスに挿入 → 先頭に追加', () async {
      await indexManager.buildIndex(diaryBox);
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);

      indexManager.insertEntry(diaryBox, entry);

      expect(indexManager.sortedIdsByDateDesc, ['a']);
      expect(indexManager.searchTextIndex.containsKey('a'), isTrue);
    });

    test('正しい降順位置に挿入', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 3, 1));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);
      await indexManager.buildIndex(diaryBox);

      // 降順: b(3/1), a(1/1)
      final entry3 = createEntry(id: 'c', date: DateTime(2025, 2, 1));
      await diaryBox.put('c', entry3);
      indexManager.insertEntry(diaryBox, entry3);

      // 降順: b(3/1), c(2/1), a(1/1)
      expect(indexManager.sortedIdsByDateDesc, ['b', 'c', 'a']);
    });
  });

  group('updateEntryDate', () {
    test('既存エントリーの日付変更 → 旧位置削除・新位置挿入', () async {
      final entry1 = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      final entry2 = createEntry(id: 'b', date: DateTime(2025, 3, 1));
      await diaryBox.put('a', entry1);
      await diaryBox.put('b', entry2);
      await indexManager.buildIndex(diaryBox);

      // 降順: b(3/1), a(1/1)
      // aの日付を4/1に変更
      final updatedEntry = createEntry(id: 'a', date: DateTime(2025, 4, 1));
      await diaryBox.put('a', updatedEntry);
      indexManager.updateEntryDate(diaryBox, updatedEntry);

      // 降順: a(4/1), b(3/1)
      expect(indexManager.sortedIdsByDateDesc, ['a', 'b']);
    });

    test('存在しないIDの場合 → 新規挿入のみ', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);
      await indexManager.buildIndex(diaryBox);

      final newEntry = createEntry(id: 'x', date: DateTime(2025, 6, 1));
      await diaryBox.put('x', newEntry);
      indexManager.updateEntryDate(diaryBox, newEntry);

      expect(indexManager.sortedIdsByDateDesc.contains('x'), isTrue);
    });
  });

  group('removeEntry', () {
    test('存在するID → インデックスとsearchTextから削除', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);
      await indexManager.buildIndex(diaryBox);

      expect(indexManager.sortedIdsByDateDesc, ['a']);
      expect(indexManager.searchTextIndex.containsKey('a'), isTrue);

      indexManager.removeEntry('a');

      expect(indexManager.sortedIdsByDateDesc, isEmpty);
      expect(indexManager.searchTextIndex.containsKey('a'), isFalse);
    });

    test('存在しないID → 何も変わらない', () async {
      final entry = createEntry(id: 'a', date: DateTime(2025, 1, 1));
      await diaryBox.put('a', entry);
      await indexManager.buildIndex(diaryBox);

      indexManager.removeEntry('nonexistent');

      expect(indexManager.sortedIdsByDateDesc, ['a']);
      expect(indexManager.searchTextIndex.containsKey('a'), isTrue);
    });
  });
}
