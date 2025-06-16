import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

void main() {
  group('Writing Prompts Data', () {
    late Map<String, dynamic> promptsData;
    late List<WritingPrompt> allPrompts;
    
    setUpAll(() async {
      // JSONファイルを読み込み
      final String jsonString = await rootBundle.loadString('assets/data/writing_prompts.json');
      promptsData = json.decode(jsonString);
      
      // プロンプトオブジェクトに変換
      final List<dynamic> promptsList = promptsData['prompts'];
      allPrompts = promptsList.map((json) => WritingPrompt.fromJson(json)).toList();
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
      final actualPremiumCount = allPrompts.where((p) => p.isPremiumOnly).length;
      
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
      
      // Basic用プロンプトは日常と感謝のカテゴリのみ
      final categories = basicPrompts.map((p) => p.category).toSet();
      expect(categories, containsAll([PromptCategory.daily, PromptCategory.gratitude]));
      expect(categories.length, 2);
      
      // 日常カテゴリのBasicプロンプト数
      final dailyBasic = basicPrompts.where((p) => p.category == PromptCategory.daily).length;
      expect(dailyBasic, 3);
      
      // 感謝カテゴリのBasicプロンプト数
      final gratitudeBasic = basicPrompts.where((p) => p.category == PromptCategory.gratitude).length;
      expect(gratitudeBasic, 2);
    });
    
    test('Premium prompts cover all categories', () {
      final premiumPrompts = allPrompts.where((p) => p.isPremiumOnly).toList();
      final categories = premiumPrompts.map((p) => p.category).toSet();
      
      // Premium用プロンプトは全8カテゴリをカバー
      expect(categories.length, 8);
      expect(categories, containsAll(PromptCategory.values));
    });
    
    test('category-specific prompt counts match specification', () {
      // 日常カテゴリ: 3 Basic + 8 Premium = 11
      final dailyPrompts = allPrompts.where((p) => p.category == PromptCategory.daily).toList();
      expect(dailyPrompts.length, 11);
      
      // 感謝カテゴリ: 2 Basic + 6 Premium = 8
      final gratitudePrompts = allPrompts.where((p) => p.category == PromptCategory.gratitude).toList();
      expect(gratitudePrompts.length, 8);
      
      // 旅行カテゴリ: 6 Premium
      final travelPrompts = allPrompts.where((p) => p.category == PromptCategory.travel).toList();
      expect(travelPrompts.length, 6);
      expect(travelPrompts.every((p) => p.isPremiumOnly), true);
      
      // 仕事カテゴリ: 7 Premium
      final workPrompts = allPrompts.where((p) => p.category == PromptCategory.work).toList();
      expect(workPrompts.length, 7);
      expect(workPrompts.every((p) => p.isPremiumOnly), true);
      
      // 振り返りカテゴリ: 8 Premium
      final reflectionPrompts = allPrompts.where((p) => p.category == PromptCategory.reflection).toList();
      expect(reflectionPrompts.length, 8);
      expect(reflectionPrompts.every((p) => p.isPremiumOnly), true);
      
      // 創作カテゴリ: 6 Premium
      final creativePrompts = allPrompts.where((p) => p.category == PromptCategory.creative).toList();
      expect(creativePrompts.length, 6);
      expect(creativePrompts.every((p) => p.isPremiumOnly), true);
      
      // 健康・ウェルネスカテゴリ: 6 Premium
      final wellnessPrompts = allPrompts.where((p) => p.category == PromptCategory.wellness).toList();
      expect(wellnessPrompts.length, 6);
      expect(wellnessPrompts.every((p) => p.isPremiumOnly), true);
      
      // 人間関係カテゴリ: 7 Premium
      final relationshipsPrompts = allPrompts.where((p) => p.category == PromptCategory.relationships).toList();
      expect(relationshipsPrompts.length, 7);
      expect(relationshipsPrompts.every((p) => p.isPremiumOnly), true);
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
        expect(prompt.text.length, greaterThan(10));
        expect(prompt.text.length, lessThan(200));
        
        // 疑問符で終わるプロンプトが多いことを確認（ただし必須ではない）
        if (prompt.text.contains('？') || prompt.text.contains('ですか')) {
          expect(prompt.text, anyOf(endsWith('？'), endsWith('ですか？')));
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
      // 日常カテゴリのプロンプトは日常関連タグを含む
      final dailyPrompts = allPrompts.where((p) => p.category == PromptCategory.daily).toList();
      for (final prompt in dailyPrompts) {
        expect(prompt.tags, anyOf(contains('日常'), contains('今日')));
      }
      
      // 感謝カテゴリのプロンプトは感謝関連タグを含む
      final gratitudePrompts = allPrompts.where((p) => p.category == PromptCategory.gratitude).toList();
      for (final prompt in gratitudePrompts) {
        expect(prompt.tags, contains('感謝'));
      }
      
      // 旅行カテゴリのプロンプトは旅行関連タグを含む
      final travelPrompts = allPrompts.where((p) => p.category == PromptCategory.travel).toList();
      for (final prompt in travelPrompts) {
        expect(prompt.tags, contains('旅行'));
      }
    });
    
    test('JSON serialization roundtrip works correctly', () {
      for (final prompt in allPrompts.take(5)) { // 最初の5個をテスト
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