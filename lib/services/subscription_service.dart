import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/environment_config.dart';
import 'interfaces/subscription_service_interface.dart';
import 'logging_service.dart';
import 'subscription_purchase_manager.dart';
import 'subscription_status_manager.dart';
import 'subscription_usage_tracker.dart';

/// SubscriptionService
///
/// サブスクリプション機能を管理するサービスクラス
/// Hiveを使用してローカルでサブスクリプション状態を管理し、
/// in_app_purchaseとの統合によりアプリ内課金機能を提供する
///
/// ## 主な機能
/// - サブスクリプション状態の管理
/// - AI生成回数の制限管理
/// - プラン別機能制限の判定
/// - 月次使用量リセット処理
///
/// ## 設計方針
/// - シングルトンパターンによるインスタンス管理
/// - Result<T>パターンによる関数型エラーハンドリング
/// - Hiveによる永続化でオフライン対応
/// - 将来のin_app_purchase統合準備
///
/// ## 実装状況
/// - Phase 1.3.1: 基本構造とシングルトンパターン ✅
/// - Phase 1.3.2: Hive操作実装 ✅
/// - Phase 1.3.3: 使用量管理機能 ✅
/// - Phase 1.3.4: アクセス権限チェック ✅
class SubscriptionService implements ISubscriptionService {
  // シングルトンインスタンス
  static SubscriptionService? _instance;

  // Hiveボックス
  Box<SubscriptionStatus>? _subscriptionBox;

  // 初期化フラグ
  bool _isInitialized = false;

  // ロギングサービス
  LoggingService? _loggingService;

  // Purchase Manager（新しい購入管理コンポーネント）
  SubscriptionPurchaseManager? _purchaseManager;

  // Status Manager（新しいステータス管理コンポーネント）
  SubscriptionStatusManager? _statusManager;

  // Usage Tracker（新しい使用量追跡コンポーネント）
  SubscriptionUsageTracker? _usageTracker;

  // プライベートコンストラクタ
  SubscriptionService._();

