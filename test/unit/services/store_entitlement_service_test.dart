import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/services/store_entitlement_service.dart';

import '../../integration/mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('smart_photo_diary/storekit2');
  late StoreEntitlementService service;
  late List<MethodCall> calls;

  setUpAll(() {
    registerMockFallbacks();
  });

  setUp(() {
    calls = [];
    service = StoreEntitlementService(
      logger: TestServiceSetup.getLoggingService(),
      channel: channel,
    );
  });

  void setHandler(Future<Object?>? Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestServiceSetup.clearAllMocks();
  });

  test('有効なエンタイトルメントを返す → Success(StoreEntitlement)', () async {
    final expiryMs = DateTime(2030, 1, 1).millisecondsSinceEpoch;
    setHandler(
      (_) async => {
        'productId': SubscriptionConstants.premiumMonthlyProductId,
        'expiryDateMs': expiryMs,
        'isActive': true,
      },
    );

    final result = await service.getActiveSubscription();

    expect(result.isSuccess, isTrue);
    expect(
      result.value!.productId,
      SubscriptionConstants.premiumMonthlyProductId,
    );
    expect(result.value!.expiryDate.millisecondsSinceEpoch, expiryMs);
    // 商品IDがネイティブへ渡されていること
    final args = calls.single.arguments as Map<dynamic, dynamic>;
    expect(
      args['productIds'],
      contains(SubscriptionConstants.premiumMonthlyProductId),
    );
  });

  test('有効な購読が無い(nullを返す) → Success(null)', () async {
    setHandler((_) async => null);

    final result = await service.getActiveSubscription();

    expect(result.isSuccess, isTrue);
    expect(result.value, isNull);
  });

  test('PlatformException → Failure', () async {
    setHandler((_) async => throw PlatformException(code: 'STOREKIT_ERROR'));

    final result = await service.getActiveSubscription();

    expect(result.isFailure, isTrue);
  });

  test('チャネル未登録(MissingPluginException相当) → Failure', () async {
    // ハンドラ未設定 = MissingPluginException が送出される
    final result = await service.getActiveSubscription();

    expect(result.isFailure, isTrue);
  });
}
