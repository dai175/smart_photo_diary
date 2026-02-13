import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';

void main() {
  group('Plan', () {
    group('基本プロパティテスト', () {
      test('Basic プランの基本プロパティが正しく設定されている', () {
        final plan = BasicPlan();

        expect(plan.displayName, equals('Basic'));
        expect(plan.id, equals('basic'));
        expect(plan.price, equals(0));
        expect(plan.monthlyAiGenerationLimit, equals(10));
        expect(plan.productId, equals(''));
        expect(plan.isPaid, isFalse);
        expect(plan.isFree, isTrue);
        expect(plan.isPremium, isFalse);
      });

      test('Premium Monthly プランの基本プロパティが正しく設定されている', () {
        final plan = PremiumMonthlyPlan();

        expect(plan.displayName, equals('Premium (Monthly)'));
        expect(plan.id, equals('premium_monthly'));
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
        final plan = PremiumYearlyPlan();

        expect(plan.displayName, equals('Premium (Yearly)'));
        expect(plan.id, equals('premium_yearly'));
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
        final plan = BasicPlan();

        expect(plan.hasWritingPrompts, isFalse);
        expect(plan.hasAdvancedFilters, isFalse);
        expect(plan.hasAdvancedAnalytics, isFalse);
        expect(plan.hasPrioritySupport, isFalse);
      });

      test('Premium Monthly プランの機能フラグが正しく設定されている', () {
        final plan = PremiumMonthlyPlan();

        expect(plan.hasWritingPrompts, isTrue);
        expect(plan.hasAdvancedFilters, isTrue);
        expect(plan.hasAdvancedAnalytics, isTrue);
        expect(plan.hasPrioritySupport, isTrue);
      });

      test('Premium Yearly プランの機能フラグが正しく設定されている', () {
        final plan = PremiumYearlyPlan();

        expect(plan.hasWritingPrompts, isTrue);
        expect(plan.hasAdvancedFilters, isTrue);
        expect(plan.hasAdvancedAnalytics, isTrue);
        expect(plan.hasPrioritySupport, isTrue);
      });
    });

    group('機能リストテスト', () {
      test('Basic プランの機能リストが正しく取得できる', () {
        final plan = BasicPlan();
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
        final monthlyPlan = PremiumMonthlyPlan();
        final yearlyPlan = PremiumYearlyPlan();

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
        final plan = BasicPlan();
        final dailyAverage = plan.dailyAverageGenerations;

        expect(dailyAverage, closeTo(0.33, 0.01)); // 10/30 ≈ 0.33
      });

      test('Premium プランの日平均生成回数が正しく計算される', () {
        final monthlyPlan = PremiumMonthlyPlan();
        final yearlyPlan = PremiumYearlyPlan();

        for (final plan in [monthlyPlan, yearlyPlan]) {
          final dailyAverage = plan.dailyAverageGenerations;
          expect(dailyAverage, closeTo(3.33, 0.01)); // 100/30 ≈ 3.33
        }
      });

      test('プラン説明文が正しく取得できる', () {
        expect(BasicPlan().description, equals('日記を試してみたい新規ユーザー、軽いユーザー向け'));
        expect(
          PremiumMonthlyPlan().description,
          equals('日常的に日記を書くユーザー、デジタル手帳として活用したいユーザー向け'),
        );
        expect(
          PremiumYearlyPlan().description,
          equals('日常的に日記を書くユーザー、デジタル手帳として活用したいユーザー向け'),
        );
      });
    });

    group('PlanFactoryテスト', () {
      test('正しいプランIDから対応するプランを取得できる', () {
        expect(PlanFactory.createPlan('basic'), isA<BasicPlan>());
        expect(
          PlanFactory.createPlan('premium_monthly'),
          isA<PremiumMonthlyPlan>(),
        );
        expect(
          PlanFactory.createPlan('premium_yearly'),
          isA<PremiumYearlyPlan>(),
        );
      });

      test('大文字小文字を区別しない', () {
        expect(PlanFactory.createPlan('BASIC'), isA<BasicPlan>());
        expect(
          PlanFactory.createPlan('Premium_Monthly'),
          isA<PremiumMonthlyPlan>(),
        );
        expect(
          PlanFactory.createPlan('PREMIUM_YEARLY'),
          isA<PremiumYearlyPlan>(),
        );
      });

      test('不正なプランIDでArgumentErrorが発生する', () {
        expect(
          () => PlanFactory.createPlan('invalid'),
          throwsA(isA<ArgumentError>()),
        );
        expect(() => PlanFactory.createPlan(''), throwsA(isA<ArgumentError>()));
        expect(
          () => PlanFactory.createPlan('pro'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('すべてのプランが取得できる', () {
        final allPlans = PlanFactory.getAllPlans();

        expect(allPlans.length, equals(3));
        expect(allPlans.any((p) => p is BasicPlan), isTrue);
        expect(allPlans.any((p) => p is PremiumMonthlyPlan), isTrue);
        expect(allPlans.any((p) => p is PremiumYearlyPlan), isTrue);
      });

      test('有料プランだけが取得できる', () {
        final premiumPlans = PlanFactory.getPremiumPlans();

        expect(premiumPlans.length, equals(2));
        expect(premiumPlans.any((p) => p is PremiumMonthlyPlan), isTrue);
        expect(premiumPlans.any((p) => p is PremiumYearlyPlan), isTrue);
        expect(premiumPlans.any((p) => p is BasicPlan), isFalse);
      });

      test('各プランのIDが一意である', () {
        final allPlans = PlanFactory.getAllPlans();
        final planIds = allPlans.map((p) => p.id).toList();
        final uniqueIds = planIds.toSet();

        expect(planIds.length, equals(uniqueIds.length));
      });

      test('各プランのproductIdが一意である（空文字除く）', () {
        final allPlans = PlanFactory.getAllPlans();
        final productIds = allPlans
            .map((p) => p.productId)
            .where((id) => id.isNotEmpty)
            .toList();
        final uniqueIds = productIds.toSet();

        expect(productIds.length, equals(uniqueIds.length));
      });
    });

    group('Premium Yearly特有の機能テスト', () {
      test('年額プランの割引率が正しく計算される', () {
        final plan = PremiumYearlyPlan();
        expect(plan.discountPercentage, equals(22));
      });

      test('年額プランの月額換算価格が正しく計算される', () {
        final plan = PremiumYearlyPlan();
        expect(plan.monthlyEquivalentPrice, closeTo(233.33, 0.01));
      });

      test('年額プランの節約額が正しく計算される', () {
        final plan = PremiumYearlyPlan();
        expect(plan.yearlySavings, equals(800));
      });
    });

    group('等価性テスト', () {
      test('同じIDのプランは等しいと判定される', () {
        final plan1 = BasicPlan();
        final plan2 = BasicPlan();

        expect(plan1, equals(plan2));
        expect(plan1.hashCode, equals(plan2.hashCode));
      });

      test('異なるIDのプランは等しくないと判定される', () {
        final basic = BasicPlan();
        final premium = PremiumMonthlyPlan();

        expect(basic, isNot(equals(premium)));
      });
    });
  });
}