  /// シングルトンインスタンスを取得
  ///
  /// 初回呼び出し時に自動的に初期化処理を実行
  /// エラーが発生した場合は例外をスロー
  static Future<SubscriptionService> getInstance() async {
    if (_instance == null) {
      _instance = SubscriptionService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// サービス初期化処理
  ///
  /// Hiveボックスの初期化と初期データ作成を実行
  /// 既に初期化済みの場合は何もしない
  Future<void> _initialize() async {
    if (_isInitialized) {
      _log('SubscriptionService already initialized', level: LogLevel.debug);
      return;
    }

    try {
      _log('Initializing SubscriptionService...', level: LogLevel.info);

      // LoggingServiceを取得
      _loggingService = await LoggingService.getInstance();

      // Hiveボックスを開く
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName,
      );

      // 初期状態の作成（まだ状態が存在しない場合）
      await _ensureInitialStatus();

      // Purchase Manager初期化
      await _initializePurchaseManager();

      // Status Manager初期化
      await _initializeStatusManager();

      // Usage Tracker初期化
      await _initializeUsageTracker();

      _isInitialized = true;
      _log(
        'SubscriptionService initialization completed successfully',
        level: LogLevel.info,
      );
    } catch (e) {
      final errorContext = 'SubscriptionService._initialize';
      _log(
        'SubscriptionService initialization failed',
        level: LogLevel.error,
        error: e,
        context: errorContext,
      );

      // ErrorHandlerを使用して適切な例外に変換
      throw ErrorHandler.handleError(e, context: errorContext);
    }
  }

  /// 初期サブスクリプション状態の確保
  ///
  /// サブスクリプション状態が存在しない場合、
  /// Basicプランの初期状態を作成する
  Future<void> _ensureInitialStatus() async {
    const statusKey = SubscriptionConstants.statusKey;

    if (_subscriptionBox?.get(statusKey) == null) {
      _log(
        'Creating initial Basic plan status',
        level: LogLevel.info,
        context: 'SubscriptionService._ensureInitialStatus',
      );

      final initialStatus = SubscriptionStatus(
        planId: BasicPlan().id,
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: null, // Basicプランは期限なし
        autoRenewal: false,
        monthlyUsageCount: 0,
        lastResetDate: DateTime.now(),
        transactionId: null,
        lastPurchaseDate: null,
      );

      await _subscriptionBox?.put(statusKey, initialStatus);
      _log(
        'Initial status created successfully',
        level: LogLevel.info,
        context: 'SubscriptionService._ensureInitialStatus',
      );
    } else {
      _log(
        'Existing status found, skipping creation',
        level: LogLevel.debug,
        context: 'SubscriptionService._ensureInitialStatus',
      );
    }
  }

  /// Purchase Manager初期化処理
  Future<void> _initializePurchaseManager() async {
    try {
      _log('Initializing PurchaseManager...', level: LogLevel.info);

      // Purchase Managerインスタンスを作成
      _purchaseManager = SubscriptionPurchaseManager(
        onSubscriptionStatusUpdate: (newStatus) async {
          // サブスクリプション状態更新のコールバック
          const statusKey = SubscriptionConstants.statusKey;
          await _subscriptionBox?.put(statusKey, newStatus);
          _log(
            'Subscription status updated via PurchaseManager',
            level: LogLevel.info,
            context: 'SubscriptionService._initializePurchaseManager',
          );
        },
      );

      // Purchase Managerを初期化
      final result = await _purchaseManager!.initialize(_loggingService!);
      if (result.isFailure) {
        _log(
          'PurchaseManager initialization failed',
          level: LogLevel.error,
          error: result.error,
          context: 'SubscriptionService._initializePurchaseManager',
        );
        // Purchase Manager初期化失敗は致命的エラーではない
        _purchaseManager = null;
      } else {
        _log(
          'PurchaseManager initialization completed',
          level: LogLevel.info,
          context: 'SubscriptionService._initializePurchaseManager',
        );
      }
    } catch (e) {
      _log(
        'Unexpected error during PurchaseManager initialization',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService._initializePurchaseManager',
      );
      _purchaseManager = null;
    }
  }

  /// Status Manager初期化処理
  Future<void> _initializeStatusManager() async {
    try {
      _log('Initializing StatusManager...', level: LogLevel.info);

      // Status Managerインスタンスを作成（依存性注入）
      _statusManager = SubscriptionStatusManager(
        _subscriptionBox!,
        _loggingService!,
      );

      _log(
        'StatusManager initialization completed',
        level: LogLevel.info,
        context: 'SubscriptionService._initializeStatusManager',
      );
    } catch (e) {
      _log(
        'Unexpected error during StatusManager initialization',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService._initializeStatusManager',
      );
      throw ServiceException(
        'Failed to initialize StatusManager',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  /// Usage Tracker初期化処理
  Future<void> _initializeUsageTracker() async {
    try {
      _log('Initializing UsageTracker...', level: LogLevel.info);

      // Usage Trackerインスタンスを作成（依存性注入）
      _usageTracker = SubscriptionUsageTracker(
        _subscriptionBox!,
        _loggingService!,
      );

      _log(
        'UsageTracker initialization completed',
        level: LogLevel.info,
        context: 'SubscriptionService._initializeUsageTracker',
      );
    } catch (e) {
      _log(
        'Unexpected error during UsageTracker initialization',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService._initializeUsageTracker',
      );
      throw ServiceException(
        'Failed to initialize UsageTracker',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  // =================================================================
  // Hive操作メソッド（Phase 1.3.2）
  // =================================================================

  // =================================================================
  // プラン管理メソッド（Phase 1.4.1）
  // =================================================================

  /// 特定のプラン情報を取得（新Planクラス）
  @override
  Result<Plan> getPlanClass(String planId) {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return _statusManager!.getPlanClass(planId);
  }

  /// 現在のプランを取得（新Planクラス）
  @override
  Future<Result<Plan>> getCurrentPlanClass() async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.getCurrentPlanClass();
  }

  /// 現在のサブスクリプション状態を取得
  /// デバッグモードでプラン強制設定がある場合、実際のデータは変更せずに返り値のみプレミアムプランとして返します
  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.getCurrentStatus();
  }

  /// サブスクリプション状態を更新
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.updateStatus(status);
  }

  /// サブスクリプション状態をリロード（強制再読み込み）
  @override
  Future<Result<void>> refreshStatus() async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.refreshStatus();
  }

  /// 指定されたプランでサブスクリプション状態を作成（Planクラス版）
  Future<Result<SubscriptionStatus>> createStatusClass(Plan plan) async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.createStatus(plan);
  }

  /// サブスクリプション状態を削除（テスト用）
  @visibleForTesting
  Future<Result<void>> clearStatus() async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.clearStatus();
  }

  // =================================================================
  // 使用量管理メソッド（Phase 1.3.3）
  // =================================================================

  /// 残りAI生成回数を取得（インターフェース用エイリアス）
  @override
  Future<Result<int>> getRemainingGenerations() async {
    return await getRemainingAiGenerations();
  }

  /// 今月の使用量を取得
  @override
  Future<Result<int>> getMonthlyUsage() async {
    if (!_isInitialized || _usageTracker == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // UsageTrackerにデリゲート
    return await _usageTracker!.getMonthlyUsage();
  }

  /// 使用量を手動でリセット（管理者・テスト用）
  @override
  Future<Result<void>> resetUsage() async {
    if (!_isInitialized || _usageTracker == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // UsageTrackerにデリゲート
    return await _usageTracker!.resetUsage();
  }

  /// AI生成を使用できるかどうかをチェック
  @override
  Future<Result<bool>> canUseAiGeneration() async {
    if (!_isInitialized || _usageTracker == null || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // 現在の状態を取得
    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;

    // UsageTrackerにデリゲート（有効性チェック関数を渡す）
    return await _usageTracker!.canUseAiGeneration(
      status,
      (status) => _statusManager!.isSubscriptionValid(status),
    );
  }

  /// AI生成使用量をインクリメント
  @override
  Future<Result<void>> incrementAiUsage() async {
    if (!_isInitialized || _usageTracker == null || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // 現在の状態を取得
    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;

    // UsageTrackerにデリゲート（有効性チェック関数を渡す）
    return await _usageTracker!.incrementAiUsage(
      status,
      (status) => _statusManager!.isSubscriptionValid(status),
    );
  }

  /// 月次使用量リセットが必要かチェックしてリセット
  @override
  Future<void> resetMonthlyUsageIfNeeded() async {
    if (!_isInitialized || _usageTracker == null) {
      return; // 内部メソッドのため、エラーは無視して継続
    }

    try {
      // UsageTrackerにデリゲート
      final result = await _usageTracker!.resetMonthlyUsageIfNeeded();
      if (result.isFailure) {
        _log(
          'UsageTracker resetMonthlyUsageIfNeeded failed',
          level: LogLevel.warning,
          error: result.error,
        );
      }
    } catch (e) {
      _log(
        'Error in resetMonthlyUsageIfNeeded delegation',
        level: LogLevel.error,
        error: e,
      );
      // このメソッドは内部的に呼ばれるため、エラーは基本的に無視
    }
  }

  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingAiGenerations() async {
    if (!_isInitialized || _usageTracker == null || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // UsageTrackerにデリゲート（有効性チェック関数を渡す）
    return await _usageTracker!.getRemainingGenerations(
      (status) => _statusManager!.isSubscriptionValid(status),
    );
  }

  /// 次の使用量リセット日を取得
  @override
  Future<Result<DateTime>> getNextResetDate() async {
    if (!_isInitialized || _usageTracker == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // UsageTrackerにデリゲート
    return await _usageTracker!.getNextResetDate();
  }


  // =================================================================
  // アクセス権限チェックメソッド（Phase 1.3.4）
  // =================================================================

  /// プレミアム機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    if (!_isInitialized || _statusManager == null) {
      return Failure(
        ServiceException('SubscriptionService is not initialized'),
      );
    }

    // StatusManagerにデリゲート
    return await _statusManager!.canAccessPremiumFeatures();
  }

  /// ライティングプロンプト機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessWritingPrompts() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      // デバッグモードでプラン強制設定をチェック
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        if (forcePlan != null) {
          _log(
            'プラン強制設定により Writing Prompts アクセス: true',
            level: LogLevel.debug,
            context: 'SubscriptionService.canAccessWritingPrompts',
            data: {'plan': forcePlan},
          );
          return const Success(true); // 全プランでライティングプロンプトは利用可能
        }
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // ライティングプロンプトは全プランで利用可能（Basicは限定版）
      if (currentPlan is BasicPlan) {
        _log(
          'Writing prompts access - Basic plan (limited prompts)',
          level: LogLevel.debug,
          context: 'SubscriptionService.canAccessWritingPrompts',
        );
        return const Success(true); // Basicプランでも基本プロンプトは利用可能
      }

      // Premiumプランの場合
      final isPremiumValid = _statusManager!.isSubscriptionValid(status);
      if (isPremiumValid) {
        // 有効なPremiumプランは全プロンプトにアクセス可能
        _log(
          'Writing prompts access - Premium plan',
          level: LogLevel.debug,
          context: 'SubscriptionService.canAccessWritingPrompts',
          data: {'valid': isPremiumValid},
        );
        return const Success(true);
      } else {
        // 期限切れ・非アクティブなPremiumプランでも基本プロンプトアクセスは可能
        _log(
          'Writing prompts access - Premium plan expired/inactive, basic access only',
          level: LogLevel.debug,
          context: 'SubscriptionService.canAccessWritingPrompts',
        );
        return const Success(true);
      }
    } catch (e) {
      _log(
        'Error checking writing prompts access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.canAccessWritingPrompts',
      );
      return Failure(
        ServiceException(
          'Failed to check writing prompts access',
          details: e.toString(),
        ),
      );
    }
  }

  /// 高度なフィルタ機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessAdvancedFilters() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // 高度なフィルタはPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = _statusManager!.isSubscriptionValid(status);
      _log(
        'Advanced filters access check',
        level: LogLevel.debug,
        context: 'SubscriptionService.canAccessAdvancedFilters',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      _log(
        'Error checking advanced filters access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.canAccessAdvancedFilters',
      );
      return Failure(
        ServiceException(
          'Failed to check advanced filters access',
          details: e.toString(),
        ),
      );
    }
  }

  /// データエクスポート機能にアクセスできるかどうか
  Future<Result<bool>> canAccessDataExport() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // データエクスポートは全プランで利用可能（Basicは基本形式のみ）
      if (currentPlan is BasicPlan) {
        _log(
          'Data export access - Basic plan (JSON only)',
          level: LogLevel.debug,
          context: 'SubscriptionService.canAccessDataExport',
        );
        return const Success(true); // BasicプランでもJSON形式は利用可能
      }

      // Premiumプランは複数形式でエクスポート可能
      final isPremiumValid = _statusManager!.isSubscriptionValid(status);
      _log(
        'Data export access - Premium plan',
        level: LogLevel.debug,
        context: 'SubscriptionService.canAccessDataExport',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      _log(
        'Error checking data export access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.canAccessDataExport',
      );
      return Failure(
        ServiceException(
          'Failed to check data export access',
          details: e.toString(),
        ),
      );
    }
  }

  /// 統計ダッシュボード機能にアクセスできるかどうか
  Future<Result<bool>> canAccessStatsDashboard() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // 統計ダッシュボードはPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = _statusManager!.isSubscriptionValid(status);
      _log(
        'Stats dashboard access check',
        level: LogLevel.debug,
        context: 'SubscriptionService.canAccessStatsDashboard',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      _log(
        'Error checking stats dashboard access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.canAccessStatsDashboard',
      );
      return Failure(
        ServiceException(
          'Failed to check stats dashboard access',
          details: e.toString(),
        ),
      );
    }
  }

