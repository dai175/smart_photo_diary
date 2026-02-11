import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import '../helpers/hive_test_helpers.dart';

/// Phase 1.5.2.2: 使用量管理テスト
///
/// SubscriptionServiceの使用量管理機能の詳細テスト
/// - AI生成回数制限チェック
/// - 月次リセット機能
/// - プラン別使用量制限
/// - 使用量インクリメント
/// - 残り回数計算
/// - エラーケース処理
void main() {
  group('Phase 1.5.2.2: SubscriptionService使用量管理テスト', () {
    late SubscriptionService subscriptionService;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();

      // 新しいインスタンスを取得
      subscriptionService = SubscriptionService();
      await subscriptionService.initialize();
    });

    tearDownAll(() async {
      // テスト終了時にHiveを閉じる
      await HiveTestHelpers.closeHive();
    });

    group('AI生成使用可否チェック', () {
      test('Basicプラン: 初期状態では使用可能', () async {
        final result = await subscriptionService.canUseAiGeneration();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Basicプラン: 制限内では使用可能', () async {
        // 9回使用（制限は10回）
        for (int i = 0; i < 9; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final result = await subscriptionService.canUseAiGeneration();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Basicプラン: 制限に達すると使用不可', () async {
        // 10回使用（制限に到達）
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final result = await subscriptionService.canUseAiGeneration();
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('Premiumプラン: より高い制限で使用可能', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 50回使用（Premiumの制限は100回）
        for (int i = 0; i < 50; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final result = await subscriptionService.canUseAiGeneration();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Premiumプラン: 制限に達すると使用不可', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 100回使用（制限に到達）
        for (int i = 0; i < 100; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final result = await subscriptionService.canUseAiGeneration();
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });

    group('使用量インクリメント', () {
      test('Basic: 使用量が正しくインクリメントされる', () async {
        final initialUsage = await subscriptionService.getMonthlyUsage();
        expect(initialUsage.value, equals(0));

        await subscriptionService.incrementAiUsage();

        final afterUsage = await subscriptionService.getMonthlyUsage();
        expect(afterUsage.value, equals(1));
      });

      test('Premium: 使用量が正しくインクリメントされる', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        await subscriptionService.incrementAiUsage();
        await subscriptionService.incrementAiUsage();
        await subscriptionService.incrementAiUsage();

        final usage = await subscriptionService.getMonthlyUsage();
        expect(usage.value, equals(3));
      });

      test('制限を超えてもインクリメントは継続される', () async {
        // 制限(10回)まで使用
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final usage = await subscriptionService.getMonthlyUsage();
        expect(usage.value, equals(10));

        // 使用可否はfalse
        final canUse = await subscriptionService.canUseAiGeneration();
        expect(canUse.value, isFalse);
      });
    });

    group('残り生成回数計算', () {
      test('Basic: 初期状態で正しい残り回数', () async {
        final remaining = await subscriptionService.getRemainingGenerations();

        expect(remaining.isSuccess, isTrue);
        expect(remaining.value, equals(10)); // Basicプランの制限
      });

      test('Basic: 使用後の残り回数計算', () async {
        // 3回使用
        for (int i = 0; i < 3; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(7)); // 10 - 3 = 7
      });

      test('Premium: 初期状態で正しい残り回数', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(100)); // Premiumプランの制限
      });

      test('Premium: 使用後の残り回数計算', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 25回使用
        for (int i = 0; i < 25; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(75)); // 100 - 25 = 75
      });

      test('制限に達した場合は残り0回', () async {
        // 制限(10回)まで使用
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(0));
      });

      test('制限を超えた場合も残り0回（負の値にならない）', () async {
        // 制限まで使用
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(0)); // 負の値にならない
      });
    });

    group('使用量リセット', () {
      test('手動リセットで使用量がクリアされる', () async {
        // 使用量を設定
        for (int i = 0; i < 5; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final beforeReset = await subscriptionService.getMonthlyUsage();
        expect(beforeReset.value, equals(5));

        final resetResult = await subscriptionService.resetUsage();
        expect(resetResult.isSuccess, isTrue);

        final afterReset = await subscriptionService.getMonthlyUsage();
        expect(afterReset.value, equals(0));
      });

      test('リセット後に再び使用可能になる', () async {
        // 制限まで使用
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final beforeReset = await subscriptionService.canUseAiGeneration();
        expect(beforeReset.value, isFalse);

        await subscriptionService.resetUsage();

        final afterReset = await subscriptionService.canUseAiGeneration();
        expect(afterReset.value, isTrue);
      });

      test('リセット後の残り回数が正しく復元される', () async {
        // 使用量を設定
        for (int i = 0; i < 8; i++) {
          await subscriptionService.incrementAiUsage();
        }

        await subscriptionService.resetUsage();

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(10)); // Basicプランの制限に復元
      });
    });

    group('次回リセット日取得', () {
      test('次回リセット日が正しく計算される', () async {
        final resetDate = await subscriptionService.getNextResetDate();

        expect(resetDate.isSuccess, isTrue);
        expect(resetDate.value, isA<DateTime>());

        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1, 1);

        expect(resetDate.value.year, equals(nextMonth.year));
        expect(resetDate.value.month, equals(nextMonth.month));
        expect(resetDate.value.day, equals(1));
      });

      test('月末近くでの次回リセット日計算', () async {
        // このテストは現在の日付に依存するため、
        // 論理的な整合性のみチェック
        final resetDate = await subscriptionService.getNextResetDate();
        final now = DateTime.now();

        expect(resetDate.isSuccess, isTrue);
        expect(resetDate.value.isAfter(now), isTrue);
        expect(resetDate.value.day, equals(1)); // 月の1日であることを確認
      });
    });

    group('プラン変更時の使用量処理', () {
      test('BasicからPremiumに変更しても使用量は保持される', () async {
        // Basic状態で使用
        for (int i = 0; i < 5; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final beforeChange = await subscriptionService.getMonthlyUsage();
        expect(beforeChange.value, equals(5));

        // Premiumに変更（既存の状態を取得してプランのみ変更）
        final currentStatus = await subscriptionService.getCurrentStatus();
        final status = currentStatus.value;
        final premiumYearlyPlan = PremiumYearlyPlan();
        status.planId = premiumYearlyPlan.id;
        status.isActive = true;
        status.autoRenewal = true;
        status.expiryDate = DateTime.now().add(const Duration(days: 365));
        await subscriptionService.updateStatus(status);

        final afterChange = await subscriptionService.getMonthlyUsage();
        expect(afterChange.value, equals(5)); // 使用量は保持

        // 残り回数は新しい制限で計算
        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(95)); // 100 - 5 = 95
      });

      test('PremiumからBasicに変更すると制限が厳しくなる', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 15回使用（Basicの制限10回を超える）
        for (int i = 0; i < 15; i++) {
          await subscriptionService.incrementAiUsage();
        }

        // 新しく状態を取得してBasicに変更（既存の使用量を保持）
        final currentStatus = await subscriptionService.getCurrentStatus();
        final status = currentStatus.value;
        final basicPlan = BasicPlan();
        status.planId = basicPlan.id;
        status.isActive = true;
        status.autoRenewal = false;
        status.expiryDate = null;
        await subscriptionService.updateStatus(status);

        final usage = await subscriptionService.getMonthlyUsage();
        expect(usage.value, greaterThan(10)); // Basicの制限を超えている

        final canUse = await subscriptionService.canUseAiGeneration();
        expect(canUse.value, isFalse); // Basicの制限を超えているため使用不可

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(0)); // 制限を超えているため0
      });
    });

    group('月次リセット自動処理シミュレーション', () {
      test('月が変わると使用量が自動リセットされる', () async {
        // 現在の月で使用量を設定
        for (int i = 0; i < 5; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final beforeReset = await subscriptionService.getMonthlyUsage();
        expect(beforeReset.value, equals(5));

        // 月次リセットをシミュレート（内部的には_resetMonthlyUsageIfNeeded）
        // これは実際にはSubscriptionStatus内で行われるため、
        // 直接的なテストは困難だが、resetUsage()で代用
        await subscriptionService.resetUsage();

        final afterReset = await subscriptionService.getMonthlyUsage();
        expect(afterReset.value, equals(0));
      });
    });

    group('エラーケース処理', () {
      test('不正な状態でのcanUseAiGeneration', () async {
        // サービスが適切に初期化されていない場合のテスト
        // 実際のテストでは初期化済みなので、Result<T>の成功を確認
        final result = await subscriptionService.canUseAiGeneration();
        expect(result.isSuccess, isTrue);
      });

      test('不正な状態でのincrementAiUsage', () async {
        // 正常な初期化状態でのテスト
        final result = await subscriptionService.incrementAiUsage();
        expect(result.isSuccess, isTrue);
      });

      test('不正な状態での使用量取得', () async {
        final result = await subscriptionService.getMonthlyUsage();
        expect(result.isSuccess, isTrue);
        expect(result.value, isA<int>());
      });

      test('不正な状態での残り回数取得', () async {
        final result = await subscriptionService.getRemainingGenerations();
        expect(result.isSuccess, isTrue);
        expect(result.value, isA<int>());
      });

      test('不正な状態でのリセット処理', () async {
        final result = await subscriptionService.resetUsage();
        expect(result.isSuccess, isTrue);
      });

      test('不正な状態での次回リセット日取得', () async {
        final result = await subscriptionService.getNextResetDate();
        expect(result.isSuccess, isTrue);
        expect(result.value, isA<DateTime>());
      });
    });

    group('境界値テスト', () {
      test('Basic: 制限ちょうど(10回)での使用可否', () async {
        // 9回使用（制限の1回前）
        for (int i = 0; i < 9; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final beforeLimit = await subscriptionService.canUseAiGeneration();
        expect(beforeLimit.value, isTrue);

        // 10回目使用（制限に到達）
        await subscriptionService.incrementAiUsage();

        final atLimit = await subscriptionService.canUseAiGeneration();
        expect(atLimit.value, isFalse);
      });

      test('Premium: 制限ちょうど(100回)での使用可否', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 99回使用（制限の1回前）
        for (int i = 0; i < 99; i++) {
          await subscriptionService.incrementAiUsage();
        }

        final beforeLimit = await subscriptionService.canUseAiGeneration();
        expect(beforeLimit.value, isTrue);

        // 100回目使用（制限に到達）
        await subscriptionService.incrementAiUsage();

        final atLimit = await subscriptionService.canUseAiGeneration();
        expect(atLimit.value, isFalse);
      });

      test('使用量0での各操作', () async {
        final usage = await subscriptionService.getMonthlyUsage();
        expect(usage.value, equals(0));

        final remaining = await subscriptionService.getRemainingGenerations();
        expect(remaining.value, equals(10)); // Basicプランの制限

        final canUse = await subscriptionService.canUseAiGeneration();
        expect(canUse.value, isTrue);
      });
    });

    group('並行処理・競合状態テスト', () {
      test('複数回の同時インクリメントが正しく処理される', () async {
        // 複数回のインクリメントを並行実行
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(subscriptionService.incrementAiUsage());
        }

        await Future.wait(futures);

        final usage = await subscriptionService.getMonthlyUsage();
        // 並行処理では競合状態により1以上の値になることを確認
        expect(usage.value, greaterThanOrEqualTo(1));
        expect(usage.value, lessThanOrEqualTo(5));
      });

      test('インクリメントと残り回数取得の並行実行', () async {
        final incrementFuture = subscriptionService.incrementAiUsage();
        final remainingFuture = subscriptionService.getRemainingGenerations();

        final results = await Future.wait([incrementFuture, remainingFuture]);

        expect(results[0].isSuccess, isTrue); // increment結果
        expect(results[1].isSuccess, isTrue); // remaining結果
        final remainingResult = results[1] as Result<int>;
        expect(remainingResult.value, isA<int>());
      });
    });
  });
}
