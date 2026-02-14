import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/prompt_usage_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import '../helpers/hive_test_helpers.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late PromptUsageService usageService;
  late MockLoggingService mockLogger;

  setUpAll(() async {
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearPromptUsageBox();
    mockLogger = MockLoggingService();
    usageService = PromptUsageService(logger: mockLogger);
  });

  tearDown(() async {
    usageService.reset();
  });

  tearDownAll(() async {
    await HiveTestHelpers.closeHive();
  });

  group('初期化', () {
    test('initialize() 後 isAvailable が true', () async {
      await usageService.initialize();
      expect(usageService.isAvailable, isTrue);
    });

    test('未初期化時 isAvailable が false', () {
      expect(usageService.isAvailable, isFalse);
    });
  });

  group('recordPromptUsage', () {
    setUp(() async {
      await usageService.initialize();
    });

    test('正常記録 → Success(true)', () async {
      final result = await usageService.recordPromptUsage(promptId: 'prompt_1');
      expect(result.isSuccess, isTrue);
      expect(result.value, isTrue);
    });

    test('未初期化時 → Failure', () async {
      final uninitService = PromptUsageService(logger: mockLogger);
      final result = await uninitService.recordPromptUsage(
        promptId: 'prompt_1',
      );
      expect(result.isFailure, isTrue);
    });

    test('パラメータ（diaryEntryId, wasHelpful）の保存確認', () async {
      await usageService.recordPromptUsage(
        promptId: 'prompt_2',
        diaryEntryId: 'diary_1',
        wasHelpful: false,
      );

      final history = usageService.getUsageHistory(promptId: 'prompt_2');
      expect(history.length, equals(1));
      expect(history.first.diaryEntryId, equals('diary_1'));
      expect(history.first.wasHelpful, isFalse);
    });
  });

  group('getUsageHistory', () {
    setUp(() async {
      await usageService.initialize();
    });

    test('新しい順にソート', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await Future.delayed(const Duration(milliseconds: 10));
      await usageService.recordPromptUsage(promptId: 'p2');
      await Future.delayed(const Duration(milliseconds: 10));
      await usageService.recordPromptUsage(promptId: 'p3');

      final history = usageService.getUsageHistory();
      expect(history.length, equals(3));
      expect(history.first.promptId, equals('p3'));
      expect(history.last.promptId, equals('p1'));
    });

    test('limit で件数制限', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p2');
      await usageService.recordPromptUsage(promptId: 'p3');

      final history = usageService.getUsageHistory(limit: 2);
      expect(history.length, equals(2));
    });

    test('promptId フィルタ', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p2');
      await usageService.recordPromptUsage(promptId: 'p1');

      final history = usageService.getUsageHistory(promptId: 'p1');
      expect(history.length, equals(2));
      expect(history.every((h) => h.promptId == 'p1'), isTrue);
    });

    test('未初期化時は空リスト', () {
      final uninitService = PromptUsageService(logger: mockLogger);
      final history = uninitService.getUsageHistory();
      expect(history, isEmpty);
    });
  });

  group('getRecentlyUsedPromptIds', () {
    setUp(() async {
      await usageService.initialize();
    });

    test('期間内の重複なし ID リスト', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p2');
      await usageService.recordPromptUsage(promptId: 'p1');

      final ids = usageService.getRecentlyUsedPromptIds();
      expect(ids.contains('p1'), isTrue);
      expect(ids.contains('p2'), isTrue);
      // 重複なし
      expect(ids.where((id) => id == 'p1').length, equals(1));
    });

    test('limit パラメータで件数制限', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p2');
      await usageService.recordPromptUsage(promptId: 'p3');

      final ids = usageService.getRecentlyUsedPromptIds(limit: 2);
      expect(ids.length, equals(2));
    });
  });

  group('clearUsageHistory', () {
    setUp(() async {
      await usageService.initialize();
    });

    test('引数なし → 全削除', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p2');

      final result = await usageService.clearUsageHistory();
      expect(result.isSuccess, isTrue);

      final history = usageService.getUsageHistory();
      expect(history, isEmpty);
    });

    test('未初期化時 → Failure', () async {
      final uninitService = PromptUsageService(logger: mockLogger);
      final result = await uninitService.clearUsageHistory();
      expect(result.isFailure, isTrue);
    });
  });

  group('getUsageFrequencyStats', () {
    setUp(() async {
      await usageService.initialize();
    });

    test('プロンプト別使用回数集計', () async {
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p1');
      await usageService.recordPromptUsage(promptId: 'p2');

      final stats = usageService.getUsageFrequencyStats();
      expect(stats['p1'], equals(2));
      expect(stats['p2'], equals(1));
    });

    test('未初期化時は空 Map', () {
      final uninitService = PromptUsageService(logger: mockLogger);
      final stats = uninitService.getUsageFrequencyStats();
      expect(stats, isEmpty);
    });
  });

  group('reset', () {
    test('reset() 後 isAvailable が false', () async {
      await usageService.initialize();
      expect(usageService.isAvailable, isTrue);

      usageService.reset();
      expect(usageService.isAvailable, isFalse);
    });
  });
}
