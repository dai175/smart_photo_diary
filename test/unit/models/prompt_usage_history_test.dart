import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/prompt_usage_history.dart';

void main() {
  group('PromptUsageHistory', () {
    test('creates with required fields and defaults', () {
      final before = DateTime.now();
      final history = PromptUsageHistory(promptId: 'prompt-1');
      final after = DateTime.now();

      expect(history.promptId, 'prompt-1');
      expect(history.diaryEntryId, isNull);
      expect(history.wasHelpful, true);
      expect(
        history.usedAt.millisecondsSinceEpoch,
        inInclusiveRange(
          before.millisecondsSinceEpoch,
          after.millisecondsSinceEpoch,
        ),
      );
    });

    test('creates with all fields specified', () {
      final time = DateTime(2024, 6, 15, 10, 30);
      final history = PromptUsageHistory(
        promptId: 'prompt-1',
        usedAt: time,
        diaryEntryId: 'diary-1',
        wasHelpful: false,
      );

      expect(history.promptId, 'prompt-1');
      expect(history.usedAt, time);
      expect(history.diaryEntryId, 'diary-1');
      expect(history.wasHelpful, false);
    });

    test('fromJson and toJson round-trip correctly', () {
      final original = PromptUsageHistory(
        promptId: 'prompt-test',
        usedAt: DateTime(2024, 1, 1, 12, 0),
        diaryEntryId: 'diary-test',
        wasHelpful: false,
      );

      final json = original.toJson();
      final restored = PromptUsageHistory.fromJson(json);

      expect(restored.promptId, original.promptId);
      expect(restored.usedAt, original.usedAt);
      expect(restored.diaryEntryId, original.diaryEntryId);
      expect(restored.wasHelpful, original.wasHelpful);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'promptId': 'p-1',
        'usedAt': DateTime(2024, 1, 1).toIso8601String(),
      };
      final history = PromptUsageHistory.fromJson(json);

      expect(history.diaryEntryId, isNull);
      expect(history.wasHelpful, true);
    });

    test('toString returns readable representation', () {
      final time = DateTime(2024, 6, 15);
      final history = PromptUsageHistory(
        promptId: 'p-1',
        usedAt: time,
        wasHelpful: true,
      );

      final str = history.toString();
      expect(str, contains('p-1'));
      expect(str, contains('true'));
    });

    test('equality based on promptId and usedAt', () {
      final time = DateTime(2024, 1, 1, 12, 0);

      final h1 = PromptUsageHistory(promptId: 'p-1', usedAt: time);
      final h2 = PromptUsageHistory(
        promptId: 'p-1',
        usedAt: time,
        wasHelpful: false,
      );
      final h3 = PromptUsageHistory(promptId: 'p-2', usedAt: time);

      expect(h1, equals(h2));
      expect(h1, isNot(equals(h3)));
      expect(h1.hashCode, h2.hashCode);
    });
  });
}
