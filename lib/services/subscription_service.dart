import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/subscription_status.dart';
import '../models/subscription_plan.dart';
import '../constants/subscription_constants.dart';

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
/// - Phase 1.3.4: アクセス権限チェック (予定)
class SubscriptionService {
  // シングルトンインスタンス
  static SubscriptionService? _instance;
  
  // Hiveボックス
  Box<SubscriptionStatus>? _subscriptionBox;
  
  // 初期化フラグ
  bool _isInitialized = false;
  
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
      debugPrint('SubscriptionService: Already initialized');
      return;
    }
    
    try {
      debugPrint('SubscriptionService: Initializing...');
      
      // Hiveボックスを開く
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName
      );
      
      // 初期状態の作成（まだ状態が存在しない場合）
      await _ensureInitialStatus();
      
      _isInitialized = true;
      debugPrint('SubscriptionService: Initialization completed');
      
    } catch (e) {
      debugPrint('SubscriptionService: Initialization failed - $e');
      rethrow;
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
  
  /// 現在のサブスクリプション状態を取得
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
  Future<Result<SubscriptionStatus>> refreshStatus() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      // Hiveボックスを再読み込み
      await _subscriptionBox?.close();
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName
      );
      
      return await getCurrentStatus();
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
  
  /// AI生成を使用できるかどうかをチェック
  Future<Result<bool>> canUseAiGeneration() async {
    try {
      if (!_isInitialized) {
        return Failure(ServiceException('SubscriptionService is not initialized'));
      }
      
      final statusResult = await getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }
      
      final status = statusResult.value;
      
      // サブスクリプションが有効でない場合は使用不可
      if (!_isSubscriptionValid(status)) {
        debugPrint('SubscriptionService: Subscription is not valid');
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
      debugPrint('SubscriptionService: AI generation check - usage: ${updatedStatus.monthlyUsageCount}/$monthlyLimit, canUse: $canUse');
      
      return Success(canUse);
    } catch (e) {
      debugPrint('SubscriptionService: Error checking AI generation usage - $e');
      return Failure(ServiceException('Failed to check AI generation usage', details: e.toString()));
    }
  }
  
  /// AI生成使用量をインクリメント
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
  
  /// プレミアム機能にアクセスできるかどうか
  /// TODO: Phase 1.3.4で実装
  Future<Result<bool>> canAccessPremiumFeatures() async {
    return Failure(ServiceException('Phase 1.3.4で実装予定'));
  }
  
  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================
  
  /// 初期化状態確認
  bool get isInitialized => _isInitialized;
  
  /// Hiveボックス取得（テスト用）
  @visibleForTesting
  Box<SubscriptionStatus>? get subscriptionBox => _subscriptionBox;
  
  /// テスト用のインスタンスリセット
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }
}