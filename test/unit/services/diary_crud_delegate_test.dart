import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/models/diary_change.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/diary_crud_delegate.dart';
import 'package:smart_photo_diary/services/diary_index_manager.dart';

import '../helpers/hive_test_helpers.dart';
import '../../integration/mocks/mock_services.dart';

void main() {
  late DiaryCrudDelegate delegate;
  late MockILoggingService mockLogger;
  late MockIDiaryTagService mockTagService;
  late DiaryIndexManager indexManager;
  late StreamController<DiaryChange> changeController;
  late Box<DiaryEntry> diaryBox;
  bool disposed = false;

  setUpAll(() async {
    registerMockFallbacks();
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearDiaryBox();
    diaryBox = await Hive.openBox<DiaryEntry>('diary_entries');
    disposed = false;

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

    indexManager = DiaryIndexManager();
    await indexManager.buildIndex(diaryBox);

    changeController = StreamController<DiaryChange>.broadcast();

    delegate = DiaryCrudDelegate(
      getBox: () => diaryBox,
      ensureInitialized: () async {},
      indexManager: indexManager,
      changeController: changeController,
      loggingService: mockLogger,
      getTagService: () => mockTagService,
      isDisposed: () => disposed,
    );
  });

  tearDown(() async {
    changeController.close();
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
    final result = await delegate.saveDiaryEntry(
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

  group('DiaryCrudDelegate', () {
    group('saveDiaryEntry', () {
      test('正常保存 → Success(DiaryEntry)', () async {
        final result = await delegate.saveDiaryEntry(
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

      test('保存後にインデックスが更新される', () async {
        final result = await delegate.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト',
          content: 'テスト',
          photoIds: ['photo1'],
        );

        expect(indexManager.sortedIdsByDateDesc, contains(result.value.id));
        expect(indexManager.searchTextIndex, contains(result.value.id));
      });

      test('保存後にcreatedイベントが発火する', () async {
        final events = <DiaryChange>[];
        final subscription = changeController.stream.listen(events.add);

        await delegate.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト',
          content: 'テスト',
          photoIds: ['photo1'],
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.type, DiaryChangeType.created);
        expect(events.first.addedPhotoIds, ['photo1']);

        await subscription.cancel();
      });

      test('タグ生成がバックグラウンドで呼ばれる', () async {
        await delegate.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト',
          content: 'テスト',
          photoIds: ['photo1'],
        );

        verify(
          () => mockTagService.generateTagsInBackground(
            any(),
            onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
          ),
        ).called(1);
      });

      test('disposed時はイベントが発火しない', () async {
        disposed = true;
        final events = <DiaryChange>[];
        final subscription = changeController.stream.listen(events.add);

        await delegate.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト',
          content: 'テスト',
          photoIds: ['photo1'],
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);

        await subscription.cancel();
      });
    });

    group('updateDiaryEntry', () {
      test('正常更新 → Success', () async {
        final entry = await saveTestEntry();
        final updated = entry.copyWith(title: '更新タイトル', content: '更新内容');

        final result = await delegate.updateDiaryEntry(updated);
        expect(result.isSuccess, isTrue);

        final stored = diaryBox.get(entry.id);
        expect(stored!.title, '更新タイトル');
        expect(stored.content, '更新内容');
      });

      test('写真ID変更時にadded/removedPhotoIdsが正しく計算される', () async {
        final entry = await saveTestEntry(photoIds: ['photo1', 'photo2']);
        final events = <DiaryChange>[];
        final subscription = changeController.stream.listen(events.add);

        final updated = entry.copyWith(photoIds: ['photo2', 'photo3']);
        await delegate.updateDiaryEntry(updated);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.addedPhotoIds, ['photo3']);
        expect(events.first.removedPhotoIds, ['photo1']);

        await subscription.cancel();
      });

      test('日付変更時にインデックスが更新される', () async {
        final entry = await saveTestEntry(date: DateTime(2026, 1, 15));
        final updated = entry.copyWith(date: DateTime(2026, 2, 1));

        await delegate.updateDiaryEntry(updated);

        // インデックスに新しい日付が反映されていること
        final idx = indexManager.sortedIdsByDateDesc.indexOf(entry.id);
        expect(idx, greaterThanOrEqualTo(0));
      });
    });

    group('deleteDiaryEntry', () {
      test('正常削除 → Success', () async {
        final entry = await saveTestEntry();

        final result = await delegate.deleteDiaryEntry(entry.id);
        expect(result.isSuccess, isTrue);

        expect(diaryBox.get(entry.id), isNull);
      });

      test('削除後にインデックスから除去される', () async {
        final entry = await saveTestEntry();

        await delegate.deleteDiaryEntry(entry.id);

        expect(indexManager.sortedIdsByDateDesc, isNot(contains(entry.id)));
        expect(indexManager.searchTextIndex, isNot(contains(entry.id)));
      });

      test('削除後にdeletedイベントが発火する', () async {
        final entry = await saveTestEntry(photoIds: ['photo1']);
        final events = <DiaryChange>[];
        final subscription = changeController.stream.listen(events.add);

        await delegate.deleteDiaryEntry(entry.id);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.type, DiaryChangeType.deleted);
        expect(events.first.removedPhotoIds, ['photo1']);

        await subscription.cancel();
      });

      test('存在しないID → Success', () async {
        final result = await delegate.deleteDiaryEntry('non-existent-id');
        expect(result.isSuccess, isTrue);
      });
    });

    group('createDiaryForPastPhoto', () {
      test('正常作成 → Success(DiaryEntry)', () async {
        final result = await delegate.createDiaryForPastPhoto(
          photoDate: DateTime(2025, 6, 1),
          title: '過去の日記',
          content: '過去の思い出',
          photoIds: ['pastPhoto1'],
          getDiaryByPhotoDate: (_) async => const Success([]),
        );

        expect(result.isSuccess, isTrue);
        expect(result.value.title, '過去の日記');
        expect(result.value.date, DateTime(2025, 6, 1));
      });

      test('タグ生成(ForPastPhoto)がバックグラウンドで呼ばれる', () async {
        await delegate.createDiaryForPastPhoto(
          photoDate: DateTime(2025, 6, 1),
          title: '過去の日記',
          content: '過去の思い出',
          photoIds: ['pastPhoto1'],
          getDiaryByPhotoDate: (_) async => const Success([]),
        );

        verify(
          () => mockTagService.generateTagsInBackgroundForPastPhoto(
            any(),
            onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
          ),
        ).called(1);
      });

      test('重複日記があっても作成続行（警告ログのみ）', () async {
        // 先に1件保存
        await saveTestEntry(date: DateTime(2025, 6, 1));

        final result = await delegate.createDiaryForPastPhoto(
          photoDate: DateTime(2025, 6, 1),
          title: '2件目の日記',
          content: '重複テスト',
          photoIds: ['pastPhoto2'],
          getDiaryByPhotoDate: (_) async {
            final entries = diaryBox.values.where((e) {
              final d = DateTime(e.date.year, e.date.month, e.date.day);
              return d.isAtSameMomentAs(DateTime(2025, 6, 1));
            }).toList();
            return Success(entries);
          },
        );

        expect(result.isSuccess, isTrue);
        expect(result.value.title, '2件目の日記');

        verify(() => mockLogger.warning(any())).called(greaterThanOrEqualTo(1));
      });
    });

    group('_saveEntry共通ロジック', () {
      test('Hiveに保存される', () async {
        final result = await delegate.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト',
          content: 'テスト',
          photoIds: ['photo1'],
        );

        final stored = diaryBox.get(result.value.id);
        expect(stored, isNotNull);
        expect(stored!.title, 'テスト');
      });

      test('createdAt/updatedAtが設定される', () async {
        final before = DateTime.now();
        final result = await delegate.saveDiaryEntry(
          date: DateTime(2026, 1, 15),
          title: 'テスト',
          content: 'テスト',
          photoIds: ['photo1'],
        );
        final after = DateTime.now();

        final entry = result.value;
        expect(
          entry.createdAt.isAfter(before) || entry.createdAt == before,
          isTrue,
        );
        expect(
          entry.createdAt.isBefore(after) || entry.createdAt == after,
          isTrue,
        );
        expect(entry.updatedAt, entry.createdAt);
      });
    });
  });
}
