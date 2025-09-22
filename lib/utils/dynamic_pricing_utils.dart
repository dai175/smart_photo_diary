import 'package:flutter/material.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/plans/plan_factory.dart';
import '../constants/subscription_constants.dart';

/// 動的価格取得のユーティリティクラス
///
/// 複数の画面で共通して使用できる価格取得・表示機能を提供
class DynamicPricingUtils {
  DynamicPricingUtils._(); // プライベートコンストラクタ

  // LoggingServiceのゲッター
  static LoggingService get _logger => serviceLocator.get<LoggingService>();

  /// 指定プランの動的価格を取得（フォールバック付き）
  ///
  /// [planId] 取得するプランのID
  /// [locale] ロケール情報（フォールバック時に使用）
  ///
  /// Returns: 動的価格（成功時）またはフォールバック価格（失敗時）
  static Future<String> getPlanPrice(
    String planId, {
    String? locale,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      _logger.debug(
        'Fetching dynamic price for plan: $planId',
        context: 'DynamicPricingUtils.getPlanPrice',
      );

      // SubscriptionServiceを取得
      final subscriptionService = await ServiceLocator()
          .getAsync<ISubscriptionService>();

      // 動的価格を取得（タイムアウト付き）
      final result = await subscriptionService
          .getProductPrice(planId)
          .timeout(
            timeout,
            onTimeout: () =>
                Failure(ServiceException('Price fetch timeout for $planId')),
          );

      if (result.isSuccess && result.value != null) {
        final product = result.value!;
        final plan = PlanFactory.createPlan(planId);

        // 動的価格を使用
        final formattedPrice = plan.formatPriceWithAmount(
          product.priceAmount,
          product.currencyCode,
          locale: locale,
        );

        _logger.debug(
          'Successfully using dynamic price for $planId',
          context: 'DynamicPricingUtils.getPlanPrice',
          data: 'price=$formattedPrice, currency=${product.currencyCode}',
        );

        return formattedPrice;
      } else {
        // 動的価格取得失敗時はフォールバックを使用
        return _getFallbackPrice(planId, locale, result.error);
      }
    } catch (e) {
      // エラー時もフォールバックを使用
      return _getFallbackPrice(planId, locale, e);
    }
  }

  /// 複数プランの動的価格を並列取得
  ///
  /// [planIds] 取得するプランIDのリスト
  /// [locale] ロケール情報
  ///
  /// Returns: プランIDをキーとした価格マップ
  static Future<Map<String, String>> getMultiplePlanPrices(
    List<String> planIds, {
    String? locale,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      _logger.debug(
        'Fetching multiple plan prices',
        context: 'DynamicPricingUtils.getMultiplePlanPrices',
        data: 'plans=${planIds.join(", ")}',
      );

      // 並列で価格を取得
      final priceResults = await Future.wait(
        planIds.map(
          (planId) => getPlanPrice(
            planId,
            locale: locale,
            timeout: Duration(seconds: timeout.inSeconds ~/ planIds.length),
          ),
        ),
      );

      // 結果をマップに変換
      final priceMap = <String, String>{};
      for (int i = 0; i < planIds.length; i++) {
        priceMap[planIds[i]] = priceResults[i];
      }

      _logger.debug(
        'Successfully fetched multiple plan prices',
        context: 'DynamicPricingUtils.getMultiplePlanPrices',
        data: 'results=${priceMap.toString()}',
      );

      return priceMap;
    } catch (e) {
      _logger.error(
        'Failed to fetch multiple plan prices',
        context: 'DynamicPricingUtils.getMultiplePlanPrices',
        error: e,
      );

      // エラー時は全てフォールバック価格を返す
      final fallbackMap = <String, String>{};
      for (final planId in planIds) {
        fallbackMap[planId] = _getFallbackPrice(planId, locale, e);
      }
      return fallbackMap;
    }
  }

  /// StatefulWidgetで使用する動的価格管理クラス
  static DynamicPriceManager createManager() {
    return DynamicPriceManager._();
  }

  /// フォールバック価格を取得
  static String _getFallbackPrice(
    String planId,
    String? locale,
    dynamic error,
  ) {
    final fallbackPrice = SubscriptionConstants.formatPriceForPlan(
      planId,
      locale ?? 'ja',
    );

    _logger.info(
      'Using fallback price for $planId',
      context: 'DynamicPricingUtils._getFallbackPrice',
      data: 'fallback_price=$fallbackPrice, error=${error.toString()}',
    );

    return fallbackPrice;
  }
}

/// 動的価格管理クラス（StatefulWidgetで使用）
class DynamicPriceManager {
  DynamicPriceManager._();

  final Map<String, String> _priceCache = {};
  bool _isLoading = false;

  /// 価格がキャッシュされているかチェック
  bool hasCachedPrice(String planId) => _priceCache.containsKey(planId);

  /// キャッシュされた価格を取得
  String? getCachedPrice(String planId) => _priceCache[planId];

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// 価格を取得してキャッシュ
  Future<String> fetchAndCachePrice(
    String planId, {
    String? locale,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_priceCache.containsKey(planId)) {
      return _priceCache[planId]!;
    }

    _isLoading = true;
    try {
      final price = await DynamicPricingUtils.getPlanPrice(
        planId,
        locale: locale,
        timeout: timeout,
      );
      _priceCache[planId] = price;
      return price;
    } finally {
      _isLoading = false;
    }
  }

  /// 複数の価格を取得してキャッシュ
  Future<Map<String, String>> fetchAndCacheMultiplePrices(
    List<String> planIds, {
    String? locale,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _isLoading = true;
    try {
      final prices = await DynamicPricingUtils.getMultiplePlanPrices(
        planIds,
        locale: locale,
        timeout: timeout,
      );
      _priceCache.addAll(prices);
      return prices;
    } finally {
      _isLoading = false;
    }
  }

  /// キャッシュをクリア
  void clearCache() {
    _priceCache.clear();
  }

  /// 特定のプランのキャッシュを削除
  void removeCachedPrice(String planId) {
    _priceCache.remove(planId);
  }
}

/// 動的価格表示用ウィジェット
class DynamicPriceText extends StatefulWidget {
  final String planId;
  final String? locale;
  final TextStyle? style;
  final String Function(String price)? formatter;
  final Duration timeout;
  final Widget? loadingWidget;

  const DynamicPriceText({
    super.key,
    required this.planId,
    this.locale,
    this.style,
    this.formatter,
    this.timeout = const Duration(seconds: 5),
    this.loadingWidget,
  });

  @override
  State<DynamicPriceText> createState() => _DynamicPriceTextState();
}

class _DynamicPriceTextState extends State<DynamicPriceText> {
  String? _price;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrice();
  }

  @override
  void didUpdateWidget(DynamicPriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planId != widget.planId ||
        oldWidget.locale != widget.locale) {
      _fetchPrice();
    }
  }

  Future<void> _fetchPrice() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final price = await DynamicPricingUtils.getPlanPrice(
        widget.planId,
        locale: widget.locale,
        timeout: widget.timeout,
      );

      if (mounted) {
        setState(() {
          _price = price;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ??
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
    }

    final displayPrice =
        _price ??
        SubscriptionConstants.formatPriceForPlan(
          widget.planId,
          widget.locale ?? 'ja',
        );

    final formattedPrice = widget.formatter?.call(displayPrice) ?? displayPrice;

    return Text(formattedPrice, style: widget.style);
  }
}
