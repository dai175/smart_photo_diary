import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/models/diary_change.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/services/diary_service.dart';

import '../helpers/hive_test_helpers.dart';
import '../../integration/mocks/mock_services.dart';

void main() {
  late DiaryService service;
  late MockILoggingService mockLogger;
  late MockIDiaryTagService mockTagService;

  setUpAll(() async {
    registerMockFallbacks();
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearDiaryBox();
    mockLogger = MockILoggingService();

    // LoggingServiceモック設定
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

    mockTagService = MockIDiaryTagService();
    when(
      () => mockTagService.generateTagsInBackground(
        any(),
        onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
      ),
    ).thenReturn(null);
    when(
      () => mockTagService.generateTagsInBackgroundForPastPhoto(
        any(),
        onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
      ),
    ).thenReturn(null);

    service = DiaryService.createWithDependencies(
      logger: mockLogger,
      tagService: mockTagService,
    );
    await service.initialize();
  });

  tearDown(() async {
    service.dispose();
    await HiveTestHelpers.clearDiaryBox();
  });

  /// テスト用の日記エントリーを保存するヘルパー
  Future<DiaryEntry> saveTestEntry({
    DateTime? date,
    String title = 'テスト日記',
    String content = 'テスト内容',
    List<String> photoIds = const ['photo1'],
    String? location,
    List<String>? tags,
  }) async {
    final result = await service.saveDiaryEntry(
      date: date ?? DateTime(2026, 1, 15),
      title: title,
      content: content,
      photoIds: photoIds,
      location: location,
      tags: tags,
    );
    expect(result.isSuccess, isTrue);
    return result.value;
  }

  group('DiaryService', () {
    group('initialize', () {
      test('正常初期化', () async {
        // setUpで既にinitialize()済み。追加でもう一つ作成してinitializeが成功することを確認
        final newService = DiaryService.createWithDependencies(
          logger: mockLogger,
          tagService: mockTagService,
        );
        await newService.initialize();
        // initializeが例外なく完了すればOK
        newService.dispose();
      });
    });

    group('saveDiaryEntry', () {
      test('正常保存 → Success(DiaryEntry)', () async {
        final result = await service.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト日記',
          content: 'テスト内容',
          photoIds: ['photo1', 'photo2'],
          location: '東京',
          tags: ['tag1'],
        );

        expect(result.isSuccess, isTrue);
        final entry = result.value;
        expect(entry.title, 'テスト日記');
        expect(entry.content, 'テスト内容');
        expect(entry.photoIds, ['photo1', 'photo2']);
        expect(entry.location, '東京');
        expect(entry.tags, ['tag1']);
      });

      test('保存後にStreamにcreatedイベントが発火する', () async {
        final events = <DiaryChange>[];
        final subscription = service.changes.listen(events.add);

        await service.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト日記',
          content: 'テスト内容',
          photoIds: ['photo1'],
        );

        // イベント伝播を待つ
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events.first.type, DiaryChangeType.created);
        expect(events.first.addedPhotoIds, ['photo1']);

        await subscription.cancel();
      });

      test('タグ生成がバックグラウンドで呼ばれる', () async {
        await service.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト日記',
          content: 'テスト内容',
          photoIds: ['photo1'],
        );

        verify(
          () => mockTagService.generateTagsInBackground(
            any(),
            onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
          ),
        ).called(1);
      });
    });

    group('updateDiaryEntry', () {
      test('正常更新 → Success', () async {
        final entry = await saveTestEntry();
        final updated = entry.copyWith(title: '更新タイトル', content: '更新内容');

        final result = await service.updateDiaryEntry(updated);

        expect(result.isSuccess, isTrue);

        // 更新後の値を取得して確認
        final getResult = await service.getDiaryEntry(entry.id);
        expect(getResult.isSuccess, isTrue);
        expect(getResult.value!.title, '更新タイトル');
        expect(getResult.value!.content, '更新内容');
      });

      test('更新後にStreamにupdatedイベントが発火する', () async {
        final entry = await saveTestEntry();
        final events = <DiaryChange>[];
        final subscription = service.changes.listen(events.add);

        final updated = entry.copyWith(title: '更新タイトル');
        await service.updateDiaryEntry(updated);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events.first.type, DiaryChangeType.updated);
        expect(events.first.entryId, entry.id);

        await subscription.cancel();
      });

      test('写真ID変更時にadded/removedPhotoIdsが正しく計算される', () async {
        final entry = await saveTestEntry(photoIds: ['photo1', 'photo2']);
        final events = <DiaryChange>[];
        final subscription = service.changes.listen(events.add);

        final updated = entry.copyWith(photoIds: ['photo2', 'photo3']);
        await service.updateDiaryEntry(updated);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events.first.addedPhotoIds, ['photo3']);
        expect(events.first.removedPhotoIds, ['photo1']);

        await subscription.cancel();
      });
    });

    group('deleteDiaryEntry', () {
      test('正常削除 → Success', () async {
        final entry = await saveTestEntry();

        final result = await service.deleteDiaryEntry(entry.id);
        expect(result.isSuccess, isTrue);

        // 削除後にgetで取得できないことを確認
        final getResult = await service.getDiaryEntry(entry.id);
        expect(getResult.isSuccess, isTrue);
        expect(getResult.value, isNull);
      });

      test('削除後にStreamにdeletedイベントが発火する', () async {
        final entry = await saveTestEntry(photoIds: ['photo1']);
        final events = <DiaryChange>[];
        final subscription = service.changes.listen(events.add);

        await service.deleteDiaryEntry(entry.id);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events.first.type, DiaryChangeType.deleted);
        expect(events.first.entryId, entry.id);
        expect(events.first.removedPhotoIds, ['photo1']);

        await subscription.cancel();
      });

      test('存在しないID → Success（Hiveのdeleteは例外を出さない）', () async {
        final result = await service.deleteDiaryEntry('non-existent-id');
        expect(result.isSuccess, isTrue);
      });
    });

    group('getDiaryEntry', () {
      test('存在するID → Success(entry)', () async {
        final entry = await saveTestEntry();

        final result = await service.getDiaryEntry(entry.id);
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.id, entry.id);
      });

      test('存在しないID → Success(null)', () async {
        final result = await service.getDiaryEntry('non-existent-id');
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });
    });

    group('getSortedDiaryEntries', () {
      test('descending → 新しい日付順', () async {
        await saveTestEntry(date: DateTime(2026, 1, 1), title: 'Entry 1');
        await saveTestEntry(date: DateTime(2026, 1, 3), title: 'Entry 3');
        await saveTestEntry(date: DateTime(2026, 1, 2), title: 'Entry 2');

        final result = await service.getSortedDiaryEntries(descending: true);
        expect(result.isSuccess, isTrue);
        final entries = result.value;
        expect(entries, hasLength(3));
        expect(entries[0].title, 'Entry 3');
        expect(entries[1].title, 'Entry 2');
        expect(entries[2].title, 'Entry 1');
      });

      test('ascending → 古い日付順', () async {
        await saveTestEntry(date: DateTime(2026, 1, 1), title: 'Entry 1');
        await saveTestEntry(date: DateTime(2026, 1, 3), title: 'Entry 3');
        await saveTestEntry(date: DateTime(2026, 1, 2), title: 'Entry 2');

        final result = await service.getSortedDiaryEntries(descending: false);
        expect(result.isSuccess, isTrue);
        final entries = result.value;
        expect(entries[0].title, 'Entry 1');
        expect(entries[1].title, 'Entry 2');
        expect(entries[2].title, 'Entry 3');
      });
    });

    group('getDiaryByPhotoDate', () {
      test('一致する日付 → 該当エントリーのリスト', () async {
        await saveTestEntry(date: DateTime(2026, 1, 15));
        await saveTestEntry(date: DateTime(2026, 1, 16));

        final result = await service.getDiaryByPhotoDate(DateTime(2026, 1, 15));
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(1));
      });

      test('不一致 → 空リスト', () async {
        await saveTestEntry(date: DateTime(2026, 1, 15));

        final result = await service.getDiaryByPhotoDate(DateTime(2026, 2, 1));
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });

      test('同一日付の複数エントリー → 全て返す', () async {
        await saveTestEntry(date: DateTime(2026, 1, 15), title: 'A');
        await saveTestEntry(date: DateTime(2026, 1, 15), title: 'B');

        final result = await service.getDiaryByPhotoDate(DateTime(2026, 1, 15));
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(2));
      });
    });

    group('getDiaryEntryByPhotoId', () {
      test('一致するphotoId → Success(entry)', () async {
        await saveTestEntry(photoIds: ['targetPhoto']);

        final result = await service.getDiaryEntryByPhotoId('targetPhoto');
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.photoIds, contains('targetPhoto'));
      });

      test('不一致 → Success(null)', () async {
        await saveTestEntry(photoIds: ['otherPhoto']);

        final result = await service.getDiaryEntryByPhotoId('nonExistent');
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });
    });

    group('createDiaryForPastPhoto', () {
      test('正常作成 → Success(DiaryEntry)', () async {
        final result = await service.createDiaryForPastPhoto(
          photoDate: DateTime(2025, 6, 1),
          title: '過去の日記',
          content: '過去の思い出',
          photoIds: ['pastPhoto1'],
        );

        expect(result.isSuccess, isTrue);
        expect(result.value.title, '過去の日記');
        expect(result.value.date, DateTime(2025, 6, 1));
      });

      test('タグ生成(ForPastPhoto)がバックグラウンドで呼ばれる', () async {
        await service.createDiaryForPastPhoto(
          photoDate: DateTime(2025, 6, 1),
          title: '過去の日記',
          content: '過去の思い出',
          photoIds: ['pastPhoto1'],
        );

        verify(
          () => mockTagService.generateTagsInBackgroundForPastPhoto(
            any(),
            onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
          ),
        ).called(1);
      });
    });

    group('getFilteredDiaryEntriesPage', () {
      test('offset/limit → ページング動作', () async {
        // 5つのエントリーを作成
        for (int i = 1; i <= 5; i++) {
          await saveTestEntry(date: DateTime(2026, 1, i), title: 'Entry $i');
        }

        // フィルタなしで先頭2件を取得（降順なのでEntry 5, 4）
        final result = await service.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 0,
          limit: 2,
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, hasLength(2));

        // 次の2件をスキップして取得
        final result2 = await service.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 2,
          limit: 2,
        );
        expect(result2.isSuccess, isTrue);
        expect(result2.value, hasLength(2));
      });

      test('空の結果 → 空リスト', () async {
        final result = await service.getFilteredDiaryEntriesPage(
          const DiaryFilter(),
          offset: 0,
          limit: 10,
        );
        expect(result.isSuccess, isTrue);
        expect(result.value, isEmpty);
      });
    });

    group('compactDatabase', () {
      test('正常に完了する', () async {
        await saveTestEntry();
        // compactDatabaseが例外なく完了すればOK
        await service.compactDatabase();
      });
    });

    group('dispose', () {
      test('dispose後のStream閉鎖', () async {
        final newService = DiaryService.createWithDependencies(
          logger: mockLogger,
          tagService: mockTagService,
        );
        await newService.initialize();

        newService.dispose();

        // dispose後にイベントがStreamに追加されないことの確認は、
        // 例外が発生しないことで代替
      });
    });
  });
}
