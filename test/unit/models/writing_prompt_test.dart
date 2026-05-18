import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
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

      expect(basicPrompt.isAvailableForPlan(isPremium: false), true);
      expect(premiumPrompt.isAvailableForPlan(isPremium: false), false);
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

      expect(prompt.matchesKeyword('grateful'), true);
      expect(prompt.matchesKeyword('today'), true);
      expect(prompt.matchesKeyword('GRATEFUL'), true);
      expect(prompt.matchesKeyword('mindfulness'), true);
      expect(prompt.matchesKeyword('thankful'), true);
      expect(prompt.matchesKeyword('appreciating'), true);
      expect(prompt.matchesKeyword('life'), true);
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

      expect(shortPrompt.textLength, 12);
      expect(longPrompt.textLength, greaterThan(50));
      expect(shortPrompt.isLongPrompt, false);
      expect(longPrompt.isLongPrompt, true);
      expect(shortPrompt.previewText, 'Short prompt');
      expect(longPrompt.previewText.length, 33);
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

      expect(copied.id, 'original');
      expect(copied.text, 'Updated text');
      expect(copied.category, PromptCategory.emotion);
      expect(copied.isPremiumOnly, true);
      expect(copied.priority, 80);
    });

    test('equality based on id only', () {
      final prompt1 = WritingPrompt(
        id: 'same-id',
        text: 'Text 1',
        category: PromptCategory.emotion,
      );

      final prompt2 = WritingPrompt(
        id: 'same-id',
        text: 'Text 2',
        category: PromptCategory.emotionDepth,
      );

      final prompt3 = WritingPrompt(
        id: 'different-id',
        text: 'Text 1',
        category: PromptCategory.emotion,
      );

      expect(prompt1, equals(prompt2));
      expect(prompt1, isNot(equals(prompt3)));
      expect(prompt1.hashCode, prompt2.hashCode);
    });

    group('localization', () {
      test('textForLocale returns Japanese text by default', () {
        final prompt = WritingPrompt(
          id: 'loc-1',
          text: '今日はどんな一日でしたか？',
          category: PromptCategory.emotion,
          localizedTexts: {'en': 'How was your day today?'},
        );

        expect(prompt.textForLocale(null), '今日はどんな一日でしたか？');
        expect(prompt.textForLocale(const Locale('ja')), '今日はどんな一日でしたか？');
      });

      test('textForLocale returns localized text for specified locale', () {
        final prompt = WritingPrompt(
          id: 'loc-2',
          text: '今日はどんな一日でしたか？',
          category: PromptCategory.emotion,
          localizedTexts: {'en': 'How was your day today?'},
        );

        expect(
          prompt.textForLocale(const Locale('en')),
          'How was your day today?',
        );
      });

      test('tagsForLocale returns localized tags', () {
        final prompt = WritingPrompt(
          id: 'loc-3',
          text: 'プロンプト',
          category: PromptCategory.emotion,
          tags: ['感謝', '日常'],
          localizedTags: {
            'en': ['gratitude', 'daily'],
          },
        );

        expect(prompt.tagsForLocale(const Locale('ja')), ['感謝', '日常']);
        expect(prompt.tagsForLocale(const Locale('en')), [
          'gratitude',
          'daily',
        ]);
      });

      test('localizedCopy returns same instance when no change', () {
        final prompt = WritingPrompt(
          id: 'loc-4',
          text: '今日の気持ちは？',
          category: PromptCategory.emotion,
        );

        expect(identical(prompt.localizedCopy(null), prompt), true);
        expect(
          identical(prompt.localizedCopy(const Locale('ja')), prompt),
          true,
        );
      });

      test('localizedCopy returns new instance with localized content', () {
        final prompt = WritingPrompt(
          id: 'loc-5',
          text: '今日の気持ちは？',
          category: PromptCategory.emotion,
          localizedTexts: {'en': 'How do you feel today?'},
        );

        final localized = prompt.localizedCopy(const Locale('en'));
        expect(localized.text, 'How do you feel today?');
        expect(localized.id, prompt.id);
      });

      test('textForLocale falls back to Japanese for unsupported locale', () {
        final prompt = WritingPrompt(
          id: 'loc-6',
          text: '今日の気持ちは？',
          category: PromptCategory.emotion,
          localizedTexts: {'en': 'How do you feel today?'},
        );

        expect(prompt.textForLocale(const Locale('fr')), '今日の気持ちは？');
      });
    });
  });
}
