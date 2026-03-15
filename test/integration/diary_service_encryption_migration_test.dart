import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/hive_registrar.g.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';

void main() {
  late LoggingService logger;
  late MockIDiaryTagService mockTagService;
  const baseDir = '/tmp/smart_photo_diary_enc_mig_test';
  const boxName = 'diary_entries';
  const metaBoxName = 'diary_meta';

  // Each test uses its own subdirectory to avoid state leaks
  late String testDir;
  var testIndex = 0;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    MockPlatformChannels.setupMocks();
    registerMockFallbacks();
  });

  setUp(() async {
    logger = LoggingService();
    mockTagService = MockIDiaryTagService();
    when(
      () => mockTagService.generateTagsInBackground(
        any(),
        onSearchIndexUpdate: any(named: 'onSearchIndexUpdate'),
      ),
    ).thenReturn(null);

    // Use unique directory per test for full isolation
    testIndex++;
    testDir = '$baseDir/test_$testIndex';
    Directory(testDir).createSync(recursive: true);
    Hive.init(testDir);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapters();
    }
  });

  tearDown(() async {
    // Close all open boxes and delete from disk
    for (final name in [boxName, metaBoxName]) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
      } catch (_) {}
    }
    try {
      await Hive.deleteFromDisk();
    } catch (_) {}
  });

  tearDownAll(() async {
    try {
      final dir = Directory(baseDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      MockPlatformChannels.clearMocks();
    } catch (_) {}
  });

  group('DiaryService encryption migration', () {
    test(
      'should migrate unencrypted data to encrypted on first open with cipher',
      () async {
        // Step 1: Create entries WITHOUT encryption (old app version)
        final oldService = DiaryService.createWithDependencies(
          logger: logger,
          tagService: mockTagService,
        );
        await oldService.initialize();

        final save1 = await oldService.saveDiaryEntry(
          date: DateTime(2024, 6, 1),
          title: 'Old Diary 1',
          content: 'Content from old version 1',
          photoIds: ['photo_a'],
        );
        final save2 = await oldService.saveDiaryEntry(
          date: DateTime(2024, 6, 2),
          title: 'Old Diary 2',
          content: 'Content from old version 2',
          photoIds: ['photo_b', 'photo_c'],
        );
        expect(save1.isSuccess, isTrue);
        expect(save2.isSuccess, isTrue);
        final savedId1 = save1.value.id;
        final savedId2 = save2.value.id;

        oldService.dispose();
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box<DiaryEntry>(boxName).close();
        }

        // Step 2: Open with encryption (new app version)
        final cipher = HiveAesCipher(Hive.generateSecureKey());
        final newService = DiaryService.createWithDependencies(
          logger: logger,
          tagService: mockTagService,
          encryptionCipher: cipher,
        );
        await newService.initialize();

        // Step 3: Verify all entries were migrated
        final allResult = await newService.getSortedDiaryEntries();
        expect(allResult.isSuccess, isTrue);
        expect(allResult.value.length, equals(2));

        final entry1 = await newService.getDiaryEntry(savedId1);
        expect(entry1.isSuccess, isTrue);
        expect(entry1.value, isNotNull);
        expect(entry1.value!.title, equals('Old Diary 1'));
        expect(entry1.value!.content, equals('Content from old version 1'));
        expect(entry1.value!.photoIds, equals(['photo_a']));

        final entry2 = await newService.getDiaryEntry(savedId2);
        expect(entry2.isSuccess, isTrue);
        expect(entry2.value, isNotNull);
        expect(entry2.value!.title, equals('Old Diary 2'));
        expect(entry2.value!.photoIds, equals(['photo_b', 'photo_c']));

        newService.dispose();
      },
    );

    test('should reopen encrypted box normally after migration', () async {
      final key = Hive.generateSecureKey();

      // Step 1: Create unencrypted data, then migrate via DiaryService
      final oldService = DiaryService.createWithDependencies(
        logger: logger,
        tagService: mockTagService,
      );
      await oldService.initialize();
      final save = await oldService.saveDiaryEntry(
        date: DateTime(2024, 7, 1),
        title: 'Original Entry',
        content: 'Original content',
        photoIds: ['photo_x'],
      );
      expect(save.isSuccess, isTrue);
      final savedId = save.value.id;
      oldService.dispose();
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<DiaryEntry>(boxName).close();
      }

      // Step 2: First open with cipher triggers migration
      final cipher1 = HiveAesCipher(key);
      final service1 = DiaryService.createWithDependencies(
        logger: logger,
        tagService: mockTagService,
        encryptionCipher: cipher1,
      );
      await service1.initialize();

      final result1 = await service1.getDiaryEntry(savedId);
      expect(result1.isSuccess, isTrue);
      expect(result1.value!.title, equals('Original Entry'));

      service1.dispose();
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<DiaryEntry>(boxName).close();
      }
      if (Hive.isBoxOpen(metaBoxName)) {
        await Hive.box(metaBoxName).close();
      }

      // Step 3: Second open with same key (normal restart)
      final cipher2 = HiveAesCipher(key);
      final service2 = DiaryService.createWithDependencies(
        logger: logger,
        tagService: mockTagService,
        encryptionCipher: cipher2,
      );
      await service2.initialize();

      final result2 = await service2.getDiaryEntry(savedId);
      expect(result2.isSuccess, isTrue);
      expect(result2.value, isNotNull);
      expect(result2.value!.title, equals('Original Entry'));

      service2.dispose();
    });

    test('should handle empty box migration gracefully', () async {
      final cipher = HiveAesCipher(Hive.generateSecureKey());

      // Open directly with cipher on fresh directory (no prior data)
      final service = DiaryService.createWithDependencies(
        logger: logger,
        tagService: mockTagService,
        encryptionCipher: cipher,
      );
      await service.initialize();

      // Should be empty but functional
      final result = await service.getSortedDiaryEntries();
      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);

      // Should be able to write new entries
      final save = await service.saveDiaryEntry(
        date: DateTime(2024, 8, 1),
        title: 'New Entry',
        content: 'New content',
        photoIds: [],
      );
      expect(save.isSuccess, isTrue);
      expect(save.value.title, equals('New Entry'));

      service.dispose();
    });

    test(
      'should preserve new entries after migration across restarts',
      () async {
        final key = Hive.generateSecureKey();

        // Step 1: Create unencrypted entry
        final oldService = DiaryService.createWithDependencies(
          logger: logger,
          tagService: mockTagService,
        );
        await oldService.initialize();
        final save1 = await oldService.saveDiaryEntry(
          date: DateTime(2024, 9, 1),
          title: 'Before Migration',
          content: 'Old content',
          photoIds: [],
        );
        expect(save1.isSuccess, isTrue);
        oldService.dispose();
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box<DiaryEntry>(boxName).close();
        }

        // Step 2: Migrate and add new entry
        final cipher1 = HiveAesCipher(key);
        final service1 = DiaryService.createWithDependencies(
          logger: logger,
          tagService: mockTagService,
          encryptionCipher: cipher1,
        );
        await service1.initialize();

        final save2 = await service1.saveDiaryEntry(
          date: DateTime(2024, 9, 2),
          title: 'After Migration',
          content: 'New content',
          photoIds: [],
        );
        expect(save2.isSuccess, isTrue);

        service1.dispose();
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box<DiaryEntry>(boxName).close();
        }
        if (Hive.isBoxOpen(metaBoxName)) {
          await Hive.box(metaBoxName).close();
        }

        // Step 3: Reopen and verify both entries exist
        final cipher2 = HiveAesCipher(key);
        final service2 = DiaryService.createWithDependencies(
          logger: logger,
          tagService: mockTagService,
          encryptionCipher: cipher2,
        );
        await service2.initialize();

        final all = await service2.getSortedDiaryEntries();
        expect(all.isSuccess, isTrue);
        expect(all.value.length, equals(2));

        final titles = all.value.map((e) => e.title).toSet();
        expect(titles, contains('Before Migration'));
        expect(titles, contains('After Migration'));

        service2.dispose();
      },
    );
  });
}
