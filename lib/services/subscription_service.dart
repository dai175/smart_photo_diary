import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/subscription_plan.dart';
import '../constants/subscription_constants.dart';
import 'interfaces/subscription_service_interface.dart';
import 'logging_service.dart';

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
        SubscriptionConstants.hiveBoxName
      );
      
      // 初期状態の作成（まだ状態が存在しない場合）
      await _ensureInitialStatus();
      
      _isInitialized = true;
      _log('SubscriptionService initialization completed successfully', level: LogLevel.info);
      
    } catch (e) {
      final errorContext = 'SubscriptionService._initialize';
      _log('SubscriptionService initialization failed', 
           level: LogLevel.error, 
           error: e, 
           context: errorContext);
      
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
        planId: SubscriptionPlan.basic.id,
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
      debugPrint('SubscriptionService: Existing status found, skipping creation');
    }
  }
  
  // =================================================================
  // Hive操作メソッド（Phase 1.3.2）
  // =================================================================
  
  // =================================================================
  // プラン管理メソッド（Phase 1.4.1）
  // =================================================================
  
  /// 利用可能なプラン一覧を取得
  @override
  Result<List<SubscriptionPlan>> getAvailablePlans() {
    try {
      _log('Getting available subscription plans', level: LogLevel.debug);
      
      const availablePlans = [
        SubscriptionPlan.basic,
        SubscriptionPlan.premiumMonthly,
        SubscriptionPlan.premiumYearly,
      ];
      
      _log('Successfully retrieved ${availablePlans.length} available plans', 
           level: LogLevel.debug,
           data: {'planCount': availablePlans.length});
           
      return const Success(availablePlans);
    } catch (e) {
      return _handleError(e, 'getAvailablePlans');
    }
  }
  
  /// 特定のプラン情報を取得
  @override
  Result<SubscriptionPlan> getPlan(String planId) {
    try {
      _log('Getting plan by ID', 
           level: LogLevel.debug,
           data: {'planId': planId});
      
      final plan = SubscriptionPlan.fromId(planId);
      
      _log('Successfully retrieved plan', 
           level: LogLevel.debug,
           data: {'planId': planId, 'planName': plan.name});
           
      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getPlan', details: 'planId: $planId');
    }
  }
  
  /// 現在のプランを取得
  @override
  Future<Result<SubscriptionPlan>> getCurrentPlan() async {
    try {
      _log('Getting current subscription plan', level: LogLevel.debug);
      
      if (!_isInitialized) {
        return _handleError(
          StateError('Service not initialized'), 
          'getCurrentPlan',
          details: 'SubscriptionService must be initialized before use'
        );
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        _log('Failed to get current status', 
             level: LogLevel.warning,
             error: statusResult.error);
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final plan = SubscriptionPlan.fromId(status.planId);
      
      _log('Successfully retrieved current plan', 
           level: LogLevel.debug,
           data: {'planId': plan.id, 'planName': plan.name});
           
      return Success(plan);
    } catch (e) {
      return _handleError(e, 'getCurrentPlan');
    }
  }
  
  /// 現在のサブスクリプション状態を取得
  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final status = _subscriptionBox?.get(SubscriptionConstants.statusKey);
      if (status == null) {
        // 状態が存在しない場合は初期状態を作成
        await _ensureInitialStatus();
        final initialStatus = _subscriptionBox?.get(SubscriptionConstants.statusKey);
        if (initialStatus == null) {
          return Failure(ServiceException('Failed to create initial subscription status'));
        }
        return Success(initialStatus);
      }
      
      return Success(status);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting current status - $e');
      return Failure(ServiceException('Failed to get current status', details: e.toString()));
    }
  }
  
  /// サブスクリプション状態を更新
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      await _subscriptionBox?.put(SubscriptionConstants.statusKey, status);
      debugPrint('SubscriptionService: Status updated successfully');
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error updating status - $e');
      return Failure(ServiceException('Failed to update status', details: e.toString()));
    }
  }
  
  /// サブスクリプション状態をリロード（強制再読み込み）
  @override
  Future<Result<void>> refreshStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      // Hiveボックスを再読み込み
      await _subscriptionBox?.close();
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName
      );
      
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error refreshing status - $e');
      return Failure(ServiceException('Failed to refresh status', details: e.toString()));
    }
  }
  
  
  /// 指定されたプランでサブスクリプション状態を作成
  Future<Result<SubscriptionStatus>> createStatus(SubscriptionPlan plan) async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final now = DateTime.now();
      SubscriptionStatus newStatus;
      
      if (plan == SubscriptionPlan.basic) {
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
        final expiryDate = plan == SubscriptionPlan.premiumYearly
            ? now.add(Duration(days: SubscriptionConstants.subscriptionYearDays))
            : now.add(Duration(days: SubscriptionConstants.subscriptionMonthDays));
            
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
      debugPrint('SubscriptionService: Created new status for plan: ${plan.id}');
      return Success(newStatus);
    } catch (e) {
      debugPrint('SubscriptionService: Error creating status - $e');
      return Failure(ServiceException('Failed to create status', details: e.toString()));
    }
  }
  
  /// サブスクリプション状態を削除（テスト用）
  @visibleForTesting
  Future<Result<void>> clearStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      await _subscriptionBox?.delete(SubscriptionConstants.statusKey);
      debugPrint('SubscriptionService: Status cleared');
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error clearing status - $e');
      return Failure(ServiceException('Failed to clear status', details: e.toString()));
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
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      return Success(status.monthlyUsageCount);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting monthly usage - $e');
      return Failure(ServiceException('Failed to get monthly usage', details: e.toString()));
    }
  }
  
  /// 使用量を手動でリセット（管理者・テスト用）
  @override
  Future<Result<void>> resetUsage() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
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
      return Failure(ServiceException('Failed to reset usage', details: e.toString()));
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
          details: 'SubscriptionService must be initialized before use'
        );
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      
      // サブスクリプションが有効でない場合は使用不可
      if (!_isSubscriptionValid(status)) {
        _log('Subscription is not valid - AI generation unavailable', 
             level: LogLevel.warning,
             data: {'planId': status.planId, 'isActive': status.isActive});
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
      final currentPlan = SubscriptionPlan.fromId(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      
      final canUse = updatedStatus.monthlyUsageCount < monthlyLimit;
      
      _log('AI generation availability check completed', 
           level: LogLevel.debug,
           data: {
             'usage': updatedStatus.monthlyUsageCount,
             'limit': monthlyLimit,
             'canUse': canUse,
             'planId': currentPlan.id
           });
      
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
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      
      // サブスクリプションが有効でない場合はインクリメント不可
      if (!_isSubscriptionValid(status)) {
        return Failure(ServiceException('Cannot increment usage: subscription is not valid'));
      }
      
      // 使用量リセットをチェック
      await _resetMonthlyUsageIfNeeded(status);
      
      // 最新の状態を取得
      final latestStatusResult = await getCurrentStatus();
      if (latestStatusResult.isFailure) {
        return Failure(latestStatusResult.error);
      }
      
      final latestStatus = latestStatusResult.value;
      final currentPlan = SubscriptionPlan.fromId(latestStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      
      // 制限チェック
      if (latestStatus.monthlyUsageCount >= monthlyLimit) {
        return Failure(ServiceException('Monthly AI generation limit reached: ${latestStatus.monthlyUsageCount}/$monthlyLimit'));
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
      
      await _subscriptionBox?.put(SubscriptionConstants.statusKey, updatedStatus);
      debugPrint('SubscriptionService: AI usage incremented to ${updatedStatus.monthlyUsageCount}/$monthlyLimit');
      
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error incrementing AI usage - $e');
      return Failure(ServiceException('Failed to increment AI usage', details: e.toString()));
    }
  }
  
  /// 月次使用量リセットが必要かチェックしてリセット
  Future<Result<void>> resetMonthlyUsageIfNeeded() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      await _resetMonthlyUsageIfNeeded(status);
      
      return const Success(null);
    } catch (e) {
      debugPrint('SubscriptionService: Error resetting monthly usage - $e');
      return Failure(ServiceException('Failed to reset monthly usage', details: e.toString()));
    }
  }
  
  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingAiGenerations() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
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
      final currentPlan = SubscriptionPlan.fromId(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      final remaining = monthlyLimit - updatedStatus.monthlyUsageCount;
      
      return Success(remaining > 0 ? remaining : 0);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting remaining generations - $e');
      return Failure(ServiceException('Failed to get remaining generations', details: e.toString()));
    }
  }
  
  /// 次の使用量リセット日を取得
  @override
  Future<Result<DateTime>> getNextResetDate() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
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
      return Failure(ServiceException('Failed to get next reset date', details: e.toString()));
    }
  }
  
  // =================================================================
  // 内部使用量管理ヘルパーメソッド
  // =================================================================
  
  /// サブスクリプションが有効かどうかをチェック
  bool _isSubscriptionValid(SubscriptionStatus status) {
    if (!status.isActive) return false;
    
    final currentPlan = SubscriptionPlan.fromId(status.planId);
    
    // Basicプランは常に有効
    if (currentPlan == SubscriptionPlan.basic) return true;
    
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
      debugPrint('SubscriptionService: Resetting monthly usage - previous month: $statusMonth, current: $currentMonth');
      
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
  
  // =================================================================
  // アクセス権限チェックメソッド（Phase 1.3.4）
  // =================================================================
  
  /// プレミアム機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // Basicプランは基本機能のみ
      if (currentPlan == SubscriptionPlan.basic) {
        return const Success(false);
      }
      
      // Premiumプランは有効期限をチェック
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint('SubscriptionService: Premium features access check - plan: ${currentPlan.id}, valid: $isPremiumValid');
      
      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking premium features access - $e');
      return Failure(ServiceException('Failed to check premium features access', details: e.toString()));
    }
  }
  
  /// ライティングプロンプト機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessWritingPrompts() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // ライティングプロンプトは全プランで利用可能（Basicは限定版）
      if (currentPlan == SubscriptionPlan.basic) {
        debugPrint('SubscriptionService: Writing prompts access - Basic plan (limited prompts)');
        return const Success(true); // Basicプランでも基本プロンプトは利用可能
      }
      
      // Premiumプランの場合
      final isPremiumValid = _isSubscriptionValid(status);
      if (isPremiumValid) {
        // 有効なPremiumプランは全プロンプトにアクセス可能
        debugPrint('SubscriptionService: Writing prompts access - Premium plan, valid: $isPremiumValid');
        return const Success(true);
      } else {
        // 期限切れ・非アクティブなPremiumプランでも基本プロンプトアクセスは可能
        debugPrint('SubscriptionService: Writing prompts access - Premium plan expired/inactive, basic access only');
        return const Success(true);
      }
    } catch (e) {
      debugPrint('SubscriptionService: Error checking writing prompts access - $e');
      return Failure(ServiceException('Failed to check writing prompts access', details: e.toString()));
    }
  }
  
  /// 高度なフィルタ機能にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessAdvancedFilters() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // 高度なフィルタはPremiumプランのみ
      if (currentPlan == SubscriptionPlan.basic) {
        return const Success(false);
      }
      
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint('SubscriptionService: Advanced filters access check - valid: $isPremiumValid');
      
      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking advanced filters access - $e');
      return Failure(ServiceException('Failed to check advanced filters access', details: e.toString()));
    }
  }
  
  /// データエクスポート機能にアクセスできるかどうか
  Future<Result<bool>> canAccessDataExport() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // データエクスポートは全プランで利用可能（Basicは基本形式のみ）
      if (currentPlan == SubscriptionPlan.basic) {
        debugPrint('SubscriptionService: Data export access - Basic plan (JSON only)');
        return const Success(true); // BasicプランでもJSON形式は利用可能
      }
      
      // Premiumプランは複数形式でエクスポート可能
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint('SubscriptionService: Data export access - Premium plan, valid: $isPremiumValid');
      
      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking data export access - $e');
      return Failure(ServiceException('Failed to check data export access', details: e.toString()));
    }
  }
  
  /// 統計ダッシュボード機能にアクセスできるかどうか
  Future<Result<bool>> canAccessStatsDashboard() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // 統計ダッシュボードはPremiumプランのみ
      if (currentPlan == SubscriptionPlan.basic) {
        return const Success(false);
      }
      
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint('SubscriptionService: Stats dashboard access check - valid: $isPremiumValid');
      
      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking stats dashboard access - $e');
      return Failure(ServiceException('Failed to check stats dashboard access', details: e.toString()));
    }
  }
  
  /// プラン別の機能制限情報を取得
  Future<Result<Map<String, bool>>> getFeatureAccess() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final premiumFeaturesResult = await canAccessPremiumFeatures();
      final writingPromptsResult = await canAccessWritingPrompts();
      final advancedFiltersResult = await canAccessAdvancedFilters();
      final dataExportResult = await canAccessDataExport();
      final statsDashboardResult = await canAccessStatsDashboard();
      
      if (premiumFeaturesResult.isFailure) return Failure(premiumFeaturesResult.error);
      if (writingPromptsResult.isFailure) return Failure(writingPromptsResult.error);
      if (advancedFiltersResult.isFailure) return Failure(advancedFiltersResult.error);
      if (dataExportResult.isFailure) return Failure(dataExportResult.error);
      if (statsDashboardResult.isFailure) return Failure(statsDashboardResult.error);
      
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
      return Failure(ServiceException('Failed to get feature access', details: e.toString()));
    }
  }
  
  /// 高度な分析にアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessAdvancedAnalytics() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // 高度な分析はPremiumプランのみ
      if (currentPlan == SubscriptionPlan.basic) {
        return const Success(false);
      }
      
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint('SubscriptionService: Advanced analytics access check - valid: $isPremiumValid');
      
      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking advanced analytics access - $e');
      return Failure(ServiceException('Failed to check advanced analytics access', details: e.toString()));
    }
  }
  
  /// 優先サポートにアクセスできるかどうか
  @override
  Future<Result<bool>> canAccessPrioritySupport() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      final currentPlan = SubscriptionPlan.fromId(status.planId);
      
      // 優先サポートはPremiumプランのみ
      if (currentPlan == SubscriptionPlan.basic) {
        return const Success(false);
      }
      
      final isPremiumValid = _isSubscriptionValid(status);
      debugPrint('SubscriptionService: Priority support access check - valid: $isPremiumValid');
      
      return Success(isPremiumValid);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking priority support access - $e');
      return Failure(ServiceException('Failed to check priority support access', details: e.toString()));
    }
  }
  
  // =================================================================
  // 購入・復元メソッド（Phase 1.6 - プレースホルダー実装）
  // =================================================================
  
  /// In-App Purchase商品情報を取得
  @override
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    try {
      debugPrint('SubscriptionService: Getting products (Phase 1.6 placeholder)');
      // Phase 1.6でin_app_purchase統合時に実装
      const products = [
        PurchaseProduct(
          id: 'smart_photo_diary_premium_monthly',
          title: 'Premium Monthly',
          description: 'Smart Photo Diary Premium Monthly Plan',
          price: '¥300',
          priceAmount: 300.0,
          currencyCode: 'JPY',
          plan: SubscriptionPlan.premiumMonthly,
        ),
        PurchaseProduct(
          id: 'smart_photo_diary_premium_yearly',
          title: 'Premium Yearly',
          description: 'Smart Photo Diary Premium Yearly Plan',
          price: '¥2,800',
          priceAmount: 2800.0,
          currencyCode: 'JPY',
          plan: SubscriptionPlan.premiumYearly,
        ),
      ];
      return const Success(products);
    } catch (e) {
      debugPrint('SubscriptionService: Error getting products - $e');
      return Failure(ServiceException('Failed to get products', details: e.toString()));
    }
  }
  
  /// プランを購入
  @override
  Future<Result<PurchaseResult>> purchasePlan(SubscriptionPlan plan) async {
    try {
      debugPrint('SubscriptionService: Purchasing plan (Phase 1.6 placeholder): ${plan.id}');
      // Phase 1.6でin_app_purchase統合時に実装
      const result = PurchaseResult(
        status: PurchaseStatus.pending,
        errorMessage: 'Purchase functionality not yet implemented',
      );
      return const Success(result);
    } catch (e) {
      debugPrint('SubscriptionService: Error purchasing plan - $e');
      return Failure(ServiceException('Failed to purchase plan', details: e.toString()));
    }
  }
  
  /// 購入を復元
  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    try {
      debugPrint('SubscriptionService: Restoring purchases (Phase 1.6 placeholder)');
      // Phase 1.6でin_app_purchase統合時に実装
      return const Success([]);
    } catch (e) {
      debugPrint('SubscriptionService: Error restoring purchases - $e');
      return Failure(ServiceException('Failed to restore purchases', details: e.toString()));
    }
  }
  
  /// 購入状態を検証
  @override
  Future<Result<bool>> validatePurchase(String transactionId) async {
    try {
      debugPrint('SubscriptionService: Validating purchase (Phase 1.6 placeholder): $transactionId');
      // Phase 1.6でin_app_purchase統合時に実装
      return const Success(false);
    } catch (e) {
      debugPrint('SubscriptionService: Error validating purchase - $e');
      return Failure(ServiceException('Failed to validate purchase', details: e.toString()));
    }
  }
  
  /// プランを変更
  @override
  Future<Result<void>> changePlan(SubscriptionPlan newPlan) async {
    try {
      debugPrint('SubscriptionService: Changing plan (Phase 1.6 placeholder): ${newPlan.id}');
      // Phase 1.6でin_app_purchase統合時に実装
      return Failure(ServiceException('Plan change functionality not yet implemented'));
    } catch (e) {
      debugPrint('SubscriptionService: Error changing plan - $e');
      return Failure(ServiceException('Failed to change plan', details: e.toString()));
    }
  }
  
  /// サブスクリプションをキャンセル
  @override
  Future<Result<void>> cancelSubscription() async {
    try {
      debugPrint('SubscriptionService: Cancelling subscription (Phase 1.6 placeholder)');
      // Phase 1.6でin_app_purchase統合時に実装
      return Failure(ServiceException('Subscription cancellation functionality not yet implemented'));
    } catch (e) {
      debugPrint('SubscriptionService: Error cancelling subscription - $e');
      return Failure(ServiceException('Failed to cancel subscription', details: e.toString()));
    }
  }
  
  // =================================================================
  // 状態監視・通知（Phase 1.6 - プレースホルダー実装）
  // =================================================================
  
  /// サブスクリプション状態変更を監視
  @override
  Stream<SubscriptionStatus> get statusStream {
    // Phase 1.6で実装予定 - 現在はプレースホルダー
    return Stream.periodic(const Duration(minutes: 5), (_) async {
      final statusResult = await getCurrentStatus();
      return statusResult.isSuccess ? statusResult.value : null;
    }).asyncMap((statusFuture) => statusFuture).where((status) => status != null).cast<SubscriptionStatus>();
  }
  
  /// 購入状態変更を監視
  @override
  Stream<PurchaseResult> get purchaseStream {
    // Phase 1.6でin_app_purchase統合時に実装
    return Stream.empty();
  }
  
  // =================================================================
  // サービスのライフサイクル管理
  // =================================================================
  
  /// サービスを破棄
  @override
  Future<void> dispose() async {
    try {
      debugPrint('SubscriptionService: Disposing service...');
      
      // Hiveボックスを閉じる
      await _subscriptionBox?.close();
      _subscriptionBox = null;
      
      // フラグをリセット
      _isInitialized = false;
      
      debugPrint('SubscriptionService: Service disposed successfully');
    } catch (e) {
      debugPrint('SubscriptionService: Error disposing service - $e');
      // エラーでもサービスを破棄する
      _subscriptionBox = null;
      _isInitialized = false;
    }
  }
  
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
      return Failure(ServiceException('Failed to initialize service', details: e.toString()));
    }
  }
  
  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================
  
  /// Hiveボックス取得（テスト用）
  @visibleForTesting
  Box<SubscriptionStatus>? get subscriptionBox => _subscriptionBox;
  
  /// テスト用のインスタンスリセット
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }
  
  // =================================================================
  // Phase 1.4.2: エラーハンドリング統合
  // =================================================================
  
  /// 統一ログ出力メソッド
  /// 
  /// LoggingServiceが利用可能な場合は構造化ログを使用し、
  /// 利用不可の場合はdebugPrintにフォールバック
  void _log(String message, {
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
      final prefix = level == LogLevel.error ? 'ERROR' : 
                     level == LogLevel.warning ? 'WARNING' : 
                     level == LogLevel.debug ? 'DEBUG' : 'INFO';
      
      debugPrint('[$prefix] $logContext: $message');
      if (error != null) {
        debugPrint('[$prefix] $logContext: Error - $error');
      }
    }
  }
  
  /// Result<T>パターンでのエラーハンドリングヘルパー
  /// 
  /// 例外をキャッチし、適切なServiceExceptionとFailureに変換
  Result<T> _handleError<T>(dynamic error, String operation, {String? details}) {
    final errorContext = 'SubscriptionService.$operation';
    final message = 'Operation failed: $operation${details != null ? ' - $details' : ''}';
    
    _log(message, 
         level: LogLevel.error, 
         error: error, 
         context: errorContext);
    
    // ErrorHandlerを使用して適切な例外に変換
    final handledException = ErrorHandler.handleError(error, context: errorContext);
    
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
}