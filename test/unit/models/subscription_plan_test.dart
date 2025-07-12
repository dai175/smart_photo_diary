import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';

void main() {
  group('SubscriptionPlan', () {
    group('基本プロパティテスト', () {
      test('Basic プランの基本プロパティが正しく設定されている', () {
        const plan = SubscriptionPlan.basic;

        expect(plan.displayName, equals('Basic'));
        expect(plan.planId, equals('basic'));
        expect(plan.yearlyPrice, equals(0));
        expect(plan.monthlyAiGenerationLimit, equals(10));
        expect(plan.productId, equals(''));
        expect(plan.isPaid, isFalse);
        expect(plan.isFree, isTrue);
      });

      test('Premium Monthly プランの基本プロパティが正しく設定されている', () {
        const plan = SubscriptionPlan.premiumMonthly;

        expect(plan.displayName, equals('Premium (月額)'));
        expect(plan.planId, equals('premium_monthly'));
        expect(plan.price, equals(300));
        expect(plan.yearlyPrice, equals(3600)); // 300 * 12
        expect(plan.monthlyAiGenerationLimit, equals(100));
        expect(
          plan.productId,
          equals('smart_photo_diary_premium_monthly_plan'),
        );
        expect(plan.isPaid, isTrue);
        expect(plan.isFree, isFalse);
        expect(plan.isMonthly, isTrue);
        expect(plan.isYearly, isFalse);
        expect(plan.isPremium, isTrue);
      });

      test('Premium Yearly プランの基本プロパティが正しく設定されている', () {
        const plan = SubscriptionPlan.premiumYearly;

        expect(plan.displayName, equals('Premium (年額)'));
        expect(plan.planId, equals('premium_yearly'));
        expect(plan.price, equals(2800));
        expect(plan.yearlyPrice, equals(2800));
        expect(plan.monthlyAiGenerationLimit, equals(100));
        expect(plan.productId, equals('smart_photo_diary_premium_yearly_plan'));
        expect(plan.isPaid, isTrue);
        expect(plan.isFree, isFalse);
        expect(plan.isMonthly, isFalse);
        expect(plan.isYearly, isTrue);
        expect(plan.isPremium, isTrue);
      });
    });

    group('機能フラグテスト', () {
      test('Basic プランの機能フラグが正しく設定されている', () {
        const plan = SubscriptionPlan.basic;

        expect(plan.hasWritingPrompts, isFalse);
        expect(plan.hasAdvancedFilters, isFalse);
        expect(plan.hasAdvancedAnalytics, isFalse);
        expect(plan.hasPrioritySupport, isFalse);
      });

      test('Premium Monthly プランの機能フラグが正しく設定されている', () {
        const plan = SubscriptionPlan.premiumMonthly;

        expect(plan.hasWritingPrompts, isTrue);
        expect(plan.hasAdvancedFilters, isTrue);
        expect(plan.hasAdvancedAnalytics, isTrue);
        expect(plan.hasPrioritySupport, isTrue);
      });

      test('Premium Yearly プランの機能フラグが正しく設定されている', () {
        const plan = SubscriptionPlan.premiumYearly;

        expect(plan.hasWritingPrompts, isTrue);
        expect(plan.hasAdvancedFilters, isTrue);
        expect(plan.hasAdvancedAnalytics, isTrue);
        expect(plan.hasPrioritySupport, isTrue);
      });
    });

    group('機能リストテスト', () {
      test('Basic プランの機能リストが正しく取得できる', () {
        const plan = SubscriptionPlan.basic;
        final features = plan.features;

        expect(features, isA<List<String>>());
        expect(features.length, equals(6));
        expect(features, contains('月10回までのAI日記生成'));
        expect(features, contains('写真選択・保存機能（最大3枚）'));
        expect(features, contains('基本的な検索・フィルタ'));
        expect(features, contains('ローカルストレージ'));
        expect(features, contains('ライト・ダークテーマ'));
        expect(features, contains('データエクスポート（JSON形式）'));
      });

      test('Premium プランの機能リストが正しく取得できる', () {
        const monthlyPlan = SubscriptionPlan.premiumMonthly;
        const yearlyPlan = SubscriptionPlan.premiumYearly;

        // 両プランとも同じ機能リストを持つ
        for (final plan in [monthlyPlan, yearlyPlan]) {
          final features = plan.features;

          expect(features, isA<List<String>>());
          expect(features.length, equals(9));
          expect(features, contains('月100回までのAI日記生成'));
          expect(features, contains('ライティングプロンプト機能'));
          expect(features, contains('高度なフィルタ・検索機能'));
          expect(features, contains('タグベース検索'));
          expect(features, contains('日付範囲指定検索'));
          expect(features, contains('時間帯フィルタ'));
          expect(features, contains('データエクスポート（複数形式）'));
          expect(features, contains('優先カスタマーサポート'));
          expect(features, contains('統計・分析ダッシュボード'));
        }
      });
    });

    group('計算プロパティテスト', () {
      test('Basic プランの日平均生成回数が正しく計算される', () {
        const plan = SubscriptionPlan.basic;
        final dailyAverage = plan.dailyAverageGenerations;

        expect(dailyAverage, closeTo(0.33, 0.01)); // 10/30 ≈ 0.33
      });

      test('Premium プランの日平均生成回数が正しく計算される', () {
        const monthlyPlan = SubscriptionPlan.premiumMonthly;
        const yearlyPlan = SubscriptionPlan.premiumYearly;

        for (final plan in [monthlyPlan, yearlyPlan]) {
          final dailyAverage = plan.dailyAverageGenerations;
          expect(dailyAverage, closeTo(3.33, 0.01)); // 100/30 ≈ 3.33
        }
      });

      test('プラン説明文が正しく取得できる', () {
        expect(
          SubscriptionPlan.basic.description,
          equals('日記を試してみたい新規ユーザー、軽いユーザー向け'),
        );
        expect(
          SubscriptionPlan.premiumMonthly.description,
          equals('日常的に日記を書くユーザー、デジタル手帳として活用したいユーザー向け'),
        );
        expect(
          SubscriptionPlan.premiumYearly.description,
          equals('日常的に日記を書くユーザー、デジタル手帳として活用したいユーザー向け'),
        );
      });
    });

    group('fromIdメソッドテスト', () {
      test('正しいプランIDから対応するプランを取得できる', () {
        expect(
          SubscriptionPlan.fromId('basic'),
          equals(SubscriptionPlan.basic),
        );
        expect(
          SubscriptionPlan.fromId('premium_monthly'),
          equals(SubscriptionPlan.premiumMonthly),
        );
        expect(
          SubscriptionPlan.fromId('premium_yearly'),
          equals(SubscriptionPlan.premiumYearly),
        );
      });

      test('大文字小文字を区別しない', () {
        expect(
          SubscriptionPlan.fromId('BASIC'),
          equals(SubscriptionPlan.basic),
        );
        expect(
          SubscriptionPlan.fromId('Premium_Monthly'),
          equals(SubscriptionPlan.premiumMonthly),
        );
        expect(
          SubscriptionPlan.fromId('PREMIUM_YEARLY'),
          equals(SubscriptionPlan.premiumYearly),
        );
      });

      test('不正なプランIDでArgumentErrorが発生する', () {
        expect(
          () => SubscriptionPlan.fromId('invalid'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => SubscriptionPlan.fromId(''),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => SubscriptionPlan.fromId('pro'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('enum値テスト', () {
      test('すべてのプランが存在する', () {
        final allPlans = SubscriptionPlan.values;

        expect(allPlans.length, equals(3));
        expect(allPlans, contains(SubscriptionPlan.basic));
        expect(allPlans, contains(SubscriptionPlan.premiumMonthly));
        expect(allPlans, contains(SubscriptionPlan.premiumYearly));
      });

      test('各プランのplanIdが一意である', () {
        final planIds = SubscriptionPlan.values.map((p) => p.planId).toList();
        final uniqueIds = planIds.toSet();

        expect(planIds.length, equals(uniqueIds.length));
      });

      test('各プランのproductIdが一意である（空文字除く）', () {
        final productIds = SubscriptionPlan.values
            .map((p) => p.productId)
            .where((id) => id.isNotEmpty)
            .toList();
        final uniqueIds = productIds.toSet();

        expect(productIds.length, equals(uniqueIds.length));
      });
    });
  });
}
