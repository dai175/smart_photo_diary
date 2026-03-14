import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/utils/dynamic_pricing_utils.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class MockSubscriptionService extends Mock implements ISubscriptionService {}

void main() {
  late MockLoggingService mockLogger;
  late MockSubscriptionService mockSubscriptionService;

  setUp(() {
    mockLogger = MockLoggingService();
    mockSubscriptionService = MockSubscriptionService();

    if (serviceLocator.isRegistered<ILoggingService>()) {
      serviceLocator.unregister<ILoggingService>();
    }
    serviceLocator.registerSingleton<ILoggingService>(mockLogger);

    if (serviceLocator.isRegistered<ISubscriptionService>()) {
      serviceLocator.unregister<ISubscriptionService>();
    }
    serviceLocator.registerAsyncFactory<ISubscriptionService>(
      () async => mockSubscriptionService,
    );
  });

  tearDown(() {
    if (serviceLocator.isRegistered<ILoggingService>()) {
      serviceLocator.unregister<ILoggingService>();
    }
    if (serviceLocator.isRegistered<ISubscriptionService>()) {
      serviceLocator.unregister<ISubscriptionService>();
    }
  });

  group('DynamicPricingUtils', () {
    group('getPlanPrice', () {
      test('returns dynamic price on success', () async {
        final product = PurchaseProduct(
          id: 'smart_photo_diary_premium_monthly_plan',
          title: 'Premium Monthly',
          description: 'Monthly plan',
          price: '¥300',
          priceAmount: 300.0,
          currencyCode: 'JPY',
          plan: PremiumMonthlyPlan(),
        );

        when(
          () => mockSubscriptionService.getProductPrice('premium_monthly'),
        ).thenAnswer((_) async => Success(product));

        final result = await DynamicPricingUtils.getPlanPrice(
          'premium_monthly',
          locale: 'ja',
          timeout: const Duration(seconds: 2),
        );

        expect(result, isNotEmpty);
        expect(result, contains('300'));
      });

      test('returns fallback price when service returns Failure', () async {
        when(
          () => mockSubscriptionService.getProductPrice('premium_monthly'),
        ).thenAnswer(
          (_) async => const Failure(ServiceException('Price fetch failed')),
        );

        final result = await DynamicPricingUtils.getPlanPrice(
          'premium_monthly',
          locale: 'ja',
          timeout: const Duration(seconds: 2),
        );

        // Should return fallback price (from SubscriptionConstants)
        expect(result, isNotEmpty);
      });

      test(
        'returns fallback price when service returns null product',
        () async {
          when(
            () => mockSubscriptionService.getProductPrice('premium_monthly'),
          ).thenAnswer((_) async => const Success(null));

          final result = await DynamicPricingUtils.getPlanPrice(
            'premium_monthly',
            locale: 'ja',
            timeout: const Duration(seconds: 2),
          );

          expect(result, isNotEmpty);
        },
      );

      test('returns fallback price on exception', () async {
        when(
          () => mockSubscriptionService.getProductPrice('premium_monthly'),
        ).thenThrow(Exception('unexpected'));

        final result = await DynamicPricingUtils.getPlanPrice(
          'premium_monthly',
          locale: 'ja',
          timeout: const Duration(seconds: 2),
        );

        expect(result, isNotEmpty);
      });
    });

    group('getMultiplePlanPrices', () {
      test('returns prices for multiple plans', () async {
        final monthlyProduct = PurchaseProduct(
          id: 'smart_photo_diary_premium_monthly_plan',
          title: 'Premium Monthly',
          description: 'Monthly',
          price: '¥300',
          priceAmount: 300.0,
          currencyCode: 'JPY',
          plan: PremiumMonthlyPlan(),
        );

        when(
          () => mockSubscriptionService.getProductPrice(any()),
        ).thenAnswer((_) async => Success(monthlyProduct));

        final result = await DynamicPricingUtils.getMultiplePlanPrices(
          ['premium_monthly', 'premium_yearly'],
          locale: 'ja',
          timeout: const Duration(seconds: 2),
        );

        expect(result, hasLength(2));
        expect(result.containsKey('premium_monthly'), isTrue);
        expect(result.containsKey('premium_yearly'), isTrue);
      });
    });
  });
}
