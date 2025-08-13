import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

/// MockSubscriptionAccessControlManager
///
/// テスト用のSubscriptionAccessControlManagerモック実装
///
/// ## 主な機能
/// - 完全なメモリベース実装で依存関係を排除
/// - テストシナリオ用の設定可能な状態管理
/// - 全公開メソッドの完全実装
/// - エラーシミュレーション機能
/// - アクセス制御機能の完全模倣
///
/// ## 設計原則
/// - SubscriptionAccessControlManagerの公開APIを完全に模倣
/// - 各メソッドの成功・失敗パターンを設定可能
/// - プラン別アクセス制御の完全実装
/// - テスト用のヘルパーメソッドを豊富に提供
class MockSubscriptionAccessControlManager {
  // =================================================================
  // 内部状態管理
  // =================================================================

  bool _isInitialized = false;

  // アクセス制御設定（プランIDごと）
  final Map<String, Map<String, bool>> _accessSettings = {};

  // エラーシミュレーション設定
  bool _shouldFailCanAccessPremiumFeatures = false;
  bool _shouldFailCanAccessWritingPrompts = false;
  bool _shouldFailCanAccessAdvancedFilters = false;
  bool _shouldFailCanAccessAdvancedAnalytics = false;
  bool _shouldFailCanAccessDataExport = false;
  bool _shouldFailCanAccessStatsDashboard = false;
  bool _shouldFailCanAccessPrioritySupport = false;
  bool _shouldFailGetFeatureAccess = false;
  String? _forcedErrorMessage;

  // =================================================================
  // コンストラクタ
  // =================================================================

  MockSubscriptionAccessControlManager() {
    _isInitialized = true;
    _initializeDefaultAccessSettings();
  }

  /// デフォルトアクセス設定の初期化
  void _initializeDefaultAccessSettings() {
    // Basicプランのデフォルト設定
    _accessSettings[SubscriptionConstants.basicPlanId] = {
      'premiumFeatures': false,
      'writingPrompts': true, // Basicでも基本プロンプトアクセス可能
      'advancedFilters': false,
      'advancedAnalytics': false,
      'dataExport': true, // BasicでもJSONエクスポート可能
      'statsDashboard': false,
      'prioritySupport': false,
    };

    // Premium月額プランのデフォルト設定
    _accessSettings[SubscriptionConstants.premiumMonthlyPlanId] = {
      'premiumFeatures': true,
      'writingPrompts': true,
      'advancedFilters': true,
      'advancedAnalytics': true,
      'dataExport': true,
      'statsDashboard': true,
      'prioritySupport': true,
    };

    // Premium年額プランのデフォルト設定
    _accessSettings[SubscriptionConstants.premiumYearlyPlanId] = {
      'premiumFeatures': true,
      'writingPrompts': true,
      'advancedFilters': true,
      'advancedAnalytics': true,
      'dataExport': true,
      'statsDashboard': true,
      'prioritySupport': true,
    };
  }

  // =================================================================
  // テスト設定メソッド
  // =================================================================

  /// テスト用: canAccessPremiumFeatures失敗を設定
  void setCanAccessPremiumFeaturesFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailCanAccessPremiumFeatures = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessWritingPrompts失敗を設定
  void setCanAccessWritingPromptsFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailCanAccessWritingPrompts = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessAdvancedFilters失敗を設定
  void setCanAccessAdvancedFiltersFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailCanAccessAdvancedFilters = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessAdvancedAnalytics失敗を設定
  void setCanAccessAdvancedAnalyticsFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailCanAccessAdvancedAnalytics = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessDataExport失敗を設定
  void setCanAccessDataExportFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailCanAccessDataExport = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessStatsDashboard失敗を設定
  void setCanAccessStatsDashboardFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailCanAccessStatsDashboard = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessPrioritySupport失敗を設定
  void setCanAccessPrioritySupportFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailCanAccessPrioritySupport = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: getFeatureAccess失敗を設定
  void setGetFeatureAccessFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetFeatureAccess = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 初期化状態を設定
  void setInitialized(bool isInitialized) {
    _isInitialized = isInitialized;
  }

