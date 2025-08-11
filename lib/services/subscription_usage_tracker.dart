import 'package:hive/hive.dart';
import 'dart:async';

import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan_factory.dart';
import '../constants/subscription_constants.dart';
import 'logging_service.dart';

/// SubscriptionUsageTracker
///
/// サブスクリプションサービスの使用量追跡機能を管理するクラス
/// SubscriptionService から使用量関連の機能を分離して責任を明確化
///
/// ## 主な機能
/// - AI生成回数の使用量追跡と管理
/// - プラン別制限チェック機能
/// - 月次自動リセット処理
/// - 使用可否判定とインクリメント処理
/// - 残り回数・次回リセット日の算出
///
/// ## 設計方針
/// - Result<T>パターンによる関数型エラーハンドリング
/// - 依存性注入によるテスト可能な設計
/// - 月次リセットの自動化
/// - プラン間での統一的な制限管理
class SubscriptionUsageTracker {
  // =================================================================
  // プロパティ
  // =================================================================

  // Hiveボックス（SubscriptionServiceから注入）
  final Box<SubscriptionStatus> _subscriptionBox;
  
  // ロギングサービス（SubscriptionServiceから注入）
  final LoggingService _loggingService;

  // 初期化フラグ
  bool _isInitialized = false;

  // =================================================================
  // コンストラクタ
  // =================================================================

  /// コンストラクタ（依存性注入）
  SubscriptionUsageTracker(
    this._subscriptionBox,
    this._loggingService,
  ) {
    _isInitialized = true;
    _log('SubscriptionUsageTracker initialized', level: LogLevel.debug);
  }

  // =================================================================
  // プロパティアクセサー
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// 統一ログ出力メソッド
  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final logContext = context ?? 'SubscriptionUsageTracker';

    // 構造化ログを使用
    switch (level) {
      case LogLevel.debug:
        _loggingService.debug(message, context: logContext, data: data);
        break;
      case LogLevel.info:
        _loggingService.info(message, context: logContext, data: data);
        break;
      case LogLevel.warning:
        _loggingService.warning(message, context: logContext, data: data);
        break;
      case LogLevel.error:
        _loggingService.error(message, context: logContext, error: data);
        break;
    }

