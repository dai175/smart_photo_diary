import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/in_app_purchase_config.dart';
import '../config/environment_config.dart';
import 'interfaces/subscription_service_interface.dart';
import 'logging_service.dart';

// 型エイリアスで名前衝突を解決
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'interfaces/subscription_service_interface.dart' as ssi;

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

  // In-App Purchase関連
  InAppPurchase? _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // 購入状態ストリーム
  final StreamController<PurchaseResult> _purchaseStreamController =
      StreamController<PurchaseResult>.broadcast();

  // 購入処理中フラグ
  bool _isPurchasing = false;

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

      // In-App Purchase初期化
      await _initializeInAppPurchase();

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
      debugPrint('SubscriptionService: Creating initial Basic plan status');

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
      debugPrint('SubscriptionService: Initial status created successfully');
    } else {
      debugPrint(
        'SubscriptionService: Existing status found, skipping creation',
      );
    }
  }

  // =================================================================
  // Hive操作メソッド（Phase 1.3.2）
  // =================================================================

  // =================================================================
  // プラン管理メソッド（Phase 1.4.1）
  // =================================================================

  // getAvailablePlansメソッドも削除（非推奨のため）

  // 非推奨メソッドはインターフェースから削除されたため、実装も削除

  // getCurrentPlanメソッドも削除（非推奨のため）

  /// 特定のプラン情報を取得（新Planクラス）
  @override
  Result<Plan> getPlanClass(String planId) {
    try {
      _log(
        'Getting plan class by ID',
        level: LogLevel.debug,
        data: {'planId': planId},
      );

      final plan = PlanFactory.createPlan(planId);

      _log(
        'Successfully retrieved plan class',
        level: LogLevel.debug,
        data: {'planId': plan.id, 'displayName': plan.displayName},
      );

      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getPlanClass', details: 'planId: $planId');
    }
  }

  /// 現在のプランを取得（新Planクラス）
  @override
  Future<Result<Plan>> getCurrentPlanClass() async {
    try {
      _log('Getting current plan class', level: LogLevel.debug);

      if (!_isInitialized) {
        return _handleError(
          StateError('Service not initialized'),
          'getCurrentPlanClass',
          details: 'SubscriptionService must be initialized before use',
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        _log(
          'Failed to get current status',
          level: LogLevel.warning,
          error: statusResult.error,
        );
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final plan = PlanFactory.createPlan(status.planId);

      _log(
        'Successfully retrieved current plan class',
        level: LogLevel.debug,
        data: {'planId': plan.id, 'displayName': plan.displayName},
      );

      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getCurrentPlanClass');
    }
  }

  /// 現在のサブスクリプション状態を取得
  /// デバッグモードでプラン強制設定がある場合、実際のデータは変更せずに返り値のみプレミアムプランとして返します
  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      // 実際のデータベース状態を取得
      final status = _subscriptionBox?.get(SubscriptionConstants.statusKey);
      if (status == null) {
        // 状態が存在しない場合は初期状態を作成
        await _ensureInitialStatus();
        final initialStatus = _subscriptionBox?.get(
          SubscriptionConstants.statusKey,
        );
        if (initialStatus == null) {
          return Failure(
            ServiceException('Failed to create initial subscription status'),
          );
        }
        return Success(initialStatus);
      }

      // デバッグモードでプラン強制設定がある場合、返り値のみを動的に変更
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        if (forcePlan != null) {
          debugPrint(
            'SubscriptionService.getCurrentStatus: プラン強制設定 - 返り値を$forcePlanとして返却（データベースは変更せず）',
          );

          // 実際のデータはそのままで、プランIDのみを強制設定に変更した状態を返す
          final forcedPlanId = _getForcedPlanId(forcePlan);
          final forcedPlan = PlanFactory.createPlan(forcedPlanId);

          // プランに応じて適切な有効期限を設定
          final expiryDuration =
              forcedPlan.id == SubscriptionConstants.premiumYearlyPlanId
              ? const Duration(days: 365)
              : const Duration(days: 30);

          final forcedStatus = SubscriptionStatus(
            planId: forcedPlanId,
            isActive: true,
            startDate: status.startDate ?? DateTime.now(),
            expiryDate: DateTime.now().add(expiryDuration),
            monthlyUsageCount: status.monthlyUsageCount, // 実際の使用量を保持
            usageMonth: status.usageMonth,
            lastResetDate: status.lastResetDate,
            autoRenewal: status.autoRenewal,
            transactionId: status.transactionId,
            lastPurchaseDate: status.lastPurchaseDate,
            cancelDate: status.cancelDate,
            planChangeDate: status.planChangeDate,
            pendingPlanId: status.pendingPlanId,
          );

          return Success(forcedStatus);
        }
      }

      return Success(status);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting current status - $e');
      return Failure(
        ServiceException('Failed to get current status', details: e.toString()),
      );
    }
  }

  /// サブスクリプション状態を更新
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, status);
      debugPrint('SubscriptionService: Status updated successfully');
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error updating status - $e');
      return Failure(
        ServiceException('Failed to update status', details: e.toString()),
      );
    }
  }

  /// サブスクリプション状態をリロード（強制再読み込み）
  @override
  Future<Result<void>> refreshStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      // Hiveボックスを再読み込み
      await _subscriptionBox?.close();
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName,
      );

      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error refreshing status - $e');
      return Failure(
        ServiceException('Failed to refresh status', details: e.toString()),
      );
    }
  }

  /// 指定されたプランでサブスクリプション状態を作成（Planクラス版）
  Future<Result<SubscriptionStatus>> createStatusClass(Plan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final now = DateTime.now();
      SubscriptionStatus newStatus;

      if (plan is BasicPlan) {
        // Basicプランの場合
        newStatus = SubscriptionStatus(
          planId: plan.id,
          isActive: true,
          startDate: now,
          expiryDate: null, // Basicプランは期限なし
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: null,
          lastPurchaseDate: null,
        );
      } else {
        // Premiumプランの場合
        final expiryDate = plan.isYearly
            ? now.add(
                Duration(days: SubscriptionConstants.subscriptionYearDays),
              )
            : now.add(
                Duration(days: SubscriptionConstants.subscriptionMonthDays),
              );

        newStatus = SubscriptionStatus(
          planId: plan.id,
          isActive: true,
          startDate: now,
          expiryDate: expiryDate,
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: null,
          lastPurchaseDate: now,
        );
      }

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, newStatus);
      debugPrint(
        'SubscriptionService: Created new status for plan: ${plan.id}',
      );
      return Success(newStatus);
    } catch (e) {
      debugPrint('SubscriptionService: Error creating status - $e');
      return Failure(
        ServiceException('Failed to create status', details: e.toString()),
      );
    }
  }

  /// 指定されたプランでサブスクリプション状態を作成（enumベース・互換性のため維持）
  Future<Result<SubscriptionStatus>> createStatus(SubscriptionPlan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      final now = DateTime.now();
      SubscriptionStatus newStatus;

      // Planクラスを使用して判定
      final planClass = PlanFactory.createPlan(plan.id);

      if (planClass is BasicPlan) {
        // Basicプランの場合
        newStatus = SubscriptionStatus(
          planId: plan.id,
          isActive: true,
          startDate: now,
          expiryDate: null, // Basicプランは期限なし
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: null,
          lastPurchaseDate: null,
        );
      } else {
        // Premiumプランの場合
        final expiryDate = plan.id == SubscriptionConstants.premiumYearlyPlanId
            ? now.add(
                Duration(days: SubscriptionConstants.subscriptionYearDays),
              )
            : now.add(
                Duration(days: SubscriptionConstants.subscriptionMonthDays),
              );

        newStatus = SubscriptionStatus(
          planId: plan.id,
          isActive: true,
          startDate: now,
          expiryDate: expiryDate,
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: null,
          lastPurchaseDate: now,
        );
      }

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, newStatus);
      debugPrint(
        'SubscriptionService: Created new status for plan: ${plan.id}',
      );
      return Success(newStatus);
    } catch (e) {
      debugPrint('SubscriptionService: Error creating status - $e');
      return Failure(
        ServiceException('Failed to create status', details: e.toString()),
      );
    }
  }

  /// サブスクリプション状態を削除（テスト用）
  @visibleForTesting
  Future<Result<void>> clearStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      await _subscriptionBox?.delete(SubscriptionConstants.statusKey);
      debugPrint('SubscriptionService: Status cleared');
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error clearing status - $e');
      return Failure(
        ServiceException('Failed to clear status', details: e.toString()),
      );
    }
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
      return Success(status.monthlyUsageCount);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting monthly usage - $e');
      return Failure(
        ServiceException('Failed to get monthly usage', details: e.toString()),
      );
    }
  }

  /// 使用量を手動でリセット（管理者・テスト用）
  @override
  Future<Result<void>> resetUsage() async {
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
      final resetStatus = SubscriptionStatus(
        planId: status.planId,
        isActive: status.isActive,
        startDate: status.startDate,
        expiryDate: status.expiryDate,
        autoRenewal: status.autoRenewal,
        monthlyUsageCount: 0, // リセット
        lastResetDate: DateTime.now(),
        transactionId: status.transactionId,
        lastPurchaseDate: status.lastPurchaseDate,
      );

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, resetStatus);
      debugPrint('SubscriptionService: Usage manually reset');

      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error resetting usage - $e');
      return Failure(
        ServiceException('Failed to reset usage', details: e.toString()),
      );
    }
  }

  /// AI生成を使用できるかどうかをチェック
  @override
  Future<Result<bool>> canUseAiGeneration() async {
    try {
      _log('Checking AI generation usage availability', level: LogLevel.debug);

      if (!_isInitialized) {
        return _handleError(
          StateError('Service not initialized'),
          'canUseAiGeneration',
          details: 'SubscriptionService must be initialized before use',
        );
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;

      // サブスクリプションが有効でない場合は使用不可
      if (!_isSubscriptionValid(status)) {
        _log(
          'Subscription is not valid - AI generation unavailable',
          level: LogLevel.warning,
          data: {'planId': status.planId, 'isActive': status.isActive},
        );
        return const Success(false);
      }

      // 月次使用量をリセット（必要に応じて）
      await _resetMonthlyUsageIfNeeded(status);

      // 更新された状態を再取得
      final updatedStatusResult = await getCurrentStatus();
      if (updatedStatusResult.isFailure) {
        return Failure(updatedStatusResult.error);
      }

      final updatedStatus = updatedStatusResult.value;
      final currentPlan = PlanFactory.createPlan(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

      final canUse = updatedStatus.monthlyUsageCount < monthlyLimit;

      _log(
        'AI generation availability check completed',
        level: LogLevel.debug,
        data: {
          'usage': updatedStatus.monthlyUsageCount,
          'limit': monthlyLimit,
          'canUse': canUse,
          'planId': currentPlan.id,
        },
      );

      return Success(canUse);
    } catch (e) {
      return _handleError(e, 'canUseAiGeneration');
    }
  }

  /// AI生成使用量をインクリメント
  @override
  Future<Result<void>> incrementAiUsage() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      // 常に最新の状態を取得（プラン強制設定により更新済み）
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;

      // サブスクリプションが有効でない場合はインクリメント不可
      if (!_isSubscriptionValid(status)) {
        return Failure(
          ServiceException('Cannot increment usage: subscription is not valid'),
        );
      }

      // 使用量リセットをチェック
      await _resetMonthlyUsageIfNeeded(status);

      // 最新の状態を取得
      final latestStatusResult = await getCurrentStatus();
      if (latestStatusResult.isFailure) {
        return Failure(latestStatusResult.error);
      }

      final latestStatus = latestStatusResult.value;
      final currentPlan = PlanFactory.createPlan(latestStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

      // 制限チェック
      if (latestStatus.monthlyUsageCount >= monthlyLimit) {
        return Failure(
          ServiceException(
            'Monthly AI generation limit reached: ${latestStatus.monthlyUsageCount}/$monthlyLimit',
          ),
        );
      }

      // 使用量をインクリメント
      final updatedStatus = SubscriptionStatus(
        planId: latestStatus.planId,
        isActive: latestStatus.isActive,
        startDate: latestStatus.startDate,
        expiryDate: latestStatus.expiryDate,
        autoRenewal: latestStatus.autoRenewal,
        monthlyUsageCount: latestStatus.monthlyUsageCount + 1,
        lastResetDate: latestStatus.lastResetDate,
        transactionId: latestStatus.transactionId,
        lastPurchaseDate: latestStatus.lastPurchaseDate,
      );

      await _subscriptionBox?.put(
        SubscriptionConstants.statusKey,
        updatedStatus,
      );
      debugPrint(
        'SubscriptionService: AI usage incremented to ${updatedStatus.monthlyUsageCount}/$monthlyLimit',
      );

      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error incrementing AI usage - $e');
      return Failure(
        ServiceException('Failed to increment AI usage', details: e.toString()),
      );
    }
  }

  /// 月次使用量リセットが必要かチェックしてリセット
  @override
  Future<void> resetMonthlyUsageIfNeeded() async {
    try {
      if (!_isInitialized) {
        throw ServiceException('SubscriptionService is not initialized');
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final status = statusResult.value;
      await _resetMonthlyUsageIfNeeded(status);
    } catch (e) {
      debugPrint('SubscriptionService: Error resetting monthly usage - $e');
      // このメソッドは内部的に呼ばれるため、エラーは基本的に無視
      // 致命的でない場合は処理を継続
    }
  }

  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingAiGenerations() async {
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

      // サブスクリプションが有効でない場合は0
      if (!_isSubscriptionValid(status)) {
        return const Success(0);
      }

      // 月次使用量をリセット（必要に応じて）
      await _resetMonthlyUsageIfNeeded(status);

      // 更新された状態を再取得
      final updatedStatusResult = await getCurrentStatus();
      if (updatedStatusResult.isFailure) {
        return Failure(updatedStatusResult.error);
      }

      final updatedStatus = updatedStatusResult.value;
      final currentPlan = PlanFactory.createPlan(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      final remaining = monthlyLimit - updatedStatus.monthlyUsageCount;

      return Success(remaining > 0 ? remaining : 0);
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error getting remaining generations - $e',
      );
      return Failure(
        ServiceException(
          'Failed to get remaining generations',
          details: e.toString(),
        ),
      );
    }
  }

  /// 次の使用量リセット日を取得
  @override
  Future<Result<DateTime>> getNextResetDate() async {
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
      final nextResetDate = _calculateNextResetDate(status.lastResetDate);

      return Success(nextResetDate);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting next reset date - $e');
      return Failure(
        ServiceException(
          'Failed to get next reset date',
          details: e.toString(),
        ),
      );
    }
  }

  // =================================================================
  // 内部使用量管理ヘルパーメソッド
  // =================================================================

  /// サブスクリプションが有効かどうかをチェック
  bool _isSubscriptionValid(SubscriptionStatus status) {
    if (!status.isActive) return false;

    final currentPlan = PlanFactory.createPlan(status.planId);

    // Basicプランは常に有効
    if (currentPlan is BasicPlan) return true;

    // Premiumプランは有効期限をチェック
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }

  /// 月次使用量リセットが必要かチェックしてリセット（内部用）
  Future<void> _resetMonthlyUsageIfNeeded(SubscriptionStatus status) async {
    final now = DateTime.now();
    final currentMonth = _getCurrentMonth();
    final statusMonth = _getUsageMonth(status);

    if (statusMonth != currentMonth) {
      debugPrint(
        'SubscriptionService: Resetting monthly usage - previous month: $statusMonth, current: $currentMonth',
      );

      final resetStatus = SubscriptionStatus(
        planId: status.planId,
        isActive: status.isActive,
        startDate: status.startDate,
        expiryDate: status.expiryDate,
        autoRenewal: status.autoRenewal,
        monthlyUsageCount: 0, // リセット
        lastResetDate: now,
        transactionId: status.transactionId,
        lastPurchaseDate: status.lastPurchaseDate,
      );

      await _subscriptionBox?.put(SubscriptionConstants.statusKey, resetStatus);
    }
  }

  /// 現在の月を YYYY-MM 形式で取得
  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  /// SubscriptionStatusから使用量月を取得
  String _getUsageMonth(SubscriptionStatus status) {
    if (status.lastResetDate != null) {
      final resetDate = status.lastResetDate!;
      return '${resetDate.year.toString().padLeft(4, '0')}-${resetDate.month.toString().padLeft(2, '0')}';
    }
    // lastResetDateがnullの場合は現在月を返す
    return _getCurrentMonth();
  }

  /// 次のリセット日を計算
  DateTime _calculateNextResetDate(DateTime? lastResetDate) {
    final baseDate = lastResetDate ?? DateTime.now();
    final currentYear = baseDate.year;
    final currentMonth = baseDate.month;

    // 翌月の1日を計算
    if (currentMonth == 12) {
      return DateTime(currentYear + 1, 1, 1);
    } else {
      return DateTime(currentYear, currentMonth + 1, 1);
    }
  }

  /// 強制プラン名からプランIDを取得
  String _getForcedPlanId(String forcePlan) {
    switch (forcePlan.toLowerCase()) {
      case 'premium':
      case 'premium_monthly':
        return SubscriptionConstants.premiumMonthlyPlanId;
      case 'premium_yearly':
        return SubscriptionConstants.premiumYearlyPlanId;
      case 'basic':
      default:
        return SubscriptionConstants.basicPlanId;
    }
  }

  // =================================================================
  // アクセス権限チェックメソッド（Phase 1.3.4）
  // =================================================================

  /// プレミアム機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      // デバッグモードでプラン強制設定をチェック
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        debugPrint('SubscriptionService: デバッグモードチェック - forcePlan: $forcePlan');
        if (forcePlan != null) {
          final forceResult = forcePlan.startsWith('premium');
          debugPrint(
            'SubscriptionService: プラン強制設定により Premium アクセス: $forceResult (プラン: $forcePlan)',
          );
          return Success(forceResult);
        } else {
          debugPrint('SubscriptionService: プラン強制設定なし、通常のプランチェックに進む');
        }
      }

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final currentPlan = PlanFactory.createPlan(status.planId);

      // Basicプランは基本機能のみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      // Premiumプランは有効期限をチェック
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint(
        'SubscriptionService: Premium features access check - plan: ${currentPlan.id}, valid: $isPremiumValid',
      );

      return Success(isPremiumValid);
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error checking premium features access - $e',
      );
      return Failure(
        ServiceException(
          'Failed to check premium features access',
          details: e.toString(),
        ),
      );
    }
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
          debugPrint(
            'SubscriptionService: プラン強制設定により Writing Prompts アクセス: true (プラン: $forcePlan)',
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
        debugPrint(
          'SubscriptionService: Writing prompts access - Basic plan (limited prompts)',
        );
        return const Success(true); // Basicプランでも基本プロンプトは利用可能
      }

      // Premiumプランの場合
      final isPremiumValid = _isSubscriptionValid(status);
      if (isPremiumValid) {
        // 有効なPremiumプランは全プロンプトにアクセス可能
        debugPrint(
          'SubscriptionService: Writing prompts access - Premium plan, valid: $isPremiumValid',
        );
        return const Success(true);
      } else {
        // 期限切れ・非アクティブなPremiumプランでも基本プロンプトアクセスは可能
        debugPrint(
          'SubscriptionService: Writing prompts access - Premium plan expired/inactive, basic access only',
        );
        return const Success(true);
      }
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error checking writing prompts access - $e',
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

      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint(
        'SubscriptionService: Advanced filters access check - valid: $isPremiumValid',
      );

      return Success(isPremiumValid);
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error checking advanced filters access - $e',
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
        debugPrint(
          'SubscriptionService: Data export access - Basic plan (JSON only)',
        );
        return const Success(true); // BasicプランでもJSON形式は利用可能
      }

      // Premiumプランは複数形式でエクスポート可能
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint(
        'SubscriptionService: Data export access - Premium plan, valid: $isPremiumValid',
      );

      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking data export access - $e');
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

      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint(
        'SubscriptionService: Stats dashboard access check - valid: $isPremiumValid',
      );

      return Success(isPremiumValid);
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error checking stats dashboard access - $e',
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

      debugPrint('SubscriptionService: Feature access map - $featureAccess');
      return Success(featureAccess);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting feature access - $e');
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

      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint(
        'SubscriptionService: Advanced analytics access check - valid: $isPremiumValid',
      );

      return Success(isPremiumValid);
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error checking advanced analytics access - $e',
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

      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint(
        'SubscriptionService: Priority support access check - valid: $isPremiumValid',
      );

      return Success(isPremiumValid);
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error checking priority support access - $e',
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
      debugPrint('SubscriptionService: Error in public initialize - $e');
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
  // Phase 1.6.2: In-App Purchase機能実装
  // =================================================================

  /// In-App Purchase初期化処理
  Future<void> _initializeInAppPurchase() async {
    try {
      _log('Initializing In-App Purchase...', level: LogLevel.info);

      // テスト環境やbinding未初期化の場合のエラーハンドリング
      try {
        // シミュレーター環境での特別な処理
        if (kDebugMode && (defaultTargetPlatform == TargetPlatform.iOS)) {
          _log(
            'Running in iOS debug mode - checking simulator environment',
            level: LogLevel.debug,
          );
        }

        // In-App Purchase利用可能性チェック
        final bool isAvailable = await InAppPurchase.instance.isAvailable();
        if (!isAvailable) {
          _log(
            'In-App Purchase not available on this device',
            level: LogLevel.warning,
          );
          return;
        }

        _inAppPurchase = InAppPurchase.instance;

        // 購入ストリームの監視開始
        _purchaseSubscription = _inAppPurchase!.purchaseStream.listen(
          _onPurchaseUpdated,
          onError: _onPurchaseError,
          onDone: () =>
              _log('Purchase stream completed', level: LogLevel.debug),
        );

        _log('In-App Purchase initialization completed', level: LogLevel.info);
      } catch (bindingError) {
        // テスト環境でよくある binding 未初期化エラーをキャッチ
        final errorString = bindingError.toString();
        if (errorString.contains('Binding has not yet been initialized') ||
            errorString.contains('ServicesBinding')) {
          _log(
            'In-App Purchase not available (test/simulator environment)',
            level: LogLevel.warning,
          );
          return;
        }
        // その他のエラーは再スロー
        rethrow;
      }
    } catch (e) {
      _log(
        'Failed to initialize In-App Purchase',
        level: LogLevel.error,
        error: e,
      );
      _log('Error details: $e', level: LogLevel.error);
      // In-App Purchase初期化失敗は致命的エラーではない
    }
  }

  /// 購入状態更新ハンドラー
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _processPurchaseUpdate(purchaseDetails);
    }
  }

  /// 購入エラーハンドラー
  void _onPurchaseError(dynamic error) {
    _log('Purchase stream error', level: LogLevel.error, error: error);

    // エラー情報をストリームに送信
    final errorResult = PurchaseResult(
      status: ssi.PurchaseStatus.error,
      errorMessage: error.toString(),
    );
    _purchaseStreamController.add(errorResult);
  }

  /// 購入状態更新の処理
  Future<void> _processPurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Processing purchase update: ${purchaseDetails.status}',
        level: LogLevel.info,
      );

      switch (purchaseDetails.status) {
        case iap.PurchaseStatus.purchased:
          await _handlePurchaseCompleted(purchaseDetails);
          break;

        case iap.PurchaseStatus.restored:
          await _handlePurchaseRestored(purchaseDetails);
          break;

        case iap.PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails);
          break;

        case iap.PurchaseStatus.canceled:
          await _handlePurchaseCanceled(purchaseDetails);
          break;

        case iap.PurchaseStatus.pending:
          await _handlePurchasePending(purchaseDetails);
          break;
      }

      // 購入完了処理（プラットフォーム側への完了通知）
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase!.completePurchase(purchaseDetails);
        _log(
          'Purchase completion confirmed to platform',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      _log('Error processing purchase update', level: LogLevel.error, error: e);
    }
  }

  /// 購入完了処理
  Future<void> _handlePurchaseCompleted(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Purchase completed: ${purchaseDetails.productID}',
        level: LogLevel.info,
      );

      // 商品IDからプランを特定
      final plan = InAppPurchaseConfig.getSubscriptionPlan(
        purchaseDetails.productID,
      );

      // サブスクリプション状態を更新
      await _updateSubscriptionFromPurchase(purchaseDetails, plan);

      // 購入結果をストリームに送信
      final result = PurchaseResult(
        status: ssi.PurchaseStatus.purchased,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: plan,
      );
      _purchaseStreamController.add(result);

      _isPurchasing = false;
    } catch (e) {
      _log(
        'Error handling purchase completion',
        level: LogLevel.error,
        error: e,
      );
      await _handlePurchaseError(purchaseDetails);
    }
  }

  /// 購入復元処理
  Future<void> _handlePurchaseRestored(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Purchase restored: ${purchaseDetails.productID}',
        level: LogLevel.info,
      );

      // 復元の場合も購入完了と同様の処理
      await _handlePurchaseCompleted(purchaseDetails);

      // ストリームの状態を復元として更新
      final result = PurchaseResult(
        status: ssi.PurchaseStatus.restored,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: InAppPurchaseConfig.getSubscriptionPlan(
          purchaseDetails.productID,
        ),
      );
      _purchaseStreamController.add(result);
    } catch (e) {
      _log(
        'Error handling purchase restoration',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  /// 購入エラー処理
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase error: ${purchaseDetails.error?.message}',
      level: LogLevel.error,
    );

    final result = PurchaseResult(
      status: ssi.PurchaseStatus.error,
      productId: purchaseDetails.productID,
      errorMessage: purchaseDetails.error?.message ?? 'Unknown purchase error',
    );
    _purchaseStreamController.add(result);

    _isPurchasing = false;
  }

  /// 購入キャンセル処理
  Future<void> _handlePurchaseCanceled(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase canceled: ${purchaseDetails.productID}',
      level: LogLevel.info,
    );

    final result = PurchaseResult(
      status: ssi.PurchaseStatus.cancelled,
      productId: purchaseDetails.productID,
    );
    _purchaseStreamController.add(result);

    _isPurchasing = false;
  }

  /// 購入保留処理
  Future<void> _handlePurchasePending(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase pending: ${purchaseDetails.productID}',
      level: LogLevel.info,
    );

    final result = PurchaseResult(
      status: ssi.PurchaseStatus.pending,
      productId: purchaseDetails.productID,
    );
    _purchaseStreamController.add(result);
  }

  /// 購入からサブスクリプション状態を更新
  Future<void> _updateSubscriptionFromPurchase(
    PurchaseDetails purchaseDetails,
    SubscriptionPlan plan,
  ) async {
    try {
      final now = DateTime.now();

      // 有効期限を計算
      DateTime expiryDate;
      if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
        expiryDate = now.add(const Duration(days: 30));
      } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
        expiryDate = now.add(const Duration(days: 365));
      } else {
        // Basicプランは購入対象外
        throw ArgumentError('Basic plan cannot be purchased');
      }

      // 新しいサブスクリプション状態を作成
      final newStatus = SubscriptionStatus(
        planId: plan.id,
        isActive: true,
        startDate: now,
        expiryDate: expiryDate,
        autoRenewal: true,
        monthlyUsageCount: 0,
        lastResetDate: now,
        transactionId: purchaseDetails.purchaseID ?? '',
        lastPurchaseDate: now,
      );

      // Hiveに保存
      const statusKey = SubscriptionConstants.statusKey;
      await _subscriptionBox!.put(statusKey, newStatus);

      _log('Subscription status updated from purchase', level: LogLevel.info);
    } catch (e) {
      _log(
        'Error updating subscription from purchase',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

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

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Fetching product information...', level: LogLevel.info);

      // 商品IDリストを取得
      final productIds = InAppPurchaseConfig.allProductIds.toSet();

      // ストアから商品情報を取得
      final ProductDetailsResponse response = await _inAppPurchase!
          .queryProductDetails(productIds);

      if (response.error != null) {
        return Failure(
          ServiceException(
            'Failed to fetch product details',
            details: response.error.toString(),
          ),
        );
      }

      // 見つからない商品があるかチェック
      if (response.notFoundIDs.isNotEmpty) {
        _log(
          'Products not found: ${response.notFoundIDs}',
          level: LogLevel.warning,
        );
      }

      // ProductDetailsをPurchaseProductに変換
      final products = response.productDetails.map((productDetail) {
        final plan = InAppPurchaseConfig.getSubscriptionPlan(productDetail.id);

        return PurchaseProduct(
          id: productDetail.id,
          title: productDetail.title,
          description: productDetail.description,
          price: productDetail.price,
          priceAmount:
              double.tryParse(productDetail.rawPrice.toString()) ?? 0.0,
          currencyCode: productDetail.currencyCode,
          plan: plan,
        );
      }).toList();

      _log(
        'Successfully fetched ${products.length} products',
        level: LogLevel.info,
      );

      return Success(products);
    } catch (e) {
      return _handleError(e, 'getProducts');
    }
  }

  // =================================================================
  // Phase 1.6.2.2: 購入フロー実装
  // =================================================================

  // 非推奨メソッドpurchasePlan削除（enumが削除されたため）
  /*
  @override
  Future<Result<PurchaseResult>> purchasePlan(SubscriptionPlan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      if (_isPurchasing) {
        return Failure(
          ServiceException('Another purchase is already in progress'),
        );
      }

      // Planクラスを使用して判定
      final planClass = PlanFactory.createPlan(plan.id);
      if (planClass is BasicPlan) {
        return Failure(ServiceException('Basic plan cannot be purchased'));
      }

      _log('Starting purchase for plan: ${plan.id}', level: LogLevel.info);
      _isPurchasing = true;

      // 商品IDを取得
      final productId = InAppPurchaseConfig.getProductId(plan);

      try {
        // 商品詳細を取得
        final productResponse = await _inAppPurchase!.queryProductDetails({
          productId,
        });

        if (productResponse.error != null) {
          _isPurchasing = false;
          return Failure(
            ServiceException(
              'Failed to get product details for purchase',
              details: productResponse.error.toString(),
            ),
          );
        }

        if (productResponse.productDetails.isEmpty) {
          _isPurchasing = false;
          return Failure(ServiceException('Product not found: $productId'));
        }

        final productDetails = productResponse.productDetails.first;

        // 購入リクエストを作成
        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );

        // 購入を開始（サブスクリプションはbuyNonConsumableを使用）
        final bool success = await _inAppPurchase!.buyNonConsumable(
          purchaseParam: purchaseParam,
        );

        if (!success) {
          _isPurchasing = false;
          return Failure(ServiceException('Failed to initiate purchase'));
        }

        _log('Purchase initiated successfully', level: LogLevel.info);

        // 購入結果は購入ストリームで非同期に処理される
        // ここでは購入開始の成功を返す
        return Success(
          PurchaseResult(
            status: ssi.PurchaseStatus.pending,
            productId: productId,
            plan: plan,
          ),
        );
      } catch (storeError) {
        _isPurchasing = false;

        // シミュレーター環境でのストアエラー処理
        if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
          final errorString = storeError.toString();
          if (errorString.contains('not connected to app store') ||
              errorString.contains('sandbox') ||
              errorString.contains('StoreKit')) {
            _log(
              'Store connection error in simulator - mocking success',
              level: LogLevel.warning,
            );

            await Future.delayed(const Duration(milliseconds: 1000));
            final result = await createStatus(plan);
            if (result.isSuccess) {
              return Success(
                PurchaseResult(
                  status: ssi.PurchaseStatus.purchased,
                  productId: productId,
                  plan: plan,
                  purchaseDate: DateTime.now(),
                ),
              );
            }
          }
        }

        rethrow;
      }
    } catch (e) {
      _isPurchasing = false;
      return _handleError(e, 'purchasePlan', details: plan.id);
    }
  }

  // =================================================================
  // Phase 1.6.2.3: 購入状態監視実装
  // =================================================================

  @override
  Stream<PurchaseResult> get purchaseStream => _purchaseStreamController.stream;

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

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Starting purchase restoration...', level: LogLevel.info);

      // 復元処理を開始
      await _inAppPurchase!.restorePurchases();

      _log('Purchase restoration initiated', level: LogLevel.info);

      // 復元結果は購入ストリームで非同期に処理される
      // ここでは復元開始の成功を返す
      return Success([PurchaseResult(status: ssi.PurchaseStatus.pending)]);
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

      _log('Validating purchase: $transactionId', level: LogLevel.info);

      // 現在の実装では基本的なローカル検証のみ
      // 将来的にサーバーサイド検証を追加予定

      // トランザクションIDの存在確認
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final isValid =
          status.transactionId == transactionId && _isSubscriptionValid(status);

      _log('Purchase validation result: $isValid', level: LogLevel.info);

      return Success(isValid);
    } catch (e) {
      return _handleError(e, 'validatePurchase', details: transactionId);
    }
  }
  */

  // 非推奨メソッドchangePlan削除（enumが削除されたため）
  /*
  @override
  Future<Result<void>> changePlan(SubscriptionPlan newPlan) async {
    // Phase 1.6では未実装（将来実装予定）
    return Failure(
      ServiceException(
        'Plan change is not yet implemented',
        details: 'This feature will be available in future versions',
      ),
    );
  }
  */

  /// プランを購入（新Planクラス）
  @override
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('SubscriptionService is not initialized'),
        );
      }

      // 直接実装（非推奨メソッドが削除されたため）
      return Failure(
        ServiceException(
          'Purchase functionality is not available in test environment',
          details: 'In-App Purchase requires proper store configuration',
        ),
      );
    } catch (e) {
      return _handleError(e, 'purchasePlanClass', details: plan.id);
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

      // 直接実装（非推奨メソッドが削除されたため）
      return Failure(
        ServiceException(
          'Plan change is not yet implemented',
          details: 'This feature will be available in future versions',
        ),
      );
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

      _log('Canceling subscription...', level: LogLevel.info);

      // プラットフォーム側での自動更新停止はユーザーが設定アプリで行う
      // ここではローカル状態の更新のみ実行

      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final currentStatus = statusResult.value;

      // 自動更新フラグを無効化
      final updatedStatus = SubscriptionStatus(
        planId: currentStatus.planId,
        isActive: currentStatus.isActive,
        startDate: currentStatus.startDate,
        expiryDate: currentStatus.expiryDate,
        autoRenewal: false, // 自動更新を無効化
        monthlyUsageCount: currentStatus.monthlyUsageCount,
        lastResetDate: currentStatus.lastResetDate,
        transactionId: currentStatus.transactionId,
        lastPurchaseDate: currentStatus.lastPurchaseDate,
      );

      const statusKey = SubscriptionConstants.statusKey;
      await _subscriptionBox!.put(statusKey, updatedStatus);

      _log('Subscription auto-renewal disabled', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'cancelSubscription');
    }
  }

  /// サービス破棄処理
  @override
  Future<void> dispose() async {
    _log('Disposing SubscriptionService...', level: LogLevel.info);

    // 購入ストリーム監視を停止
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    // ストリームコントローラーを閉じる
    await _purchaseStreamController.close();

    // In-App Purchaseリソースをクリア
    _inAppPurchase = null;

    _log('SubscriptionService disposed', level: LogLevel.info);
  }

  /// テスト用リセットメソッド
  static void resetForTesting() {
    _instance?._purchaseSubscription?.cancel();
    _instance?._purchaseStreamController.close();
    _instance = null;
  }
}
