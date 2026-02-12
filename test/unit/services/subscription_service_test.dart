import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/services/subscription_state_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../helpers/hive_test_helpers.dart';
import '../helpers/subscription_test_helpers.dart';

void main() {
  group('SubscriptionService', () {
    late SubscriptionService subscriptionService;
    late SubscriptionStateService stateService;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();
    });

    tearDownAll(() async {
      // テスト終了時にHiveを閉じる
      await HiveTestHelpers.closeHive();
    });

    group('コンストラクタパターン', () {
      test('コンストラクタは独立したインスタンスを作成する', () async {
        // Act
        final bundle1 = await SubscriptionTestHelpers.createInitializedBundle();
        final bundle2 = await SubscriptionTestHelpers.createInitializedBundle();

        // Assert
        expect(
          bundle1.subscriptionService,
          isNot(same(bundle2.subscriptionService)),
        );
        expect(bundle1.subscriptionService.isInitialized, isTrue);
        expect(bundle2.subscriptionService.isInitialized, isTrue);
      });

      test('各インスタンスが独立して初期化される', () async {
        // Act
        final bundle1 = await SubscriptionTestHelpers.createInitializedBundle();
        final bundle2 = await SubscriptionTestHelpers.createInitializedBundle();

        // Assert
        expect(bundle1.subscriptionService.isInitialized, isTrue);
        expect(bundle2.subscriptionService.isInitialized, isTrue);

        // 各コンストラクタ呼び出しが独立したインスタンスを生成
        expect(
          bundle1.subscriptionService,
          isNot(same(bundle2.subscriptionService)),
        );
      });
    });

    group('初期化処理', () {
      test('初回初期化時にBasicプランの初期状態が作成される', () async {
        // Act
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;

        // Assert
        expect(subscriptionService.isInitialized, isTrue);

        // Hiveボックスが初期化されている（stateServiceから取得）
        final box = stateService.subscriptionBox;
        expect(box, isNotNull);
        expect(box!.isOpen, isTrue);

        // 初期状態が作成されている
        final status = box.get(SubscriptionConstants.statusKey);
        expect(status, isNotNull);
        expect(status!.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.expiryDate, isNull); // Basicプランは期限なし
      });

      test('既に状態が存在する場合は初期状態を作成しない', () async {
        // Arrange - 事前に状態を作成
        final box = await Hive.openBox<SubscriptionStatus>(
          SubscriptionConstants.hiveBoxName,
        );

        final existingStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        await box.put(SubscriptionConstants.statusKey, existingStatus);
        await box.close();

        // Act
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;

        // Assert
        final status = stateService.subscriptionBox?.get(
          SubscriptionConstants.statusKey,
        );
        expect(status, isNotNull);
        expect(status!.planId, equals('premium_monthly'));
        expect(status.monthlyUsageCount, equals(5));
        expect(status.transactionId, equals('test_transaction'));
      });

      test('正常に初期化が完了する', () async {
        // Act
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;

        // Assert
        expect(subscriptionService.isInitialized, isTrue);
        expect(stateService.subscriptionBox?.isOpen, isTrue);
      });
    });

    group('Hive操作実装確認 (Phase 1.3.2)', () {
      setUp(() async {
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;
      });

      test('getCurrentStatus()は初期化後にBasicプランを返す', () async {
        // Act
        final result = await subscriptionService.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
      });

      test('updateStatus()でサブスクリプション状態を更新できる', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction_update',
          lastPurchaseDate: DateTime.now(),
        );

        // Act - updateStatusはSubscriptionStateServiceのメソッド
        final updateResult = await stateService.updateStatus(newStatus);
        final getResult = await subscriptionService.getCurrentStatus();

        // Assert
        expect(updateResult.isSuccess, isTrue);
        expect(getResult.isSuccess, isTrue);
        final status = getResult.value;
        expect(status.planId, equals('premium_monthly'));
        expect(status.monthlyUsageCount, equals(5));
        expect(status.transactionId, equals('test_transaction_update'));
      });

      test('refreshStatus()でHiveボックスを再読み込みできる', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          autoRenewal: true,
          monthlyUsageCount: 15,
          lastResetDate: DateTime.now(),
          transactionId: 'test_refresh',
          lastPurchaseDate: DateTime.now(),
        );

        await stateService.updateStatus(newStatus);

        // Act
        final result = await subscriptionService.refreshStatus();

        // Assert
        expect(result.isSuccess, isTrue);

        // refreshStatus後に現在の状態を確認
        final statusResult = await subscriptionService.getCurrentStatus();
        expect(statusResult.isSuccess, isTrue);
        final status = statusResult.value;
        expect(status.planId, equals('premium_yearly'));
        expect(status.monthlyUsageCount, equals(15));
        expect(status.transactionId, equals('test_refresh'));
      });

      test('createStatusForPlan()でBasicプランの状態を作成できる', () async {
        // Arrange
        await stateService.clearStatus();

        // Act
        final basicPlan = BasicPlan();
        final result = await stateService.createStatusForPlan(basicPlan);

        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNull); // Basicプランは期限なし
        expect(status.autoRenewal, isFalse);
        expect(status.monthlyUsageCount, equals(0));
      });

      test('createStatusForPlan()でPremium月額プランの状態を作成できる', () async {
        // Arrange
        await stateService.clearStatus();

        // Act
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        final result = await stateService.createStatusForPlan(
          premiumMonthlyPlan,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals('premium_monthly'));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.autoRenewal, isTrue);
        expect(status.monthlyUsageCount, equals(0));

        // 有効期限が月額プラン期間（30日）に設定されている
        final expectedExpiry = status.startDate!.add(
          const Duration(days: SubscriptionConstants.subscriptionMonthDays),
        );
        expect(
          status.expiryDate!.difference(expectedExpiry).inMinutes.abs(),
          lessThan(1),
        );
      });

      test('createStatusForPlan()でPremium年額プランの状態を作成できる', () async {
        // Arrange
        await stateService.clearStatus();

        // Act
        final premiumYearlyPlan = PremiumYearlyPlan();
        final result = await stateService.createStatusForPlan(
          premiumYearlyPlan,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals('premium_yearly'));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.autoRenewal, isTrue);
        expect(status.monthlyUsageCount, equals(0));

        // 有効期限が年額プラン期間（365日）に設定されている
        final expectedExpiry = status.startDate!.add(
          const Duration(days: SubscriptionConstants.subscriptionYearDays),
        );
        expect(
          status.expiryDate!.difference(expectedExpiry).inMinutes.abs(),
          lessThan(1),
        );
      });

      test('clearStatus()でサブスクリプション状態を削除できる', () async {
        // Act
        final clearResult = await stateService.clearStatus();
        final getResult = await subscriptionService.getCurrentStatus();

        // Assert
        expect(clearResult.isSuccess, isTrue);
        expect(getResult.isSuccess, isTrue);
        // getCurrentStatus()は状態がない場合に初期状態を作成するため、Basicプランが返される
        final status = getResult.value;
        expect(status.planId, equals('basic'));
      });
    });

    group('使用量管理機能確認 (Phase 1.3.3)', () {
      setUp(() async {
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;
      });

      test('canUseAiGeneration()はBasicプランで制限内なら使用可能', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // Act
        final result = await subscriptionService.canUseAiGeneration();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Basic: 10回制限、0回使用なので使用可能
      });

      test('incrementAiUsage()で使用量を正しくインクリメントできる', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // Act
        final incrementResult = await subscriptionService.incrementAiUsage();
        final statusResult = await subscriptionService.getCurrentStatus();

        // Assert
        expect(incrementResult.isSuccess, isTrue);
        expect(statusResult.isSuccess, isTrue);
        expect(statusResult.value.monthlyUsageCount, equals(1));
      });

      test('incrementAiUsage()を複数回実行して制限に達する', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // Act - Basic制限の10回まで使用
        for (int i = 0; i < 10; i++) {
          final result = await subscriptionService.incrementAiUsage();
          expect(result.isSuccess, isTrue);
        }

        // 11回目は制限エラー
        final limitResult = await subscriptionService.incrementAiUsage();

        // Assert
        expect(limitResult.isFailure, isTrue);
        expect(
          limitResult.error.toString(),
          contains('Monthly AI generation limit reached'),
        );
      });

      test('canUseAiGeneration()は制限に達すると使用不可を返す', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // 制限まで使用
        for (int i = 0; i < 10; i++) {
          await subscriptionService.incrementAiUsage();
        }

        // Act
        final result = await subscriptionService.canUseAiGeneration();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // 制限に達したので使用不可
      });

      test('getRemainingGenerations()で残り回数を取得できる', () async {
        // Arrange
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await stateService.createStatusForPlan(premiumMonthlyPlan);

        // 5回使用
        for (int i = 0; i < 5; i++) {
          await subscriptionService.incrementAiUsage();
        }

        // Act
        final result = await subscriptionService.getRemainingGenerations();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(95)); // Premium: 100回制限 - 5回使用 = 95回
      });

      test('getNextResetDate()で翌月1日を取得できる', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // Act
        final result = await subscriptionService.getNextResetDate();

        // Assert
        expect(result.isSuccess, isTrue);
        final nextReset = result.value;
        final now = DateTime.now();

        // 翌月の1日であることを確認
        if (now.month == 12) {
          expect(nextReset.year, equals(now.year + 1));
          expect(nextReset.month, equals(1));
        } else {
          expect(nextReset.year, equals(now.year));
          expect(nextReset.month, equals(now.month + 1));
        }
        expect(nextReset.day, equals(1));
      });

      test('月次使用量リセットが正しく動作する', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // 使用量を増やす
        await subscriptionService.incrementAiUsage();
        await subscriptionService.incrementAiUsage();

        // 前月の日付でリセット日を設定（手動でテスト）
        final status = (await subscriptionService.getCurrentStatus()).value;
        final previousMonth = DateTime(
          DateTime.now().month == 1
              ? DateTime.now().year - 1
              : DateTime.now().year,
          DateTime.now().month == 1 ? 12 : DateTime.now().month - 1,
          1,
        );

        final modifiedStatus = SubscriptionStatus(
          planId: status.planId,
          isActive: status.isActive,
          startDate: status.startDate,
          expiryDate: status.expiryDate,
          autoRenewal: status.autoRenewal,
          monthlyUsageCount: status.monthlyUsageCount,
          lastResetDate: previousMonth, // 前月に設定
          transactionId: status.transactionId,
          lastPurchaseDate: status.lastPurchaseDate,
        );

        await stateService.updateStatus(modifiedStatus);

        // Act - リセットチェックを実行
        await subscriptionService.resetMonthlyUsageIfNeeded();
        final newStatus = (await subscriptionService.getCurrentStatus()).value;

        // Assert
        expect(newStatus.monthlyUsageCount, equals(0)); // リセットされている
      });

      test('Premiumプランは制限が100回に設定される', () async {
        // Arrange
        final premiumYearlyPlan = PremiumYearlyPlan();
        await stateService.createStatusForPlan(premiumYearlyPlan);

        // Act
        final remainingResult = await subscriptionService
            .getRemainingGenerations();

        // Assert
        expect(remainingResult.isSuccess, isTrue);
        expect(remainingResult.value, equals(100)); // Premium制限
      });

      test('期限切れのPremiumプランでは使用不可', () async {
        // Arrange - 期限切れのPremiumプランを作成
        final expiredStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          expiryDate: DateTime.now().subtract(
            const Duration(days: 30),
          ), // 30日前に期限切れ
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'expired_premium',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 60)),
        );

        await stateService.updateStatus(expiredStatus);

        // Act
        final canUseResult = await subscriptionService.canUseAiGeneration();
        final remainingResult = await subscriptionService
            .getRemainingGenerations();

        // Assert
        expect(canUseResult.isSuccess, isTrue);
        expect(canUseResult.value, isFalse); // 期限切れなので使用不可
        expect(remainingResult.isSuccess, isTrue);
        expect(remainingResult.value, equals(0)); // 期限切れなので0
      });
    });

    group('Phase 1.3.4 未実装メソッド確認', () {
      setUp(() async {
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;
      });

      test('getCurrentStatus()は正常にBasicプランを返す', () async {
        // Act
        final result = await subscriptionService.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
      });

      test('canUseAiGeneration()は正常に動作する', () async {
        // Act
        final result = await subscriptionService.canUseAiGeneration();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(
          result.value,
          isTrue,
        ); // Basic plan with 0 usage should allow generation
      });

      test('canAccessPremiumFeatures()はBasicプランでfalseを返す', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // Act
        final result = await subscriptionService.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは基本機能のみ
      });

      test('canAccessPremiumFeatures()は有効なPremiumプランでtrueを返す', () async {
        // Arrange
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await stateService.createStatusForPlan(premiumMonthlyPlan);

        // Act
        final result = await subscriptionService.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // 有効なPremiumプランは全機能利用可能
      });

      test('canAccessPremiumFeatures()は期限切れPremiumプランでfalseを返す', () async {
        // Arrange - 期限切れのPremiumプランを作成
        final expiredStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          expiryDate: DateTime.now().subtract(
            const Duration(days: 30),
          ), // 30日前に期限切れ
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'expired_premium',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 60)),
        );

        await stateService.updateStatus(expiredStatus);

        // Act
        final result = await subscriptionService.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // 期限切れなのでアクセス不可
      });
    });

    group('機能別アクセス権限テスト (Phase 1.3.4)', () {
      setUp(() async {
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;
        stateService = bundle.stateService;
      });

      test('canAccessWritingPrompts()は全プランで制限付きアクセス可能', () async {
        // Basic プランのテスト
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);
        var result = await subscriptionService.canAccessWritingPrompts();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Basicプランでも基本プロンプトは利用可能

        // Premium プランのテスト
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await stateService.createStatusForPlan(premiumMonthlyPlan);
        result = await subscriptionService.canAccessWritingPrompts();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Premiumプランでは全プロンプト利用可能
      });

      test('canAccessAdvancedFilters()はPremiumプランのみtrueを返す', () async {
        // Basic プランのテスト
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);
        var result = await subscriptionService.canAccessAdvancedFilters();
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは高度なフィルタ利用不可

        // Premium プランのテスト
        final premiumYearlyPlan = PremiumYearlyPlan();
        await stateService.createStatusForPlan(premiumYearlyPlan);
        result = await subscriptionService.canAccessAdvancedFilters();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Premiumプランは高度なフィルタ利用可能
      });

      test('canAccessAdvancedAnalytics()はPremiumプランのみtrueを返す', () async {
        // Basic プランのテスト
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);
        var result = await subscriptionService.canAccessAdvancedAnalytics();
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは高度な分析利用不可

        // Premium プランのテスト
        final premiumYearlyPlan = PremiumYearlyPlan();
        await stateService.createStatusForPlan(premiumYearlyPlan);
        result = await subscriptionService.canAccessAdvancedAnalytics();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Premiumプランは高度な分析利用可能
      });

      test('canAccessPrioritySupport()はPremiumプランのみtrueを返す', () async {
        // Basic プランのテスト
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);
        var result = await subscriptionService.canAccessPrioritySupport();
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは優先サポート利用不可

        // Premium プランのテスト
        final premiumYearlyPlan = PremiumYearlyPlan();
        await stateService.createStatusForPlan(premiumYearlyPlan);
        result = await subscriptionService.canAccessPrioritySupport();
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // Premiumプランは優先サポート利用可能
      });

      test('Basicプランの全アクセス権限確認', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await stateService.createStatusForPlan(basicPlan);

        // Act
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

        // Assert
        expect(premiumResult.value, isFalse); // Premium機能は利用不可
        expect(promptsResult.value, isTrue); // 基本プロンプトは利用可能
        expect(filtersResult.value, isFalse); // 高度なフィルタは利用不可
        expect(analyticsResult.value, isFalse); // 高度な分析は利用不可
        expect(supportResult.value, isFalse); // 優先サポートは利用不可
      });

      test('Premiumプランの全アクセス権限確認', () async {
        // Arrange
        final premiumYearlyPlan = PremiumYearlyPlan();
        await stateService.createStatusForPlan(premiumYearlyPlan);

        // Act
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

        // Assert
        expect(premiumResult.value, isTrue); // Premium機能は利用可能
        expect(promptsResult.value, isTrue); // 全プロンプトは利用可能
        expect(filtersResult.value, isTrue); // 高度なフィルタは利用可能
        expect(analyticsResult.value, isTrue); // 高度な分析は利用可能
        expect(supportResult.value, isTrue); // 優先サポートは利用可能
      });

      test('期限切れPremiumプランでは機能制限が適用される', () async {
        // Arrange - 期限切れのPremiumプランを作成
        final expiredStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          expiryDate: DateTime.now().subtract(
            const Duration(days: 30),
          ), // 30日前に期限切れ
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'expired_premium',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 60)),
        );

        await stateService.updateStatus(expiredStatus);

        // Act
        final premiumFeaturesResult = await subscriptionService
            .canAccessPremiumFeatures();
        final advancedFiltersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final analyticsResult = await subscriptionService
            .canAccessAdvancedAnalytics();
        final supportResult = await subscriptionService
            .canAccessPrioritySupport();

        // Assert
        expect(premiumFeaturesResult.isSuccess, isTrue);
        expect(advancedFiltersResult.isSuccess, isTrue);
        expect(analyticsResult.isSuccess, isTrue);
        expect(supportResult.isSuccess, isTrue);

        expect(premiumFeaturesResult.value, isFalse);
        expect(advancedFiltersResult.value, isFalse);
        expect(analyticsResult.value, isFalse);
        expect(supportResult.value, isFalse);
      });
    });

    group('内部状態確認', () {
      test('isInitialized プロパティが正しく動作する', () async {
        // Act
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        subscriptionService = bundle.subscriptionService;

        // Assert
        expect(subscriptionService.isInitialized, isTrue);
      });

      test('stateService.subscriptionBox プロパティがHiveボックスを返す', () async {
        // Act
        final bundle = await SubscriptionTestHelpers.createInitializedBundle();
        stateService = bundle.stateService;

        // Assert
        final box = stateService.subscriptionBox;
        expect(box, isNotNull);
        expect(box!.isOpen, isTrue);
        expect(box.name, equals(SubscriptionConstants.hiveBoxName));
      });

      test('新しいインスタンスが別のオブジェクトとして作成される', () async {
        // Arrange
        final bundle1 = await SubscriptionTestHelpers.createInitializedBundle();
        final bundle2 = await SubscriptionTestHelpers.createInitializedBundle();

        // Assert
        expect(
          bundle1.subscriptionService,
          isNot(same(bundle2.subscriptionService)),
        );
      });
    });
  });
}
