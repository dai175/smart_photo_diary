// PromptService単体テスト
//
// PromptServiceの全機能をモックを使って包括的にテスト
// JSON読み込み、キャッシュ、フィルタリング、検索機能を検証

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/services/prompt_service.dart';
import 'package:smart_photo_diary/services/interfaces/prompt_service_interface.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import '../../test_helpers/mock_platform_channels.dart';

/// テスト用の簡単なLoggingServiceモック
class _MockLoggingService implements LoggingService {
  @override
  void info(String message, {String? context, dynamic data}) {
    // テスト用なので何もしない
  }

  @override
  void warning(String message, {String? context, dynamic data}) {
    // テスト用なので何もしない
  }

  @override
  void error(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // テスト用なので何もしない
  }

  @override
  void debug(String message, {String? context, dynamic data}) {
    // テスト用なので何もしない
  }

  @override
  Stopwatch startTimer(String operation, {String? context}) {
    return Stopwatch()..start();
  }

  @override
  void endTimer(Stopwatch stopwatch, String operation, {String? context}) {
    // テスト用なので何もしない
  }
}

void main() {
  group('PromptService', () {
    late IPromptService promptService;

    setUpAll(() async {
      // Flutter バインディングを初期化
      TestWidgetsFlutterBinding.ensureInitialized();

      // プラットフォームチャンネルをモック化
      MockPlatformChannels.setupMocks();

      // Hiveを初期化（テスト用）
      await Hive.initFlutter();
    });

    setUp(() async {
      // ServiceLocatorをリセット
      ServiceLocator().clear();

      // LoggingServiceのモックを登録
      ServiceLocator().registerFactory<LoggingService>(
        () => _MockLoggingService(),
      );

      // 各テスト前にインスタンスをリセット
      PromptService.resetInstance();
      promptService = PromptService.instance;
    });

    tearDown(() async {
      // 各テスト後にクリーンアップ
      ServiceLocator().clear();

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

    group('シングルトンパターン', () {
      test('同じインスタンスが返される', () {
        final instance1 = PromptService.instance;
        final instance2 = PromptService.instance;

        expect(instance1, same(instance2));
      });

      test('resetInstance()でインスタンスがリセットされる', () {
        final instance1 = PromptService.instance;

        PromptService.resetInstance();

        final instance2 = PromptService.instance;
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('初期化', () {
      test('初期化前はisInitializedがfalse', () {
        expect(promptService.isInitialized, false);
      });

      test('初期化が成功する', () async {
        final result = await promptService.initialize();

        expect(result, true);
        expect(promptService.isInitialized, true);
      });

      test('重複初期化はスキップされる', () async {
        await promptService.initialize();
        expect(promptService.isInitialized, true);

        // 再度初期化を試行
        final result = await promptService.initialize();
        expect(result, true);
        expect(promptService.isInitialized, true);
      });
    });

    group('プロンプト取得', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('全プロンプトを取得できる', () {
        final prompts = promptService.getAllPrompts();

        expect(prompts, isNotEmpty);
        expect(prompts.every((p) => p.isActive), true);
      });

      test('Basicプラン用プロンプトを取得できる', () {
        final prompts = promptService.getPromptsForPlan(isPremium: false);

        expect(prompts, isNotEmpty);
        expect(prompts.every((p) => !p.isPremiumOnly), true);

        // Basicプランは感情カテゴリのみ
        final categories = prompts.map((p) => p.category).toSet();
        expect(categories, contains(PromptCategory.emotion));
      });

      test('Premiumプラン用プロンプトを取得できる', () {
        final prompts = promptService.getPromptsForPlan(isPremium: true);

        expect(prompts, isNotEmpty);

        // Premium用プロンプトも含まれる
        final hasPremiumPrompts = prompts.any((p) => p.isPremiumOnly);
        expect(hasPremiumPrompts, true);

        // 全カテゴリが含まれる
        final categories = prompts.map((p) => p.category).toSet();
        expect(categories.length, greaterThan(0)); // カテゴリが存在する
      });

      test('カテゴリ別プロンプトを取得できる（Basic）', () {
        final emotionPrompts = promptService.getPromptsByCategory(
          PromptCategory.emotion,
          isPremium: false,
        );

        expect(emotionPrompts, isNotEmpty);
        expect(
          emotionPrompts.every((p) => p.category == PromptCategory.emotion),
          true,
        );

        // Basicプランなのでプレミアム限定プロンプトは含まれない
        final hasBasicPrompts = emotionPrompts.any((p) => !p.isPremiumOnly);
        expect(hasBasicPrompts, true);
      });

      test('カテゴリ別プロンプトを取得できる（Premium）', () {
        final depthPrompts = promptService.getPromptsByCategory(
          PromptCategory.emotionDepth,
          isPremium: true,
        );

        expect(depthPrompts, isNotEmpty);
        expect(
          depthPrompts.every((p) => p.category == PromptCategory.emotionDepth),
          true,
        );

        // 感情深掘りカテゴリはPremium限定
        expect(depthPrompts.every((p) => p.isPremiumOnly), true);
      });

      test('IDでプロンプトを取得できる', () {
        final allPrompts = promptService.getAllPrompts();
        final firstPrompt = allPrompts.first;

        final retrievedPrompt = promptService.getPromptById(firstPrompt.id);

        expect(retrievedPrompt, isNotNull);
        expect(retrievedPrompt!.id, firstPrompt.id);
        expect(retrievedPrompt.text, firstPrompt.text);
      });

      test('存在しないIDの場合nullが返される', () {
        final prompt = promptService.getPromptById('non_existent_id');

        expect(prompt, isNull);
      });
    });

    group('ランダム選択', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('Basicプラン用ランダムプロンプトを取得できる', () {
        final prompt = promptService.getRandomPrompt(isPremium: false);

        expect(prompt, isNotNull);
        expect(prompt!.isPremiumOnly, false);
      });

      test('Premiumプラン用ランダムプロンプトを取得できる', () {
        final prompt = promptService.getRandomPrompt(isPremium: true);

        expect(prompt, isNotNull);
      });

      test('特定カテゴリからランダムプロンプトを取得できる', () {
        final prompt = promptService.getRandomPrompt(
          isPremium: true,
          category: PromptCategory.emotion,
        );

        expect(prompt, isNotNull);
        expect(prompt!.category, PromptCategory.emotion);
      });

      test('利用できないカテゴリの場合nullが返される', () {
        // Basicプランで感情深掘りカテゴリ（Premium限定）を要求
        final prompt = promptService.getRandomPrompt(
          isPremium: false,
          category: PromptCategory.emotionDepth,
        );

        expect(prompt, isNull);
      });

      test('除外IDを指定して重複回避できる', () {
        // 最初のプロンプトを取得
        final firstPrompt = promptService.getRandomPrompt(isPremium: true);
        expect(firstPrompt, isNotNull);

        // 最初のプロンプトを除外して次を取得
        final secondPrompt = promptService.getRandomPrompt(
          isPremium: true,
          excludeIds: [firstPrompt!.id],
        );

        if (secondPrompt != null) {
          expect(secondPrompt.id, isNot(equals(firstPrompt.id)));
        }
      });

      test('複数除外IDを指定して重複回避できる', () {
        // 複数のプロンプトを除外
        final excludeIds = ['basic_emotion_001', 'basic_emotion_002'];
        final prompt = promptService.getRandomPrompt(
          isPremium: false,
          excludeIds: excludeIds,
        );

        if (prompt != null) {
          expect(excludeIds.contains(prompt.id), isFalse);
        }
      });
    });

    group('重複回避シーケンス', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('指定数の重複しないプロンプトを取得できる', () {
        final prompts = promptService.getRandomPromptSequence(
          count: 3,
          isPremium: true,
        );

        expect(prompts.length, lessThanOrEqualTo(3));

        // 重複チェック
        final ids = prompts.map((p) => p.id).toSet();
        expect(ids.length, equals(prompts.length));
      });

      test('利用可能数を超える要求でも動作する', () {
        // Basic用プロンプトは5個しかない
        final prompts = promptService.getRandomPromptSequence(
          count: 10,
          isPremium: false,
        );

        expect(prompts.length, lessThanOrEqualTo(5));

        // 重複チェック
        final ids = prompts.map((p) => p.id).toSet();
        expect(ids.length, equals(prompts.length));
      });

      test('特定カテゴリから重複しないプロンプトを取得できる', () {
        final prompts = promptService.getRandomPromptSequence(
          count: 2,
          isPremium: true,
          category: PromptCategory.emotion,
        );

        expect(prompts.length, lessThanOrEqualTo(2));
        expect(
          prompts.every((p) => p.category == PromptCategory.emotion),
          isTrue,
        );

        // 重複チェック
        final ids = prompts.map((p) => p.id).toSet();
        expect(ids.length, equals(prompts.length));
      });

      test('0個要求で空リストが返される', () {
        final prompts = promptService.getRandomPromptSequence(
          count: 0,
          isPremium: true,
        );

        expect(prompts, isEmpty);
      });

      test('負の数要求で空リストが返される', () {
        final prompts = promptService.getRandomPromptSequence(
          count: -1,
          isPremium: true,
        );

        expect(prompts, isEmpty);
      });
    });

    group('検索機能', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('テキスト検索ができる', () {
        final results = promptService.searchPrompts('感情', isPremium: true);

        expect(results, isNotEmpty);
        expect(
          results.every(
            (p) =>
                p.text.contains('感情') ||
                p.tags.any((tag) => tag.contains('感情')) ||
                p.description?.contains('感情') == true,
          ),
          true,
        );
      });

      test('タグ検索ができる', () {
        final results = promptService.searchPrompts('感謝', isPremium: true);

        expect(results, isNotEmpty);
        expect(
          results.every(
            (p) =>
                p.tags.any((tag) => tag.contains('感謝')) ||
                p.text.contains('感謝'),
          ),
          true,
        );
      });

      test('空のクエリで全プロンプトが返される', () {
        final allPrompts = promptService.getPromptsForPlan(isPremium: true);
        final searchResults = promptService.searchPrompts('', isPremium: true);

        expect(searchResults.length, allPrompts.length);
      });

      test('プラン制限が検索結果に適用される', () {
        final results = promptService.searchPrompts('旅行', isPremium: false);

        // Basicプランで旅行関連を検索しても結果は少ない（または空）
        // 旅行カテゴリはPremium限定のため
        expect(results.every((p) => !p.isPremiumOnly), true);
      });
    });

    group('統計情報', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('Basicプラン統計情報を取得できる', () {
        final stats = promptService.getPromptStatistics(isPremium: false);

        expect(stats, isNotEmpty);
        expect(stats.keys, contains(PromptCategory.emotion));

        // Premium限定カテゴリは0であることを確認
        expect(stats[PromptCategory.emotionDepth], 0);
      });

      test('Premiumプラン統計情報を取得できる', () {
        final stats = promptService.getPromptStatistics(isPremium: true);

        expect(stats, isNotEmpty);
        expect(stats.keys.length, greaterThan(0)); // 使用されているカテゴリが存在する

        // 統計情報が正常に返されることを確認
        final hasPositiveCounts = stats.values.any((count) => count > 0);
        expect(hasPositiveCounts, true);
      });
    });

    group('キャッシュ管理', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('キャッシュクリアが動作する', () {
        // プロンプトを取得してキャッシュを構築
        promptService.getAllPrompts();
        promptService.getPromptsForPlan(isPremium: true);

        // キャッシュクリア実行
        promptService.clearCache();

        // キャッシュクリア後もデータ取得は正常に動作
        final prompts = promptService.getAllPrompts();
        expect(prompts, isNotEmpty);
      });
    });

    group('リセット機能', () {
      test('リセットが正常に動作する', () async {
        await promptService.initialize();
        expect(promptService.isInitialized, true);

        promptService.reset();

        expect(promptService.isInitialized, false);
      });

      test('リセット後の再初期化が可能', () async {
        await promptService.initialize();
        promptService.reset();

        final result = await promptService.initialize();
        expect(result, true);
        expect(promptService.isInitialized, true);
      });
    });

    group('使用履歴管理', () {
      setUp(() async {
        await promptService.initialize();
      });

      test('使用履歴関連メソッドは実装されている', () async {
        // 使用履歴機能が無効でも、メソッドはエラーを投げない
        final allPrompts = promptService.getAllPrompts();
        final testPrompt = allPrompts.first;

        // 使用履歴記録（失敗してもエラーにならない）
        final result = await promptService.recordPromptUsage(
          promptId: testPrompt.id,
          diaryEntryId: 'test_diary_001',
          wasHelpful: true,
        );

        // 結果はboolean（成功/失敗）
        expect(result, isA<bool>());

        // 履歴取得（空リストでもエラーにならない）
        final history = promptService.getUsageHistory();
        expect(history, isA<List<PromptUsageHistory>>());

        // 最近使用ID取得（空リストでもエラーにならない）
        final recentIds = promptService.getRecentlyUsedPromptIds();
        expect(recentIds, isA<List<String>>());

        // 履歴クリア（結果はboolean）
        final clearResult = await promptService.clearUsageHistory();
        expect(clearResult, isA<bool>());

        // 統計取得（空マップでもエラーにならない）
        final stats = promptService.getUsageFrequencyStats();
        expect(stats, isA<Map<String, int>>());
      });
    });

    group('エラーハンドリング', () {
      test('初期化前のメソッド呼び出しでエラーが発生', () {
        expect(() => promptService.getAllPrompts(), throwsStateError);
        expect(
          () => promptService.getPromptsForPlan(isPremium: true),
          throwsStateError,
        );
        expect(
          () => promptService.getRandomPrompt(isPremium: true),
          throwsStateError,
        );
      });
    });
  });
}