  /// テスト用: 状態をリセット
  void resetToDefaults() {
    _isInitialized = true;
    _shouldFailCanAccessPremiumFeatures = false;
    _shouldFailCanAccessWritingPrompts = false;
    _shouldFailCanAccessAdvancedFilters = false;
    _shouldFailCanAccessAdvancedAnalytics = false;
    _shouldFailCanAccessDataExport = false;
    _shouldFailCanAccessStatsDashboard = false;
    _shouldFailCanAccessPrioritySupport = false;
    _shouldFailGetFeatureAccess = false;
    _forcedErrorMessage = null;
    _accessSettings.clear();
    _initializeDefaultAccessSettings();
  }

  // =================================================================
  // エラーハンドリングヘルパー
  // =================================================================

  Result<T> _simulateError<T>(String operation) {
    final message = _forcedErrorMessage ?? 'Mock error in $operation';
    return Failure(
      ServiceException(message, details: 'Simulated error for testing'),
    );
  }

  // =================================================================
  // プロパティアクセサー
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  // =================================================================
  // 公開API実装
  // =================================================================

  /// プレミアム機能にアクセスできるかどうか
  Future<Result<bool>> canAccessPremiumFeatures(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessPremiumFeatures) {
      return _simulateError('canAccessPremiumFeatures');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // サブスクリプションが有効でない場合は拒否
    if (!isValidSubscription(status)) {
      return const Success(false);
    }

    // 設定された値を使用（存在する場合）
    final accessSetting = _accessSettings[status.planId];
    if (accessSetting != null && accessSetting.containsKey('premiumFeatures')) {
      return Success(accessSetting['premiumFeatures']!);
    }

    // デフォルトロジック：プレミアムプランかどうかをチェック
    final isPremium =
        status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
        status.planId == SubscriptionConstants.premiumYearlyPlanId;

    return Success(isPremium);
  }

  /// ライティングプロンプト機能にアクセスできるかどうか
  Future<Result<bool>> canAccessWritingPrompts(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessWritingPrompts) {
      return _simulateError('canAccessWritingPrompts');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    final accessSetting = _accessSettings[status.planId];
    if (accessSetting == null) {
      return const Success(false);
    }

    // ライティングプロンプトは全プランで利用可能（Basicは限定版）
    return Success(accessSetting['writingPrompts'] ?? false);
  }

  /// 高度なフィルタ機能にアクセスできるかどうか
  Future<Result<bool>> canAccessAdvancedFilters(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessAdvancedFilters) {
      return _simulateError('canAccessAdvancedFilters');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // Basicプランでは使用不可
    if (status.planId == SubscriptionConstants.basicPlanId) {
      return const Success(false);
    }

    // Premiumプランの場合、サブスクリプションが有効かチェック
    final isPremiumValid = isValidSubscription(status);
    return Success(isPremiumValid);
  }

  /// 高度な分析にアクセスできるかどうか
  Future<Result<bool>> canAccessAdvancedAnalytics(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessAdvancedAnalytics) {
      return _simulateError('canAccessAdvancedAnalytics');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // Basicプランでは使用不可
    if (status.planId == SubscriptionConstants.basicPlanId) {
      return const Success(false);
    }

    // Premiumプランの場合、サブスクリプションが有効かチェック
    final isPremiumValid = isValidSubscription(status);
    return Success(isPremiumValid);
  }

  /// データエクスポート機能にアクセスできるかどうか
  Future<Result<bool>> canAccessDataExport(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessDataExport) {
      return _simulateError('canAccessDataExport');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    final accessSetting = _accessSettings[status.planId];
    if (accessSetting == null) {
      return const Success(false);
    }

    // データエクスポートは全プランで利用可能（Basicは基本形式のみ）
    if (status.planId == SubscriptionConstants.basicPlanId) {
      return Success(accessSetting['dataExport'] ?? false); // BasicプランでもJSONは可能
    }

    // Premiumプランの場合、サブスクリプションが有効かチェック
    final isPremiumValid = isValidSubscription(status);
    return Success(isPremiumValid);
  }

