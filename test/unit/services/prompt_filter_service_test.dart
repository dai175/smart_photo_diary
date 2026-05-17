import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/services/prompt_cache_service.dart';
import 'package:smart_photo_diary/services/prompt_filter_service.dart';
import '../helpers/writing_prompt_test_helpers.dart';

void main() {
  group('PromptFilterService', () {
    late PromptCacheService cache;
    late PromptFilterService filter;

    setUp(() {
      cache = PromptCacheService(logger: NoOpLogger());
      filter = PromptFilterService(cache: cache, random: Random(0));
      cache.build([
        makeWritingPrompt(id: 'basic_em_1', category: PromptCategory.emotion),
        makeWritingPrompt(id: 'basic_em_2', category: PromptCategory.emotion),
        makeWritingPrompt(
          id: 'premium_ed_1',
          category: PromptCategory.emotionDepth,
          isPremiumOnly: true,
        ),
        makeWritingPrompt(
          id: 'inactive_1',
          category: PromptCategory.emotion,
          isActive: false,
        ),
      ]);
    });

    group('getPromptsForPlan()', () {
      test('Basic プランで isPremiumOnly=true を除外する', () {
        final result = filter.getPromptsForPlan(isPremium: false);
        expect(result.any((p) => p.isPremiumOnly), false);
        expect(result.any((p) => p.id == 'basic_em_1'), true);
      });

      test('Premium プランで全有効プロンプトを含む', () {
        final result = filter.getPromptsForPlan(isPremium: true);
        expect(result.any((p) => p.id == 'premium_ed_1'), true);
        expect(result.any((p) => p.id == 'basic_em_1'), true);
      });

      test('locale 指定でリストが返る', () {
        final result = filter.getPromptsForPlan(
          isPremium: false,
          locale: const Locale('en'),
        );
        expect(result, isNotEmpty);
      });
    });

    group('getPromptsByCategory()', () {
      test('指定カテゴリ + プラン制限が適用される', () {
        final result = filter.getPromptsByCategory(
          PromptCategory.emotion,
          isPremium: false,
        );
        expect(result.every((p) => p.category == PromptCategory.emotion), true);
      });

      test('Basic プランで Premium 限定カテゴリが空リストになる', () {
        final result = filter.getPromptsByCategory(
          PromptCategory.emotionDepth,
          isPremium: false,
        );
        expect(result, isEmpty);
      });

      test('Premium プランで Premium 限定カテゴリが返る', () {
        final result = filter.getPromptsByCategory(
          PromptCategory.emotionDepth,
          isPremium: true,
        );
        expect(result, isNotEmpty);
      });
    });

    group('getById()', () {
      test('存在する ID でプロンプトを返す', () {
        final result = filter.getById('basic_em_1');
        expect(result, isNotNull);
        expect(result!.id, 'basic_em_1');
      });

      test('存在しない ID で null を返す', () {
        expect(filter.getById('non_existent'), isNull);
      });

      test('locale 指定で呼べる', () {
        final result = filter.getById('basic_em_1', locale: const Locale('en'));
        expect(result, isNotNull);
      });
    });

    group('searchPrompts()', () {
      setUp(() {
        cache.build([
          makeWritingPrompt(
            id: 's1',
            category: PromptCategory.emotion,
            text: '今日の感情を振り返ろう',
          ),
          makeWritingPrompt(
            id: 's2',
            category: PromptCategory.emotion,
            text: 'What happened today?',
            tags: ['gratitude', 'reflection'],
          ),
          makeWritingPrompt(
            id: 's3',
            category: PromptCategory.emotionDepth,
            isPremiumOnly: true,
            text: 'Deep emotional exploration',
          ),
        ]);
      });

      test('テキストにマッチするプロンプトが返る', () {
        final result = filter.searchPrompts('感情', isPremium: true);
        expect(result.any((p) => p.id == 's1'), true);
      });

      test('タグにマッチするプロンプトが返る', () {
        final result = filter.searchPrompts('gratitude', isPremium: true);
        expect(result.any((p) => p.id == 's2'), true);
      });

      test('空クエリで全有効プロンプトが返る', () {
        final all = filter.getPromptsForPlan(isPremium: true);
        final result = filter.searchPrompts('', isPremium: true);
        expect(result.length, all.length);
      });

      test('プラン制限が検索結果に適用される', () {
        final result = filter.searchPrompts('Deep', isPremium: false);
        expect(result.any((p) => p.isPremiumOnly), false);
      });
    });

    group('getPromptStatistics()', () {
      test('カテゴリ別件数が正しい', () {
        final stats = filter.getPromptStatistics(isPremium: true);
        expect(stats[PromptCategory.emotion], 2);
        expect(stats[PromptCategory.emotionDepth], 1);
      });

      test('Basic プランで Premium 限定カテゴリが 0 になる', () {
        final stats = filter.getPromptStatistics(isPremium: false);
        expect(stats[PromptCategory.emotionDepth], 0);
        expect(stats[PromptCategory.emotion], greaterThan(0));
      });
    });

    group('getRandomPrompt()', () {
      test('戻り値がプラン制限を満たす（Basic）', () {
        final result = filter.getRandomPrompt(isPremium: false);
        expect(result, isNotNull);
        expect(result!.isPremiumOnly, false);
      });

      test('excludeIds で指定された ID が返らない', () {
        const excludedId = 'basic_em_1';
        final result = filter.getRandomPrompt(
          isPremium: false,
          excludeIds: [excludedId],
        );
        if (result != null) {
          expect(result.id, isNot(excludedId));
        }
      });

      test('候補がない場合 null を返す', () {
        final result = filter.getRandomPrompt(
          isPremium: false,
          category: PromptCategory.emotionDepth,
        );
        expect(result, isNull);
      });

      test('候補1件でその1件が返る（_selectWeightedRandom 間接検証）', () {
        cache.build([
          makeWritingPrompt(
            id: 'only_one',
            category: PromptCategory.emotion,
            priority: 50,
          ),
        ]);
        expect(filter.getRandomPrompt(isPremium: false)?.id, 'only_one');
      });
    });

    group('getRandomPromptSequence()', () {
      test('指定件数・重複なしでプロンプトを返す', () {
        final result = filter.getRandomPromptSequence(
          count: 2,
          isPremium: true,
        );
        expect(result.length, lessThanOrEqualTo(2));
        expect(result.map((p) => p.id).toSet().length, result.length);
      });

      test('count=0 で空リストを返す', () {
        expect(
          filter.getRandomPromptSequence(count: 0, isPremium: true),
          isEmpty,
        );
      });

      test('count が候補数を超えた場合は候補数分返す', () {
        // Basic プランは 2 件のみ
        final result = filter.getRandomPromptSequence(
          count: 100,
          isPremium: false,
        );
        expect(result.length, 2);
      });
    });

    group('localizePrompts()', () {
      test('locale=null でそのままのリストを返す', () {
        final prompts = [
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ];
        final result = filter.localizePrompts(prompts, null);
        expect(result.length, 1);
        expect(result.first.id, 'p1');
      });

      test('locale 指定でリストが返る', () {
        final prompts = [
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ];
        expect(filter.localizePrompts(prompts, const Locale('en')).length, 1);
      });
    });
  });
}
