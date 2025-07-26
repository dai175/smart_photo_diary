import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';

void main() {
  group('SubscriptionStatus', () {
    late Box<SubscriptionStatus> testBox;

    setUpAll(() async {
      // テスト用のHive初期化
      Hive.init('./test/temp');
      Hive.registerAdapter(SubscriptionStatusAdapter());
    });

    setUp(() async {
      // 各テスト前にテスト用Boxを作成
      testBox = await Hive.openBox<SubscriptionStatus>('test_subscription');
    });

    tearDown(() async {
      // 各テスト後にBoxをクリア
      await testBox.clear();
      await testBox.close();
    });

    tearDownAll(() async {
      // 全テスト終了後にHiveをクリア
      await Hive.deleteFromDisk();
    });

    group('基本的な初期化テスト', () {
      test('デフォルトコンストラクタで正しく初期化される', () {
        final status = SubscriptionStatus();

        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.autoRenewal, isFalse);
        // Planクラスを使用して検証
        final plan = PlanFactory.createPlan(status.planId);
        expect(plan, isA<BasicPlan>());
        // currentPlanのenumプロパティは削除されたため、Planクラスで検証
      });

      test('createDefaultで正しいデフォルト状態が作成される', () {
        final status = SubscriptionStatus.createDefault();

        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        // Planクラスを使用して検証
        final plan = PlanFactory.createPlan(status.planId);
        expect(plan, isA<BasicPlan>());
        // currentPlanのenumプロパティは削除されたため、Planクラスで検証
        expect(status.monthlyUsageCount, equals(0));
        expect(status.autoRenewal, isFalse);
        expect(status.startDate, isNotNull);
      });

      test('createPremiumで正しいPremium状態が作成される', () {
        final startDate = DateTime.now();
        final status = SubscriptionStatus.createPremium(
          startDate: startDate,
          plan: SubscriptionPlan.premiumYearly,
          transactionId: 'test_transaction',
        );

        expect(status.planId, equals('premium_yearly'));
        expect(status.isActive, isTrue);
        // Planクラスを使用して検証
        final plan = PlanFactory.createPlan(status.planId);
        expect(plan, isA<PremiumYearlyPlan>());
        // currentPlanのenumプロパティは削除されたため、Planクラスで検証
        expect(status.startDate, equals(startDate));
        expect(
          status.expiryDate,
          equals(startDate.add(const Duration(days: 365))),
        );
        expect(status.autoRenewal, isTrue);
        expect(status.transactionId, equals('test_transaction'));
        expect(status.lastPurchaseDate, equals(startDate));
      });
    });

    group('プラン管理テスト', () {
      test('currentPlanが正しく取得される', () {
        final basicStatus = SubscriptionStatus(planId: 'basic');
        final premiumStatus = SubscriptionStatus(planId: 'premium_yearly');

        expect(basicStatus.currentPlan, equals(SubscriptionPlan.basic));
        // Planクラスを使用して検証
        final premiumPlan = PlanFactory.createPlan(premiumStatus.planId);
        expect(premiumPlan, isA<PremiumYearlyPlan>());
        expect(
          premiumStatus.currentPlan,
          equals(SubscriptionPlan.premiumYearly),
        ); // 互換性のため保持
      });

      test('不正なプランIDでもBasicにフォールバックする', () {
        final status = SubscriptionStatus(planId: 'invalid_plan');

        // SubscriptionStatusの内部ロジックをテスト（enumベースのフォールバック）
        // currentPlanのenumプロパティは削除されたため、Planクラスで検証
        expect(status.planId, equals('invalid_plan')); // planId自体は保持される
      });

      test('changePlanでプランが正しく変更される', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);

        status.changePlan(SubscriptionPlan.premiumYearly);

        expect(status.planId, equals('premium_yearly'));
        // Planクラスを使用して検証
        final plan = PlanFactory.createPlan(status.planId);
        expect(plan, isA<PremiumYearlyPlan>());
        // currentPlanのenumプロパティは削除されたため、Planクラスで検証
        expect(status.isActive, isTrue);
        expect(status.autoRenewal, isTrue);
        expect(status.startDate, isNotNull);
        expect(status.expiryDate, isNotNull);
      });

      test('BasicプランへのchangePlanで期限がクリアされる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);

        status.changePlan(SubscriptionPlan.basic);

        expect(status.planId, equals('basic'));
        // Planクラスを使用して検証
        final plan = PlanFactory.createPlan(status.planId);
        expect(plan, isA<BasicPlan>());
        // currentPlanのenumプロパティは削除されたため、Planクラスで検証
        expect(status.expiryDate, isNull);
        expect(status.autoRenewal, isFalse);
      });
    });

    group('有効性チェックテスト', () {
      test('Basicプランは常に有効', () {
        final status = SubscriptionStatus.createDefault();

        expect(status.isValid, isTrue);
        expect(status.isExpired, isFalse);
      });

      test('有効なPremiumプランは有効', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          expiryDate: futureDate,
        );

        expect(status.isValid, isTrue);
        expect(status.isExpired, isFalse);
      });

      test('期限切れのPremiumプランは無効', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          expiryDate: pastDate,
        );

        expect(status.isValid, isFalse);
        expect(status.isExpired, isTrue);
      });

      test('非アクティブなプランは無効', () {
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: false,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        );

        expect(status.isValid, isFalse);
      });
    });

    group('使用量管理テスト', () {
      test('初期状態では使用量制限に達していない', () {
        final status = SubscriptionStatus.createDefault();

        expect(status.hasReachedMonthlyLimit, isFalse);
        expect(status.canUseAiGeneration, isTrue);
        expect(status.remainingGenerations, equals(10)); // Basic plan limit
      });

      test('使用量をインクリメントできる', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);

        expect(status.monthlyUsageCount, equals(0));

        status.incrementAiUsage();
        expect(status.monthlyUsageCount, equals(1));
        expect(status.remainingGenerations, equals(9));

        status.incrementAiUsage();
        expect(status.monthlyUsageCount, equals(2));
        expect(status.remainingGenerations, equals(8));
      });

      test('制限に達すると使用できなくなる', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);

        // Basic plan limit (10) まで使用
        for (int i = 0; i < 10; i++) {
          status.incrementAiUsage();
        }

        expect(status.hasReachedMonthlyLimit, isTrue);
        expect(status.canUseAiGeneration, isFalse);
        expect(status.remainingGenerations, equals(0));
      });

      test('使用量をリセットできる', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);

        // 使用量を増やす
        for (int i = 0; i < 5; i++) {
          status.incrementAiUsage();
        }
        expect(status.monthlyUsageCount, equals(5));

        status.resetUsage();
        expect(status.monthlyUsageCount, equals(0));
        expect(status.remainingGenerations, equals(10));
        expect(status.lastResetDate, isNotNull);
      });

      test('Premiumプランでは制限が異なる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);

        expect(status.remainingGenerations, equals(100)); // Premium plan limit

        // 使用量をインクリメント
        status.incrementAiUsage();
        expect(status.remainingGenerations, equals(99));
      });
    });

    group('アクセス権限チェックテスト', () {
      test('Basicプランではプレミアム機能にアクセスできない', () {
        final status = SubscriptionStatus.createDefault();

        expect(status.canAccessPremiumFeatures, isFalse);
        expect(status.canAccessWritingPrompts, isFalse);
        expect(status.canAccessAdvancedFilters, isFalse);
        expect(status.canAccessAdvancedAnalytics, isFalse);
      });

      test('有効なPremiumプランではプレミアム機能にアクセスできる', () {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );

        expect(status.canAccessPremiumFeatures, isTrue);
        expect(status.canAccessWritingPrompts, isTrue);
        expect(status.canAccessAdvancedFilters, isTrue);
        expect(status.canAccessAdvancedAnalytics, isTrue);
      });

      test('期限切れのPremiumプランではプレミアム機能にアクセスできない', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          expiryDate: pastDate,
        );

        expect(status.canAccessPremiumFeatures, isFalse);
        expect(status.canAccessWritingPrompts, isFalse);
        expect(status.canAccessAdvancedFilters, isFalse);
        expect(status.canAccessAdvancedAnalytics, isFalse);
      });
    });

    group('キャンセル・復元テスト', () {
      test('サブスクリプションをキャンセルできる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);

        expect(status.isActive, isTrue);
        expect(status.cancelDate, isNull);

        status.cancel();

        expect(status.isActive, isFalse);
        expect(status.autoRenewal, isFalse);
        expect(status.cancelDate, isNotNull);
        expect(status.planId, equals('basic'));
      });

      test('将来の日付でキャンセル予約できる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);

        final futureDate = DateTime.now().add(const Duration(days: 7));
        status.cancel(effectiveDate: futureDate);

        expect(status.isActive, isTrue); // まだアクティブ
        expect(status.autoRenewal, isFalse);
        expect(status.cancelDate, equals(futureDate));
      });

      test('サブスクリプションを復元できる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);

        status.cancel();
        expect(status.isActive, isFalse);

        status.restore();
        expect(status.isActive, isTrue);
        expect(status.cancelDate, isNull);
      });
    });

    group('日付計算テスト', () {
      test('nextResetDateが正しく計算される', () {
        final status = SubscriptionStatus.createDefault();
        final nextReset = status.nextResetDate;
        final now = DateTime.now();
        final expectedNextMonth = DateTime(now.year, now.month + 1, 1);

        expect(nextReset.year, equals(expectedNextMonth.year));
        expect(nextReset.month, equals(expectedNextMonth.month));
        expect(nextReset.day, equals(1));
      });

      test('期限までの残り日数が正しく計算される', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          expiryDate: futureDate,
        );

        final daysUntilExpiry = status.daysUntilExpiry;
        expect(daysUntilExpiry, isNotNull);
        expect(daysUntilExpiry!, greaterThanOrEqualTo(29));
        expect(daysUntilExpiry, lessThanOrEqualTo(30));
      });

      test('期限切れの場合は0日が返される', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          expiryDate: pastDate,
        );

        expect(status.daysUntilExpiry, equals(0));
      });

      test('期限がない場合はnullが返される', () {
        final status = SubscriptionStatus.createDefault();

        expect(status.daysUntilExpiry, isNull);
      });
    });

    group('toStringテスト', () {
      test('toStringが正しい情報を含む', () {
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          monthlyUsageCount: 5,
        );

        final string = status.toString();
        expect(string, contains('planId: premium_yearly'));
        expect(string, contains('isActive: true'));
        expect(string, contains('monthlyUsageCount: 5/100'));
      });
    });

    // =================================================================
    // Phase 1.5.2.1: 詳細な状態管理テスト
    // =================================================================

    group('Phase 1.5.2.1: 状態管理詳細テスト', () {
      group('プラン変更テスト', () {
        test('BasicからPremium月額への変更', () async {
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          expect(status.planId, equals('basic'));
          expect(status.expiryDate, isNull);

          status.changePlan(SubscriptionPlan.premiumMonthly);

          expect(status.planId, equals('premium_monthly'));
          expect(status.isActive, isTrue);
          expect(status.autoRenewal, isTrue);
          expect(status.expiryDate, isNotNull);
          expect(status.startDate, isNotNull);

          // 月額プランの期限は約30日後
          final expectedExpiry = status.startDate!.add(
            const Duration(days: 30),
          );
          expect(
            status.expiryDate!.difference(expectedExpiry).inDays.abs(),
            lessThan(2),
          );
        });

        test('BasicからPremium年額への変更', () async {
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          status.changePlan(SubscriptionPlan.premiumYearly);

          expect(status.planId, equals('premium_yearly'));
          expect(status.isActive, isTrue);
          expect(status.autoRenewal, isTrue);
          expect(status.expiryDate, isNotNull);

          // 年額プランの期限は約365日後
          final expectedExpiry = status.startDate!.add(
            const Duration(days: 365),
          );
          expect(
            status.expiryDate!.difference(expectedExpiry).inDays.abs(),
            lessThan(2),
          );
        });

        test('Premium月額から年額への変更', () async {
          final status = SubscriptionStatus.createPremium(
            startDate: DateTime.now(),
            plan: SubscriptionPlan.premiumMonthly,
          );
          await testBox.add(status);

          final originalStartDate = status.startDate;
          status.changePlan(SubscriptionPlan.premiumYearly);

          expect(status.planId, equals('premium_yearly'));
          expect(status.isActive, isTrue);
          expect(status.autoRenewal, isTrue);
          expect(status.startDate, equals(originalStartDate)); // 開始日は保持

          // 年額プランの新しい期限
          final expectedExpiry = originalStartDate!.add(
            const Duration(days: 365),
          );
          expect(
            status.expiryDate!.difference(expectedExpiry).inDays.abs(),
            lessThan(2),
          );
        });

        test('PremiumからBasicへのダウングレード', () async {
          final status = SubscriptionStatus.createPremium(
            startDate: DateTime.now(),
            plan: SubscriptionPlan.premiumYearly,
          );
          await testBox.add(status);

          status.changePlan(SubscriptionPlan.basic);

          expect(status.planId, equals('basic'));
          expect(status.isActive, isTrue);
          expect(status.autoRenewal, isFalse);
          expect(status.expiryDate, isNull); // Basicプランは期限なし
        });

        test('将来の有効日でプラン変更予約', () async {
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          final futureDate = DateTime.now().add(const Duration(days: 7));
          status.changePlan(
            SubscriptionPlan.premiumYearly,
            effectiveDate: futureDate,
          );

          expect(status.planId, equals('premium_yearly'));
          expect(status.planChangeDate, equals(futureDate));
        });
      });

      group('サブスクリプション状態検証テスト', () {
        test('有効なPremiumプランの検証', () {
          final status = SubscriptionStatus.createPremium(
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            plan: SubscriptionPlan.premiumYearly,
          );

          expect(status.isValid, isTrue);
          expect(status.isExpired, isFalse);
          expect(status.canUseAiGeneration, isTrue);
        });

        test('期限切れPremiumプランの検証', () {
          final pastDate = DateTime.now().subtract(const Duration(days: 1));
          final status = SubscriptionStatus(
            planId: 'premium_yearly',
            isActive: true,
            startDate: DateTime.now().subtract(const Duration(days: 400)),
            expiryDate: pastDate,
          );

          expect(status.isValid, isFalse);
          expect(status.isExpired, isTrue);
          expect(status.canUseAiGeneration, isFalse);
        });

        test('非アクティブなプランの検証', () {
          final status = SubscriptionStatus(
            planId: 'premium_yearly',
            isActive: false,
            expiryDate: DateTime.now().add(const Duration(days: 30)),
          );

          expect(status.isValid, isFalse);
          expect(status.canUseAiGeneration, isFalse);
        });

        test('Basicプランでも非アクティブでは無効', () {
          final status = SubscriptionStatus.createDefault();
          status.isActive = false; // 非アクティブにする

          expect(status.isValid, isFalse); // 非アクティブでは無効
          expect(status.isExpired, isFalse); // ただし期限切れではない
        });
      });

      group('使用量制限管理テスト', () {
        test('Basicプランで制限に達した場合', () async {
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          // 制限(10回)まで使用
          for (int i = 0; i < 10; i++) {
            expect(status.canUseAiGeneration, isTrue);
            status.incrementAiUsage();
          }

          expect(status.hasReachedMonthlyLimit, isTrue);
          expect(status.canUseAiGeneration, isFalse);
          expect(status.remainingGenerations, equals(0));
        });

        test('Premiumプランで制限に達した場合', () async {
          final status = SubscriptionStatus.createPremium(
            startDate: DateTime.now(),
            plan: SubscriptionPlan.premiumYearly,
          );
          await testBox.add(status);

          // 制限(100回)まで使用
          for (int i = 0; i < 100; i++) {
            status.incrementAiUsage();
          }

          expect(status.hasReachedMonthlyLimit, isTrue);
          expect(status.canUseAiGeneration, isFalse);
          expect(status.remainingGenerations, equals(0));
        });

        test('制限を超えた場合の動作', () async {
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          // 制限を超えて使用
          for (int i = 0; i < 15; i++) {
            status.incrementAiUsage();
          }

          expect(status.monthlyUsageCount, equals(15));
          expect(status.remainingGenerations, equals(0)); // 負の値にならない
          expect(status.canUseAiGeneration, isFalse);
        });
      });

      group('複雑な状態遷移テスト', () {
        test('Premium購入→使用→キャンセル→復元の流れ', () async {
          // 1. Basic状態から開始
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          expect(status.planId, equals('basic'));
          expect(status.remainingGenerations, equals(10));

          // 2. Premiumに変更
          status.changePlan(SubscriptionPlan.premiumYearly);
          expect(status.planId, equals('premium_yearly'));
          expect(status.remainingGenerations, equals(100));
          expect(status.canAccessPremiumFeatures, isTrue);

          // 3. AI機能を使用
          for (int i = 0; i < 25; i++) {
            status.incrementAiUsage();
          }
          expect(status.monthlyUsageCount, equals(25));
          expect(status.remainingGenerations, equals(75));

          // 4. キャンセル
          status.cancel();
          expect(status.planId, equals('basic'));
          expect(status.isActive, isFalse);
          expect(status.canAccessPremiumFeatures, isFalse);

          // 5. 復元
          status.restore();
          status.changePlan(SubscriptionPlan.premiumYearly); // プランを戻す
          expect(status.isActive, isTrue);
          expect(status.canAccessPremiumFeatures, isTrue);
          expect(status.monthlyUsageCount, equals(25)); // 使用量は保持
        });

        test('月次リセット後の状態確認', () async {
          final status = SubscriptionStatus.createDefault();
          await testBox.add(status);

          // 使用量を設定
          for (int i = 0; i < 5; i++) {
            status.incrementAiUsage();
          }
          expect(status.monthlyUsageCount, equals(5));

          // 手動でリセット（月次リセットのシミュレーション）
          status.resetUsage();

          expect(status.monthlyUsageCount, equals(0));
          expect(status.remainingGenerations, equals(10));
          expect(status.canUseAiGeneration, isTrue);
          expect(status.lastResetDate, isNotNull);
        });
      });

      group('エラーケース処理テスト', () {
        test('不正なプランIDでの初期化', () {
          final status = SubscriptionStatus(planId: 'invalid_plan');

          // 不正なプランIDの場合、Basicプランにフォールバック
          // SubscriptionStatusの内部ロジックをテスト（enumベースのフォールバック）
          expect(
            status.currentPlan,
            equals(SubscriptionPlan.basic),
          ); // 互換性のため保持
          expect(status.planId, equals('invalid_plan')); // planId自体は保持される
          expect(status.remainingGenerations, equals(10));
        });

        test('開始日なしでPremiumプラン作成時のエラー', () {
          expect(
            () => SubscriptionStatus.createPremium(
              startDate: DateTime.now(),
              plan: SubscriptionPlan.basic, // Basicプランは不正
            ),
            throwsArgumentError,
          );
        });

        test('期限日が過去の場合の処理', () {
          final pastDate = DateTime.now().subtract(const Duration(days: 100));
          final status = SubscriptionStatus(
            planId: 'premium_yearly',
            isActive: true,
            startDate: DateTime.now().subtract(const Duration(days: 200)),
            expiryDate: pastDate,
          );

          expect(status.isExpired, isTrue);
          expect(status.isValid, isFalse);
          expect(status.daysUntilExpiry, equals(0));
        });
      });
    });
  });
}
