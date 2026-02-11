import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/services/subscription_state_service.dart';
import 'package:smart_photo_diary/services/ai_usage_service.dart';
import 'package:smart_photo_diary/services/feature_access_service.dart';
import 'package:smart_photo_diary/services/in_app_purchase_service.dart';

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
    final stateService = SubscriptionStateService();
    await stateService.initialize();

    // 2. 各サブサービスを構築（全て stateService に依存）
    final usageService = AiUsageService(stateService: stateService);
    final accessService = FeatureAccessService(stateService: stateService);
    final purchaseService = InAppPurchaseService(stateService: stateService);

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
