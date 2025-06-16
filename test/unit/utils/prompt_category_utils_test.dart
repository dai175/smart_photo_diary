import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/utils/prompt_category_utils.dart';

void main() {
  group('PromptCategoryUtils', () {
    group('getAvailableCategories', () {
      test('returns all categories for Premium users', () {
        final categories = PromptCategoryUtils.getAvailableCategories(isPremium: true);
        
        expect(categories.length, PromptCategory.values.length);
        expect(categories, containsAll(PromptCategory.values));
      });
      
      test('returns limited categories for Basic users', () {
        final categories = PromptCategoryUtils.getAvailableCategories(isPremium: false);
        
        expect(categories, [
          PromptCategory.daily,
          PromptCategory.gratitude,
        ]);
        expect(categories.length, 2);
      });
    });
    
    group('isBasicAvailable', () {
      test('returns true for Basic-available categories', () {
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.daily), true);
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.gratitude), true);
      });
      
      test('returns false for Premium-only categories', () {
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.travel), false);
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.work), false);
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.reflection), false);
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.creative), false);
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.wellness), false);
        expect(PromptCategoryUtils.isBasicAvailable(PromptCategory.relationships), false);
      });
    });
    
    group('getBasicPromptCount', () {
      test('returns correct basic prompt counts', () {
        expect(PromptCategoryUtils.getBasicPromptCount(PromptCategory.daily), 3);
        expect(PromptCategoryUtils.getBasicPromptCount(PromptCategory.gratitude), 2);
        expect(PromptCategoryUtils.getBasicPromptCount(PromptCategory.travel), 0);
        expect(PromptCategoryUtils.getBasicPromptCount(PromptCategory.work), 0);
        expect(PromptCategoryUtils.getBasicPromptCount(PromptCategory.reflection), 0);
      });
    });
    
    group('getPremiumPromptCount', () {
      test('returns correct premium prompt counts', () {
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.daily), 8);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.travel), 6);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.work), 7);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.gratitude), 6);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.reflection), 8);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.creative), 6);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.wellness), 6);
        expect(PromptCategoryUtils.getPremiumPromptCount(PromptCategory.relationships), 7);
      });
    });
    
    group('getTotalPromptCount', () {
      test('returns basic count for Basic users', () {
        expect(
          PromptCategoryUtils.getTotalPromptCount(PromptCategory.daily, isPremium: false),
          3,
        );
        expect(
          PromptCategoryUtils.getTotalPromptCount(PromptCategory.gratitude, isPremium: false),
          2,
        );
      });
      
      test('returns total count for Premium users', () {
        expect(
          PromptCategoryUtils.getTotalPromptCount(PromptCategory.daily, isPremium: true),
          11, // 3 basic + 8 premium
        );
        expect(
          PromptCategoryUtils.getTotalPromptCount(PromptCategory.gratitude, isPremium: true),
          8, // 2 basic + 6 premium
        );
        expect(
          PromptCategoryUtils.getTotalPromptCount(PromptCategory.travel, isPremium: true),
          6, // 0 basic + 6 premium
        );
      });
    });
    
    group('getCategoryDescription', () {
      test('returns correct descriptions for all categories', () {
        expect(
          PromptCategoryUtils.getCategoryDescription(PromptCategory.daily),
          '日々の出来事や感情を記録し、日常の価値を再発見する',
        );
        expect(
          PromptCategoryUtils.getCategoryDescription(PromptCategory.travel),
          '旅行体験を深く記録し、文化的発見と思い出を鮮明に保存する',
        );
        expect(
          PromptCategoryUtils.getCategoryDescription(PromptCategory.gratitude),
          'ポジティブ心理学に基づいた感謝の記録で心理的健康を向上させる',
        );
      });
    });
    
    group('getRecommendedTags', () {
      test('returns appropriate tags for each category', () {
        final dailyTags = PromptCategoryUtils.getRecommendedTags(PromptCategory.daily);
        expect(dailyTags, contains('日常'));
        expect(dailyTags, contains('気持ち'));
        expect(dailyTags, contains('発見'));
        
        final travelTags = PromptCategoryUtils.getRecommendedTags(PromptCategory.travel);
        expect(travelTags, contains('旅行'));
        expect(travelTags, contains('発見'));
        expect(travelTags, contains('文化'));
        
        final gratitudeTags = PromptCategoryUtils.getRecommendedTags(PromptCategory.gratitude);
        expect(gratitudeTags, contains('感謝'));
        expect(gratitudeTags, contains('幸せ'));
        expect(gratitudeTags, contains('大切'));
      });
    });
    
    group('filterPromptsByPlan', () {
      late List<WritingPrompt> testPrompts;
      
      setUp(() {
        testPrompts = [
          WritingPrompt(
            id: 'basic-daily-1',
            text: 'What happened today?',
            category: PromptCategory.daily,
            isPremiumOnly: false,
          ),
          WritingPrompt(
            id: 'premium-daily-1',
            text: 'Reflect deeply on today',
            category: PromptCategory.daily,
            isPremiumOnly: true,
          ),
          WritingPrompt(
            id: 'basic-gratitude-1',
            text: 'What are you thankful for?',
            category: PromptCategory.gratitude,
            isPremiumOnly: false,
          ),
          WritingPrompt(
            id: 'premium-travel-1',
            text: 'Describe your travel experience',
            category: PromptCategory.travel,
            isPremiumOnly: true,
          ),
          WritingPrompt(
            id: 'inactive-prompt',
            text: 'Inactive prompt',
            category: PromptCategory.daily,
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
        
        expect(filtered.length, 2);
        expect(filtered.map((p) => p.id), containsAll([
          'basic-daily-1',
          'basic-gratitude-1',
        ]));
      });
      
      test('includes all active prompts for Premium users', () {
        final filtered = PromptCategoryUtils.filterPromptsByPlan(
          testPrompts,
          isPremium: true,
        );
        
        expect(filtered.length, 4);
        expect(filtered.map((p) => p.id), containsAll([
          'basic-daily-1',
          'premium-daily-1',
          'basic-gratitude-1',
          'premium-travel-1',
        ]));
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
            category: PromptCategory.daily,
            isPremiumOnly: false,
          ),
          WritingPrompt(
            id: '2',
            text: 'Test 2',
            category: PromptCategory.daily,
            isPremiumOnly: true,
          ),
          WritingPrompt(
            id: '3',
            text: 'Test 3',
            category: PromptCategory.travel,
            isPremiumOnly: true,
          ),
        ];
        
        final stats = PromptCategoryUtils.getCategoryStats(prompts);
        
        // Daily category stats
        final dailyStats = stats[PromptCategory.daily]!;
        expect(dailyStats.totalPrompts, 2);
        expect(dailyStats.basicPrompts, 1);
        expect(dailyStats.premiumPrompts, 1);
        expect(dailyStats.isBasicAvailable, true);
        expect(dailyStats.premiumRatio, 0.5);
        expect(dailyStats.basicAvailability, 0.5);
        
        // Travel category stats
        final travelStats = stats[PromptCategory.travel]!;
        expect(travelStats.totalPrompts, 1);
        expect(travelStats.basicPrompts, 0);
        expect(travelStats.premiumPrompts, 1);
        expect(travelStats.isBasicAvailable, false);
        expect(travelStats.premiumRatio, 1.0);
        expect(travelStats.basicAvailability, 0.0);
        
        // Empty category stats
        final gratitudeStats = stats[PromptCategory.gratitude]!;
        expect(gratitudeStats.totalPrompts, 0);
        expect(gratitudeStats.basicPrompts, 0);
        expect(gratitudeStats.premiumPrompts, 0);
        expect(gratitudeStats.premiumRatio, 0.0);
        expect(gratitudeStats.basicAvailability, 0.0);
      });
    });
    
    group('getPremiumOnlyCategories', () {
      test('returns all Premium-only categories', () {
        final premiumOnly = PromptCategoryUtils.getPremiumOnlyCategories();
        
        expect(premiumOnly, containsAll([
          PromptCategory.travel,
          PromptCategory.work,
          PromptCategory.reflection,
          PromptCategory.creative,
          PromptCategory.wellness,
          PromptCategory.relationships,
        ]));
        expect(premiumOnly, isNot(contains(PromptCategory.daily)));
        expect(premiumOnly, isNot(contains(PromptCategory.gratitude)));
      });
    });
    
    group('getExpectedBenefits', () {
      test('returns expected benefits for each category', () {
        final dailyBenefits = PromptCategoryUtils.getExpectedBenefits(PromptCategory.daily);
        expect(dailyBenefits, contains('日記習慣の継続促進'));
        expect(dailyBenefits, contains('日常生活への意識向上'));
        
        final workBenefits = PromptCategoryUtils.getExpectedBenefits(PromptCategory.work);
        expect(workBenefits, contains('キャリア発展の記録'));
        expect(workBenefits, contains('スキル向上の自覚'));
        
        final gratitudeBenefits = PromptCategoryUtils.getExpectedBenefits(PromptCategory.gratitude);
        expect(gratitudeBenefits, contains('心理的ウェルビーイングの向上'));
        expect(gratitudeBenefits, contains('ポジティブ思考の強化'));
      });
    });
  });
  
  group('CategoryStats', () {
    test('calculates ratios correctly', () {
      final stats = CategoryStats(
        category: PromptCategory.daily,
        totalPrompts: 10,
        basicPrompts: 3,
        premiumPrompts: 7,
        isBasicAvailable: true,
      );
      
      expect(stats.categoryName, '日常');
      expect(stats.premiumRatio, 0.7);
      expect(stats.basicAvailability, 0.3);
    });
    
    test('handles zero prompts correctly', () {
      final stats = CategoryStats(
        category: PromptCategory.travel,
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
      expect(PromptWeightConfig.getPriorityWeight(60), 1.0); // Standard priority
      expect(PromptWeightConfig.getPriorityWeight(30), 0.8); // Low priority
    });
    
    test('calculates recency weights correctly', () {
      expect(PromptWeightConfig.getRecencyWeight(0), 0.1);  // Today
      expect(PromptWeightConfig.getRecencyWeight(2), 0.5);  // 2 days ago
      expect(PromptWeightConfig.getRecencyWeight(5), 0.8);  // 5 days ago
      expect(PromptWeightConfig.getRecencyWeight(10), 1.0); // 10 days ago
    });
  });
}