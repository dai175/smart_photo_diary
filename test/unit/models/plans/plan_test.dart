import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';

void main() {
  group('Plan Abstract Class', () {
    late Plan basicPlan;
    late Plan premiumMonthlyPlan;
    late Plan premiumYearlyPlan;

    setUp(() {
      basicPlan = BasicPlan();
      premiumMonthlyPlan = PremiumMonthlyPlan();
      premiumYearlyPlan = PremiumYearlyPlan();
    });

    group('共通プロパティ', () {
      test('各プランが正しいIDを持つ', () {
        expect(basicPlan.id, 'basic');
        expect(premiumMonthlyPlan.id, 'premium_monthly');
        expect(premiumYearlyPlan.id, 'premium_yearly');
      });

      test('各プランが正しい表示名を持つ', () {
        expect(basicPlan.displayName, 'Basic');
        expect(premiumMonthlyPlan.displayName, contains('Premium'));
        expect(premiumMonthlyPlan.displayName, contains('月額'));
        expect(premiumYearlyPlan.displayName, contains('Premium'));
        expect(premiumYearlyPlan.displayName, contains('年額'));
      });

      test('各プランが正しい価格を持つ', () {
        expect(basicPlan.price, 0);
        expect(premiumMonthlyPlan.price, 300);
        expect(premiumYearlyPlan.price, 2800);
      });

      test('各プランが正しいAI生成制限を持つ', () {
        expect(basicPlan.monthlyAiGenerationLimit, 10);
        expect(premiumMonthlyPlan.monthlyAiGenerationLimit, 100);
        expect(premiumYearlyPlan.monthlyAiGenerationLimit, 100);
      });
    });

    group('共通メソッド', () {
      test('isPaidが正しく動作する', () {
        expect(basicPlan.isPaid, false);
        expect(premiumMonthlyPlan.isPaid, true);
        expect(premiumYearlyPlan.isPaid, true);
      });

      test('isFreeが正しく動作する', () {
        expect(basicPlan.isFree, true);
        expect(premiumMonthlyPlan.isFree, false);
        expect(premiumYearlyPlan.isFree, false);
      });

      test('dailyAverageGenerationsが正しく計算される', () {
        expect(basicPlan.dailyAverageGenerations, closeTo(0.333, 0.001));
        expect(
          premiumMonthlyPlan.dailyAverageGenerations,
          closeTo(3.333, 0.001),
        );
        expect(
          premiumYearlyPlan.dailyAverageGenerations,
          closeTo(3.333, 0.001),
        );
      });

      test('formattedPriceが正しくフォーマットされる', () {
        expect(basicPlan.formattedPrice, '無料');
        expect(premiumMonthlyPlan.formattedPrice, '¥300');
        expect(premiumYearlyPlan.formattedPrice, '¥2,800');
      });

      test('isMonthlyが正しく判定される', () {
        expect(basicPlan.isMonthly, false);
        expect(premiumMonthlyPlan.isMonthly, true);
        expect(premiumYearlyPlan.isMonthly, false);
      });

      test('isYearlyが正しく判定される', () {
        expect(basicPlan.isYearly, false);
        expect(premiumMonthlyPlan.isYearly, false);
        expect(premiumYearlyPlan.isYearly, true);
      });

      test('yearlyPriceが正しく計算される', () {
        expect(basicPlan.yearlyPrice, 0);
        expect(premiumMonthlyPlan.yearlyPrice, 3600); // 300 * 12
        expect(premiumYearlyPlan.yearlyPrice, 2800);
      });

      test('hasMoreFeaturesThanが正しく比較する', () {
        expect(basicPlan.hasMoreFeaturesThan(premiumMonthlyPlan), false);
        expect(premiumMonthlyPlan.hasMoreFeaturesThan(basicPlan), true);
        expect(
          premiumMonthlyPlan.hasMoreFeaturesThan(premiumYearlyPlan),
          false,
        );
        expect(
          premiumYearlyPlan.hasMoreFeaturesThan(premiumMonthlyPlan),
          false,
        );
      });
    });

    group('等価性とハッシュコード', () {
      test('同じIDのプランは等しい', () {
        final anotherBasicPlan = BasicPlan();
        expect(basicPlan, equals(anotherBasicPlan));
        expect(basicPlan.hashCode, equals(anotherBasicPlan.hashCode));
      });

      test('異なるIDのプランは等しくない', () {
        expect(basicPlan, isNot(equals(premiumMonthlyPlan)));
        expect(basicPlan.hashCode, isNot(equals(premiumMonthlyPlan.hashCode)));
      });
    });

    group('機能フラグ', () {
      test('isPremiumが正しく判定される', () {
        expect(basicPlan.isPremium, false);
        expect(premiumMonthlyPlan.isPremium, true);
        expect(premiumYearlyPlan.isPremium, true);
      });

      test('hasWritingPromptsが正しく判定される', () {
        expect(basicPlan.hasWritingPrompts, false);
        expect(premiumMonthlyPlan.hasWritingPrompts, true);
        expect(premiumYearlyPlan.hasWritingPrompts, true);
      });

      test('hasAdvancedFiltersが正しく判定される', () {
        expect(basicPlan.hasAdvancedFilters, false);
        expect(premiumMonthlyPlan.hasAdvancedFilters, true);
        expect(premiumYearlyPlan.hasAdvancedFilters, true);
      });

      test('hasAdvancedAnalyticsが正しく判定される', () {
        expect(basicPlan.hasAdvancedAnalytics, false);
        expect(premiumMonthlyPlan.hasAdvancedAnalytics, true);
        expect(premiumYearlyPlan.hasAdvancedAnalytics, true);
      });

      test('hasPrioritySupportが正しく判定される', () {
        expect(basicPlan.hasPrioritySupport, false);
        expect(premiumMonthlyPlan.hasPrioritySupport, true);
        expect(premiumYearlyPlan.hasPrioritySupport, true);
      });
    });

    group('toString', () {
      test('デバッグ用文字列が適切に生成される', () {
        final basicString = basicPlan.toString();
        expect(basicString, contains('id: basic'));
        expect(basicString, contains('displayName: Basic'));
        expect(basicString, contains('price: 無料'));
        expect(basicString, contains('monthlyLimit: 10'));
        expect(basicString, contains('isPremium: false'));

        final premiumString = premiumMonthlyPlan.toString();
        expect(premiumString, contains('id: premium_monthly'));
        expect(premiumString, contains('price: ¥300'));
        expect(premiumString, contains('monthlyLimit: 100'));
        expect(premiumString, contains('isPremium: true'));
      });
    });
  });
}