    // エラーオブジェクトがある場合は追加ログ
    if (error != null) {
      _loggingService.error('Error details: $error', context: logContext);
    }
  }

  /// Result<T>パターンでのエラーハンドリングヘルパー
  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'SubscriptionUsageTracker.$operation';
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

  /// 現在のサブスクリプション状態を取得（依存性注入版）
  Future<Result<SubscriptionStatus>> _getCurrentStatus() async {
    try {
      final statusKey = SubscriptionConstants.statusKey;
      final storedStatus = _subscriptionBox.get(statusKey);

      if (storedStatus == null) {
        return Failure(
          ServiceException(
            'Subscription status not found',
            details: 'No subscription status exists in storage',
          ),
        );
      }

      return Success(storedStatus);
    } catch (e) {
      return _handleError(e, '_getCurrentStatus');
    }
  }

  /// サブスクリプション状態を更新（依存性注入版）
  Future<Result<void>> _updateStatus(SubscriptionStatus status) async {
    try {
      const statusKey = SubscriptionConstants.statusKey;
      await _subscriptionBox.put(statusKey, status);
      return const Success(null);
    } catch (e) {
      return _handleError(e, '_updateStatus');
    }
  }

  // =================================================================
  // 使用量取得・管理の中核メソッド
  // =================================================================

  /// 今月の使用量を取得
  ///
  /// [Returns] 現在の月次使用量
  Future<Result<int>> getMonthlyUsage() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      _log('Getting monthly usage...', level: LogLevel.debug);

      final statusResult = await _getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      
      // 月次リセットをチェック（必要に応じて）
      await _resetMonthlyUsageIfNeeded(status);

      // 更新された状態を再取得
      final updatedStatusResult = await _getCurrentStatus();
      if (updatedStatusResult.isFailure) {
        return Failure(updatedStatusResult.error);
      }

      final updatedStatus = updatedStatusResult.value;

      _log(
        'Monthly usage retrieved successfully',
        level: LogLevel.debug,
        data: {'monthlyUsageCount': updatedStatus.monthlyUsageCount},
      );

      return Success(updatedStatus.monthlyUsageCount);
    } catch (e) {
      return _handleError(e, 'getMonthlyUsage');
    }
  }

  /// 使用量を手動でリセット（管理者・テスト用）
  ///
  /// [Returns] リセット処理の結果
  Future<Result<void>> resetUsage() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      _log('Manually resetting usage...', level: LogLevel.info);

      final statusResult = await _getCurrentStatus();
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

      final updateResult = await _updateStatus(resetStatus);
      if (updateResult.isFailure) {
        return Failure(updateResult.error);
      }

      _log('Usage manually reset successfully', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'resetUsage');
    }
  }

  /// 残りAI生成回数を取得
  ///
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] 残り使用可能回数
  Future<Result<int>> getRemainingGenerations(
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      _log('Getting remaining generations...', level: LogLevel.debug);

      final statusResult = await _getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;

      // サブスクリプションが有効でない場合は0
      if (!isValidSubscription(status)) {
        _log(
          'Subscription is not valid - returning 0 remaining generations',
          level: LogLevel.debug,
          data: {'planId': status.planId, 'isActive': status.isActive},
        );
        return const Success(0);
      }

      // 月次使用量をリセット（必要に応じて）
      await _resetMonthlyUsageIfNeeded(status);

      // 更新された状態を再取得
      final updatedStatusResult = await _getCurrentStatus();
      if (updatedStatusResult.isFailure) {
        return Failure(updatedStatusResult.error);
      }

      final updatedStatus = updatedStatusResult.value;
      final currentPlan = PlanFactory.createPlan(updatedStatus.planId);
      final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
      final remaining = monthlyLimit - updatedStatus.monthlyUsageCount;

      _log(
        'Remaining generations calculated',
        level: LogLevel.debug,
        data: {
          'current': updatedStatus.monthlyUsageCount,
          'limit': monthlyLimit,
          'remaining': remaining > 0 ? remaining : 0,
        },
      );

      return Success(remaining > 0 ? remaining : 0);
    } catch (e) {
      return _handleError(e, 'getRemainingGenerations');
    }
  }

  /// 次の使用量リセット日を取得
  ///
  /// [Returns] 次回リセット予定日
  Future<Result<DateTime>> getNextResetDate() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      _log('Getting next reset date...', level: LogLevel.debug);

      final statusResult = await _getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final nextResetDate = _calculateNextResetDate(status.lastResetDate);

      _log(
        'Next reset date calculated successfully',
        level: LogLevel.debug,
        data: {'nextResetDate': nextResetDate.toIso8601String()},
      );

      return Success(nextResetDate);
    } catch (e) {
      return _handleError(e, 'getNextResetDate');
    }
  }

  // =================================================================
  // 使用可否判定・インクリメント処理
  // =================================================================

  /// AI生成を使用できるかどうかをチェック
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] 使用可能かどうか
  Future<Result<bool>> canUseAiGeneration(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      _log('Checking AI generation usage availability...', level: LogLevel.debug);

      // サブスクリプションが有効でない場合は使用不可
      if (!isValidSubscription(status)) {
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
      final updatedStatusResult = await _getCurrentStatus();
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
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] インクリメント処理の結果
  Future<Result<void>> incrementAiUsage(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      _log('Incrementing AI usage...', level: LogLevel.info);

      // サブスクリプションが有効でない場合はインクリメント不可
      if (!isValidSubscription(status)) {
        return Failure(
          ServiceException('Cannot increment usage: subscription is not valid'),
        );
      }

      // 使用量リセットをチェック
      await _resetMonthlyUsageIfNeeded(status);

      // 最新の状態を取得
      final latestStatusResult = await _getCurrentStatus();
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

      final updateResult = await _updateStatus(updatedStatus);
      if (updateResult.isFailure) {
        return Failure(updateResult.error);
      }

      _log(
        'AI usage incremented successfully',
        level: LogLevel.info,
        data: {
          'current': updatedStatus.monthlyUsageCount,
          'limit': monthlyLimit,
        },
      );

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'incrementAiUsage');
    }
  }

  /// 月次使用量リセットが必要かチェックしてリセット
  ///
  /// [Returns] リセット処理の結果
  Future<Result<void>> resetMonthlyUsageIfNeeded() async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('UsageTracker is not initialized'),
        );
      }

      final statusResult = await _getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      await _resetMonthlyUsageIfNeeded(status);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'resetMonthlyUsageIfNeeded');
    }
  }

  // =================================================================
  // 内部月次リセット・計算ロジック
  // =================================================================

  /// 月次使用量リセットが必要かチェックしてリセット（内部用）
  ///
  /// [status] 現在のサブスクリプション状態
  Future<void> _resetMonthlyUsageIfNeeded(SubscriptionStatus status) async {
    final now = DateTime.now();
    final currentMonth = _getCurrentMonth();
    final statusMonth = _getUsageMonth(status);

    if (statusMonth != currentMonth) {
      _log(
        'Resetting monthly usage',
        level: LogLevel.info,
        data: {'previousMonth': statusMonth, 'currentMonth': currentMonth},
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

      final updateResult = await _updateStatus(resetStatus);
      if (updateResult.isFailure) {
        _log(
          'Failed to reset monthly usage',
          level: LogLevel.error,
          error: updateResult.error,
        );
        // 内部メソッドなので例外は投げない
      }
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
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  void dispose() {
    _log('Disposing SubscriptionUsageTracker...', level: LogLevel.info);
    _isInitialized = false;
    _log('SubscriptionUsageTracker disposed', level: LogLevel.info);
  }
}