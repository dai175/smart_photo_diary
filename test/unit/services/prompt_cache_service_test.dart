import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/services/prompt_cache_service.dart';
import '../helpers/writing_prompt_test_helpers.dart';

void main() {
  group('PromptCacheService', () {
    late PromptCacheService cache;

    setUp(() {
      cache = PromptCacheService(logger: NoOpLogger());
    });

    group('build()', () {
      test('正常なリストで Success を返し isBuilt が true になる', () {
        final result = cache.build([
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ]);
        expect(result, isA<Success<void>>());
        expect(cache.isBuilt, true);
      });

      test('空リストで Success を返す', () {
        final result = cache.build([]);
        expect(result, isA<Success<void>>());
        expect(cache.isBuilt, true);
      });
    });

    group('getPlanCache()', () {
      setUp(() {
        cache.build([
          makeWritingPrompt(id: 'basic1', category: PromptCategory.emotion),
          makeWritingPrompt(
            id: 'premium1',
            category: PromptCategory.emotionDepth,
            isPremiumOnly: true,
          ),
          makeWritingPrompt(
            id: 'inactive1',
            category: PromptCategory.emotion,
            isActive: false,
          ),
        ]);
      });

      test('Basic プランで isPremiumOnly=true を除外する', () {
        final result = cache.getPlanCache(false);
        expect(result.any((p) => p.isPremiumOnly), false);
        expect(result.any((p) => p.id == 'basic1'), true);
      });

      test('Premium プランで isPremiumOnly=true を含む', () {
        final result = cache.getPlanCache(true);
        expect(result.any((p) => p.isPremiumOnly), true);
      });

      test('isActive=false を両プランで除外する', () {
        expect(
          cache.getPlanCache(false).any((p) => p.id == 'inactive1'),
          false,
        );
        expect(cache.getPlanCache(true).any((p) => p.id == 'inactive1'), false);
      });
    });

    group('getCategoryCache()', () {
      setUp(() {
        cache.build([
          makeWritingPrompt(id: 'em1', category: PromptCategory.emotion),
          makeWritingPrompt(
            id: 'ed1',
            category: PromptCategory.emotionDepth,
            isPremiumOnly: true,
          ),
          makeWritingPrompt(
            id: 'em_inactive',
            category: PromptCategory.emotion,
            isActive: false,
          ),
        ]);
      });

      test('指定カテゴリのプロンプトのみ返す', () {
        final result = cache.getCategoryCache(PromptCategory.emotion);
        expect(result.every((p) => p.category == PromptCategory.emotion), true);
        expect(
          result.any((p) => p.category == PromptCategory.emotionDepth),
          false,
        );
      });

      test('isActive=false を除外する', () {
        final result = cache.getCategoryCache(PromptCategory.emotion);
        expect(result.any((p) => p.id == 'em_inactive'), false);
      });
    });

    group('getById()', () {
      setUp(() {
        cache.build([
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ]);
      });

      test('存在する ID でプロンプトを返す', () {
        final result = cache.getById('p1');
        expect(result, isNotNull);
        expect(result!.id, 'p1');
      });

      test('存在しない ID で null を返す', () {
        expect(cache.getById('non_existent'), isNull);
      });
    });

    group('clear()', () {
      test('クリア後 isBuilt が false になる', () {
        cache.build([
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ]);
        cache.clear();
        expect(cache.isBuilt, false);
      });

      test('クリア後 getPlanCache() が空リストを返す', () {
        cache.build([
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ]);
        cache.clear();
        expect(cache.getPlanCache(false), isEmpty);
        expect(cache.getPlanCache(true), isEmpty);
      });

      test('クリア後に再 build() で正常動作する', () {
        cache.build([
          makeWritingPrompt(id: 'p1', category: PromptCategory.emotion),
        ]);
        cache.clear();
        cache.build([
          makeWritingPrompt(id: 'p2', category: PromptCategory.emotion),
        ]);
        expect(cache.isBuilt, true);
        expect(cache.getPlanCache(false).any((p) => p.id == 'p2'), true);
        expect(cache.getPlanCache(false).any((p) => p.id == 'p1'), false);
      });
    });
  });
}
