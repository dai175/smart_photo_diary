import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

void main() {
  group('SubscriptionConstants', () {
    group('価格設定テスト', () {
      test('Basic プランの価格が正しく設定されている', () {
        expect(SubscriptionConstants.basicYearlyPrice, equals(0));
      });

      test('Premium プランの価格が正しく設定されている', () {
        expect(SubscriptionConstants.premiumYearlyPrice, equals(2800));
        expect(SubscriptionConstants.premiumMonthlyPrice, equals(300));
      });

      test('年額割引計算が正しく動作する', () {
        final discount = SubscriptionConstants.calculateYearlyDiscount();
        final expectedDiscount = (300 * 12) - 2800; // 800円割引
        expect(discount, equals(expectedDiscount));
        expect(discount, equals(800));
      });

      test('年額割引率計算が正しく動作する', () {
        final discountPercentage =
            SubscriptionConstants.calculateDiscountPercentage();
        final expectedPercentage = ((300 * 12 - 2800) / (300 * 12)) * 100;
        expect(discountPercentage, closeTo(expectedPercentage, 0.01));
        expect(discountPercentage, closeTo(22.22, 0.01));
      });
    });

    group('AI生成制限テスト', () {
      test('Basic プランの制限が正しく設定されている', () {
        expect(SubscriptionConstants.basicMonthlyAiLimit, equals(10));
      });

      test('Premium プランの制限が正しく設定されている', () {
        expect(SubscriptionConstants.premiumMonthlyAiLimit, equals(100));
      });

      test('日平均計算が正しく動作する', () {
        final basicDaily = SubscriptionConstants.calculateDailyAverage(
          SubscriptionConstants.basicMonthlyAiLimit,
        );
        final premiumDaily = SubscriptionConstants.calculateDailyAverage(
          SubscriptionConstants.premiumMonthlyAiLimit,
        );

        expect(basicDaily, closeTo(10 / 30.0, 0.01));
        expect(premiumDaily, closeTo(100 / 30.0, 0.01));
      });
    });

    group('商品IDテスト', () {
      test('Premium商品IDが正しく設定されている', () {
        expect(
          SubscriptionConstants.premiumYearlyProductId,
          equals('smart_photo_diary_premium_yearly_plan'),
        );
        expect(
          SubscriptionConstants.premiumMonthlyProductId,
          equals('smart_photo_diary_premium_monthly_plan'),
        );
      });
    });

    group('プラン識別子テスト', () {
      test('プランIDが正しく設定されている', () {
        expect(SubscriptionConstants.basicPlanId, equals('basic'));
        expect(
          SubscriptionConstants.premiumMonthlyPlanId,
          equals('premium_monthly'),
        );
        expect(
          SubscriptionConstants.premiumYearlyPlanId,
          equals('premium_yearly'),
        );
      });

      test('プラン表示名が正しく設定されている', () {
        expect(SubscriptionConstants.basicDisplayName, equals('Basic'));
        expect(SubscriptionConstants.premiumDisplayName, equals('Premium'));
      });
    });

    group('期間設定テスト', () {
      test('サブスクリプション期間が正しく設定されている', () {
        expect(SubscriptionConstants.subscriptionYearDays, equals(365));
        expect(SubscriptionConstants.subscriptionMonthDays, equals(30));
        expect(SubscriptionConstants.freeTrialDays, equals(7));
      });

      test('機能制限設定が正しく設定されている', () {
        expect(SubscriptionConstants.tagsValidityDays, equals(7));
      });
    });

    group('UI表示設定テスト', () {
      test('通貨設定が正しく設定されている', () {
        expect(SubscriptionConstants.defaultCurrencySymbol, equals('¥'));
        expect(SubscriptionConstants.defaultCurrencyCode, equals('JPY'));
      });

      test('年額割引率の表示値が正しい', () {
        expect(SubscriptionConstants.yearlyDiscountPercentage, equals(22));
      });

      test('平均月日数が正しく設定されている', () {
        expect(SubscriptionConstants.averageMonthDays, equals(30.0));
      });
    });

    group('説明文テスト', () {
      test('プラン説明文が設定されている', () {
        expect(SubscriptionConstants.basicDescription, isNotEmpty);
        expect(SubscriptionConstants.premiumDescription, isNotEmpty);
        expect(
          SubscriptionConstants.basicDescription,
          equals('日記を試してみたい新規ユーザー、軽いユーザー向け'),
        );
        expect(
          SubscriptionConstants.premiumDescription,
          equals('日常的に日記を書くユーザー、デジタル手帳として活用したいユーザー向け'),
        );
      });
    });

    group('機能リストテスト', () {
      test('Basic プランの機能リストが正しく設定されている', () {
        final features = SubscriptionConstants.basicFeatures;

        expect(features, isA<List<String>>());
        expect(features.length, equals(6));
        expect(features, contains('月10回までのAI日記生成'));
        expect(features, contains('写真選択・保存機能（最大3枚）'));
        expect(features, contains('基本的な検索・フィルタ'));
        expect(features, contains('ローカルストレージ'));
        expect(features, contains('ライト・ダークテーマ'));
        expect(features, contains('データエクスポート（JSON形式）'));
      });

      test('Premium プランの機能リストが正しく設定されている', () {
        final features = SubscriptionConstants.premiumFeatures;

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
      });
    });

    group('ヘルパーメソッドテスト', () {
      test('価格フォーマットが正しく動作する', () {
        // 日本語ロケール（デフォルト）での円表示
        expect(SubscriptionConstants.formatPrice(0), equals('¥0'));
        expect(SubscriptionConstants.formatPrice(300), equals('¥300'));
        expect(SubscriptionConstants.formatPrice(2800), equals('¥2,800'));
        expect(SubscriptionConstants.formatPrice(10000), equals('¥10,000'));
        expect(SubscriptionConstants.formatPrice(100000), equals('¥100,000'));

        // 英語ロケールでもJPY（動的価格取得システムによる実際の通貨使用を推奨）
        expect(
          SubscriptionConstants.formatPrice(2800, locale: 'en'),
          equals('¥2,800'),
        );

        // 通貨コード明示指定での円表示
        expect(
          SubscriptionConstants.formatPrice(
            2800,
            locale: 'en',
            currencyCode: 'JPY',
          ),
          equals('¥2,800'),
        );
      });

      test('プランIDから価格を取得できる', () {
        expect(SubscriptionConstants.getPriceByPlanId('basic'), equals(0));
        expect(
          SubscriptionConstants.getPriceByPlanId('premium_monthly'),
          equals(300),
        );
        expect(
          SubscriptionConstants.getPriceByPlanId('premium_yearly'),
          equals(2800),
        );
        expect(SubscriptionConstants.getPriceByPlanId('BASIC'), equals(0));
        expect(
          SubscriptionConstants.getPriceByPlanId('PREMIUM_MONTHLY'),
          equals(300),
        );
        expect(
          SubscriptionConstants.getPriceByPlanId('PREMIUM_YEARLY'),
          equals(2800),
        );
      });

      test('不正なプランIDで例外が発生する', () {
        expect(
          () => SubscriptionConstants.getPriceByPlanId('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('プランIDから制限回数を取得できる', () {
        expect(SubscriptionConstants.getLimitByPlanId('basic'), equals(10));
        expect(
          SubscriptionConstants.getLimitByPlanId('premium_monthly'),
          equals(100),
        );
        expect(
          SubscriptionConstants.getLimitByPlanId('premium_yearly'),
          equals(100),
        );
        expect(SubscriptionConstants.getLimitByPlanId('BASIC'), equals(10));
        expect(
          SubscriptionConstants.getLimitByPlanId('PREMIUM_MONTHLY'),
          equals(100),
        );
        expect(
          SubscriptionConstants.getLimitByPlanId('PREMIUM_YEARLY'),
          equals(100),
        );
      });

      test('不正なプランIDで制限回数取得時に例外が発生する', () {
        expect(
          () => SubscriptionConstants.getLimitByPlanId('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('言語に応じた価格取得が正しく動作する（フォールバック）', () {
        // 日本語での価格取得
        final (priceJA, currencyJA) = SubscriptionConstants.getPriceForLocale(
          'premium_monthly',
          'ja',
        );
        expect(priceJA, equals(300));
        expect(currencyJA, equals('JPY'));

        // 英語でも同じJPY価格（動的価格取得システムでは実際の地域価格を使用）
        final (priceEN, currencyEN) = SubscriptionConstants.getPriceForLocale(
          'premium_monthly',
          'en',
        );
        expect(priceEN, equals(300)); // フォールバック価格
        expect(currencyEN, equals('JPY'));

        // 年額プランのテスト
        final (yearlyPriceJA, yearlyCurrencyJA) =
            SubscriptionConstants.getPriceForLocale('premium_yearly', 'ja');
        expect(yearlyPriceJA, equals(2800));
        expect(yearlyCurrencyJA, equals('JPY'));

        final (yearlyPriceEN, yearlyCurrencyEN) =
            SubscriptionConstants.getPriceForLocale('premium_yearly', 'en');
        expect(yearlyPriceEN, equals(2800)); // フォールバック価格
        expect(yearlyCurrencyEN, equals('JPY'));
      });

      test('プラン用価格表示が正しく動作する（フォールバック）', () {
        // 日本語での表示
        expect(
          SubscriptionConstants.formatPriceForPlan('premium_monthly', 'ja'),
          equals('¥300'),
        );
        expect(
          SubscriptionConstants.formatPriceForPlan('premium_yearly', 'ja'),
          equals('¥2,800'),
        );

        // 英語でもJPY表示（フォールバック価格）
        expect(
          SubscriptionConstants.formatPriceForPlan('premium_monthly', 'en'),
          equals('¥300'),
        );
        expect(
          SubscriptionConstants.formatPriceForPlan('premium_yearly', 'en'),
          equals('¥2,800'),
        );
      });
    });

    group('定数値の妥当性テスト', () {
      test('価格設定の妥当性', () {
        // Basic は無料
        expect(SubscriptionConstants.basicYearlyPrice, equals(0));

        // Premium の年額は月額×12より安い（割引がある）
        final monthlyTotal = SubscriptionConstants.premiumMonthlyPrice * 12;
        expect(
          SubscriptionConstants.premiumYearlyPrice,
          lessThan(monthlyTotal),
        );

        // 割引率は正の値
        final discountPercentage =
            SubscriptionConstants.calculateDiscountPercentage();
        expect(discountPercentage, greaterThan(0));
        expect(discountPercentage, lessThan(100));
      });

      test('AI制限設定の妥当性', () {
        // Premium は Basic より多い制限
        expect(
          SubscriptionConstants.premiumMonthlyAiLimit,
          greaterThan(SubscriptionConstants.basicMonthlyAiLimit),
        );

        // 制限回数は正の値
        expect(SubscriptionConstants.basicMonthlyAiLimit, greaterThan(0));
        expect(SubscriptionConstants.premiumMonthlyAiLimit, greaterThan(0));
      });

      test('期間設定の妥当性', () {
        // 期間は正の値
        expect(SubscriptionConstants.subscriptionYearDays, greaterThan(0));
        expect(SubscriptionConstants.subscriptionMonthDays, greaterThan(0));
        expect(SubscriptionConstants.freeTrialDays, greaterThan(0));

        // 年は月より長い
        expect(
          SubscriptionConstants.subscriptionYearDays,
          greaterThan(SubscriptionConstants.subscriptionMonthDays),
        );
      });

      test('機能リストの妥当性', () {
        // 機能リストは空でない
        expect(SubscriptionConstants.basicFeatures, isNotEmpty);
        expect(SubscriptionConstants.premiumFeatures, isNotEmpty);

        // Premium は Basic より多い機能
        expect(
          SubscriptionConstants.premiumFeatures.length,
          greaterThan(SubscriptionConstants.basicFeatures.length),
        );
      });
    });
  });
}
