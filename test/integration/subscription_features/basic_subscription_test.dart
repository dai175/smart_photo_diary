import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import '../../mocks/mock_subscription_service.dart';

/// Phase 3.1.1: サブスクリプション機能統合テスト（簡易版）
///
/// このテストは以下の基本項目を検証します：
/// - MockSubscriptionServiceの基本動作
/// - プラン設定と状態取得
/// - 使用量管理の基本機能
/// - サービス登録とアクセス
void main() {
  group('Phase 3.1.1: サブスクリプション機能基本テスト', () {
    late MockSubscriptionService mockService;
    late ServiceLocator serviceLocator;

    setUp(() async {
      // 新しいServiceLocatorインスタンスを作成
      serviceLocator = ServiceLocator();

      // MockSubscriptionServiceを作成・登録
      mockService = MockSubscriptionService();
      serviceLocator.registerSingleton<ISubscriptionService>(mockService);

      // サービスを初期化
      await mockService.initialize();
    });

    tearDown(() {
      // テスト後のクリーンアップ
      mockService.resetToDefaults();
    });

    test('3.1.1.1: Basicプランの初期状態確認', () async {
      // Given: デフォルト状態（Basic）

      // When: 現在の状態を取得
      final result = await mockService.getCurrentStatus();

      // Then: Basicプランの状態が正しく取得される
      expect(result.isSuccess, isTrue);
      final status = result.value;
      expect(status.planId, equals(BasicPlan().id));
      expect(status.monthlyUsageCount, equals(0));
      expect(status.currentPlanClass.monthlyAiGenerationLimit, equals(10));
      expect(status.isActive, isTrue);
    });

    test('3.1.1.2: Premiumプランへの変更と状態確認', () async {
      // Given: 初期状態はBasic
      var result = await mockService.getCurrentStatus();
      expect(result.value.planId, equals(BasicPlan().id));

      // When: Premiumプランに変更
      mockService.setCurrentPlanClass(PremiumMonthlyPlan());

      // Then: Premium状態に変更されている
      result = await mockService.getCurrentStatus();
      expect(result.isSuccess, isTrue);
      final status = result.value;
      expect(status.planId, equals(PremiumMonthlyPlan().id));
      final plan = PremiumMonthlyPlan();
      expect(plan.monthlyAiGenerationLimit, equals(100));
      expect(plan.hasWritingPrompts, isTrue);
    });

    test('3.1.1.3: 使用量制限テスト（Basic 10回制限）', () async {
      // Given: Basicプランに設定
      mockService.setCurrentPlanClass(BasicPlan());

      // When: 使用量を9回に設定
      mockService.setUsageCount(9);

      // Then: 使用量が正しく設定されている
      var result = await mockService.getCurrentStatus();
      var status = result.value;
      expect(status.monthlyUsageCount, equals(9));
      expect(
        status.monthlyUsageCount < BasicPlan().monthlyAiGenerationLimit,
        isTrue,
      );

      // When: 使用量を10回に設定（制限到達）
      mockService.setUsageCount(10);

      // Then: 制限に到達している
      result = await mockService.getCurrentStatus();
      status = result.value;
      expect(status.monthlyUsageCount, equals(10));
      expect(
        status.monthlyUsageCount >= BasicPlan().monthlyAiGenerationLimit,
        isTrue,
      );
    });

    test('3.1.1.4: 使用量制限テスト（Premium 100回制限）', () async {
      // Given: Premiumプランに設定
      mockService.setCurrentPlanClass(PremiumMonthlyPlan());

      // When: 使用量を99回に設定
      mockService.setUsageCount(99);

      // Then: 使用量が正しく設定されている
      var result = await mockService.getCurrentStatus();
      var status = result.value;
      expect(status.monthlyUsageCount, equals(99));
      expect(
        status.monthlyUsageCount < PremiumMonthlyPlan().monthlyAiGenerationLimit,
        isTrue,
      );

      // When: 使用量を100回に設定（制限到達）
      mockService.setUsageCount(100);

      // Then: 制限に到達している
      result = await mockService.getCurrentStatus();
      status = result.value;
      expect(status.monthlyUsageCount, equals(100));
      expect(
        status.monthlyUsageCount >= PremiumMonthlyPlan().monthlyAiGenerationLimit,
        isTrue,
      );
    });

    test('3.1.1.5: ServiceLocator経由でのアクセステスト', () async {
      // Given: ServiceLocatorにサービスが登録済み

      // When: ServiceLocator経由でサービスを取得
      final service = serviceLocator.get<ISubscriptionService>();

      // Then: 正しいサービスインスタンスが取得される
      expect(service, isNotNull);
      expect(service, equals(mockService));

      // サービス経由で状態取得可能
      final result = await service.getCurrentStatus();
      expect(result.isSuccess, isTrue);
    });

    test('3.1.1.6: 使用量インクリメント機能テスト', () async {
      // Given: Basicプランで3回使用済み
      mockService.setCurrentPlanClass(BasicPlan());
      mockService.setUsageCount(3);

      // When: AI使用量をインクリメント
      final incrementResult = await mockService.incrementAiUsage();

      // Then: インクリメントが成功し、使用量が4回になる
      expect(incrementResult.isSuccess, isTrue);

      final statusResult = await mockService.getCurrentStatus();
      expect(statusResult.value.monthlyUsageCount, equals(4));
    });

    test('3.1.1.7: AI使用可否チェック機能', () async {
      // Given: Basicプランで9回使用済み
      mockService.setCurrentPlanClass(BasicPlan());
      mockService.setUsageCount(9);

      // When: AI使用可否をチェック
      var canUseResult = await mockService.canUseAiGeneration();

      // Then: 使用可能
      expect(canUseResult.isSuccess, isTrue);
      expect(canUseResult.value, isTrue);

      // When: 制限到達状態に変更
      mockService.setUsageCount(10);
      canUseResult = await mockService.canUseAiGeneration();

      // Then: 使用不可
      expect(canUseResult.isSuccess, isTrue);
      expect(canUseResult.value, isFalse);
    });

    test('3.1.1.8: プラン情報取得テスト', () async {
      // When: 利用可能なプラン一覧を取得（Planクラス版）
      final plansResult = mockService.getAvailablePlansClass();

      // Then: Basic, Premium Monthly, Premium Yearlyが取得される
      expect(plansResult.isSuccess, isTrue);
      final plans = plansResult.value;
      expect(plans.length, equals(3));

      expect(plans.any((p) => p is BasicPlan), isTrue);
      expect(plans.any((p) => p is PremiumMonthlyPlan), isTrue);
      expect(plans.any((p) => p is PremiumYearlyPlan), isTrue);
    });

    test('3.1.1.9: 残りAI生成回数計算テスト', () async {
      // Given: Basicプランで7回使用済み
      mockService.setCurrentPlanClass(BasicPlan());
      mockService.setUsageCount(7);

      // When: 状態を取得して残り回数を計算
      final statusResult = await mockService.getCurrentStatus();
      final status = statusResult.value;
      final basicPlan = BasicPlan();
      final remaining = basicPlan.monthlyAiGenerationLimit - status.monthlyUsageCount;

      // Then: 残り3回
      expect(remaining, equals(3));

      // Given: Premiumプランで50回使用済み
      mockService.setCurrentPlanClass(PremiumMonthlyPlan());
      mockService.setUsageCount(50);

      // When: 状態を取得して残り回数を計算
      final premiumStatusResult = await mockService.getCurrentStatus();
      final premiumStatus = premiumStatusResult.value;
      final premiumPlan = PremiumMonthlyPlan();
      final premiumRemaining = premiumPlan.monthlyAiGenerationLimit - premiumStatus.monthlyUsageCount;

      // Then: 残り50回
      expect(premiumRemaining, equals(50));
    });

    test('3.1.1.10: エラーハンドリングテスト', () async {
      // Given: 状態取得失敗を設定
      mockService.setStatusRetrievalFailure(true, 'テスト用エラー');

      // When: 状態取得を試行
      final result = await mockService.getCurrentStatus();

      // Then: 適切にエラーが返される
      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('テスト用エラー'));

      // エラー状態をリセット
      mockService.setStatusRetrievalFailure(false);

      // 正常状態に復帰
      final normalResult = await mockService.getCurrentStatus();
      expect(normalResult.isSuccess, isTrue);
    });
  });
}
