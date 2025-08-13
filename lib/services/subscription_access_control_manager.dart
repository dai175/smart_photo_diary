import 'package:flutter/foundation.dart';
import 'dart:async';

import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/environment_config.dart';
import 'logging_service.dart';

/// SubscriptionAccessControlManager
///
/// サブスクリプションサービスのアクセス権限管理機能を管理するクラス
/// SubscriptionService からアクセス制御関連の機能を分離して責任を明確化
///
/// ## 主な機能
/// - プレミアム機能のアクセス権限判定
/// - ライティングプロンプト機能のアクセス権限判定
/// - 高度なフィルタ・分析機能のアクセス権限判定
/// - データエクスポート機能のアクセス権限判定
/// - 優先サポート機能のアクセス権限判定
/// - 統計ダッシュボード機能のアクセス権限判定
/// - プラン別機能制限情報の統合取得
///
/// ## 設計方針
/// - Result<T>パターンによる関数型エラーハンドリング
/// - デバッグモード対応（強制プラン設定）
/// - プラン間での統一的なアクセス制御
/// - 機能別の細分化された権限管理
class SubscriptionAccessControlManager {
  // =================================================================
  // プロパティ
  // =================================================================

  // ロギングサービス（SubscriptionServiceから注入）
  final LoggingService _loggingService;

  // 初期化フラグ
  bool _isInitialized = false;

  // =================================================================
  // コンストラクタ
  // =================================================================

