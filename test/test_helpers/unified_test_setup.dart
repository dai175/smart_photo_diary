import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/services/storage_service.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import '../integration/mocks/mock_services.dart';
import '../mocks/mock_subscription_purchase_manager.dart';
import '../mocks/mock_subscription_status_manager.dart';
import '../mocks/mock_subscription_usage_tracker.dart';
import '../mocks/mock_subscription_access_control_manager.dart';
import 'mock_platform_channels.dart';
import 'common_test_utilities.dart';
import 'subscription_test_helpers.dart';

/// 統一テストセットアップ
///
/// ## 主な機能
/// - 全テストタイプ（Unit/Widget/Integration）の統一セットアップ
/// - Mock Service の自動初期化と依存性注入
/// - テスト環境の標準化とクリーンアップ
/// - Manager 統合テスト用のワンストップセットアップ
///
/// ## 使用方法
/// ```dart
/// void main() {
///   group('My Test Group', () {
///     UnifiedTestSetup.standardSetup();
///
///     testWidgets('my test', (tester) async {
///       final setup = UnifiedTestSetup.createBasicPlanSetup();
///       // テスト実行
///       await setup.dispose();
///     });
///   });
/// }
/// ```
class UnifiedTestSetup {
  // =================================================================
  // 静的プロパティ
  // =================================================================

  static bool _isGloballyInitialized = false;
  static ServiceLocator? _currentServiceLocator;
  static final List<Completer<void>> _activeDisposers = [];

  // =================================================================
  // 標準セットアップメソッド
  // =================================================================

  /// 全テストタイプで使用可能な標準セットアップ
  /// setUpAll/setUp/tearDown/tearDownAll を自動設定
  static void standardSetup() {
    setUpAll(() async {
      await _globalInitialization();
    });

    setUp(() async {
      await _testInitialization();
    });

    tearDown(() async {
      await _testCleanup();
    });

    tearDownAll(() async {
      await _globalCleanup();
    });
  }

