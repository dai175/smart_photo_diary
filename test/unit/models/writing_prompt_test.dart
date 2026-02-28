import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
  group('PromptCategory', () {
    test('fromId returns correct category', () {
      expect(PromptCategory.fromId('emotion'), PromptCategory.emotion);
      expect(
        PromptCategory.fromId('emotion_depth'),
        PromptCategory.emotionDepth,
      );
      expect(
        PromptCategory.fromId('sensory_emotion'),
        PromptCategory.sensoryEmotion,
      );
      expect(
        PromptCategory.fromId('emotion_growth'),
        PromptCategory.emotionGrowth,
      );
      expect(
        PromptCategory.fromId('emotion_connection'),
        PromptCategory.emotionConnection,
      );
      expect(
        PromptCategory.fromId('emotion_discovery'),
        PromptCategory.emotionDiscovery,
      );
      expect(
        PromptCategory.fromId('emotion_fantasy'),
        PromptCategory.emotionFantasy,
      );
      expect(
        PromptCategory.fromId('emotion_healing'),
        PromptCategory.emotionHealing,
      );
      expect(
        PromptCategory.fromId('emotion_energy'),
        PromptCategory.emotionEnergy,
      );
    });

    test('fromId returns emotion for unknown id', () {
      expect(PromptCategory.fromId('unknown'), PromptCategory.emotion);
      expect(PromptCategory.fromId(''), PromptCategory.emotion);
    });

    test('all categories have unique IDs', () {
      final ids = PromptCategory.values.map((c) => c.id).toList();
      expect(ids.length, 9);
      expect(ids.toSet().length, ids.length);
    });
  });

  group('WritingPrompt', () {
    test('creates basic prompt correctly', () {
      final prompt = WritingPrompt(
        id: 'test-1',
        text: 'What made you smile today?',
        category: PromptCategory.emotion,
      );

      expect(prompt.id, 'test-1');
      expect(prompt.text, 'What made you smile today?');
      expect(prompt.category, PromptCategory.emotion);
      expect(prompt.isPremiumOnly, false);
      expect(prompt.tags, isEmpty);
      expect(prompt.description, isNull);
      expect(prompt.priority, 0);
      expect(prompt.isActive, true);
      expect(prompt.createdAt, isNotNull);
    });

    test('creates premium prompt correctly', () {
      final prompt = WritingPrompt(
        id: 'premium-1',
        text: 'Describe a challenging decision you made this week',
        category: PromptCategory.emotionDiscovery,
        isPremiumOnly: true,
        tags: ['decision', 'challenge', 'reflection'],
        description: 'Deep reflection prompt for personal growth',
        priority: 85,
      );

      expect(prompt.isPremiumOnly, true);
      expect(prompt.tags, ['decision', 'challenge', 'reflection']);
      expect(prompt.description, 'Deep reflection prompt for personal growth');
      expect(prompt.priority, 85);
    });

    test('fromJson creates correct WritingPrompt', () {
      final json = {
        'id': 'json-1',
        'text': 'What are you grateful for today?',
        'category': 'emotion',
        'isPremiumOnly': true,
        'tags': ['gratitude', 'mindfulness'],
        'description': 'Gratitude practice prompt',
        'priority': 70,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'isActive': true,
      };

      final prompt = WritingPrompt.fromJson(json);

      expect(prompt.id, 'json-1');
      expect(prompt.text, 'What are you grateful for today?');
      expect(prompt.category, PromptCategory.emotion);
      expect(prompt.isPremiumOnly, true);
      expect(prompt.tags, ['gratitude', 'mindfulness']);
      expect(prompt.description, 'Gratitude practice prompt');
      expect(prompt.priority, 70);
      expect(prompt.isActive, true);
    });

    test('toJson creates correct map', () {
      final prompt = WritingPrompt(
        id: 'test-json',
        text: 'Describe your ideal day',
        category: PromptCategory.emotion,
        isPremiumOnly: false,
        tags: ['daily', 'vision'],
        description: 'Vision setting prompt',
        priority: 50,
      );

      final json = prompt.toJson();

      expect(json['id'], 'test-json');
      expect(json['text'], 'Describe your ideal day');
      expect(json['category'], 'emotion');
      expect(json['isPremiumOnly'], false);
      expect(json['tags'], ['daily', 'vision']);
      expect(json['description'], 'Vision setting prompt');
      expect(json['priority'], 50);
      expect(json['isActive'], true);
      expect(json['createdAt'], isNotNull);
    });

    test('isAvailableForPlan works correctly', () {
      final basicPrompt = WritingPrompt(
        id: 'basic-1',
        text: 'Basic prompt',
        category: PromptCategory.emotion,
        isPremiumOnly: false,
      );

      final premiumPrompt = WritingPrompt(
        id: 'premium-1',
        text: 'Premium prompt',
        category: PromptCategory.emotionDiscovery,
        isPremiumOnly: true,
      );

      // Basic user
      expect(basicPrompt.isAvailableForPlan(isPremium: false), true);
      expect(premiumPrompt.isAvailableForPlan(isPremium: false), false);

      // Premium user
      expect(basicPrompt.isAvailableForPlan(isPremium: true), true);
      expect(premiumPrompt.isAvailableForPlan(isPremium: true), true);
    });

    test('inactive prompts are not available', () {
      final inactivePrompt = WritingPrompt(
        id: 'inactive-1',
        text: 'Inactive prompt',
        category: PromptCategory.emotion,
        isActive: false,
      );

      expect(inactivePrompt.isAvailableForPlan(isPremium: false), false);
      expect(inactivePrompt.isAvailableForPlan(isPremium: true), false);
    });

    test('matchesKeyword works correctly', () {
      final prompt = WritingPrompt(
        id: 'search-1',
        text: 'What made you feel grateful today?',
        category: PromptCategory.emotion,
        tags: ['thankfulness', 'mindfulness'],
        description: 'A prompt about appreciating good things in life',
      );

      // Text matches
      expect(prompt.matchesKeyword('grateful'), true);
      expect(prompt.matchesKeyword('today'), true);
      expect(prompt.matchesKeyword('GRATEFUL'), true); // Case insensitive

      // Tag matches
      expect(prompt.matchesKeyword('mindfulness'), true);
      expect(prompt.matchesKeyword('thankful'), true); // Partial match

      // Description matches
      expect(prompt.matchesKeyword('appreciating'), true);
      expect(prompt.matchesKeyword('life'), true);

      // No matches
      expect(prompt.matchesKeyword('travel'), false);
      expect(prompt.matchesKeyword('xyz'), false);
    });

    test('helper properties work correctly', () {
      final shortPrompt = WritingPrompt(
        id: 'short-1',
        text: 'Short prompt',
        category: PromptCategory.emotion,
      );

      final longPrompt = WritingPrompt(
        id: 'long-1',
        text:
            'This is a very long prompt that contains more than fifty characters to test the isLongPrompt property',
        category: PromptCategory.emotionDiscovery,
        priority: 90,
      );

      // textLength
      expect(shortPrompt.textLength, 12);
      expect(longPrompt.textLength, greaterThan(50));

      // isLongPrompt
      expect(shortPrompt.isLongPrompt, false);
      expect(longPrompt.isLongPrompt, true);

      // previewText
      expect(shortPrompt.previewText, 'Short prompt');
      expect(longPrompt.previewText.length, 33); // 30 chars + "..."
      expect(longPrompt.previewText.endsWith('...'), true);
    });

    test('copyWith works correctly', () {
      final original = WritingPrompt(
        id: 'original',
        text: 'Original text',
        category: PromptCategory.emotion,
        isPremiumOnly: false,
        priority: 10,
      );

      final copied = original.copyWith(
        text: 'Updated text',
        isPremiumOnly: true,
        priority: 80,
      );

      expect(copied.id, 'original'); // Unchanged
      expect(copied.text, 'Updated text'); // Changed
      expect(copied.category, PromptCategory.emotion); // Unchanged
      expect(copied.isPremiumOnly, true); // Changed
      expect(copied.priority, 80); // Changed
    });

    test('equality works correctly', () {
      final prompt1 = WritingPrompt(
        id: 'same-id',
        text: 'Text 1',
        category: PromptCategory.emotion,
      );

      final prompt2 = WritingPrompt(
        id: 'same-id',
        text: 'Text 2', // Different text
        category: PromptCategory.emotionDepth, // Different category
      );

      final prompt3 = WritingPrompt(
        id: 'different-id',
        text: 'Text 1',
        category: PromptCategory.emotion,
      );

      expect(prompt1, equals(prompt2)); // Same ID
      expect(prompt1, isNot(equals(prompt3))); // Different ID
      expect(prompt1.hashCode, prompt2.hashCode); // Same hash
    });
  });

  group('PromptUsageHistory', () {
    test('creates usage history correctly', () {
      final history = PromptUsageHistory(
        promptId: 'prompt-1',
        diaryEntryId: 'diary-1',
        wasHelpful: true,
      );

      expect(history.promptId, 'prompt-1');
      expect(history.diaryEntryId, 'diary-1');
      expect(history.wasHelpful, true);
      expect(history.usedAt, isNotNull);
    });

    test('fromJson and toJson work correctly', () {
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

    test('equality works correctly', () {
      final time = DateTime(2024, 1, 1, 12, 0);

      final history1 = PromptUsageHistory(promptId: 'prompt-1', usedAt: time);

      final history2 = PromptUsageHistory(
        promptId: 'prompt-1',
        usedAt: time,
        wasHelpful: false, // Different helpful status
      );

      final history3 = PromptUsageHistory(promptId: 'prompt-2', usedAt: time);

      expect(history1, equals(history2)); // Same prompt and time
      expect(history1, isNot(equals(history3))); // Different prompt
      expect(history1.hashCode, history2.hashCode);
    });
  });
}