  /// プラン別の機能制限情報を取得
  Future<Result<Map<String, bool>>> getFeatureAccess() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final premiumFeaturesResult = await canAccessPremiumFeatures();
      final writingPromptsResult = await canAccessWritingPrompts();
      final advancedFiltersResult = await canAccessAdvancedFilters();
      final dataExportResult = await canAccessDataExport();
      final statsDashboardResult = await canAccessStatsDashboard();

      if (premiumFeaturesResult.isFailure)
        return Failure(premiumFeaturesResult.error);
      if (writingPromptsResult.isFailure)
        return Failure(writingPromptsResult.error);
      if (advancedFiltersResult.isFailure)
        return Failure(advancedFiltersResult.error);
      if (dataExportResult.isFailure) return Failure(dataExportResult.error);
      if (statsDashboardResult.isFailure)
        return Failure(statsDashboardResult.error);

      final featureAccess = {
        'premiumFeatures': premiumFeaturesResult.value,
        'writingPrompts': writingPromptsResult.value,
        'advancedFilters': advancedFiltersResult.value,
        'dataExport': dataExportResult.value,
        'statsDashboard': statsDashboardResult.value,
      };

      _log(
        'Feature access map generated',
        level: LogLevel.debug,
        context: 'SubscriptionService.getFeatureAccess',
        data: featureAccess,
      );
      return Success(featureAccess);
    } catch (e) {
      _log(
        'Error getting feature access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.getFeatureAccess',
      );
      return Failure(
        ServiceException('Failed to get feature access', details: e.toString()),
      );
    }
  }

  /// 高度な分析にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessAdvancedAnalytics() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // 高度な分析はPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = _statusManager!.isSubscriptionValid(status);
      _log(
        'Advanced analytics access check',
        level: LogLevel.debug,
        context: 'SubscriptionService.canAccessAdvancedAnalytics',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      _log(
        'Error checking advanced analytics access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.canAccessAdvancedAnalytics',
      );
      return Failure(
        ServiceException(
          'Failed to check advanced analytics access',
          details: e.toString(),
        ),
      );
    }
  }

  /// 優先サポートにアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessPrioritySupport() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // 優先サポートはPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = _statusManager!.isSubscriptionValid(status);
      _log(
        'Priority support access check',
        level: LogLevel.debug,
        context: 'SubscriptionService.canAccessPrioritySupport',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      _log(
        'Error checking priority support access',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.canAccessPrioritySupport',
      );
      return Failure(
        ServiceException(
          'Failed to check priority support access',
          details: e.toString(),
        ),
      );
    }
  }

  // =================================================================
  // サービスのライフサイクル管理
  // =================================================================

  // =================================================================
  // インターフェース実装完了 - ServiceLocator統合用
  // =================================================================

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<Result<void>> initialize() async {
    try {
      await _initialize();
      return const Success(null);
    } catch (e) {
      _log(
        'Error in public initialize',
        level: LogLevel.error,
        error: e,
        context: 'SubscriptionService.initialize',
      );
      return Failure(
        ServiceException('Failed to initialize service', details: e.toString()),
      );
    }
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// Hiveボックス取得（テスト用）
  @visibleForTesting
  Box<SubscriptionStatus>? get subscriptionBox => _subscriptionBox;

  // =================================================================
  // Phase 1.4.2: エラーハンドリング統合
  // =================================================================

  /// 統一ログ出力メソッド
  ///
  /// LoggingServiceが利用可能な場合は構造化ログを使用し、
  /// 利用不可の場合はdebugPrintにフォールバック
  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final logContext = context ?? 'SubscriptionService';

    if (_loggingService != null) {
      // 構造化ログを使用
      switch (level) {
        case LogLevel.debug:
          _loggingService!.debug(message, context: logContext, data: data);
          break;
        case LogLevel.info:
          _loggingService!.info(message, context: logContext, data: data);
          break;
        case LogLevel.warning:
          _loggingService!.warning(message, context: logContext, data: data);
          break;
        case LogLevel.error:
          _loggingService!.error(message, context: logContext, error: data);
          break;
      }

      // エラーオブジェクトがある場合は追加ログ
      if (error != null) {
        _loggingService!.error('Error details: $error', context: logContext);
      }
    } else {
      // フォールバックとしてdebugPrintを使用
      final prefix = level == LogLevel.error
          ? 'ERROR'
          : level == LogLevel.warning
          ? 'WARNING'
          : level == LogLevel.debug
          ? 'DEBUG'
          : 'INFO';

      debugPrint('[$prefix] $logContext: $message');
      if (error != null) {
        debugPrint('[$prefix] $logContext: Error - $error');
      }
    }
  }

  /// Result<T>パターンでのエラーハンドリングヘルパー
  ///
  /// 例外をキャッチし、適切なServiceExceptionとFailureに変換
  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'SubscriptionService.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    _log(message, level: LogLevel.error, error: error, context: errorContext);

    // ErrorHandlerを使用して適切な例外に変換
    final handledException = ErrorHandler.handleError(
      error,
      context: errorContext,
    );

    // ServiceExceptionに変換
    final serviceException = handledException is ServiceException
        ? handledException
        : ServiceException(
            'Failed to $operation',
            details: details ?? error.toString(),
            originalError: error,
          );

    return Failure(serviceException);
  }

  // =================================================================
  // 購入機能（Purchase Manager統合済み）
  // =================================================================

  // =================================================================
  // Phase 1.6.2.1: 商品情報取得実装
  // =================================================================

  @override
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_purchaseManager == null) {
        return Failure(ServiceException('Purchase Manager not available'));
      }

      // Purchase Managerに委譲
      return await _purchaseManager!.getProducts();
    } catch (e) {
      return _handleError(e, 'getProducts');
    }
  }

  // =================================================================
  // Phase 1.6.2.2: 購入フロー実装
  // =================================================================

  // =================================================================
  // Phase 1.6.2.3: 購入状態監視実装
  // =================================================================

  @override
  Stream<PurchaseResult> get purchaseStream => 
      _purchaseManager?.purchaseStream ?? const Stream.empty();

  /// サブスクリプション状態変更を監視
  @override
  Stream<SubscriptionStatus> get statusStream {
    // 現在は基本的な実装のみ
    // 将来的にはリアルタイム更新を追加予定
    return Stream.periodic(const Duration(minutes: 5), (_) async {
          final statusResult = await getCurrentStatus();
          return statusResult.isSuccess ? statusResult.value : null;
        })
        .asyncMap((statusFuture) => statusFuture)
        .where((status) => status != null)
        .cast<SubscriptionStatus>();
  }

  // =================================================================
  // Phase 1.6.2.4: 復元機能実装
  // =================================================================

  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_purchaseManager == null) {
        return Failure(ServiceException('Purchase Manager not available'));
      }

      // Purchase Managerに委譲
      return await _purchaseManager!.restorePurchases();
    } catch (e) {
      return _handleError(e, 'restorePurchases');
    }
  }

  @override
  Future<Result<bool>> validatePurchase(String transactionId) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_purchaseManager == null) {
        return Failure(ServiceException('Purchase Manager not available'));
      }

      // Purchase Managerに委譲
      return await _purchaseManager!.validatePurchase(
        transactionId,
        getCurrentStatus,
      );
    } catch (e) {
      return _handleError(e, 'validatePurchase', details: transactionId);
    }
  }

  /// プランを購入（新Planクラス）
  @override
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_purchaseManager == null) {
        return Failure(ServiceException('Purchase Manager not available'));
      }

      // Purchase Managerに委譲
      return await _purchaseManager!.purchasePlanClass(plan);
    } catch (e) {
      return _handleError(
        e,
        'purchasePlanClass',
        details: 'planId: ${plan.id}',
      );
    }
  }

  /// プランを変更（新Planクラス）
  @override
  Future<Result<void>> changePlanClass(Plan newPlan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_purchaseManager == null) {
        return Failure(ServiceException('Purchase Manager not available'));
      }

      // Purchase Managerに委譲
      return await _purchaseManager!.changePlanClass(newPlan);
    } catch (e) {
      return _handleError(e, 'changePlanClass', details: newPlan.id);
    }
  }

  @override
  Future<Result<void>> cancelSubscription() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_purchaseManager == null) {
        return Failure(ServiceException('Purchase Manager not available'));
      }

      // Purchase Managerに委譲（ヘルパー関数を渡す）
      return await _purchaseManager!.cancelSubscription(
        getCurrentStatus,
        (updatedStatus) async {
          const statusKey = SubscriptionConstants.statusKey;
          await _subscriptionBox?.put(statusKey, updatedStatus);
        },
      );
    } catch (e) {
      return _handleError(e, 'cancelSubscription');
    }
  }

  /// サービス破棄処理
  @override
  Future<void> dispose() async {
    _log('Disposing SubscriptionService...', level: LogLevel.info);

    // Purchase Managerの破棄
    if (_purchaseManager != null) {
      await _purchaseManager!.dispose();
      _purchaseManager = null;
    }

    // Status Managerの破棄
    if (_statusManager != null) {
      _statusManager!.dispose();
      _statusManager = null;
    }

    // Usage Trackerの破棄
    if (_usageTracker != null) {
      _usageTracker!.dispose();
      _usageTracker = null;
    }

    _log('SubscriptionService disposed', level: LogLevel.info);
  }

  /// テスト用リセットメソッド
  static void resetForTesting() {
    _instance?._purchaseManager?.dispose();
    _instance?._statusManager?.dispose();
    _instance?._usageTracker?.dispose();
    _instance = null;
  }
}
