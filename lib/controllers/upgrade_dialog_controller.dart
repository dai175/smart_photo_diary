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

  /// 現在の状態
  UpgradeDialogState get state => _state;

  /// 利用可能なプランリスト
  List<Plan> get plans => _plans;

  /// プランIDから価格文字列へのマップ
  Map<String, String> get priceStrings => _priceStrings;

  UpgradeDialogController({
    required ILoggingService logger,
    required ISubscriptionService subscriptionService,
  }) : _logger = logger,
       _subscriptionService = subscriptionService;

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
        data: 'prices=${_priceStrings.toString()}',
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
  Future<void> purchasePlan(Plan plan) async {
    if (_state == UpgradeDialogState.purchasing) {
      _logger.warning(
        'Purchase already in progress; skipping',
        context: 'UpgradeDialogController.purchasePlan',
      );
      return;
    }

    _state = UpgradeDialogState.purchasing;
    notifyListeners();

    try {
      _logger.info(
        'Purchase flow started: ${plan.id}',
        context: 'UpgradeDialogController.purchasePlan',
        data: 'productId=${plan.productId}, price=${plan.price}',
      );

      final result = await _subscriptionService.purchasePlanClass(plan);

      if (result.isSuccess) {
        final purchaseResult = result.value;
        _logger.info(
          'Purchase succeeded',
          context: 'UpgradeDialogController.purchasePlan',
          data:
              'status=${purchaseResult.status}, productId=${purchaseResult.productId}',
        );
      } else {
        final error = result.error;
        if (error.toString().contains('In-App Purchase not available') ||
            error.toString().contains('Product not found')) {
          _logger.warning(
            'Possibly simulator or TestFlight environment',
            context: 'UpgradeDialogController.purchasePlan',
            data: error.toString(),
          );
        } else {
          _logger.error(
            'Purchase failed',
            context: 'UpgradeDialogController.purchasePlan',
            error: error,
          );
        }
      }
    } catch (e) {
      _logger.error(
        'Unexpected error occurred',
        context: 'UpgradeDialogController.purchasePlan',
        error: e,
      );
    } finally {
      _state = UpgradeDialogState.showingPlans;
      notifyListeners();
      _logger.debug(
        'Purchase flow finished, resetting state',
        context: 'UpgradeDialogController.purchasePlan',
      );
    }
  }
}
