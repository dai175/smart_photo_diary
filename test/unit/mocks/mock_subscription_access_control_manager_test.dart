import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../../mocks/mock_subscription_access_control_manager.dart';

void main() {
  group('MockSubscriptionAccessControlManager', () {
    late MockSubscriptionAccessControlManager mockManager;

    setUp(() {
      mockManager = MockSubscriptionAccessControlManager();
    });

    tearDown(() {
      mockManager.dispose();
    });

    group('初期化とセットアップ', () {
      test('初期状態では初期化済み', () {
        expect(mockManager.isInitialized, true);
      });

      test('初期化状態を設定できる', () {
        // Act
        mockManager.setInitialized(false);

        // Assert
        expect(mockManager.isInitialized, false);
      });

      test('デフォルトでプラン別アクセス設定が初期化される', () async {
        // Arrange
        final basicStatus = _createBasicStatus();

        // Act
        final writingPromptsResult = await mockManager.canAccessWritingPrompts(basicStatus, _isValidBasicSubscription);
        final premiumFeaturesResult = await mockManager.canAccessPremiumFeatures(basicStatus, _isValidBasicSubscription);

        // Assert
        expect(writingPromptsResult.isSuccess, true);
        expect(writingPromptsResult.value, true); // Basicでも基本プロンプトアクセス可能
        expect(premiumFeaturesResult.isSuccess, true);
        expect(premiumFeaturesResult.value, false); // Basicプランではプレミアム機能は使用不可
      });

      test('状態をリセットできる', () async {
        // Arrange
        mockManager.setInitialized(false);
        mockManager.setCanAccessPremiumFeaturesFailure(true);

        // Act
        mockManager.resetToDefaults();

        // Assert
        expect(mockManager.isInitialized, true);
        final status = _createBasicStatus();
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);
        expect(result.isSuccess, true);
      });
    });

    group('プレミアム機能アクセス権限判定', () {
      test('未初期化時はエラーを返す', () async {
        // Arrange
        mockManager.setInitialized(false);
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('Basicプランではプレミアム機能にアクセスできない', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premium月額プランでプレミアム機能にアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('Premium年額プランでプレミアム機能にアクセスできる', () async {
        // Arrange
        final status = _createPremiumYearlyStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('無効なサブスクリプションではアクセス不可', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isInvalidSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('プレミアム機能アクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessPremiumFeaturesFailure(true, 'Test premium features error');
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test premium features error'));
      });
    });

    group('ライティングプロンプトアクセス権限判定', () {
      test('Basicプランでライティングプロンプトにアクセスできる', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessWritingPrompts(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('Premiumプランでライティングプロンプトにアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessWritingPrompts(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('未知のプランIDではアクセス不可', () async {
        // Arrange
        final status = SubscriptionStatus(
          planId: 'unknown_plan',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );

        // Act
        final result = await mockManager.canAccessWritingPrompts(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('ライティングプロンプトアクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessWritingPromptsFailure(true, 'Test writing prompts error');
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessWritingPrompts(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test writing prompts error'));
      });
    });

    group('高度なフィルタアクセス権限判定', () {
      test('Basicプランでは高度なフィルタにアクセスできない', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessAdvancedFilters(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premiumプランで高度なフィルタにアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessAdvancedFilters(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('期限切れPremiumプランではアクセス不可', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessAdvancedFilters(status, _isInvalidSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('高度なフィルタアクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessAdvancedFiltersFailure(true, 'Test advanced filters error');
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessAdvancedFilters(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test advanced filters error'));
      });
    });

    group('高度な分析アクセス権限判定', () {
      test('Basicプランでは高度な分析にアクセスできない', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessAdvancedAnalytics(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premiumプランで高度な分析にアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessAdvancedAnalytics(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('高度な分析アクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessAdvancedAnalyticsFailure(true, 'Test advanced analytics error');
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessAdvancedAnalytics(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test advanced analytics error'));
      });
    });

    group('データエクスポートアクセス権限判定', () {
      test('Basicプランでデータエクスポートにアクセスできる', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessDataExport(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('Premiumプランでデータエクスポートにアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessDataExport(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('期限切れPremiumプランではアクセス不可', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessDataExport(status, _isInvalidSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('データエクスポートアクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessDataExportFailure(true, 'Test data export error');
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessDataExport(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test data export error'));
      });
    });

    group('統計ダッシュボードアクセス権限判定', () {
      test('Basicプランでは統計ダッシュボードにアクセスできない', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessStatsDashboard(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premiumプランで統計ダッシュボードにアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessStatsDashboard(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('統計ダッシュボードアクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessStatsDashboardFailure(true, 'Test stats dashboard error');
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessStatsDashboard(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test stats dashboard error'));
      });
    });

    group('優先サポートアクセス権限判定', () {
      test('Basicプランでは優先サポートにアクセスできない', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessPrioritySupport(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premiumプランで優先サポートにアクセスできる', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessPrioritySupport(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('優先サポートアクセス失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessPrioritySupportFailure(true, 'Test priority support error');
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.canAccessPrioritySupport(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test priority support error'));
      });
    });

    group('統合機能アクセス権限取得', () {
      test('Basicプランで正しい機能アクセスマップが返される', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.getFeatureAccess(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        final featureAccess = result.value;
        expect(featureAccess['premiumFeatures'], false);
        expect(featureAccess['writingPrompts'], true);
        expect(featureAccess['advancedFilters'], false);
        expect(featureAccess['dataExport'], true);
        expect(featureAccess['statsDashboard'], false);
        expect(featureAccess['advancedAnalytics'], false);
        expect(featureAccess['prioritySupport'], false);
      });

      test('Premiumプランで正しい機能アクセスマップが返される', () async {
        // Arrange
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockManager.getFeatureAccess(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        final featureAccess = result.value;
        expect(featureAccess['premiumFeatures'], true);
        expect(featureAccess['writingPrompts'], true);
        expect(featureAccess['advancedFilters'], true);
        expect(featureAccess['dataExport'], true);
        expect(featureAccess['statsDashboard'], true);
        expect(featureAccess['advancedAnalytics'], true);
        expect(featureAccess['prioritySupport'], true);
      });

      test('機能アクセス取得失敗を設定できる', () async {
        // Arrange
        mockManager.setGetFeatureAccessFailure(true, 'Test getFeatureAccess error');
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.getFeatureAccess(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test getFeatureAccess error'));
      });

      test('個別機能でエラーが発生した場合、統合取得もエラーになる', () async {
        // Arrange
        mockManager.setCanAccessPremiumFeaturesFailure(true, 'Individual feature error');
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.getFeatureAccess(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Individual feature error'));
      });
    });

    group('テスト用ヘルパーメソッド', () {
      test('特定プランの機能アクセスを設定できる', () async {
        // Arrange
        mockManager.setFeatureAccessForPlan(SubscriptionConstants.basicPlanId, 'premiumFeatures', true);
        final status = _createBasicStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true); // 設定により変更された
      });

      test('Basic制限状態を作成できる', () async {
        // Act
        mockManager.createBasicRestrictedState();
        final status = _createBasicStatus();
        final premiumResult = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);
        final promptsResult = await mockManager.canAccessWritingPrompts(status, _isValidBasicSubscription);

        // Assert
        expect(premiumResult.value, false);
        expect(promptsResult.value, true); // Basicでも基本プロンプトアクセス可能
      });

      test('Premium全アクセス状態を作成できる', () async {
        // Act
        mockManager.createPremiumFullAccessState();
        final status = _createPremiumMonthlyStatus();
        final result = await mockManager.getFeatureAccess(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, true);
        final featureAccess = result.value;
        for (final hasAccess in featureAccess.values) {
          expect(hasAccess, true); // 全機能にアクセス可能
        }
      });

      test('全機能アクセス拒否状態を作成できる', () async {
        // Act
        mockManager.createAllAccessDeniedState();
        final status = _createBasicStatus();
        final result = await mockManager.getFeatureAccess(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, true);
        final featureAccess = result.value;
        for (final hasAccess in featureAccess.values) {
          expect(hasAccess, false); // 全機能にアクセス不可
        }
      });

      test('現在のアクセス設定を取得できる', () {
        // Act
        final accessSettings = mockManager.getCurrentAccessSettings();

        // Assert
        expect(accessSettings.isNotEmpty, true);
        expect(accessSettings.containsKey(SubscriptionConstants.basicPlanId), true);
        expect(accessSettings.containsKey(SubscriptionConstants.premiumMonthlyPlanId), true);
        expect(accessSettings.containsKey(SubscriptionConstants.premiumYearlyPlanId), true);
      });
    });

    group('エラーハンドリング', () {
      test('初期化されていない場合、全メソッドがエラーを返す', () async {
        // Arrange
        mockManager.setInitialized(false);
        final status = _createBasicStatus();

        // Act & Assert
        final canAccessPremiumFeatures = await mockManager.canAccessPremiumFeatures(status, _isValidBasicSubscription);
        expect(canAccessPremiumFeatures.isFailure, true);

        final canAccessWritingPrompts = await mockManager.canAccessWritingPrompts(status, _isValidBasicSubscription);
        expect(canAccessWritingPrompts.isFailure, true);

        final canAccessAdvancedFilters = await mockManager.canAccessAdvancedFilters(status, _isValidBasicSubscription);
        expect(canAccessAdvancedFilters.isFailure, true);

        final canAccessAdvancedAnalytics = await mockManager.canAccessAdvancedAnalytics(status, _isValidBasicSubscription);
        expect(canAccessAdvancedAnalytics.isFailure, true);

        final canAccessDataExport = await mockManager.canAccessDataExport(status, _isValidBasicSubscription);
        expect(canAccessDataExport.isFailure, true);

        final canAccessStatsDashboard = await mockManager.canAccessStatsDashboard(status, _isValidBasicSubscription);
        expect(canAccessStatsDashboard.isFailure, true);

        final canAccessPrioritySupport = await mockManager.canAccessPrioritySupport(status, _isValidBasicSubscription);
        expect(canAccessPrioritySupport.isFailure, true);

        final getFeatureAccess = await mockManager.getFeatureAccess(status, _isValidBasicSubscription);
        expect(getFeatureAccess.isFailure, true);
      });
    });

    group('破棄処理', () {
      test('破棄処理が正常に実行される', () {
        // Act
        mockManager.dispose();

        // Assert
        expect(mockManager.isInitialized, false);
        expect(mockManager.getCurrentAccessSettings().isEmpty, true);
      });
    });
  });
}

// =================================================================
// テスト用ヘルパー関数
// =================================================================

/// Basicプランのサブスクリプション状態を作成
SubscriptionStatus _createBasicStatus() {
  return SubscriptionStatus(
    planId: SubscriptionConstants.basicPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: null,
    autoRenewal: false,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: '',
    lastPurchaseDate: null,
  );
}

/// PremiumMonthlyプランのサブスクリプション状態を作成
SubscriptionStatus _createPremiumMonthlyStatus() {
  return SubscriptionStatus(
    planId: SubscriptionConstants.premiumMonthlyPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 30)),
    autoRenewal: true,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: 'test_transaction',
    lastPurchaseDate: DateTime.now(),
  );
}

/// PremiumYearlyプランのサブスクリプション状態を作成
SubscriptionStatus _createPremiumYearlyStatus() {
  return SubscriptionStatus(
    planId: SubscriptionConstants.premiumYearlyPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 365)),
    autoRenewal: true,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: 'test_transaction_yearly',
    lastPurchaseDate: DateTime.now(),
  );
}

/// Basicプラン有効性チェック関数
bool _isValidBasicSubscription(SubscriptionStatus status) {
  return status.isActive && status.planId == SubscriptionConstants.basicPlanId;
}

/// Premiumプラン有効性チェック関数
bool _isValidPremiumSubscription(SubscriptionStatus status) {
  final isPremium = status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
                    status.planId == SubscriptionConstants.premiumYearlyPlanId;
  final isActive = status.isActive;
  final isNotExpired = status.expiryDate?.isAfter(DateTime.now()) ?? false;
  
  return isPremium && isActive && isNotExpired;
}

/// 無効なサブスクリプション（常にfalseを返す）
bool _isInvalidSubscription(SubscriptionStatus status) {
  return false;
}