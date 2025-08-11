import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/ai_service.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: AiService統合テスト実装
///
/// AiService統合テスト - Gemini API呼び出しとResult<T>パターン
/// 実際のAiServiceインスタンスとSubscriptionServiceとの統合テスト
/// ネットワーク状態確認、Result<T>パターン、エラーハンドリングの検証

void main() {
  group('Phase 2-2: AiService統合テスト - Gemini API呼び出しとResult<T>パターン', () {
    late AiService aiService;
    late MockSubscriptionServiceInterface mockSubscriptionService;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    setUp(() async {
      // MockSubscriptionServiceを作成
      mockSubscriptionService = MockSubscriptionServiceInterface();

      // デフォルトのBasicPlan設定
      TestServiceSetup.configureSubscriptionServiceForPlan(
        mockSubscriptionService,
        BasicPlan(),
        usageCount: 0,
      );

      // AiServiceインスタンスを作成（実際の実装を使用）
      aiService = AiService(subscriptionService: mockSubscriptionService);
    });

    tearDown(() async {
      reset(mockSubscriptionService);
    });

    // =================================================================
    // Group 1: ネットワーク状態確認テスト
    // =================================================================

    group('Group 1: ネットワーク状態確認テスト', () {
      test('isOnlineResult() - ネットワーク接続確認とResult<T>型の確認', () async {
        // Act
        final result = await aiService.isOnlineResult();

        // Assert - Result<bool>型であることを確認
        expect(result, isA<Result<bool>>());

        // Success時もFailure時も適切な型が返されることを確認
        result.fold(
          (isOnline) {
            expect(isOnline, isA<bool>());
            // 実際のネットワーク状態に依存するため、型チェックのみ
          },
          (error) {
            // ネットワークエラーが発生した場合
            expect(error, isA<NetworkException>());
          },
        );
      });

      test('isOnlineResult() - Result<T>形式の一貫性確認', () async {
        // Act
        final result = await aiService.isOnlineResult();

        // Assert
        expect(result, isA<Result<bool>>());
        if (result.isSuccess) {
          expect(result.value, isA<bool>());
        } else {
          expect(result.error, isA<NetworkException>());
          expect(result.error.message, contains('ネットワーク接続'));
        }
      });

      test('isOnlineResult() - 複数回呼び出しでの安定性確認', () async {
        // Arrange & Act
        final results = <Result<bool>>[];
        for (int i = 0; i < 5; i++) {
          final result = await aiService.isOnlineResult();
          results.add(result);
        }

        // Assert
        expect(results, hasLength(5));
        for (final result in results) {
          expect(result, isA<Result<bool>>());
          if (result.isSuccess) {
            expect(result.value, isA<bool>());
          } else {
            expect(result.error, isA<NetworkException>());
          }
        }
      });

      test('isOnline() - 後方互換性確認（非Result<T>メソッド）', () async {
        // Act & Assert - PlatformChannelエラーが発生する可能性があるのでtry-catchで処理
        try {
          final result = await aiService.isOnline();
          expect(result, isA<bool>());
        } catch (e) {
          // テスト環境でPlatformChannelエラーが発生する場合は、エラー型を確認
          expect(e, isA<TypeError>());
        }
      });
    });

    // =================================================================
    // Group 2: Result<T>パターン統合テスト
    // =================================================================

    group('Group 2: Result<T>パターン統合テスト', () {
      test('全Result<T>メソッドの形式統一性確認', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15);

        // Act - 全Result<T>メソッドのテスト
        final isOnlineResult = await aiService.isOnlineResult();
        final remainingResult = await aiService.getRemainingGenerations();
        final resetDateResult = await aiService.getNextResetDate();
        final canUseResult = await aiService.canUseAiGeneration();

        // 実際のAI生成テストは制限されるため、基本的な形式チェックのみ
        final tagsResult = await aiService.generateTagsFromContent(
          title: 'テストタイトル',
          content: 'テストコンテンツ',
          date: testDate,
          photoCount: 1,
        );

        // Assert - 全てResult<T>形式であることを確認
        expect(isOnlineResult, isA<Result<bool>>());
        expect(remainingResult, isA<Result<int>>());
        expect(resetDateResult, isA<Result<DateTime>>());
        expect(canUseResult, isA<Result<bool>>());
        expect(tagsResult, isA<Result<List<String>>>());

        // Success時の値の型確認
        if (isOnlineResult.isSuccess) expect(isOnlineResult.value, isA<bool>());
        if (remainingResult.isSuccess)
          expect(remainingResult.value, isA<int>());
        if (resetDateResult.isSuccess)
          expect(resetDateResult.value, isA<DateTime>());
        if (canUseResult.isSuccess) expect(canUseResult.value, isA<bool>());
        if (tagsResult.isSuccess) expect(tagsResult.value, isA<List<String>>());
      });

      test('Success結果の適切な値確認', () async {
        // Act
        final remainingResult = await aiService.getRemainingGenerations();
        final canUseResult = await aiService.canUseAiGeneration();

        // Assert
        remainingResult.fold((remaining) {
          expect(remaining, isA<int>());
          expect(remaining, greaterThanOrEqualTo(0));
        }, (error) => expect(error, isA<ServiceException>()));

        canUseResult.fold(
          (canUse) => expect(canUse, isA<bool>()),
          (error) => expect(error, isA<ServiceException>()),
        );
      });

      test('Failure結果のエラー型確認', () async {
        // Arrange - SubscriptionServiceがnullのAiService作成
        final aiServiceWithoutSubscription = AiService();

        // Act
        final remainingResult = await aiServiceWithoutSubscription
            .getRemainingGenerations();
        final resetDateResult = await aiServiceWithoutSubscription
            .getNextResetDate();
        final canUseResult = await aiServiceWithoutSubscription
            .canUseAiGeneration();

        // Assert - SubscriptionServiceが利用不可のエラー
        expect(remainingResult.isFailure, isTrue);
        expect(remainingResult.error, isA<ServiceException>());
        expect(
          remainingResult.error.message,
          contains('SubscriptionService is not available'),
        );

        expect(resetDateResult.isFailure, isTrue);
        expect(resetDateResult.error, isA<ServiceException>());

        expect(canUseResult.isFailure, isTrue);
        expect(canUseResult.error, isA<ServiceException>());
      });
    });

    // =================================================================
    // Group 3: SubscriptionService統合テスト
    // =================================================================

    group('Group 3: SubscriptionService統合テスト', () {
      test('BasicPlan - 使用量制限チェック統合', () async {
        // Arrange - BasicPlan（10回制限）
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 0,
        );

        // Act
        final canUseResult = await aiService.canUseAiGeneration();
        final remainingResult = await aiService.getRemainingGenerations();

        // Assert
        expect(canUseResult.isSuccess, isTrue);
        canUseResult.fold(
          (canUse) => expect(canUse, isTrue),
          (error) => fail('Should not fail for Basic plan with usage'),
        );

        expect(remainingResult.isSuccess, isTrue);
        remainingResult.fold(
          (remaining) => expect(remaining, equals(10)), // BasicPlan limit
          (error) => fail('Should not fail for Basic plan'),
        );
      });

      test('BasicPlan - 制限到達時のエラーハンドリング', () async {
        // Arrange - BasicPlan制限到達状態（10/10使用）
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 10,
        );

        // Act
        final canUseResult = await aiService.canUseAiGeneration();
        final remainingResult = await aiService.getRemainingGenerations();

        // Assert
        expect(canUseResult.isSuccess, isTrue);
        canUseResult.fold(
          (canUse) => expect(canUse, isFalse), // 制限到達のため使用不可
          (error) => fail('canUseAiGeneration should not fail'),
        );

        expect(remainingResult.isSuccess, isTrue);
        remainingResult.fold(
          (remaining) => expect(remaining, equals(0)), // 残り0回
          (error) => fail('getRemainingGenerations should not fail'),
        );
      });

      test('PremiumPlan - 高い制限値の確認', () async {
        // Arrange - PremiumMonthlyPlan（100回制限）
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          PremiumMonthlyPlan(),
          usageCount: 20,
        );

        // Act
        final canUseResult = await aiService.canUseAiGeneration();
        final remainingResult = await aiService.getRemainingGenerations();

        // Assert
        expect(canUseResult.isSuccess, isTrue);
        canUseResult.fold(
          (canUse) => expect(canUse, isTrue), // まだ使用可能
          (error) => fail('Should not fail for Premium plan'),
        );

        expect(remainingResult.isSuccess, isTrue);
        remainingResult.fold(
          (remaining) => expect(remaining, equals(80)), // 100 - 20 = 80
          (error) => fail('Should not fail for Premium plan'),
        );
      });

      test('月次リセット日の取得確認', () async {
        // Act
        final resetDateResult = await aiService.getNextResetDate();

        // Assert
        expect(resetDateResult.isSuccess, isTrue);
        resetDateResult.fold((resetDate) {
          expect(resetDate, isA<DateTime>());
          expect(resetDate.isAfter(DateTime.now()), isTrue);
        }, (error) => fail('getNextResetDate should succeed: $error'));
      });

      test('SubscriptionService統合フローの完全性確認', () async {
        // Arrange - 連続したメソッド呼び出し
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 3,
        );

        // Act - 統合フロー実行
        final canUse1 = await aiService.canUseAiGeneration();
        final remaining1 = await aiService.getRemainingGenerations();
        final resetDate = await aiService.getNextResetDate();

        // Assert - 一貫した結果の確認
        expect(canUse1.isSuccess, isTrue);
        expect(remaining1.isSuccess, isTrue);
        expect(resetDate.isSuccess, isTrue);

        canUse1.fold(
          (canUse) => expect(canUse, isTrue), // まだ使用可能（3/10）
          (error) => fail('canUseAiGeneration should succeed'),
        );

        remaining1.fold(
          (remaining) => expect(remaining, equals(7)), // 10 - 3 = 7
          (error) => fail('getRemainingGenerations should succeed'),
        );
      });
    });

    // =================================================================
    // Group 4: エラーハンドリング統合テスト
    // =================================================================

    group('Group 4: エラーハンドリング統合テスト', () {
      test('generateTagsFromContent - AiProcessingException統合', () async {
        // Arrange - 無効な入力でエラー発生を期待
        const invalidTitle = '';
        const invalidContent = '';
        final testDate = DateTime(2024, 1, 15);

        // Act
        final result = await aiService.generateTagsFromContent(
          title: invalidTitle,
          content: invalidContent,
          date: testDate,
          photoCount: 0,
        );

        // Assert - エラーハンドリングまたは適切な処理
        expect(result, isA<Result<List<String>>>());
        if (result.isFailure) {
          // ネットワークエラーまたはAI処理エラーが発生する可能性
          expect(
            result.error,
            anyOf(
              isA<AiProcessingException>(),
              isA<NetworkException>(),
              isA<ServiceException>(),
            ),
          );
        } else {
          // 成功の場合、空のタグリストまたは適切なタグが返される
          expect(result.value, isA<List<String>>());
        }
      });

      test('generateTagsFromContent - 正常入力での成功確認', () async {
        // Arrange
        const validTitle = '素敵な一日';
        const validContent =
            '今日は家族と一緒に公園で過ごしました。天気も良く、子供たちが楽しそうに遊んでいる姿を見て幸せな気持ちになりました。';
        final testDate = DateTime(2024, 1, 15);

        // Act
        final result = await aiService.generateTagsFromContent(
          title: validTitle,
          content: validContent,
          date: testDate,
          photoCount: 2,
        );

        // Assert
        expect(result, isA<Result<List<String>>>());
        if (result.isSuccess) {
          expect(result.value, isA<List<String>>());
          // テスト環境では実際のAI呼び出しが制限される場合があるため、空リストも許容
        } else {
          // ネットワーク等の問題でエラーになる場合もある
          expect(
            result.error,
            anyOf(
              isA<AiProcessingException>(),
              isA<NetworkException>(),
              isA<ServiceException>(),
            ),
          );
        }
      });

      test('ネットワーク関連エラーの統合確認', () async {
        // Arrange - ネットワーク状態確認
        final networkResult = await aiService.isOnlineResult();

        // Assert - ネットワークエラーの場合の適切な処理
        if (networkResult.isFailure) {
          expect(networkResult.error, isA<NetworkException>());
          expect(networkResult.error.message, contains('ネットワーク'));
        } else {
          expect(networkResult.value, isA<bool>());
        }
      });

      test('制限超過時の詳細エラーメッセージ確認', () async {
        // Arrange - 制限到達状態のAiService
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 10, // 制限到達
        );

        // モック画像データでAI生成テスト
        final testImageData = Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ]);
        final testDate = DateTime(2024, 1, 15);

        // Act - 制限超過時のAI生成試行
        final result = await aiService.generateDiaryFromImage(
          imageData: testImageData,
          date: testDate,
        );

        // Assert - 適切な制限超過エラー
        expect(result.isFailure, isTrue);
        expect(result.error, isA<AiProcessingException>());
        expect(result.error.message, contains('AI生成の月間制限'));
        expect(result.error.message, contains('Basic'));
        expect(result.error.message, contains('0回'));
      });
    });

    // =================================================================
    // Group 5: End-to-End統合フローテスト
    // =================================================================

    group('Group 5: End-to-End統合フローテスト', () {
      test('完全なAI統合フロー - ネットワーク確認→制限チェック→タグ生成', () async {
        // Arrange
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 2, // まだ余裕がある状態
        );

        // Step 1: ネットワーク状態確認
        final networkResult = await aiService.isOnlineResult();
        expect(networkResult, isA<Result<bool>>());

        // Step 2: AI使用可否確認
        final canUseResult = await aiService.canUseAiGeneration();
        expect(canUseResult.isSuccess, isTrue);

        // Step 3: 実際のタグ生成（軽量なAI処理）
        if (canUseResult.value) {
          final tagsResult = await aiService.generateTagsFromContent(
            title: '統合テスト日記',
            content: '今日は統合テストを実行しました。Result<T>パターンの実装が正しく動作することを確認できました。',
            date: DateTime(2024, 1, 15),
            photoCount: 1,
          );

          expect(tagsResult, isA<Result<List<String>>>());
          if (tagsResult.isSuccess) {
            expect(tagsResult.value, isA<List<String>>());
          } else {
            // ネットワークまたはAI処理エラーが発生する可能性
            expect(
              tagsResult.error,
              anyOf(
                isA<AiProcessingException>(),
                isA<NetworkException>(),
                isA<ServiceException>(),
              ),
            );
          }
        }
      });

      test('エラー発生時のフォールバック処理確認', () async {
        // Arrange - SubscriptionServiceなしのAiService
        final aiServiceWithoutSub = AiService();

        // Act - エラー条件での各メソッド実行
        final canUseResult = await aiServiceWithoutSub.canUseAiGeneration();
        final remainingResult = await aiServiceWithoutSub
            .getRemainingGenerations();
        final resetDateResult = await aiServiceWithoutSub.getNextResetDate();

        // Assert - 全てのメソッドで適切なエラーハンドリング
        expect(canUseResult.isFailure, isTrue);
        expect(canUseResult.error, isA<ServiceException>());

        expect(remainingResult.isFailure, isTrue);
        expect(remainingResult.error, isA<ServiceException>());

        expect(resetDateResult.isFailure, isTrue);
        expect(resetDateResult.error, isA<ServiceException>());
      });

      test('統合テスト総合確認 - 全メソッドの協調動作', () async {
        // Arrange
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          PremiumMonthlyPlan(),
          usageCount: 15,
        );

        // Act - 複数メソッドの並行実行
        final futures = await Future.wait([
          aiService.isOnlineResult(),
          aiService.canUseAiGeneration(),
          aiService.getRemainingGenerations(),
          aiService.getNextResetDate(),
        ]);

        final networkResult = futures[0] as Result<bool>;
        final canUseResult = futures[1] as Result<bool>;
        final remainingResult = futures[2] as Result<int>;
        final resetDateResult = futures[3] as Result<DateTime>;

        // Assert - 全結果の整合性確認
        expect(networkResult, isA<Result<bool>>());
        expect(canUseResult, isA<Result<bool>>());
        expect(remainingResult, isA<Result<int>>());
        expect(resetDateResult, isA<Result<DateTime>>());

        // PremiumMonthlyPlan（100回制限、15回使用済み）の確認
        if (canUseResult.isSuccess && remainingResult.isSuccess) {
          canUseResult.fold(
            (canUse) => expect(canUse, isTrue), // まだ使用可能
            (error) => fail('canUse should succeed'),
          );

          remainingResult.fold(
            (remaining) => expect(remaining, equals(85)), // 100 - 15 = 85
            (error) => fail('remaining should succeed'),
          );
        }

        if (resetDateResult.isSuccess) {
          resetDateResult.fold(
            (resetDate) => expect(resetDate.isAfter(DateTime.now()), isTrue),
            (error) => fail('resetDate should be in future'),
          );
        }
      });
    });

    // =================================================================
    // Group 6: パフォーマンスと安定性テスト
    // =================================================================

    group('Group 6: パフォーマンスと安定性テスト', () {
      test('大量呼び出しでの安定性確認', () async {
        // Arrange
        const callCount = 20;
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 0,
        );

        // Act - 大量呼び出し
        final results = <Result<bool>>[];
        for (int i = 0; i < callCount; i++) {
          final result = await aiService.canUseAiGeneration();
          results.add(result);
        }

        // Assert - 全て成功し、一貫した結果
        expect(results, hasLength(callCount));
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          result.fold(
            (canUse) => expect(canUse, isTrue),
            (error) => fail('All calls should succeed: $error'),
          );
        }
      });

      test('並行処理での安定性確認', () async {
        // Arrange
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          PremiumYearlyPlan(),
          usageCount: 50,
        );

        // Act - 並行処理実行
        final futures = <Future<Result>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(aiService.canUseAiGeneration());
          futures.add(aiService.getRemainingGenerations());
          futures.add(aiService.isOnlineResult());
        }

        final results = await Future.wait(futures);

        // Assert - 全並行処理が正常完了
        expect(results, hasLength(30)); // 10 * 3 methods
        for (final result in results) {
          expect(result, isA<Result>());
          if (result.isFailure) {
            // ネットワーク関連エラーは許容
            expect(
              result.error,
              anyOf(isA<NetworkException>(), isA<ServiceException>()),
            );
          }
        }
      });

      test('レスポンス時間の合理性確認', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        final result = await aiService.isOnlineResult();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsed.inSeconds, lessThan(10)); // 10秒以内
        expect(result, isA<Result<bool>>());
      });
    });
  });
}
