import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/services/diary_query_delegate.dart';
import 'package:smart_photo_diary/services/diary_index_manager.dart';

import '../helpers/hive_test_helpers.dart';
import '../../integration/mocks/mock_services.dart';

void main() {
  late DiaryQueryDelegate delegate;
  late MockILoggingService mockLogger;
  late DiaryIndexManager indexManager;
  late Box<DiaryEntry> diaryBox;
  int nextId = 0;

  setUpAll(() async {
    registerMockFallbacks();
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearDiaryBox();
    diaryBox = await Hive.openBox<DiaryEntry>('diary_entries');
    nextId = 0;

    mockLogger = MockILoggingService();
    when(
      () => mockLogger.debug(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.info(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.warning(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        context: any(named: 'context'),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);

    indexManager = DiaryIndexManager();

    delegate = DiaryQueryDelegate(
      getBox: () => diaryBox,
      ensureInitialized: () async {},
      indexManager: indexManager,
      loggingService: mockLogger,
    );
  });

  tearDown(() async {
    await HiveTestHelpers.clearDiaryBox();
  });

  /// テスト用の日記エントリーを直接Hiveに保存するヘルパー
  Future<DiaryEntry> addTestEntry({
    DateTime? date,
    String title = 'テスト日記',
    String content = 'テスト内容',
    List<String> photoIds = const ['photo1'],
    String? location,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final id = 'test-id-${nextId++}';
    final entry = DiaryEntry(
      id: id,
      date: date ?? DateTime(2026, 1, 15),
      title: title,
      content: content,
      photoIds: photoIds,
      location: location,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    await diaryBox.put(entry.id, entry);
    // インデックスを再構築
    await indexManager.buildIndex(diaryBox);
    return entry;
  }

  group('DiaryQueryDelegate', () {
    group('getSortedDiaryEntries', () {
      test('descending → 新しい日付順', () async {
        await addTestEntry(date: DateTime(2026, 1, 1), title: 'Entry 1');
        await addTestEntry(date: DateTime(2026, 1, 3), title: 'Entry 3');
        await addTestEntry(date: DateTime(2026, 1, 2), title: 'Entry 2');

        final result = await delegate.getSortedDiaryEntries(descending: true);
        expect(result.isSuccess, isTrue);
        final entries = result.value;
        expect(entries, hasLength(3));
        expect(entries[0].title, 'Entry 3');
        expect(entries[1].title, 'Entry 2');
        expect(entries[2].title, 'Entry 1');
      });

      test('ascending → 古い日付順', () async {
        await addTestEntry(date: DateTime(2026, 1, 1), title: 'Entry 1');
        await addTestEntry(date: DateTime(2026, 1, 3), title: 'Entry 3');
        await addTestEntry(date: DateTime(2026, 1, 2), title: 'Entry 2');

        final result = await delegate.getSortedDiaryEntries(descending: false);
        expect(result.isSuccess, isTrue);
        final entries = result.value;
        expect(entries[0].title, 'Entry 1');
        expect(entries[1].title, 'Entry 2');
        expect(entries[2].title, 'Entry 3');
      });

      test('空の場合 → 空リスト', () async {
        final result = await delegate.getSortedDiaryEntries();
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });
    });

    group('getDiaryEntry', () {
      test('存在するID → Success(entry)', () async {
        final entry = await addTestEntry();

        final result = await delegate.getDiaryEntry(entry.id);
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.id, entry.id);
      });

      test('存在しないID → Success(null)', () async {
        final result = await delegate.getDiaryEntry('non-existent-id');
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });
    });

    group('getFilteredDiaryEntries', () {
      test('フィルタなし → 全件（日付降順）', () async {
        await addTestEntry(date: DateTime(2026, 1, 1), title: 'Entry 1');
        await addTestEntry(date: DateTime(2026, 1, 3), title: 'Entry 3');
        await addTestEntry(date: DateTime(2026, 1, 2), title: 'Entry 2');

        final result = await delegate.getFilteredDiaryEntries(
          const DiaryFilter(),
        );
        expect(result.isSuccess, isTrue);
        final entries = result.value;
        expect(entries, hasLength(3));
        // インデックス順（降順）
        expect(entries[0].title, 'Entry 3');
        expect(entries[1].title, 'Entry 2');
        expect(entries[2].title, 'Entry 1');
      });

      test('テキスト検索 → 一致するエントリーのみ', () async {
        await addTestEntry(title: '晴れの日', content: '公園で遊んだ');
        await addTestEntry(title: '雨の日', content: '家で過ごした');

        final result = await delegate.getFilteredDiaryEntries(
          const DiaryFilter(searchText: '公園'),
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(1));
        expect(result.value.first.title, '晴れの日');
      });
    });

    group('getFilteredDiaryEntriesPage', () {
      test('offset/limit → ページング動作', () async {
        for (int i = 1; i <= 5; i++) {
          await addTestEntry(date: DateTime(2026, 1, i), title: 'Entry $i');
        }

        final result = await delegate.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 0,
          limit: 2,
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(2));

        final result2 = await delegate.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 2,
          limit: 2,
        );
        expect(result2.isSuccess, isTrue);
        expect(result2.value, hasLength(2));

        // 最後のページ
        final result3 = await delegate.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 4,
          limit: 2,
        );
        expect(result3.isSuccess, isTrue);
        expect(result3.value, hasLength(1));
      });

      test('空の結果 → 空リスト', () async {
        final result = await delegate.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 0,
          limit: 10,
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });
    });

    group('getDiaryByPhotoDate', () {
      test('一致する日付 → 該当エントリーのリスト', () async {
        await addTestEntry(date: DateTime(2026, 1, 15));
        await addTestEntry(date: DateTime(2026, 1, 16));

        final result = await delegate.getDiaryByPhotoDate(
          DateTime(2026, 1, 15),
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(1));
      });

      test('不一致 → 空リスト', () async {
        await addTestEntry(date: DateTime(2026, 1, 15));

        final result = await delegate.getDiaryByPhotoDate(DateTime(2026, 2, 1));
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });

      test('同一日付の複数エントリー → 全て返す', () async {
        await addTestEntry(date: DateTime(2026, 1, 15), title: 'A');
        await addTestEntry(date: DateTime(2026, 1, 15), title: 'B');

        final result = await delegate.getDiaryByPhotoDate(
          DateTime(2026, 1, 15),
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(2));
      });
    });

    group('getDiaryEntryByPhotoId', () {
      test('一致するphotoId → Success(entry)', () async {
        await addTestEntry(photoIds: ['targetPhoto']);

        final result = await delegate.getDiaryEntryByPhotoId('targetPhoto');
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.photoIds, contains('targetPhoto'));
      });

      test('不一致 → Success(null)', () async {
        await addTestEntry(photoIds: ['otherPhoto']);

        final result = await delegate.getDiaryEntryByPhotoId('nonExistent');
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });
    });
  });
}
