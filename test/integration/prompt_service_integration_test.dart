import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/prompt_service.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: PromptService統合テスト実装
///
/// assets/data/writing_prompts.jsonからの実データ読み込み統合テスト
/// 3層キャッシングシステム、プロンプト分類、ランダム選択機能の検証

/// LoggingServiceのモック設定ヘルパーメソッド
void _setupLoggingServiceMock(MockLoggingService mock) {
  when(() => mock.info(any(), context: any(named: 'context'))).thenReturn(null);
  when(
    () => mock.debug(any(), context: any(named: 'context')),
  ).thenReturn(null);
  when(
    () => mock.warning(any(), context: any(named: 'context')),
  ).thenReturn(null);
  when(
    () => mock.error(
      any(),
      context: any(named: 'context'),
      error: any(named: 'error'),
      stackTrace: any(named: 'stackTrace'),
    ),
  ).thenReturn(null);
}

void main() {
  group(
    'Phase 2-2: PromptService統合テスト - assets/data/writing_prompts.jsonからの実データ読み込み',
    () {
      late PromptService promptService;
      late ServiceLocator serviceLocator;
      late MockLoggingService mockLoggingService;

      setUpAll(() async {
        registerMockFallbacks();
        await IntegrationTestHelpers.setUpIntegrationEnvironment();
      });

      tearDownAll(() async {
        await IntegrationTestHelpers.tearDownIntegrationEnvironment();
      });

      setUp(() async {
        // ServiceLocator準備
        serviceLocator = ServiceLocator();

        // LoggingServiceのモック設定
        mockLoggingService = MockLoggingService();
        _setupLoggingServiceMock(mockLoggingService);
        serviceLocator.registerSingleton<LoggingService>(mockLoggingService);

        // PromptServiceインスタンス作成
        promptService = PromptService.instance;

        // テスト前にリセット
        promptService.reset();
      });

      tearDown(() {
        promptService.reset();
        PromptService.resetInstance();
        serviceLocator.clear();
      });

      // =================================================================
      // Group 1: 実データ読み込み統合テスト
      // =================================================================

      group('Group 1: assets/data/writing_prompts.jsonからの実データ読み込み', () {
        test('initialize() - JSONアセットからの正常な読み込み確認', () async {
          // Act
          final result = await promptService.initialize();

          // Assert
          expect(result, isTrue);
          expect(promptService.isInitialized, isTrue);

          // 全プロンプト取得確認
          final allPrompts = promptService.getAllPrompts();
          expect(allPrompts, isNotEmpty);

          // LoggingServiceの呼び出し確認
          verify(
            () => mockLoggingService.info('PromptService: 初期化開始'),
          ).called(1);
        });

        test('プロンプト総数確認 - 20個のプロンプト読み込み', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final allPrompts = promptService.getAllPrompts();

          // Assert
          expect(allPrompts, hasLength(20));

          // 各プロンプトの基本構造確認
          for (final prompt in allPrompts) {
            expect(prompt.id, isNotEmpty);
            expect(prompt.text, isNotEmpty);
            expect(prompt.category, isNotNull);
            expect(prompt.tags, isNotNull);
            expect(prompt.priority, greaterThan(0));
            expect(prompt.isActive, isTrue);
          }
        });

        test('Basic/Premium分類確認 - Basic 5個 + Premium 15個', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final basicPrompts = promptService.getPromptsForPlan(
            isPremium: false,
          );
          final premiumPrompts = promptService.getPromptsForPlan(
            isPremium: true,
          );

          // Assert
          expect(basicPrompts, hasLength(5));
          expect(premiumPrompts, hasLength(20)); // Basic + Premium

          // Basic prompts should all be non-premium
          for (final prompt in basicPrompts) {
            expect(prompt.isPremiumOnly, isFalse);
          }

          // Premium prompts should include both basic and premium
          final premiumOnlyPrompts = premiumPrompts
              .where((p) => p.isPremiumOnly)
              .toList();
          expect(premiumOnlyPrompts, hasLength(15));
        });

        test('カテゴリ分布確認 - 9種類のPromptCategoryマッピング', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final allPrompts = promptService.getAllPrompts();
          final categoryGroups = <PromptCategory, List<WritingPrompt>>{};

          for (final prompt in allPrompts) {
            categoryGroups.putIfAbsent(prompt.category, () => []).add(prompt);
          }

          // Assert
          expect(categoryGroups.keys, hasLength(greaterThan(1)));

          // emotion カテゴリ（Basic）の確認
          final emotionPrompts = categoryGroups[PromptCategory.emotion] ?? [];
          expect(emotionPrompts, hasLength(5));

          // Premium カテゴリの確認
          final premiumCategories = [
            PromptCategory.emotionDepth,
            PromptCategory.sensoryEmotion,
            PromptCategory.emotionGrowth,
            PromptCategory.emotionConnection,
            PromptCategory.emotionDiscovery,
            PromptCategory.emotionFantasy,
            PromptCategory.emotionHealing,
            PromptCategory.emotionEnergy,
          ];

          int premiumCount = 0;
          for (final category in premiumCategories) {
            final prompts = categoryGroups[category] ?? [];
            premiumCount += prompts.length;
          }
          expect(premiumCount, equals(15));
        });
      });

      // =================================================================
      // Group 2: JSONデータ整合性テスト
      // =================================================================

      group('Group 2: JSONデータ整合性テスト', () {
        test('メタデータ整合性確認 - totalPrompts/basicPrompts/premiumPrompts', () async {
          // Arrange - 直接JSONを読み込んでメタデータ確認
          final String jsonString = await rootBundle.loadString(
            'assets/data/writing_prompts.json',
          );
          final Map<String, dynamic> jsonData = json.decode(jsonString);

          await promptService.initialize();
          final allPrompts = promptService.getAllPrompts();

          // Act
          final expectedTotal = jsonData['totalPrompts'] as int;
          final expectedBasic = jsonData['basicPrompts'] as int;
          final expectedPremium = jsonData['premiumPrompts'] as int;

          final actualTotal = allPrompts.length;
          final actualBasic = allPrompts.where((p) => !p.isPremiumOnly).length;
          final actualPremium = allPrompts.where((p) => p.isPremiumOnly).length;

          // Assert
          expect(actualTotal, equals(expectedTotal));
          expect(actualBasic, equals(expectedBasic));
          expect(actualPremium, equals(expectedPremium));
          expect(expectedTotal, equals(20));
          expect(expectedBasic, equals(5));
          expect(expectedPremium, equals(15));
        });

        test('ID重複チェック - 20個のユニークなプロンプトID', () async {
          // Arrange
          await promptService.initialize();
          final allPrompts = promptService.getAllPrompts();

          // Act
          final ids = allPrompts.map((p) => p.id).toList();
          final uniqueIds = ids.toSet();

          // Assert
          expect(ids.length, equals(uniqueIds.length));
          expect(uniqueIds, hasLength(20));

          // ID命名規則確認
          final basicIds = allPrompts
              .where((p) => !p.isPremiumOnly)
              .map((p) => p.id)
              .where((id) => id.startsWith('basic_'))
              .toList();
          expect(basicIds, hasLength(5));

          final premiumIds = allPrompts
              .where((p) => p.isPremiumOnly)
              .map((p) => p.id)
              .where((id) => id.startsWith('premium_'))
              .toList();
          expect(premiumIds, hasLength(15));
        });

        test('プロンプト構造完全性確認 - 必須フィールド・オプションフィールド', () async {
          // Arrange
          await promptService.initialize();
          final allPrompts = promptService.getAllPrompts();

          // Act & Assert
          for (final prompt in allPrompts) {
            // 必須フィールド
            expect(prompt.id, isNotEmpty);
            expect(prompt.text, isNotEmpty);
            expect(prompt.category, isNotNull);
            expect(prompt.tags, isNotNull);
            expect(prompt.tags, isNotEmpty);
            expect(prompt.priority, inInclusiveRange(1, 100));
            expect(prompt.createdAt, isNotNull);
            expect(prompt.isActive, isTrue);

            // オプションフィールド（description）
            if (prompt.description != null) {
              expect(prompt.description!, isNotEmpty);
            }

            // カテゴリ別特有の確認
            if (prompt.category == PromptCategory.emotion) {
              expect(prompt.isPremiumOnly, isFalse);
            } else {
              expect(prompt.isPremiumOnly, isTrue);
            }
          }
        });
      });

      // =================================================================
      // Group 3: プロンプト分類統合テスト
      // =================================================================

      group('Group 3: プロンプト分類統合テスト', () {
        test('getPromptsForPlan() - Basic/Premium別フィルタリング', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final basicPrompts = promptService.getPromptsForPlan(
            isPremium: false,
          );
          final premiumAllPrompts = promptService.getPromptsForPlan(
            isPremium: true,
          );

          // Assert
          expect(basicPrompts, hasLength(5));
          expect(premiumAllPrompts, hasLength(20));

          // Basic prompts accessibility check
          for (final prompt in basicPrompts) {
            expect(prompt.isAvailableForPlan(isPremium: false), isTrue);
            expect(prompt.isAvailableForPlan(isPremium: true), isTrue);
          }

          // Premium only prompts check
          final premiumOnlyPrompts = premiumAllPrompts
              .where((p) => p.isPremiumOnly)
              .toList();
          for (final prompt in premiumOnlyPrompts) {
            expect(prompt.isAvailableForPlan(isPremium: false), isFalse);
            expect(prompt.isAvailableForPlan(isPremium: true), isTrue);
          }
        });

        test('getPromptsByCategory() - カテゴリ別・プラン制限統合確認', () async {
          // Arrange
          await promptService.initialize();

          // Act & Assert - emotion カテゴリ（Basic）
          final basicEmotionPrompts = promptService.getPromptsByCategory(
            PromptCategory.emotion,
            isPremium: false,
          );
          expect(basicEmotionPrompts, hasLength(5));

          final premiumEmotionPrompts = promptService.getPromptsByCategory(
            PromptCategory.emotion,
            isPremium: true,
          );
          expect(premiumEmotionPrompts, hasLength(5)); // 同じ結果

          // Premium専用カテゴリ確認
          final basicDepthPrompts = promptService.getPromptsByCategory(
            PromptCategory.emotionDepth,
            isPremium: false,
          );
          expect(basicDepthPrompts, isEmpty); // Basic では取得できない

          final premiumDepthPrompts = promptService.getPromptsByCategory(
            PromptCategory.emotionDepth,
            isPremium: true,
          );
          expect(premiumDepthPrompts, isNotEmpty); // Premium では取得可能
        });

        test('getPromptStatistics() - カテゴリ別統計情報の正確性', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final basicStats = promptService.getPromptStatistics(
            isPremium: false,
          );
          final premiumStats = promptService.getPromptStatistics(
            isPremium: true,
          );

          // Assert
          expect(basicStats[PromptCategory.emotion], equals(5));
          expect(premiumStats[PromptCategory.emotion], equals(5));

          // Premium専用カテゴリはBasicでは0
          for (final category in [
            PromptCategory.emotionDepth,
            PromptCategory.sensoryEmotion,
            PromptCategory.emotionGrowth,
          ]) {
            expect(basicStats[category], equals(0));
            expect(premiumStats[category], greaterThan(0));
          }

          // 全カテゴリの合計確認
          final basicTotal = basicStats.values.fold(
            0,
            (sum, count) => sum + count,
          );
          final premiumTotal = premiumStats.values.fold(
            0,
            (sum, count) => sum + count,
          );
          expect(basicTotal, equals(5));
          expect(premiumTotal, equals(20));
        });
      });

      // =================================================================
      // Group 4: ランダム選択統合テスト
      // =================================================================

      group('Group 4: ランダム選択統合テスト', () {
        test('getRandomPrompt() - 基本的なランダム選択動作', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final basicRandomPrompt = promptService.getRandomPrompt(
            isPremium: false,
          );
          final premiumRandomPrompt = promptService.getRandomPrompt(
            isPremium: true,
          );

          // Assert
          expect(basicRandomPrompt, isNotNull);
          expect(premiumRandomPrompt, isNotNull);
          expect(
            basicRandomPrompt!.isAvailableForPlan(isPremium: false),
            isTrue,
          );
          expect(
            premiumRandomPrompt!.isAvailableForPlan(isPremium: true),
            isTrue,
          );
        });

        test('getRandomPrompt() - excludeIds除外ロジック確認', () async {
          // Arrange
          await promptService.initialize();
          final basicPrompts = promptService.getPromptsForPlan(
            isPremium: false,
          );
          final excludeIds = basicPrompts.take(3).map((p) => p.id).toList();

          // Act
          final selectedPrompts = <WritingPrompt>[];
          for (int i = 0; i < 10; i++) {
            final randomPrompt = promptService.getRandomPrompt(
              isPremium: false,
              excludeIds: excludeIds,
            );
            if (randomPrompt != null) {
              selectedPrompts.add(randomPrompt);
            }
          }

          // Assert
          expect(selectedPrompts, isNotEmpty);
          for (final prompt in selectedPrompts) {
            expect(excludeIds, isNot(contains(prompt.id)));
          }
        });

        test('getRandomPromptSequence() - 重複なし連続選択', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final sequence = promptService.getRandomPromptSequence(
            count: 3,
            isPremium: false,
          );

          // Assert
          expect(sequence, hasLength(3));

          // 重複なし確認
          final ids = sequence.map((p) => p.id).toList();
          final uniqueIds = ids.toSet();
          expect(ids.length, equals(uniqueIds.length));

          // プラン制限確認
          for (final prompt in sequence) {
            expect(prompt.isAvailableForPlan(isPremium: false), isTrue);
          }
        });

        test('getRandomPrompt() - カテゴリ指定ランダム選択', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final categoryPrompts = <WritingPrompt>[];
          for (int i = 0; i < 5; i++) {
            final randomPrompt = promptService.getRandomPrompt(
              isPremium: true,
              category: PromptCategory.emotion,
            );
            if (randomPrompt != null) {
              categoryPrompts.add(randomPrompt);
            }
          }

          // Assert
          expect(categoryPrompts, isNotEmpty);
          for (final prompt in categoryPrompts) {
            expect(prompt.category, equals(PromptCategory.emotion));
          }
        });
      });

      // =================================================================
      // Group 5: 検索機能統合テスト
      // =================================================================

      group('Group 5: 検索機能統合テスト', () {
        test('searchPrompts() - テキスト検索（プロンプト本文内）', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final results = promptService.searchPrompts('感情', isPremium: true);

          // Assert
          expect(results, isNotEmpty);
          for (final prompt in results) {
            final matchesText = prompt.text.contains('感情');
            final matchesTag = prompt.tags.any((tag) => tag.contains('感情'));
            final matchesDescription =
                prompt.description?.contains('感情') == true;

            expect(matchesText || matchesTag || matchesDescription, isTrue);
          }
        });

        test('searchPrompts() - タグ検索機能', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final results = promptService.searchPrompts('気持ち', isPremium: true);

          // Assert
          expect(results, isNotEmpty);
          bool foundTagMatch = false;
          for (final prompt in results) {
            if (prompt.tags.any((tag) => tag.contains('気持ち'))) {
              foundTagMatch = true;
              break;
            }
          }
          expect(foundTagMatch, isTrue);
        });

        test('searchPrompts() - プラン制限付き検索', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final basicResults = promptService.searchPrompts(
            '感情',
            isPremium: false,
          );
          final premiumResults = promptService.searchPrompts(
            '感情',
            isPremium: true,
          );

          // Assert
          expect(basicResults.length, lessThanOrEqualTo(premiumResults.length));

          // Basic結果はすべてBasic利用可能
          for (final prompt in basicResults) {
            expect(prompt.isAvailableForPlan(isPremium: false), isTrue);
          }

          // Premium結果にはPremium専用も含まれる可能性
          final premiumOnlyInResults = premiumResults
              .where((p) => p.isPremiumOnly)
              .toList();
          // Premium専用プロンプトは Basic 結果には含まれない
          for (final premiumPrompt in premiumOnlyInResults) {
            expect(basicResults, isNot(contains(premiumPrompt)));
          }
        });

        test('searchPrompts() - 空文字検索で全プロンプト返却', () async {
          // Arrange
          await promptService.initialize();

          // Act
          final emptySearchResults = promptService.searchPrompts(
            '',
            isPremium: true,
          );
          final allPrompts = promptService.getPromptsForPlan(isPremium: true);

          // Assert
          expect(emptySearchResults.length, equals(allPrompts.length));
        });
      });

      // =================================================================
      // Group 6: 3層キャッシングシステム基盤確認
      // =================================================================

      group('Group 6: 3層キャッシングシステム基盤確認', () {
        test('メモリキャッシュ動作確認 - 初期化後のキャッシュ生成', () async {
          // Arrange & Act
          await promptService.initialize();

          // キャッシュを明示的にクリアしてフレッシュな状態にする
          promptService.clearCache();

          // 初回呼び出し（キャッシュ構築）
          final result1 = promptService.getPromptsForPlan(isPremium: true);

          // 2回目呼び出し（キャッシュヒット）
          final result2 = promptService.getPromptsForPlan(isPremium: true);

          // Assert - 結果の一貫性確認（キャッシュが正しく動作していることを示す）
          expect(result1.length, equals(result2.length));
          expect(result1.length, greaterThan(0)); // 実際にプロンプトが取得できている
          expect(
            identical(result1, result2),
            isFalse,
          ); // 異なるインスタンス（unmodifiableListのため）

          // キャッシュが内部的に作成されていることを確認するため、
          // さらに多数回呼び出しても安定した結果が得られることを検証
          for (int i = 0; i < 10; i++) {
            final resultN = promptService.getPromptsForPlan(isPremium: true);
            expect(resultN.length, equals(result1.length));
          }
        });

        test('キャッシュクリア・リビルド動作確認', () async {
          // Arrange
          await promptService.initialize();
          final beforeClear = promptService.getPromptsForPlan(isPremium: true);

          // Act
          promptService.clearCache();

          // キャッシュクリア後も初期化済み状態は維持
          expect(promptService.isInitialized, isTrue);

          // キャッシュ再構築確認
          final afterClear = promptService.getPromptsForPlan(isPremium: true);

          // Assert
          expect(beforeClear.length, equals(afterClear.length));
        });

        test('reset() - 完全初期化状態への復帰', () async {
          // Arrange
          await promptService.initialize();
          expect(promptService.isInitialized, isTrue);

          // Act
          promptService.reset();

          // Assert
          expect(promptService.isInitialized, isFalse);

          // 再初期化可能確認
          final reinitResult = await promptService.initialize();
          expect(reinitResult, isTrue);
          expect(promptService.isInitialized, isTrue);
        });
      });

      // =================================================================
      // Group 7: エラーシナリオテスト
      // =================================================================

      group('Group 7: エラーシナリオテスト', () {
        test('未初期化時の操作でStateError確認', () {
          // Arrange - 未初期化状態
          expect(promptService.isInitialized, isFalse);

          // Act & Assert
          expect(
            () => promptService.getAllPrompts(),
            throwsA(isA<StateError>()),
          );
          expect(
            () => promptService.getPromptsForPlan(isPremium: true),
            throwsA(isA<StateError>()),
          );
          expect(
            () => promptService.getRandomPrompt(isPremium: true),
            throwsA(isA<StateError>()),
          );
        });

        test('getRandomPrompt() - 利用可能プロンプトなしでnull返却', () async {
          // Arrange
          await promptService.initialize();
          final allBasicIds = promptService
              .getPromptsForPlan(isPremium: false)
              .map((p) => p.id)
              .toList();

          // Act - すべてのBasicプロンプトを除外
          final result = promptService.getRandomPrompt(
            isPremium: false,
            excludeIds: allBasicIds,
          );

          // Assert
          expect(result, isNull);
        });

        test('getRandomPromptSequence() - 要求数が利用可能数を超える場合', () async {
          // Arrange
          await promptService.initialize();

          // Act - Basic（5個）に対して10個要求
          final sequence = promptService.getRandomPromptSequence(
            count: 10,
            isPremium: false,
          );

          // Assert - 利用可能な5個のみ返却
          expect(sequence, hasLength(5));

          // 重複なし確認
          final ids = sequence.map((p) => p.id).toSet();
          expect(ids, hasLength(5));
        });
      });
    },
  );
}