  /// コンストラクタ（依存性注入）
  SubscriptionAccessControlManager(this._loggingService) {
    _isInitialized = true;
    _log('SubscriptionAccessControlManager initialized', level: LogLevel.debug);
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
    final logContext = context ?? 'SubscriptionAccessControlManager';

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
    final errorContext = 'SubscriptionAccessControlManager.$operation';
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
  // プレミアム機能アクセス権限判定
  // =================================================================

  /// プレミアム機能にアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessPremiumFeatures(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking premium features access...', level: LogLevel.debug);

      // サブスクリプションの有効性をチェック
      if (!isValidSubscription(status)) {
        _log(
          'Premium features access denied: inactive subscription',
          level: LogLevel.debug,
        );
        return const Success(false);
      }

      // プレミアムプランかどうかをチェック
      final isPremium =
          status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
          status.planId == SubscriptionConstants.premiumYearlyPlanId;

      _log(
        'Premium features access check completed',
        level: LogLevel.debug,
        data: {'hasAccess': isPremium, 'planId': status.planId},
      );

      return Success(isPremium);
    } catch (e) {
      return _handleError(e, 'canAccessPremiumFeatures');
    }
  }

  // =================================================================
  // ライティングプロンプト機能アクセス権限判定
  // =================================================================

  /// ライティングプロンプト機能にアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessWritingPrompts(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking writing prompts access...', level: LogLevel.debug);

      // デバッグモードでプラン強制設定をチェック
      if (kDebugMode) {
        final forcePlan = EnvironmentConfig.forcePlan;
        if (forcePlan != null) {
          _log(
            'プラン強制設定により Writing Prompts アクセス: true',
            level: LogLevel.debug,
            context: 'SubscriptionAccessControlManager.canAccessWritingPrompts',
            data: {'plan': forcePlan},
          );
          return const Success(true); // 全プランでライティングプロンプトは利用可能
        }
      }

      final currentPlan = PlanFactory.createPlan(status.planId);

      // ライティングプロンプトは全プランで利用可能（Basicは限定版）
      if (currentPlan is BasicPlan) {
        _log(
          'Writing prompts access - Basic plan (limited prompts)',
          level: LogLevel.debug,
          context: 'SubscriptionAccessControlManager.canAccessWritingPrompts',
        );
        return const Success(true); // Basicプランでも基本プロンプトは利用可能
      }

      // Premiumプランの場合
      final isPremiumValid = isValidSubscription(status);
      if (isPremiumValid) {
        // 有効なPremiumプランは全プロンプトにアクセス可能
        _log(
          'Writing prompts access - Premium plan',
          level: LogLevel.debug,
          context: 'SubscriptionAccessControlManager.canAccessWritingPrompts',
          data: {'valid': isPremiumValid},
        );
        return const Success(true);
      } else {
        // 期限切れ・非アクティブなPremiumプランでも基本プロンプトアクセスは可能
        _log(
          'Writing prompts access - Premium plan expired/inactive, basic access only',
          level: LogLevel.debug,
          context: 'SubscriptionAccessControlManager.canAccessWritingPrompts',
        );
        return const Success(true);
      }
    } catch (e) {
      return _handleError(e, 'canAccessWritingPrompts');
    }
  }

  // =================================================================
  // 高度なフィルタ・分析機能アクセス権限判定
  // =================================================================

  /// 高度なフィルタ機能にアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessAdvancedFilters(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking advanced filters access...', level: LogLevel.debug);

      final currentPlan = PlanFactory.createPlan(status.planId);

      // 高度なフィルタはPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = isValidSubscription(status);
      _log(
        'Advanced filters access check',
        level: LogLevel.debug,
        context: 'SubscriptionAccessControlManager.canAccessAdvancedFilters',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      return _handleError(e, 'canAccessAdvancedFilters');
    }
  }

  /// 高度な分析にアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessAdvancedAnalytics(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking advanced analytics access...', level: LogLevel.debug);

      final currentPlan = PlanFactory.createPlan(status.planId);

      // 高度な分析はPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = isValidSubscription(status);
      _log(
        'Advanced analytics access check',
        level: LogLevel.debug,
        context: 'SubscriptionAccessControlManager.canAccessAdvancedAnalytics',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      return _handleError(e, 'canAccessAdvancedAnalytics');
    }
  }

  // =================================================================
  // データエクスポート・統計機能アクセス権限判定
  // =================================================================

  /// データエクスポート機能にアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessDataExport(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking data export access...', level: LogLevel.debug);

      final currentPlan = PlanFactory.createPlan(status.planId);

      // データエクスポートは全プランで利用可能（Basicは基本形式のみ）
      if (currentPlan is BasicPlan) {
        _log(
          'Data export access - Basic plan (JSON only)',
          level: LogLevel.debug,
          context: 'SubscriptionAccessControlManager.canAccessDataExport',
        );
        return const Success(true); // BasicプランでもJSON形式は利用可能
      }

      // Premiumプランは複数形式でエクスポート可能
      final isPremiumValid = isValidSubscription(status);
      _log(
        'Data export access - Premium plan',
        level: LogLevel.debug,
        context: 'SubscriptionAccessControlManager.canAccessDataExport',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      return _handleError(e, 'canAccessDataExport');
    }
  }

  /// 統計ダッシュボード機能にアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessStatsDashboard(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking stats dashboard access...', level: LogLevel.debug);

      final currentPlan = PlanFactory.createPlan(status.planId);

      // 統計ダッシュボードはPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = isValidSubscription(status);
      _log(
        'Stats dashboard access check',
        level: LogLevel.debug,
        context: 'SubscriptionAccessControlManager.canAccessStatsDashboard',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      return _handleError(e, 'canAccessStatsDashboard');
    }
  }

  // =================================================================
  // サポート機能アクセス権限判定
  // =================================================================

  /// 優先サポートにアクセスできるかどうか
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] アクセス可能かどうか
  Future<Result<bool>> canAccessPrioritySupport(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Checking priority support access...', level: LogLevel.debug);

      final currentPlan = PlanFactory.createPlan(status.planId);

      // 優先サポートはPremiumプランのみ
      if (currentPlan is BasicPlan) {
        return const Success(false);
      }

      final isPremiumValid = isValidSubscription(status);
      _log(
        'Priority support access check',
        level: LogLevel.debug,
        context: 'SubscriptionAccessControlManager.canAccessPrioritySupport',
        data: {'valid': isPremiumValid},
      );

      return Success(isPremiumValid);
    } catch (e) {
      return _handleError(e, 'canAccessPrioritySupport');
    }
  }

  // =================================================================
  // 統合機能アクセス権限取得
  // =================================================================

  /// プラン別の機能制限情報を取得
  ///
  /// [status] 現在のサブスクリプション状態
  /// [isValidSubscription] サブスクリプション有効性チェック関数
  /// [Returns] 機能別アクセス権限情報マップ
  Future<Result<Map<String, bool>>> getFeatureAccess(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    try {
      if (!_isInitialized) {
        return Failure(
          ServiceException('AccessControlManager is not initialized'),
        );
      }

      _log('Getting feature access map...', level: LogLevel.debug);

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

      _log(
        'Feature access map generated',
        level: LogLevel.debug,
        context: 'SubscriptionAccessControlManager.getFeatureAccess',
        data: featureAccess,
      );

      return Success(featureAccess);
    } catch (e) {
      return _handleError(e, 'getFeatureAccess');
    }
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  void dispose() {
    _log('Disposing SubscriptionAccessControlManager...', level: LogLevel.info);
    _isInitialized = false;
    _log('SubscriptionAccessControlManager disposed', level: LogLevel.info);
  }
}