  /// Widget テスト専用の軽量セットアップ
  static void widgetTestSetup() {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await _initializeMockPlatformChannels();
      registerMockFallbacks();
      _isGloballyInitialized = true;
    });

    setUp(() async {
      TestServiceSetup.clearAllMocks();
    });

    tearDown(() async {
      await _clearTestResources();
    });

    tearDownAll(() async {
      MockPlatformChannels.clearMocks();
      _isGloballyInitialized = false;
    });
  }

  /// Integration テスト用の完全セットアップ
  static void integrationTestSetup() {
    setUpAll(() async {
      await _globalInitialization();
      await _initializeHiveForIntegration();
    });

    setUp(() async {
      await _testInitialization();
      await _setupServiceLocatorForIntegration();
    });

    tearDown(() async {
      await _testCleanup();
      await _cleanupHive();
    });

    tearDownAll(() async {
      await _globalCleanup();
    });
  }

  // =================================================================
  // 便利なセットアップファクトリメソッド
  // =================================================================

  /// Basicプラン用の統合セットアップを作成
  static UnifiedTestContext createBasicPlanSetup({
    int usageCount = 0,
    bool enableErrors = false,
  }) {
    final managerSetup = SubscriptionTestHelpers.setupBasicPlanManagers(
      usageCount: usageCount,
      enableErrors: enableErrors,
    );

    final subscriptionService = SubscriptionTestHelpers.setupBasicPlanService(
      usageCount: usageCount,
    );

    return UnifiedTestContext._(
      plan: BasicPlan(),
      managerSetup: managerSetup,
      subscriptionService: subscriptionService,
      serviceLocator: _getOrCreateServiceLocator(),
    );
  }

  /// Premiumプラン用の統合セットアップを作成
  static UnifiedTestContext createPremiumPlanSetup({
    bool isYearly = true,
    int usageCount = 0,
    bool enableErrors = false,
  }) {
    final managerSetup = SubscriptionTestHelpers.setupPremiumPlanManagers(
      isYearly: isYearly,
      usageCount: usageCount,
      enableErrors: enableErrors,
    );

    final subscriptionService = SubscriptionTestHelpers.setupPremiumPlanService(
      isYearly: isYearly,
      usageCount: usageCount,
    );

    return UnifiedTestContext._(
      plan: managerSetup.plan,
      managerSetup: managerSetup,
      subscriptionService: subscriptionService,
      serviceLocator: _getOrCreateServiceLocator(),
    );
  }

  /// エラーシナリオ用のセットアップを作成
  static UnifiedTestContext createErrorScenarioSetup({
    Plan? plan,
    String? errorMessage,
  }) {
    final selectedPlan = plan ?? BasicPlan();

    final managerSetup = CommonTestUtilities.setupAllManagers(
      plan: selectedPlan,
      enableErrors: true,
    );

    final subscriptionService = TestServiceSetup.getSubscriptionService();

    return UnifiedTestContext._(
      plan: selectedPlan,
      managerSetup: ManagerIntegratedSetup(
        plan: selectedPlan,
        status: SubscriptionTestHelpers.createBasicPlanStatus(),
        purchaseManager: managerSetup.purchaseManager,
        statusManager: managerSetup.statusManager,
        usageTracker: managerSetup.usageTracker,
        accessControlManager: managerSetup.accessControlManager,
      ),
      subscriptionService: subscriptionService,
      serviceLocator: _getOrCreateServiceLocator(),
    );
  }

  /// カスタムプラン・状態でのセットアップを作成
  static UnifiedTestContext createCustomSetup({
    required Plan plan,
    required SubscriptionStatus status,
    bool enableErrors = false,
  }) {
    final purchaseManager = MockSubscriptionPurchaseManager();
    final statusManager = MockSubscriptionStatusManager();
    final usageTracker = MockSubscriptionUsageTracker();
    final accessControlManager = MockSubscriptionAccessControlManager();

    // カスタム設定を適用
    statusManager.setCurrentPlan(plan);
    statusManager.setCurrentStatus(status);
    usageTracker.setCurrentStatus(status);

    if (plan.isPremium) {
      accessControlManager.createPremiumFullAccessState();
    } else {
      accessControlManager.createBasicRestrictedState();
    }

    if (enableErrors) {
      final errorMessage = 'Custom setup test error';
      purchaseManager.setPurchaseFailure(true, errorMessage);
      statusManager.setGetCurrentStatusFailure(true, errorMessage);
      usageTracker.setCanUseAiGenerationFailure(true, errorMessage);
      accessControlManager.setCanAccessPremiumFeaturesFailure(
        true,
        errorMessage,
      );
    }

    final managerSetup = ManagerIntegratedSetup(
      plan: plan,
      status: status,
      purchaseManager: purchaseManager,
      statusManager: statusManager,
      usageTracker: usageTracker,
      accessControlManager: accessControlManager,
    );

    final subscriptionService = MockSubscriptionServiceInterface();
    TestServiceSetup.configureSubscriptionServiceForPlan(
      subscriptionService,
      plan,
      usageCount: status.monthlyUsageCount,
      isActive: status.isActive,
    );

    return UnifiedTestContext._(
      plan: plan,
      managerSetup: managerSetup,
      subscriptionService: subscriptionService,
      serviceLocator: _getOrCreateServiceLocator(),
    );
  }

  // =================================================================
  // 内部初期化メソッド
  // =================================================================

  static Future<void> _globalInitialization() async {
    if (_isGloballyInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    await _initializeMockPlatformChannels();
    registerMockFallbacks();

    _isGloballyInitialized = true;
  }

  static Future<void> _testInitialization() async {
    TestServiceSetup.clearAllMocks();
    _currentServiceLocator = null;
  }

  static Future<void> _testCleanup() async {
    await _clearTestResources();

    // アクティブなDisposerを実行
    for (final completer in _activeDisposers) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _activeDisposers.clear();

    _currentServiceLocator?.clear();
    _currentServiceLocator = null;
  }

  static Future<void> _globalCleanup() async {
    MockPlatformChannels.clearMocks();
    TestServiceSetup.clearAllMocks();

    try {
      await Hive.deleteFromDisk();
    } catch (e) {
      // Ignore cleanup errors
    }

    _isGloballyInitialized = false;
  }

  static Future<void> _initializeMockPlatformChannels() async {
    MockPlatformChannels.setupMocks();
  }

  static Future<void> _initializeHiveForIntegration() async {
    const testDirectory = '/tmp/smart_photo_diary_unified_test';
    await Hive.initFlutter(testDirectory);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DiaryEntryAdapter());
    }
  }

  static Future<void> _setupServiceLocatorForIntegration() async {
    final serviceLocator = _getOrCreateServiceLocator();

    // 基本サービスの登録
    serviceLocator.registerSingleton<PhotoServiceInterface>(
      TestServiceSetup.getPhotoService(),
    );
    serviceLocator.registerSingleton<AiServiceInterface>(
      TestServiceSetup.getAiService(),
    );
    serviceLocator.registerSingleton<DiaryServiceInterface>(
      TestServiceSetup.getDiaryService(),
    );
    serviceLocator.registerSingleton<ISubscriptionService>(
      TestServiceSetup.getSubscriptionService(),
    );
    serviceLocator.registerSingleton<SettingsService>(
      TestServiceSetup.getSettingsService(),
    );
    serviceLocator.registerSingleton<StorageService>(
      TestServiceSetup.getStorageService(),
    );
    serviceLocator.registerSingleton<LoggingService>(MockLoggingService());
  }

  static Future<void> _cleanupHive() async {
    try {
      await Hive.deleteFromDisk();
    } catch (e) {
      // Ignore cleanup errors in tests
    }
  }

  static Future<void> _clearTestResources() async {
    // テスト用リソースのクリーンアップ
    // 必要に応じて追加のクリーンアップ処理を実装
  }

  static ServiceLocator _getOrCreateServiceLocator() {
    return _currentServiceLocator ??= ServiceLocator();
  }
}

