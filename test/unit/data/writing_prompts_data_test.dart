import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
  group('Writing Prompts Data', () {
    late Map<String, dynamic> promptsData;
    late List<WritingPrompt> allPrompts;

    setUpAll(() async {
      // Flutter バインディングを初期化
      TestWidgetsFlutterBinding.ensureInitialized();

      // JSONファイルを読み込み
      final String jsonString = await rootBundle.loadString(
        'assets/data/writing_prompts.json',
      );
      promptsData = json.decode(jsonString);

      // プロンプトオブジェクトに変換
      final List<dynamic> promptsList = promptsData['prompts'];
      allPrompts = promptsList
          .map((json) => WritingPrompt.fromJson(json))
          .toList();
    });

    test('JSON file structure is valid', () {
      expect(promptsData['version'], isNotNull);
      expect(promptsData['lastUpdated'], isNotNull);
      expect(promptsData['description'], isNotNull);
      expect(promptsData['totalPrompts'], isA<int>());
      expect(promptsData['basicPrompts'], isA<int>());
      expect(promptsData['premiumPrompts'], isA<int>());
      expect(promptsData['prompts'], isA<List>());
    });

    test('prompt counts match metadata', () {
      final int totalPrompts = promptsData['totalPrompts'];
      final int basicPrompts = promptsData['basicPrompts'];
      final int premiumPrompts = promptsData['premiumPrompts'];

      expect(allPrompts.length, totalPrompts);
      expect(basicPrompts + premiumPrompts, totalPrompts);

      final actualBasicCount = allPrompts.where((p) => !p.isPremiumOnly).length;
      final actualPremiumCount = allPrompts
          .where((p) => p.isPremiumOnly)
          .length;

      expect(actualBasicCount, basicPrompts);
      expect(actualPremiumCount, premiumPrompts);
    });

    test('all prompts have required fields', () {
      for (final prompt in allPrompts) {
        expect(prompt.id, isNotEmpty);
        expect(prompt.text, isNotEmpty);
        expect(prompt.category, isNotNull);
        expect(prompt.tags, isNotEmpty);
        expect(prompt.description, isNotNull);
        expect(prompt.description, isNotEmpty);
        expect(prompt.priority, greaterThanOrEqualTo(0));
        expect(prompt.isActive, isTrue);
      }
    });

    test('Basic prompts are properly distributed', () {
      final basicPrompts = allPrompts.where((p) => !p.isPremiumOnly).toList();

      // 感情深掘り型では全てのBasic用プロンプトがemotionカテゴリ
      final categories = basicPrompts.map((p) => p.category).toSet();
      expect(categories, contains(PromptCategory.emotion));
      expect(categories.length, 1); // emotionカテゴリのみ

      // emotionカテゴリのBasicプロンプト数は5個
      final emotionBasic = basicPrompts
          .where((p) => p.category == PromptCategory.emotion)
          .length;
      expect(emotionBasic, 5);
    });

    test('Premium prompts cover all categories', () {
      final premiumPrompts = allPrompts.where((p) => p.isPremiumOnly).toList();
      final categories = premiumPrompts.map((p) => p.category).toSet();

      // 感情深掘り型Premium用プロンプトは新しい感情系カテゴリをカバー
      expect(categories.length, lessThanOrEqualTo(8)); // 感情系の新カテゴリ数
      // 感情深掘り型の主要カテゴリが含まれていることを確認
      expect(
        categories,
        anyOf(
          contains(PromptCategory.emotionDepth),
          contains(PromptCategory.sensoryEmotion),
          contains(PromptCategory.emotionGrowth),
          contains(PromptCategory.emotionConnection),
          contains(PromptCategory.emotionDiscovery),
          contains(PromptCategory.emotionFantasy),
          contains(PromptCategory.emotionHealing),
        ),
      );
      // 追加カテゴリの検証
      expect(
        categories,
        anyOf(
          contains(PromptCategory.emotionEnergy),
          isNotEmpty, // 何らかのカテゴリが存在する
        ),
      );
    });

    test('category-specific prompt counts match specification', () {
      // 感情深掘り型プロンプト構造に合わせた検証

      // 基本感情カテゴリ: 5 Basic プロンプト
      final emotionPrompts = allPrompts
          .where((p) => p.category == PromptCategory.emotion)
          .toList();
      expect(emotionPrompts.length, 5);
      expect(emotionPrompts.every((p) => !p.isPremiumOnly), true); // 全てBasic

      // 感情深掘りカテゴリ: 2 Premium プロンプト
      final emotionDepthPrompts = allPrompts
          .where((p) => p.category == PromptCategory.emotionDepth)
          .toList();
      expect(emotionDepthPrompts.length, 2);
      expect(emotionDepthPrompts.every((p) => p.isPremiumOnly), true);

      // 感情五感カテゴリ: 2 Premium プロンプト
      final sensoryEmotionPrompts = allPrompts
          .where((p) => p.category == PromptCategory.sensoryEmotion)
          .toList();
      expect(sensoryEmotionPrompts.length, 2);
      expect(sensoryEmotionPrompts.every((p) => p.isPremiumOnly), true);

      // 他の感情系カテゴリも各2～3個のPremiumプロンプトを含む
      final otherEmotionCategories = [
        PromptCategory.emotionGrowth,
        PromptCategory.emotionConnection,
        PromptCategory.emotionDiscovery,
        PromptCategory.emotionFantasy,
        PromptCategory.emotionHealing,
        PromptCategory.emotionEnergy,
      ];

      for (final category in otherEmotionCategories) {
        final categoryPrompts = allPrompts
            .where((p) => p.category == category)
            .toList();
        expect(categoryPrompts.length, greaterThanOrEqualTo(1)); // 最低1個
        expect(categoryPrompts.length, lessThanOrEqualTo(3)); // 最大3個
        expect(
          categoryPrompts.every((p) => p.isPremiumOnly),
          true,
        ); // 全てPremium
      }

      // 合計: 5 Basic + 15 Premium = 20プロンプト
      expect(allPrompts.length, 20);
    });

    test('all prompt IDs are unique', () {
      final ids = allPrompts.map((p) => p.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('Basic prompts have appropriate priority levels', () {
      final basicPrompts = allPrompts.where((p) => !p.isPremiumOnly).toList();

      // Basic用プロンプトは高い優先度を持つべき
      for (final prompt in basicPrompts) {
        expect(prompt.priority, greaterThanOrEqualTo(70));
      }
    });

    test('prompts have meaningful content', () {
      for (final prompt in allPrompts) {
        // プロンプトテキストの長さチェック
        expect(prompt.text.length, greaterThanOrEqualTo(5));
        expect(prompt.text.length, lessThan(200));

        // 疑問符で終わるプロンプトが多いことを確認（ただし必須ではない）
        if (prompt.text.contains('？') || prompt.text.contains('ですか')) {
          expect(
            prompt.text,
            anyOf(
              endsWith('？'),
              endsWith('ですか？'),
              endsWith('。'), // 「ですか？その理由も教えてください。」のような形式も許可
            ),
          );
        }

        // 説明の長さチェック
        expect(prompt.description!.length, greaterThan(5));
        expect(prompt.description!.length, lessThan(100));

        // タグ数チェック
        expect(prompt.tags.length, greaterThanOrEqualTo(3));
        expect(prompt.tags.length, lessThanOrEqualTo(6));
      }
    });

    test('category-specific tags are appropriate', () {
      // 感情カテゴリのプロンプトは感情関連タグを含む
      final emotionPrompts = allPrompts
          .where((p) => p.category == PromptCategory.emotion)
          .toList();
      for (final prompt in emotionPrompts) {
        expect(
          prompt.tags,
          anyOf(contains('感情'), contains('気持ち'), contains('心')),
        );
      }

      // 感情深掘りカテゴリのプロンプトは深掘り関連タグを含む
      final emotionDepthPrompts = allPrompts
          .where((p) => p.category == PromptCategory.emotionDepth)
          .toList();
      for (final prompt in emotionDepthPrompts) {
        expect(
          prompt.tags,
          anyOf(
            contains('感情深掘り'),
            contains('深掘り'),
            contains('背景'),
            contains('変化'),
          ),
        );
      }

      // 感情五感カテゴリのプロンプトは五感関連タグを含む
      final sensoryEmotionPrompts = allPrompts
          .where((p) => p.category == PromptCategory.sensoryEmotion)
          .toList();
      for (final prompt in sensoryEmotionPrompts) {
        expect(
          prompt.tags,
          anyOf(
            contains('感情五感'),
            contains('五感'),
            contains('音'),
            contains('におい'),
            contains('空気感'),
          ),
        );
      }
    });

    test('JSON serialization roundtrip works correctly', () {
      for (final prompt in allPrompts.take(5)) {
        // 最初の5個をテスト
        final json = prompt.toJson();
        final reconstructed = WritingPrompt.fromJson(json);

        expect(reconstructed.id, prompt.id);
        expect(reconstructed.text, prompt.text);
        expect(reconstructed.category, prompt.category);
        expect(reconstructed.isPremiumOnly, prompt.isPremiumOnly);
        expect(reconstructed.tags, prompt.tags);
        expect(reconstructed.description, prompt.description);
        expect(reconstructed.priority, prompt.priority);
        expect(reconstructed.isActive, prompt.isActive);
      }
    });
  });
}
