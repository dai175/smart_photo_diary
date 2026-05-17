import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/subscription_limit_checker.dart';

void main() {
  group('SubscriptionLimitChecker.isValid', () {
    test('Basic プラン + isActive=true → true', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
      );
      expect(SubscriptionLimitChecker.isValid(status), isTrue);
    });

    test('Premium + 有効期限内 → true', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(SubscriptionLimitChecker.isValid(status), isTrue);
    });

    test('Premium + 期限切れ → false', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(SubscriptionLimitChecker.isValid(status), isFalse);
    });

    test('isActive=false → false', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: false,
        startDate: DateTime.now(),
      );
      expect(SubscriptionLimitChecker.isValid(status), isFalse);
    });

    test('Premium + expiryDate=null → false', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: null,
      );
      expect(SubscriptionLimitChecker.isValid(status), isFalse);
    });

    test('Premium Yearly + 有効期限内 → true', () {
      final status = SubscriptionStatus(
        planId: 'premium_yearly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
      );
      expect(SubscriptionLimitChecker.isValid(status), isTrue);
    });

    test('不明な planId + isActive=true → false', () {
      final status = SubscriptionStatus(
        planId: 'unknown_corrupted_plan',
        isActive: true,
        startDate: DateTime.now(),
      );
      expect(SubscriptionLimitChecker.isValid(status), isFalse);
    });
  });
}
