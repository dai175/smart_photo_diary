import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/utils/prompt_category_utils.dart';

void main() {
  group('PromptCategoryUtils', () {
    group('getAvailableCategories', () {
      test('returns all categories for Premium users', () {
        final categories = PromptCategoryUtils.getAvailableCategories(
          isPremium: true,
        );

        // 感情深掘り型では9つの感情カテゴリをサポート
        expect(categories.length, 9);
        expect(
          categories,
          containsAll([
            PromptCategory.emotion,
            PromptCategory.emotionDepth,
            PromptCategory.sensoryEmotion,
            PromptCategory.emotionGrowth,
            PromptCategory.emotionConnection,
            PromptCategory.emotionDiscovery,
            PromptCategory.emotionFantasy,
            PromptCategory.emotionHealing,
            PromptCategory.emotionEnergy,
          ]),
        );
      });

      test('returns limited categories for Basic users', () {
        final categories = PromptCategoryUtils.getAvailableCategories(
          isPremium: false,
        );

        // 感情深掘り型ではBasicユーザーは基本感情カテゴリのみ
        expect(categories, [PromptCategory.emotion]);
        expect(categories.length, 1);
      });
    });

    group('isBasicAvailable', () {
      test('returns true for Basic-available categories', () {
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotion),
          true,
        );
      });

      test('returns false for Premium-only categories', () {
        // 感情深掘り型Premium専用カテゴリ
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotionDepth),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.sensoryEmotion),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotionGrowth),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(
            PromptCategory.emotionConnection,
          ),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotionDiscovery),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotionFantasy),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotionHealing),
          false,
        );
        expect(
          PromptCategoryUtils.isBasicAvailable(PromptCategory.emotionEnergy),
          false,
        );
      });
    });

    group('getBasicPromptCount', () {
      test('returns correct basic prompt counts', () {
        // 感情深掘り型カテゴリ
        expect(
          PromptCategoryUtils.getBasicPromptCount(PromptCategory.emotion),
          5,
        );
        expect(
          PromptCategoryUtils.getBasicPromptCount(PromptCategory.emotionDepth),
          0,
        );
        expect(
          PromptCategoryUtils.getBasicPromptCount(
            PromptCategory.sensoryEmotion,
          ),
          0,
        );
      });
    });

    group('getPremiumPromptCount', () {
      test('returns correct premium prompt counts', () {
        // 感情深掘り型カテゴリ
        expect(
          PromptCategoryUtils.getPremiumPromptCount(PromptCategory.emotion),
          0,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionDepth,
          ),
          2,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.sensoryEmotion,
          ),
          2,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionGrowth,
          ),
          2,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionConnection,
          ),
          2,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionDiscovery,
          ),
          2,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionFantasy,
          ),
          1,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionHealing,
          ),
          2,
        );
        expect(
          PromptCategoryUtils.getPremiumPromptCount(
            PromptCategory.emotionEnergy,
          ),
          2,
        );
      });
    });

    group('getTotalPromptCount', () {
      test('returns basic count for Basic users', () {
        expect(
          PromptCategoryUtils.getTotalPromptCount(
            PromptCategory.emotion,
            isPremium: false,
          ),
          5, // 感情基本カテゴリ
        );
      });

      test('returns total count for Premium users', () {
        expect(
          PromptCategoryUtils.getTotalPromptCount(
            PromptCategory.emotion,
            isPremium: true,
          ),
          5, // 5 basic + 0 premium
        );
        expect(
          PromptCategoryUtils.getTotalPromptCount(
            PromptCategory.emotionDepth,
            isPremium: true,
          ),
          2, // 0 basic + 2 premium
        );
      });
    });

    group('getCategoryDescription', () {
      test('returns correct descriptions for all categories', () {
        // 感情深掘り型カテゴリ
        expect(
          PromptCategoryUtils.getCategoryDescription(PromptCategory.emotion),
          '基本的な感情や気持ちを探るプロンプト',
        );
        expect(
          PromptCategoryUtils.getCategoryDescription(
            PromptCategory.emotionDepth,
          ),
          '感情の奥深くを掘り下げるプロンプト',
        );
        expect(
          PromptCategoryUtils.getCategoryDescription(
            PromptCategory.sensoryEmotion,
          ),
          '五感を通じて感情を表現するプロンプト',
        );
      });
    });

    group('getRecommendedTags', () {
      test('returns appropriate tags for each category', () {
        // 感情深掘り型カテゴリ
        final emotionTags = PromptCategoryUtils.getRecommendedTags(
          PromptCategory.emotion,
        );
        expect(emotionTags, contains('感情'));
        expect(emotionTags, contains('気持ち'));
        expect(emotionTags, contains('心'));

        final emotionDepthTags = PromptCategoryUtils.getRecommendedTags(
          PromptCategory.emotionDepth,
        );
        expect(emotionDepthTags, contains('感情深掘り'));
        expect(emotionDepthTags, contains('深掘り'));
        expect(emotionDepthTags, contains('背景'));

        final sensoryEmotionTags = PromptCategoryUtils.getRecommendedTags(
          PromptCategory.sensoryEmotion,
        );
        expect(sensoryEmotionTags, contains('感情五感'));
        expect(sensoryEmotionTags, contains('五感'));
        expect(sensoryEmotionTags, contains('音'));
      });
    });

    group('filterPromptsByPlan', () {
      late List<WritingPrompt> testPrompts;

      setUp(() {
        testPrompts = [
          WritingPrompt(
            id: 'basic-emotion-1',
            text: 'この瞬間にどんな気持ちになりましたか？',
            category: PromptCategory.emotion,
            isPremiumOnly: false,
          ),
          WritingPrompt(
            id: 'premium-emotion-depth-1',
            text: 'この感情の背景にはどんな体験がありますか？',
            category: PromptCategory.emotionDepth,
            isPremiumOnly: true,
          ),
          WritingPrompt(
            id: 'inactive-prompt',
            text: 'Inactive prompt',
            category: PromptCategory.emotion,
            isPremiumOnly: false,
            isActive: false,
          ),
        ];
      });

      test('filters correctly for Basic users', () {
        final filtered = PromptCategoryUtils.filterPromptsByPlan(
          testPrompts,
          isPremium: false,
        );

        expect(filtered.length, 1);
        expect(filtered.map((p) => p.id), containsAll(['basic-emotion-1']));
      });

      test('includes all active prompts for Premium users', () {
        final filtered = PromptCategoryUtils.filterPromptsByPlan(
          testPrompts,
          isPremium: true,
        );

        expect(filtered.length, 2);
        expect(
          filtered.map((p) => p.id),
          containsAll(['basic-emotion-1', 'premium-emotion-depth-1']),
        );
      });

      test('excludes inactive prompts', () {
        final filtered = PromptCategoryUtils.filterPromptsByPlan(
          testPrompts,
          isPremium: true,
        );

        expect(filtered.any((p) => p.id == 'inactive-prompt'), false);
      });
    });

    group('getCategoryStats', () {
      test('calculates correct statistics', () {
        final prompts = [
          WritingPrompt(
            id: '1',
            text: 'Test 1',
            category: PromptCategory.emotion,
            isPremiumOnly: false,
          ),
          WritingPrompt(
            id: '2',
            text: 'Test 2',
            category: PromptCategory.emotionDepth,
            isPremiumOnly: true,
          ),
        ];

        final stats = PromptCategoryUtils.getCategoryStats(prompts);

        // Emotion category stats (感情深掘り型の基本カテゴリ)
        final emotionStats = stats[PromptCategory.emotion]!;
        expect(emotionStats.totalPrompts, 1);
        expect(emotionStats.basicPrompts, 1);
        expect(emotionStats.premiumPrompts, 0);
        expect(emotionStats.isBasicAvailable, true);
        expect(emotionStats.premiumRatio, 0.0);
        expect(emotionStats.basicAvailability, 1.0);

        // EmotionDepth category stats
        final emotionDepthStats = stats[PromptCategory.emotionDepth]!;
        expect(emotionDepthStats.totalPrompts, 1);
        expect(emotionDepthStats.basicPrompts, 0);
        expect(emotionDepthStats.premiumPrompts, 1);
        expect(emotionDepthStats.isBasicAvailable, false);
        expect(emotionDepthStats.premiumRatio, 1.0);
        expect(emotionDepthStats.basicAvailability, 0.0);

        // Empty category stats
        final emotionGrowthStats = stats[PromptCategory.emotionGrowth]!;
        expect(emotionGrowthStats.totalPrompts, 0);
        expect(emotionGrowthStats.basicPrompts, 0);
        expect(emotionGrowthStats.premiumPrompts, 0);
        expect(emotionGrowthStats.premiumRatio, 0.0);
        expect(emotionGrowthStats.basicAvailability, 0.0);
      });
    });

    group('getPremiumOnlyCategories', () {
      test('returns all Premium-only categories', () {
        final premiumOnly = PromptCategoryUtils.getPremiumOnlyCategories();

        expect(
          premiumOnly,
          containsAll([
            // 感情深掘り型Premium専用カテゴリ
            PromptCategory.emotionDepth,
            PromptCategory.sensoryEmotion,
            PromptCategory.emotionGrowth,
            PromptCategory.emotionConnection,
            PromptCategory.emotionDiscovery,
            PromptCategory.emotionFantasy,
            PromptCategory.emotionHealing,
            PromptCategory.emotionEnergy,
          ]),
        );
        expect(premiumOnly, isNot(contains(PromptCategory.emotion)));
      });
    });

    group('getExpectedBenefits', () {
      test('returns expected benefits for each category', () {
        // 感情深掘り型カテゴリ
        final emotionBenefits = PromptCategoryUtils.getExpectedBenefits(
          PromptCategory.emotion,
        );
        expect(emotionBenefits, contains('感情の認識向上'));
        expect(emotionBenefits, contains('自己理解の深化'));
        expect(emotionBenefits, contains('心の整理'));

        final emotionDepthBenefits = PromptCategoryUtils.getExpectedBenefits(
          PromptCategory.emotionDepth,
        );
        expect(emotionDepthBenefits, contains('感情の深い洞察'));
        expect(emotionDepthBenefits, contains('内面の成長'));
        expect(emotionDepthBenefits, contains('心の平穏'));

        final sensoryEmotionBenefits = PromptCategoryUtils.getExpectedBenefits(
          PromptCategory.sensoryEmotion,
        );
        expect(sensoryEmotionBenefits, contains('五感の鋭敏化'));
        expect(sensoryEmotionBenefits, contains('感覚的記憶の向上'));
        expect(sensoryEmotionBenefits, contains('豊かな表現力'));
      });
    });
  });

  group('CategoryStats', () {
    test('calculates ratios correctly', () {
      final stats = const CategoryStats(
        category: PromptCategory.emotion,
        totalPrompts: 10,
        basicPrompts: 3,
        premiumPrompts: 7,
        isBasicAvailable: true,
      );

      expect(stats.categoryName, '感情'); // PromptCategory.emotion.displayName
      expect(stats.premiumRatio, 0.7);
      expect(stats.basicAvailability, 0.3);
    });

    test('handles zero prompts correctly', () {
      final stats = const CategoryStats(
        category: PromptCategory.emotionDepth,
        totalPrompts: 0,
        basicPrompts: 0,
        premiumPrompts: 0,
        isBasicAvailable: false,
      );

      expect(stats.premiumRatio, 0.0);
      expect(stats.basicAvailability, 0.0);
    });
  });

  group('PromptWeightConfig', () {
    test('has weights for all categories', () {
      for (final category in PromptCategory.values) {
        expect(
          PromptWeightConfig.categoryWeights.containsKey(category),
          true,
          reason: 'Missing weight for category: ${category.displayName}',
        );
      }
    });

    test('calculates priority weights correctly', () {
      expect(PromptWeightConfig.getPriorityWeight(90), 1.2); // High priority
      expect(
        PromptWeightConfig.getPriorityWeight(60),
        1.0,
      ); // Standard priority
      expect(PromptWeightConfig.getPriorityWeight(30), 0.8); // Low priority
    });

    test('calculates recency weights correctly', () {
      expect(PromptWeightConfig.getRecencyWeight(0), 0.1); // Today
      expect(PromptWeightConfig.getRecencyWeight(2), 0.5); // 2 days ago
      expect(PromptWeightConfig.getRecencyWeight(5), 0.8); // 5 days ago
      expect(PromptWeightConfig.getRecencyWeight(10), 1.0); // 10 days ago
    });
  });
}