/// 統合テストコンテキスト
///
/// テストに必要な全てのMockオブジェクトとセットアップを含む
class UnifiedTestContext {
  final Plan plan;
  final ManagerIntegratedSetup managerSetup;
  final MockSubscriptionServiceInterface subscriptionService;
  final ServiceLocator serviceLocator;
  final Completer<void> _disposer = Completer<void>();

  UnifiedTestContext._({
    required this.plan,
    required this.managerSetup,
    required this.subscriptionService,
    required this.serviceLocator,
  }) {
    UnifiedTestSetup._activeDisposers.add(_disposer);
  }

  // =================================================================
  // 便利なアクセサ
  // =================================================================

  /// Purchase Manager への参照
  MockSubscriptionPurchaseManager get purchaseManager =>
      managerSetup.purchaseManager;

  /// Status Manager への参照
  MockSubscriptionStatusManager get statusManager => managerSetup.statusManager;

  /// Usage Tracker への参照
  MockSubscriptionUsageTracker get usageTracker => managerSetup.usageTracker;

  /// Access Control Manager への参照
  MockSubscriptionAccessControlManager get accessControlManager =>
      managerSetup.accessControlManager;

  /// 現在のサブスクリプション状態への参照
  SubscriptionStatus get currentStatus => managerSetup.status;

  // =================================================================
  // 状態変更メソッド
  // =================================================================

  /// プランを変更
  void changePlan(Plan newPlan) {
    statusManager.setCurrentPlan(newPlan);

    if (newPlan.isPremium) {
      accessControlManager.createPremiumFullAccessState();
    } else {
      accessControlManager.createBasicRestrictedState();
    }
  }

  /// 使用量を設定
  void setUsageCount(int count) {
    usageTracker.setMonthlyUsage(count);
  }

  /// エラーシナリオを有効化
  void enableErrors([String? message]) {
    managerSetup.enableAllErrors(message);
  }

  /// エラーシナリオを無効化
  void disableErrors() {
    managerSetup.disableAllErrors();
  }

  /// 状態をリセット
  void reset() {
    managerSetup.resetAll();
  }

  // =================================================================
  // リソース管理
  // =================================================================

  /// リソースを破棄
  Future<void> dispose() async {
    await managerSetup.dispose();

    if (!_disposer.isCompleted) {
      _disposer.complete();
    }
  }

  /// 自動破棄の登録
  /// テストが終了すると自動的にdisposeが呼ばれる
  void registerAutoDispose() {
    // すでに登録済み（コンストラクタで実行）
  }
}

/// Mock Service の自動セットアップを提供するミックスイン
mixin UnifiedTestMixin {
  late UnifiedTestContext testContext;

  /// テストコンテキストを初期化（Basic プラン）
  void initializeBasicPlanContext({int usageCount = 0}) {
    testContext = UnifiedTestSetup.createBasicPlanSetup(usageCount: usageCount);
  }

  /// テストコンテキストを初期化（Premium プラン）
  void initializePremiumPlanContext({
    bool isYearly = true,
    int usageCount = 0,
  }) {
    testContext = UnifiedTestSetup.createPremiumPlanSetup(
      isYearly: isYearly,
      usageCount: usageCount,
    );
  }

  /// テストコンテキストを初期化（カスタム）
  void initializeCustomContext({
    required Plan plan,
    required SubscriptionStatus status,
  }) {
    testContext = UnifiedTestSetup.createCustomSetup(
      plan: plan,
      status: status,
    );
  }

  /// テストコンテキストを破棄
  Future<void> disposeTestContext() async {
    await testContext.dispose();
  }
}
