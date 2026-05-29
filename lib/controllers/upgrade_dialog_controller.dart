import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exceptions.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../utils/dynamic_pricing_utils.dart';
import 'base_error_controller.dart';

/// アップグレードダイアログの状態
enum UpgradeDialogState {
  /// 価格読み込み中
  loadingPrices,

  /// プラン選択表示中
  showingPlans,

  /// 購入処理中
  purchasing,

  /// エラー
  error,
}

/// アップグレードダイアログのビジネスロジック
class UpgradeDialogController extends BaseErrorController {
  final ILoggingService _logger;
  final ISubscriptionService _subscriptionService;

  UpgradeDialogState _state = UpgradeDialogState.loadingPrices;
  List<Plan> _plans = [];
  Map<String, String> _priceStrings = {};
  bool _isDisposed = false;
  StreamSubscription<PurchaseResult>? _purchaseSub;
  final Duration _purchaseTimeout;

  /// 現在の状態
  UpgradeDialogState get state => _state;

  /// 利用可能なプランリスト
  List<Plan> get plans => _plans;

  /// プランIDから価格文字列へのマップ
  Map<String, String> get priceStrings => _priceStrings;

  UpgradeDialogController({
    required ILoggingService logger,
    required ISubscriptionService subscriptionService,
    @visibleForTesting Duration purchaseTimeout = const Duration(minutes: 3),
  }) : _logger = logger,
       _subscriptionService = subscriptionService,
       _purchaseTimeout = purchaseTimeout;

  /// プラン情報と価格を読み込む
  Future<bool> loadPlansAndPrices({required String locale}) async {
    try {
      _state = UpgradeDialogState.loadingPrices;
      notifyListeners();

      _plans = PlanFactory.getPremiumPlans();

      if (_plans.isEmpty) {
        _state = UpgradeDialogState.error;
        notifyListeners();
        return false;
      }

      final planIds = _plans.map((plan) => plan.id).toList();
      _priceStrings = await DynamicPricingUtils.getMultiplePlanPrices(
        planIds,
        locale: locale,
      );

      _logger.debug(
        'Fetched multiple plan prices via DynamicPricingUtils',
        context: 'UpgradeDialogController.loadPlansAndPrices',
        data: {'prices': _priceStrings},
      );

      _state = UpgradeDialogState.showingPlans;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error(
        'Failed to load plans and prices',
        context: 'UpgradeDialogController.loadPlansAndPrices',
        error: e,
      );
      _state = UpgradeDialogState.error;
      setError(
        e is AppException
            ? e
            : ServiceException('Failed to load plans', originalError: e),
      );
      return false;
    }
  }

  /// プランを購入する
  ///
  /// 購入フローを最後まで実行した場合 true、既に購入中でスキップした場合 false を返す。
  /// 呼び出し元は false の場合にダイアログを閉じない等の制御ができる。
  Future<bool> purchasePlan(Plan plan) async {
    if (_state == UpgradeDialogState.purchasing) {
      _logger.warning(
        'Purchase already in progress; skipping',
        context: 'UpgradeDialogController.purchasePlan',
      );
      return false;
    }

    _state = UpgradeDialogState.purchasing;
    if (!_isDisposed) notifyListeners();

    // buyNonConsumable より前に購読してイベント取りこぼしを防ぐ
    final completer = Completer<PurchaseResult>();
    try {
      _purchaseSub = _subscriptionService.purchaseStream.listen(
        (result) {
          final matchesProduct =
              result.productId == null || result.productId == plan.productId;
          if (result.isTerminal && matchesProduct && !completer.isCompleted) {
            completer.complete(result);
          }
        },
        onError: (Object e, StackTrace st) {
          if (!completer.isCompleted) {
            completer.complete(
              PurchaseResult(
                status: PurchaseStatus.error,
                productId: plan.productId,
                errorMessage: e.toString(),
              ),
            );
          }
        },
      );
      _logger.info(
        'Purchase flow started: ${plan.id}',
        context: 'UpgradeDialogController.purchasePlan',
        data: {'productId': plan.productId, 'price': plan.price},
      );

      final initResult = await _subscriptionService.purchasePlanClass(plan);

      if (initResult.isFailure) {
        final error = initResult.error;
        if (error.message.contains('In-App Purchase not available') ||
            error.message.contains('Product not found')) {
          _logger.warning(
            'Possibly simulator or TestFlight environment',
            context: 'UpgradeDialogController.purchasePlan',
            data: {'error': error.toString()},
          );
        } else {
          _logger.error(
            'Purchase initiation failed',
            context: 'UpgradeDialogController.purchasePlan',
            error: error,
          );
        }
        if (!completer.isCompleted) {
          completer.complete(
            PurchaseResult(
              status: PurchaseStatus.error,
              productId: plan.productId,
              errorMessage: error.message,
            ),
          );
        }
      } else if (initResult.value.status == PurchaseStatus.purchased) {
        if (!completer.isCompleted) {
          completer.complete(initResult.value);
        }
      }

      final finalResult = await completer.future.timeout(
        _purchaseTimeout,
        onTimeout: () => PurchaseResult(
          status: PurchaseStatus.error,
          productId: plan.productId,
          errorMessage: 'Purchase timed out after $_purchaseTimeout',
        ),
      );

      _logger.info(
        'Purchase flow finished',
        context: 'UpgradeDialogController.purchasePlan',
        data: {
          'status': finalResult.status.toString(),
          'productId': finalResult.productId,
        },
      );
    } catch (e) {
      _logger.error(
        'Unexpected error in purchase flow',
        context: 'UpgradeDialogController.purchasePlan',
        error: e,
      );
      return false;
    } finally {
      await _purchaseSub?.cancel();
      _purchaseSub = null;
      _state = UpgradeDialogState.showingPlans;
      if (!_isDisposed) notifyListeners();
      _logger.debug(
        'Purchase flow finished, resetting state',
        context: 'UpgradeDialogController.purchasePlan',
      );
    }
    return true;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _purchaseSub?.cancel();
    _purchaseSub = null;
    super.dispose();
  }
}
