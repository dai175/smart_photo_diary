import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/store_entitlement.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/services/subscription_state_service.dart';
import 'package:smart_photo_diary/services/ai_usage_service.dart';
import 'package:smart_photo_diary/services/feature_access_service.dart';
import 'package:smart_photo_diary/services/in_app_purchase_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/store_entitlement_service_interface.dart';

class _MockLoggingService extends Mock implements ILoggingService {}

class _MockStoreEntitlementService extends Mock
    implements IStoreEntitlementService {}

/// テスト用のサブスクリプションサービス構築結果
///
/// Facade パターンの SubscriptionService とその内部サブサービスを保持する。
/// テストコードから各サブサービスへ直接アクセスするために使用。
class SubscriptionServiceTestBundle {
  final SubscriptionStateService stateService;
  final AiUsageService usageService;
  final FeatureAccessService accessService;
  final InAppPurchaseService purchaseService;
  final SubscriptionService subscriptionService;

  SubscriptionServiceTestBundle({
    required this.stateService,
    required this.usageService,
    required this.accessService,
    required this.purchaseService,
    required this.subscriptionService,
  });
}

/// サブスクリプションサービスのテスト用ヘルパー
///
/// SubscriptionService (Facade) とその依存サブサービスを
/// テスト用に構築するためのユーティリティ。
class SubscriptionTestHelpers {
  /// SubscriptionService とサブサービスを構築して初期化する
  ///
  /// SubscriptionStateService を初期化してから、
  /// 各サブサービスを構築し、Facade に注入する。
  static Future<SubscriptionServiceTestBundle> createInitializedBundle() async {
    // 1. SubscriptionStateService を構築・初期化
    final mockLogger = _MockLoggingService();
    final stateService = SubscriptionStateService(logger: mockLogger);
    await stateService.initialize();

    // 2. 各サブサービスを構築（全て stateService に依存）
    final usageService = AiUsageService(
      stateService: stateService,
      logger: mockLogger,
    );
    final accessService = FeatureAccessService(
      stateService: stateService,
      logger: mockLogger,
    );
    final mockEntitlementService = _MockStoreEntitlementService();
    when(
      () => mockEntitlementService.getActiveSubscription(),
    ).thenAnswer((_) async => const Success<StoreEntitlement?>(null));
    final purchaseService = InAppPurchaseService(
      stateService: stateService,
      entitlementService: mockEntitlementService,
      logger: mockLogger,
    );

    // 3. Facade を構築
    final subscriptionService = SubscriptionService(
      stateService: stateService,
      usageService: usageService,
      accessService: accessService,
      purchaseService: purchaseService,
    );

    return SubscriptionServiceTestBundle(
      stateService: stateService,
      usageService: usageService,
      accessService: accessService,
      purchaseService: purchaseService,
      subscriptionService: subscriptionService,
    );
  }

  /// SubscriptionService (Facade) のみ構築・初期化する
  ///
  /// サブサービスへの直接アクセスが不要なテスト向け。
  static Future<SubscriptionService> createInitializedService() async {
    final bundle = await createInitializedBundle();
    return bundle.subscriptionService;
  }
}
