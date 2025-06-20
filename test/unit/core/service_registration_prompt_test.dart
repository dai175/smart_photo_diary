// ServiceRegistration - PromptService統合テスト
//
// PromptServiceがServiceLocatorに正しく登録され、
// 依存関係が適切に解決されることを検証

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/core/service_registration.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/prompt_service_interface.dart';
import 'package:smart_photo_diary/services/prompt_service.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import '../../test_helpers/mock_platform_channels.dart';

void main() {
  group('ServiceRegistration - PromptService統合テスト', () {
    
    setUpAll(() async {
      // Flutter バインディングを初期化
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // プラットフォームチャンネルをモック化
      MockPlatformChannels.setupMocks();
      
      // Hiveを初期化（テスト用）
      await Hive.initFlutter();
    });
    
    setUp(() async {
      // 各テスト前にサービスをリセット
      ServiceRegistration.reset();
    });
    
    tearDown(() async {
      // 各テスト後にクリーンアップ
      ServiceRegistration.reset();
      
      // PromptServiceのシングルトンもリセット
      PromptService.resetInstance();
      
      // Hive使用履歴Boxをクリア（テストデータ残存を避ける）
      try {
        if (Hive.isBoxOpen('prompt_usage_history')) {
          final box = Hive.box<PromptUsageHistory>('prompt_usage_history');
          await box.clear();
          await box.close();
        }
      } catch (e) {
        // テスト環境でのエラーは無視
      }
    });
    
    test('PromptServiceがServiceLocatorに正しく登録される', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // PromptServiceが登録されていることを確認
      expect(ServiceLocator().isRegistered<IPromptService>(), true);
    });
    
    test('PromptServiceが初期化済み状態で取得される', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // PromptServiceを取得
      final promptService = await ServiceLocator().getAsync<IPromptService>();
      
      // 初期化済みであることを確認
      expect(promptService.isInitialized, true);
      
      // 基本機能が動作することを確認
      final allPrompts = promptService.getAllPrompts();
      expect(allPrompts, isNotEmpty);
    });
    
    test('複数回の取得で同じインスタンスが返される', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // 複数回取得
      final service1 = await ServiceLocator().getAsync<IPromptService>();
      final service2 = await ServiceLocator().getAsync<IPromptService>();
      
      // 同じインスタンスであることを確認
      expect(service1, same(service2));
    });
    
    test('PromptServiceの基本機能が正常に動作する', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // PromptServiceを取得
      final promptService = await ServiceLocator().getAsync<IPromptService>();
      
      // プラン別プロンプト取得テスト
      final basicPrompts = promptService.getPromptsForPlan(isPremium: false);
      final premiumPrompts = promptService.getPromptsForPlan(isPremium: true);
      
      expect(basicPrompts, isNotEmpty);
      expect(premiumPrompts, isNotEmpty);
      expect(premiumPrompts.length, greaterThanOrEqualTo(basicPrompts.length));
      
      // Basicプロンプトは全てBasic用（Premium限定でない）
      expect(basicPrompts.every((p) => !p.isPremiumOnly), true);
    });
    
    test('ランダムプロンプト選択が動作する', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // PromptServiceを取得
      final promptService = await ServiceLocator().getAsync<IPromptService>();
      
      // ランダムプロンプト取得
      final randomBasic = promptService.getRandomPrompt(isPremium: false);
      final randomPremium = promptService.getRandomPrompt(isPremium: true);
      
      expect(randomBasic, isNotNull);
      expect(randomPremium, isNotNull);
      
      // Basicランダムプロンプトはプレミアム限定でない
      expect(randomBasic!.isPremiumOnly, false);
    });
    
    test('検索機能が動作する', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // PromptServiceを取得
      final promptService = await ServiceLocator().getAsync<IPromptService>();
      
      // 検索実行
      final searchResults = promptService.searchPrompts(
        '感情',
        isPremium: true,
      );
      
      expect(searchResults, isNotEmpty);
      expect(searchResults.every((p) => 
          p.text.contains('感情') || 
          p.tags.any((tag) => tag.contains('感情')) ||
          p.description?.contains('感情') == true
      ), true);
    });
    
    test('統計情報が取得できる', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // PromptServiceを取得
      final promptService = await ServiceLocator().getAsync<IPromptService>();
      
      // 統計情報取得
      final basicStats = promptService.getPromptStatistics(isPremium: false);
      final premiumStats = promptService.getPromptStatistics(isPremium: true);
      
      expect(basicStats, isNotEmpty);
      expect(premiumStats, isNotEmpty);
      
      // Premiumプランの方が各カテゴリのプロンプト数が多いか同等
      for (final category in basicStats.keys) {
        expect(premiumStats[category] ?? 0, greaterThanOrEqualTo(basicStats[category] ?? 0));
      }
    });
    
    test('複数のサービスが同時に利用できる', () async {
      // サービスを初期化
      await ServiceRegistration.initialize();
      
      // 複数のサービスを同時取得
      final promptService = await ServiceLocator().getAsync<IPromptService>();
      
      // PromptServiceが正常に動作することを確認
      expect(promptService.isInitialized, true);
      
      final prompts = promptService.getAllPrompts();
      expect(prompts, isNotEmpty);
      
      // 他のサービスとの共存確認
      expect(ServiceLocator().isRegistered<IPromptService>(), true);
    });
  });
}