  /// 統計ダッシュボード機能にアクセスできるかどうか
  Future<Result<bool>> canAccessStatsDashboard(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessStatsDashboard) {
      return _simulateError('canAccessStatsDashboard');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // Basicプランでは使用不可
    if (status.planId == SubscriptionConstants.basicPlanId) {
      return const Success(false);
    }

    // Premiumプランの場合、サブスクリプションが有効かチェック
    final isPremiumValid = isValidSubscription(status);
    return Success(isPremiumValid);
  }

  /// 優先サポートにアクセスできるかどうか
  Future<Result<bool>> canAccessPrioritySupport(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessPrioritySupport) {
      return _simulateError('canAccessPrioritySupport');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // Basicプランでは使用不可
    if (status.planId == SubscriptionConstants.basicPlanId) {
      return const Success(false);
    }

    // Premiumプランの場合、サブスクリプションが有効かチェック
    final isPremiumValid = isValidSubscription(status);
    return Success(isPremiumValid);
  }

  /// プラン別の機能制限情報を取得
  Future<Result<Map<String, bool>>> getFeatureAccess(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('AccessControlManager is not initialized'),
      );
    }

    if (_shouldFailGetFeatureAccess) {
      return _simulateError('getFeatureAccess');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 非同期処理をシミュレート

    // 各機能のアクセス権限を並行して取得
    final results = await Future.wait([
      canAccessPremiumFeatures(status, isValidSubscription),
      canAccessWritingPrompts(status, isValidSubscription),
      canAccessAdvancedFilters(status, isValidSubscription),
      canAccessDataExport(status, isValidSubscription),
      canAccessStatsDashboard(status, isValidSubscription),
      canAccessAdvancedAnalytics(status, isValidSubscription),
      canAccessPrioritySupport(status, isValidSubscription),
    ]);

    // エラーチェック
    for (final result in results) {
      if (result.isFailure) {
        return Failure(result.error);
      }
    }

    final featureAccess = {
      'premiumFeatures': results[0].value,
      'writingPrompts': results[1].value,
      'advancedFilters': results[2].value,
      'dataExport': results[3].value,
      'statsDashboard': results[4].value,
      'advancedAnalytics': results[5].value,
      'prioritySupport': results[6].value,
    };

    return Success(featureAccess);
  }

  // =================================================================
  // テスト用ヘルパーメソッド
  // =================================================================

  /// テスト用: 特定プランの機能アクセスを設定
  void setFeatureAccessForPlan(String planId, String feature, bool hasAccess) {
    _accessSettings.putIfAbsent(planId, () => {});
    _accessSettings[planId]![feature] = hasAccess;
  }

  /// テスト用: Basic制限状態を作成
  void createBasicRestrictedState() {
    _accessSettings[SubscriptionConstants.basicPlanId] = {
      'premiumFeatures': false,
      'writingPrompts': true, // Basicでも基本プロンプトアクセス可能
      'advancedFilters': false,
      'advancedAnalytics': false,
      'dataExport': true, // BasicでもJSONエクスポート可能
      'statsDashboard': false,
      'prioritySupport': false,
    };
  }

  /// テスト用: Premium全アクセス状態を作成
  void createPremiumFullAccessState() {
    final fullAccessMap = {
      'premiumFeatures': true,
      'writingPrompts': true,
      'advancedFilters': true,
      'advancedAnalytics': true,
      'dataExport': true,
      'statsDashboard': true,
      'prioritySupport': true,
    };

    _accessSettings[SubscriptionConstants.premiumMonthlyPlanId] = Map.from(
      fullAccessMap,
    );
    _accessSettings[SubscriptionConstants.premiumYearlyPlanId] = Map.from(
      fullAccessMap,
    );
  }

  /// テスト用: 全機能アクセス拒否状態を作成
  void createAllAccessDeniedState() {
    final noAccessMap = {
      'premiumFeatures': false,
      'writingPrompts': false,
      'advancedFilters': false,
      'advancedAnalytics': false,
      'dataExport': false,
      'statsDashboard': false,
      'prioritySupport': false,
    };

    for (final planId in _accessSettings.keys) {
      _accessSettings[planId] = Map.from(noAccessMap);
    }
  }

  /// テスト用: 現在のアクセス設定を取得
  Map<String, Map<String, bool>> getCurrentAccessSettings() {
    return Map.from(_accessSettings);
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  void dispose() {
    _isInitialized = false;
    _accessSettings.clear();
  }
}
