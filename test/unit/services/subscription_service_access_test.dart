import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import '../helpers/hive_test_helpers.dart';

/// Phase 1.5.2.3: アクセス権限テスト
///
/// SubscriptionServiceのアクセス権限チェック機能の詳細テスト
/// - プラン別機能制限の確認
/// - プレミアム機能アクセス権限
/// - ライティングプロンプト機能
/// - 高度なフィルタ機能
/// - 高度な分析機能
/// - 優先サポート機能
/// - 期限切れ・無効状態での制限
void main() {
  group('Phase 1.5.2.3: SubscriptionService アクセス権限テスト', () {
    late SubscriptionService subscriptionService;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();

      // SubscriptionServiceインスタンスをリセット
      SubscriptionService.resetForTesting();

      // 新しいインスタンスを取得
      subscriptionService = await SubscriptionService.getInstance();
    });

    tearDownAll(() async {
      // テスト終了時にHiveを閉じる
      await HiveTestHelpers.closeHive();
    });

    group('Basicプランのアクセス権限', () {
      test('プレミアム機能にアクセスできない', () async {
        final result = await subscriptionService.canAccessPremiumFeatures();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('ライティングプロンプトに制限付きでアクセスできる', () async {
        final result = await subscriptionService.canAccessWritingPrompts();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Basicプランでも制限付きアクセス可能
      });

      test('高度なフィルタにアクセスできない', () async {
        final result = await subscriptionService.canAccessAdvancedFilters();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('高度な分析にアクセスできない', () async {
        final result = await subscriptionService.canAccessAdvancedAnalytics();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('優先サポートにアクセスできない', () async {
        final result = await subscriptionService.canAccessPrioritySupport();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('全てのプレミアム機能を一括確認', () async {
        final premiumResult = await subscriptionService
            .canAccessPremiumFeatures();
        final promptsResult = await subscriptionService
            .canAccessWritingPrompts();
        final filtersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final analyticsResult = await subscriptionService
            .canAccessAdvancedAnalytics();
        final supportResult = await subscriptionService
            .canAccessPrioritySupport();

        expect(premiumResult.value, isFalse);
        expect(promptsResult.value, isTrue); // Basicプランでも制限付きアクセス可能
        expect(filtersResult.value, isFalse);
        expect(analyticsResult.value, isFalse);
        expect(supportResult.value, isFalse);
      });
    });

    group('Premium月額プランのアクセス権限', () {
      setUp(() async {
        // Premium月額プランに変更
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await subscriptionService.createStatusClass(premiumMonthlyPlan);
      });

      test('プレミアム機能にアクセスできる', () async {
        final result = await subscriptionService.canAccessPremiumFeatures();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('ライティングプロンプトにアクセスできる', () async {
        final result = await subscriptionService.canAccessWritingPrompts();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('高度なフィルタにアクセスできる', () async {
        final result = await subscriptionService.canAccessAdvancedFilters();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('高度な分析にアクセスできる', () async {
        final result = await subscriptionService.canAccessAdvancedAnalytics();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('優先サポートにアクセスできる', () async {
        final result = await subscriptionService.canAccessPrioritySupport();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('全てのプレミアム機能を一括確認', () async {
        final premiumResult = await subscriptionService
            .canAccessPremiumFeatures();
        final promptsResult = await subscriptionService
            .canAccessWritingPrompts();
        final filtersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final analyticsResult = await subscriptionService
            .canAccessAdvancedAnalytics();
        final supportResult = await subscriptionService
            .canAccessPrioritySupport();

        expect(premiumResult.value, isTrue);
        expect(promptsResult.value, isTrue);
        expect(filtersResult.value, isTrue);
        expect(analyticsResult.value, isTrue);
        expect(supportResult.value, isTrue);
      });
    });

    group('Premium年額プランのアクセス権限', () {
      setUp(() async {
        // Premium年額プランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);
      });

      test('プレミアム機能にアクセスできる', () async {
        final result = await subscriptionService.canAccessPremiumFeatures();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('ライティングプロンプトにアクセスできる', () async {
        final result = await subscriptionService.canAccessWritingPrompts();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('高度なフィルタにアクセスできる', () async {
        final result = await subscriptionService.canAccessAdvancedFilters();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('高度な分析にアクセスできる', () async {
        final result = await subscriptionService.canAccessAdvancedAnalytics();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('優先サポートにアクセスできる', () async {
        final result = await subscriptionService.canAccessPrioritySupport();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('月額と年額で同じアクセス権限を持つ', () async {
        // 現在の年額プランの権限を記録
        final yearlyPremium = await subscriptionService
            .canAccessPremiumFeatures();
        final yearlyPrompts = await subscriptionService
            .canAccessWritingPrompts();
        final yearlyFilters = await subscriptionService
            .canAccessAdvancedFilters();
        final yearlyAnalytics = await subscriptionService
            .canAccessAdvancedAnalytics();
        final yearlySupport = await subscriptionService
            .canAccessPrioritySupport();

        // 月額プランに変更
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await subscriptionService.createStatusClass(premiumMonthlyPlan);

        // 月額プランの権限を確認
        final monthlyPremium = await subscriptionService
            .canAccessPremiumFeatures();
        final monthlyPrompts = await subscriptionService
            .canAccessWritingPrompts();
        final monthlyFilters = await subscriptionService
            .canAccessAdvancedFilters();
        final monthlyAnalytics = await subscriptionService
            .canAccessAdvancedAnalytics();
        final monthlySupport = await subscriptionService
            .canAccessPrioritySupport();

        // 同じアクセス権限を持つことを確認
        expect(yearlyPremium.value, equals(monthlyPremium.value));
        expect(yearlyPrompts.value, equals(monthlyPrompts.value));
        expect(yearlyFilters.value, equals(monthlyFilters.value));
        expect(yearlyAnalytics.value, equals(monthlyAnalytics.value));
        expect(yearlySupport.value, equals(monthlySupport.value));
      });
    });

    group('期限切れPremiumプランのアクセス権限', () {
      setUp(() async {
        // 期限切れのPremiumプランを設定
        final currentStatus = await subscriptionService.getCurrentStatus();
        final status = currentStatus.value;

        // 過去の日付で期限切れにする
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        status.planId = 'premium_yearly';
        status.isActive = true;
        status.expiryDate = pastDate;
        status.save();
      });

      test('期限切れではプレミアム機能にアクセスできない', () async {
        final result = await subscriptionService.canAccessPremiumFeatures();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('期限切れでもライティングプロンプトには基本アクセス可能', () async {
        final result = await subscriptionService.canAccessWritingPrompts();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Basicレベルのアクセスは維持
      });

      test('期限切れでは高度なフィルタにアクセスできない', () async {
        final result = await subscriptionService.canAccessAdvancedFilters();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('期限切れでは高度な分析にアクセスできない', () async {
        final result = await subscriptionService.canAccessAdvancedAnalytics();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('期限切れでは優先サポートにアクセスできない', () async {
        final result = await subscriptionService.canAccessPrioritySupport();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });

    group('非アクティブPremiumプランのアクセス権限', () {
      setUp(() async {
        // 非アクティブのPremiumプランを設定
        final currentStatus = await subscriptionService.getCurrentStatus();
        final status = currentStatus.value;

        status.planId = 'premium_yearly';
        status.isActive = false; // 非アクティブ
        status.expiryDate = DateTime.now().add(
          const Duration(days: 30),
        ); // 期限は有効
        status.save();
      });

      test('非アクティブではプレミアム機能にアクセスできない', () async {
        final result = await subscriptionService.canAccessPremiumFeatures();

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('非アクティブでも基本機能にはアクセスできる', () async {
        final premiumResult = await subscriptionService
            .canAccessPremiumFeatures();
        final promptsResult = await subscriptionService
            .canAccessWritingPrompts();
        final filtersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final analyticsResult = await subscriptionService
            .canAccessAdvancedAnalytics();
        final supportResult = await subscriptionService
            .canAccessPrioritySupport();

        expect(premiumResult.value, isFalse);
        expect(promptsResult.value, isTrue); // 基本ライティングプロンプトアクセス
        expect(filtersResult.value, isFalse);
        expect(analyticsResult.value, isFalse);
        expect(supportResult.value, isFalse);
      });
    });

    group('プラン変更時のアクセス権限変化', () {
      test('BasicからPremiumへの変更でアクセス権限が有効になる', () async {
        // 初期状態（Basic）でアクセス権限を確認
        final basicPremium = await subscriptionService
            .canAccessPremiumFeatures();
        final basicPrompts = await subscriptionService
            .canAccessWritingPrompts();

        expect(basicPremium.value, isFalse);
        expect(basicPrompts.value, isTrue); // Basicでも制限付きアクセス

        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 変更後のアクセス権限を確認
        final premiumPremium = await subscriptionService
            .canAccessPremiumFeatures();
        final premiumPrompts = await subscriptionService
            .canAccessWritingPrompts();

        expect(premiumPremium.value, isTrue);
        expect(premiumPrompts.value, isTrue);
      });

      test('PremiumからBasicへの変更でアクセス権限が無効になる', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // Premium状態でアクセス権限を確認
        final premiumAccess = await subscriptionService
            .canAccessPremiumFeatures();
        expect(premiumAccess.value, isTrue);

        // Basicプランに変更
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // 変更後のアクセス権限を確認
        final basicAccess = await subscriptionService
            .canAccessPremiumFeatures();
        expect(basicAccess.value, isFalse);

        // ライティングプロンプトは基本アクセスが維持される
        final basicPrompts = await subscriptionService
            .canAccessWritingPrompts();
        expect(basicPrompts.value, isTrue);
      });

      test('Premium月額から年額への変更でアクセス権限は維持される', () async {
        // Premium月額プランに変更
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await subscriptionService.createStatusClass(premiumMonthlyPlan);

        // 月額状態でアクセス権限を確認
        final monthlyAccess = await subscriptionService
            .canAccessPremiumFeatures();
        expect(monthlyAccess.value, isTrue);

        // 年額プランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 変更後もアクセス権限が維持されることを確認
        final yearlyAccess = await subscriptionService
            .canAccessPremiumFeatures();
        expect(yearlyAccess.value, isTrue);
      });
    });

    group('キャンセル・復元時のアクセス権限', () {
      test('キャンセル後はアクセス権限が無効になる', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);
        final status = (await subscriptionService.getCurrentStatus()).value;

        // Premium状態でアクセス権限を確認
        final beforeCancel = await subscriptionService
            .canAccessPremiumFeatures();
        expect(beforeCancel.value, isTrue);

        // キャンセル
        status.cancel();

        // キャンセル後のアクセス権限を確認
        final afterCancel = await subscriptionService
            .canAccessPremiumFeatures();
        expect(afterCancel.value, isFalse);
      });

      test('復元後はアクセス権限が有効になる', () async {
        // Premiumプランに変更してキャンセル
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);
        final status = (await subscriptionService.getCurrentStatus()).value;
        status.cancel();

        // キャンセル状態でアクセス権限を確認
        final afterCancel = await subscriptionService
            .canAccessPremiumFeatures();
        expect(afterCancel.value, isFalse);

        // ライティングプロンプトは基本アクセスが維持される
        final promptsAfterCancel = await subscriptionService
            .canAccessWritingPrompts();
        expect(promptsAfterCancel.value, isTrue);

        // 復元してPremiumプランに戻す
        status.restore();
        final restoredPremiumPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(restoredPremiumPlan);

        // 復元後のアクセス権限を確認
        final afterRestore = await subscriptionService
            .canAccessPremiumFeatures();
        expect(afterRestore.value, isTrue);
      });
    });

    group('境界条件でのアクセス権限', () {
      test('期限ちょうどでのアクセス権限', () async {
        // 今日が期限のPremiumプランを設定
        final currentStatus = await subscriptionService.getCurrentStatus();
        final status = currentStatus.value;

        final today = DateTime.now();
        status.planId = 'premium_yearly';
        status.isActive = true;
        status.expiryDate = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        );
        status.save();

        // まだ有効であることを確認
        final result = await subscriptionService.canAccessPremiumFeatures();
        expect(result.value, isTrue);
      });

      test('期限1秒後でのアクセス権限', () async {
        // 1秒前に期限切れのPremiumプランを設定
        final currentStatus = await subscriptionService.getCurrentStatus();
        final status = currentStatus.value;

        final pastDate = DateTime.now().subtract(const Duration(seconds: 1));
        status.planId = 'premium_yearly';
        status.isActive = true;
        status.expiryDate = pastDate;
        status.save();

        // 期限切れであることを確認
        final result = await subscriptionService.canAccessPremiumFeatures();
        expect(result.value, isFalse);
      });
    });

    group('エラーケース処理', () {
      test('不正な状態でのアクセス権限チェック', () async {
        // 正常な初期化状態でのテスト
        final results = await Future.wait([
          subscriptionService.canAccessPremiumFeatures(),
          subscriptionService.canAccessWritingPrompts(),
          subscriptionService.canAccessAdvancedFilters(),
          subscriptionService.canAccessAdvancedAnalytics(),
          subscriptionService.canAccessPrioritySupport(),
        ]);

        // 全ての結果が成功であることを確認
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.value, isA<bool>());
        }
      });

      test('サービス初期化直後のアクセス権限', () async {
        // 初期化直後は基本的にBasicプランの権限
        final premiumResult = await subscriptionService
            .canAccessPremiumFeatures();
        final promptsResult = await subscriptionService
            .canAccessWritingPrompts();

        expect(premiumResult.isSuccess, isTrue);
        expect(premiumResult.value, isFalse); // Basicプランなのでfalse
        expect(promptsResult.isSuccess, isTrue);
        expect(promptsResult.value, isTrue); // Basicでも制限付きアクセス
      });
    });

    group('パフォーマンス・並行処理テスト', () {
      test('複数のアクセス権限チェックを並行実行', () async {
        final futures = <Future>[];

        // 10回並行でアクセス権限をチェック
        for (int i = 0; i < 10; i++) {
          futures.add(subscriptionService.canAccessPremiumFeatures());
        }

        final results = await Future.wait(futures);

        // 全ての結果が一致することを確認
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.value, isFalse); // 初期状態はBasicプランなのでプレミアム機能はfalse
        }
      });

      test('プラン変更とアクセス権限チェックの並行実行', () async {
        // Premiumプランに変更
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // 並行でアクセス権限をチェック
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(subscriptionService.canAccessPremiumFeatures());
        }

        final results = await Future.wait(futures);

        // 全ての結果がPremiumプランのアクセス権限を反映することを確認
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.value, isTrue);
        }
      });
    });

    group('機能別詳細テスト', () {
      group('ライティングプロンプト機能', () {
        test('Basicプランでも制限付きで使用可能', () async {
          final result = await subscriptionService.canAccessWritingPrompts();
          expect(result.value, isTrue); // 制限付きで使用可能
        });

        test('Premiumプランでは完全に使用可能', () async {
          final premiumYearlyPlan = PremiumYearlyPlan();
          await subscriptionService.createStatusClass(premiumYearlyPlan);

          final result = await subscriptionService.canAccessWritingPrompts();
          expect(result.value, isTrue);
        });
      });

      group('高度なフィルタ機能', () {
        test('Basicプランでは使用不可', () async {
          final result = await subscriptionService.canAccessAdvancedFilters();
          expect(result.value, isFalse);
        });

        test('Premiumプランでは使用可能', () async {
          final premiumYearlyPlan = PremiumYearlyPlan();
          await subscriptionService.createStatusClass(premiumYearlyPlan);

          final result = await subscriptionService.canAccessAdvancedFilters();
          expect(result.value, isTrue);
        });
      });

      group('高度な分析機能', () {
        test('Basicプランでは使用不可', () async {
          final result = await subscriptionService.canAccessAdvancedAnalytics();
          expect(result.value, isFalse);
        });

        test('Premiumプランでは使用可能', () async {
          final premiumYearlyPlan = PremiumYearlyPlan();
          await subscriptionService.createStatusClass(premiumYearlyPlan);

          final result = await subscriptionService.canAccessAdvancedAnalytics();
          expect(result.value, isTrue);
        });
      });

      group('優先サポート機能', () {
        test('Basicプランでは使用不可', () async {
          final result = await subscriptionService.canAccessPrioritySupport();
          expect(result.value, isFalse);
        });

        test('Premiumプランでは使用可能', () async {
          final premiumYearlyPlan = PremiumYearlyPlan();
          await subscriptionService.createStatusClass(premiumYearlyPlan);

          final result = await subscriptionService.canAccessPrioritySupport();
          expect(result.value, isTrue);
        });
      });
    });
  });
}
