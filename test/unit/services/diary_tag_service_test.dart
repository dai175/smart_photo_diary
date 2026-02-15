import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_tag_service.dart';
import 'package:smart_photo_diary/services/interfaces/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../helpers/hive_test_helpers.dart';

class MockAiService extends Mock implements IAiService {}

class MockLoggingService extends Mock implements ILoggingService {}

class FakeLocale extends Fake implements Locale {}

void main() {
  late DiaryTagService tagService;
  late MockAiService mockAiService;
  late MockLoggingService mockLogger;
  late Box<DiaryEntry> diaryBox;

  setUpAll(() async {
    await HiveTestHelpers.setupHiveForTesting();
    registerFallbackValue(FakeLocale());
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    await HiveTestHelpers.clearDiaryBox();
    mockAiService = MockAiService();
    mockLogger = MockLoggingService();
    diaryBox = await Hive.openBox<DiaryEntry>('diary_entries');
    tagService = DiaryTagService(aiService: mockAiService, logger: mockLogger);
  });

  tearDown(() async {
    if (diaryBox.isOpen) {
      await diaryBox.close();
    }
  });

  tearDownAll(() async {
    await HiveTestHelpers.closeHive();
  });

  DiaryEntry createEntry({
    required String id,
    DateTime? date,
    String title = 'Test Title',
    String content = 'Test Content',
    List<String>? tags,
    DateTime? tagsGeneratedAt,
  }) {
    return DiaryEntry(
      id: id,
      date: date ?? DateTime.now(),
      title: title,
      content: content,
      photoIds: ['photo_1'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
      tagsGeneratedAt: tagsGeneratedAt,
    );
  }

  group('getTagsForEntry', () {
    test('キャッシュ有効時はキャッシュを返す（AI呼び出しなし）', () async {
      final entry = createEntry(
        id: 'cached_entry',
        tags: ['タグ1', 'タグ2'],
        tagsGeneratedAt: DateTime.now(),
      );

      final result = await tagService.getTagsForEntry(entry);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(['タグ1', 'タグ2']));
      verifyNever(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      );
    });

    test('キャッシュ無効時はAI生成 → 結果を返す + 永続化', () async {
      final entry = createEntry(id: 'new_entry');
      await diaryBox.put(entry.id, entry);

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => const Success(['AI生成タグ1', 'AI生成タグ2']));

      final result = await tagService.getTagsForEntry(entry);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(['AI生成タグ1', 'AI生成タグ2']));
    });

    test('AI生成失敗時はフォールバックタグを返す', () async {
      final entry = createEntry(
        id: 'fail_entry',
        date: DateTime(2025, 6, 15, 10, 0),
      );

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer(
        (_) async => const Failure(AiProcessingException('AI error')),
      );

      final result = await tagService.getTagsForEntry(entry);

      expect(result.isSuccess, isTrue);
      // 10時 → 朝
      expect(result.value.isNotEmpty, isTrue);
    });
  });

  group('getAllTags', () {
    test('全エントリーのユニークタグを集計', () async {
      await diaryBox.put('e1', createEntry(id: 'e1', tags: ['タグA', 'タグB']));
      await diaryBox.put('e2', createEntry(id: 'e2', tags: ['タグB', 'タグC']));

      final result = await tagService.getAllTags();
      expect(result.isSuccess, isTrue);
      expect(result.value, containsAll(['タグA', 'タグB', 'タグC']));
      expect(result.value.length, equals(3));
    });

    test('Box 未オープン時は空セット', () async {
      await diaryBox.close();
      final service = DiaryTagService(
        aiService: mockAiService,
        logger: mockLogger,
      );

      final result = await service.getAllTags();
      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });
  });

  group('getPopularTags', () {
    test('頻度順にソート', () async {
      await diaryBox.put('e1', createEntry(id: 'e1', tags: ['日常', '散歩']));
      await diaryBox.put('e2', createEntry(id: 'e2', tags: ['日常', '食事']));
      await diaryBox.put('e3', createEntry(id: 'e3', tags: ['日常', '散歩', '食事']));

      final result = await tagService.getPopularTags();
      expect(result.isSuccess, isTrue);
      // '日常' 3回, '散歩' 2回, '食事' 2回
      expect(result.value.first, equals('日常'));
    });

    test('limit パラメータで件数制限', () async {
      await diaryBox.put(
        'e1',
        createEntry(id: 'e1', tags: ['A', 'B', 'C', 'D']),
      );

      final result = await tagService.getPopularTags(limit: 2);
      expect(result.isSuccess, isTrue);
      expect(result.value.length, equals(2));
    });
  });

  group('generateTagsInBackground', () {
    test('AI 成功時にタグが更新される', () async {
      final entry = createEntry(id: 'bg_entry');
      await diaryBox.put(entry.id, entry);

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => const Success(['背景タグ']));

      bool callbackCalled = false;
      tagService.generateTagsInBackground(
        entry,
        onSearchIndexUpdate: (id, text) {
          callbackCalled = true;
        },
      );

      // Wait for async to complete
      await Future.delayed(const Duration(milliseconds: 100));

      final updated = diaryBox.get('bg_entry');
      expect(updated?.tags, equals(['背景タグ']));
      expect(callbackCalled, isTrue);
    });

    test('onSearchIndexUpdate コールバックが呼ばれる', () async {
      final entry = createEntry(id: 'cb_entry', content: 'callback test');
      await diaryBox.put(entry.id, entry);

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => const Success(['tag1']));

      String? callbackId;
      String? callbackText;
      tagService.generateTagsInBackground(
        entry,
        onSearchIndexUpdate: (id, text) {
          callbackId = id;
          callbackText = text;
        },
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackId, equals('cb_entry'));
      expect(callbackText, isNotNull);
    });

    test('AI 失敗時はエラーログのみ', () async {
      final entry = createEntry(id: 'fail_bg');
      await diaryBox.put(entry.id, entry);

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer(
        (_) async => const Failure(AiProcessingException('background error')),
      );

      tagService.generateTagsInBackground(entry);

      await Future.delayed(const Duration(milliseconds: 100));

      final updated = diaryBox.get('fail_bg');
      expect(updated?.tags, isNull);
    });
  });

  group('フォールバックタグ', () {
    test('朝の時間帯で朝タグ', () async {
      final entry = createEntry(
        id: 'morning',
        date: DateTime(2025, 6, 15, 8, 0),
      );

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => const Failure(AiProcessingException('error')));

      final result = await tagService.getTagsForEntry(entry);
      expect(result.isSuccess, isTrue);
      expect(result.value.any((t) => t == '朝' || t == 'Morning'), isTrue);
    });

    test('昼の時間帯で昼タグ', () async {
      final entry = createEntry(
        id: 'afternoon',
        date: DateTime(2025, 6, 15, 14, 0),
      );

      when(
        () => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async => const Failure(AiProcessingException('error')));

      final result = await tagService.getTagsForEntry(entry);
      expect(result.isSuccess, isTrue);
      expect(result.value.any((t) => t == '昼' || t == 'Afternoon'), isTrue);
    });
  });
}
