/// StoreKit2 から取得した、現在有効な自動更新サブスクリプションのエンタイトルメント。
///
/// in_app_purchase プラグインが公開しない Apple 管理の実有効期限 ([expiryDate]) を保持する。
class StoreEntitlement {
  /// 有効な購読の商品ID（例: smart_photo_diary_premium_monthly_plan）
  final String productId;

  /// Apple が管理する実際の有効期限
  final DateTime expiryDate;

  /// Apple が返す自動更新の意思。ネイティブ側で取得できなかった場合は null。
  /// （解約済みだが期限内の購読を判別するために使用）
  final bool? willAutoRenew;

  const StoreEntitlement({
    required this.productId,
    required this.expiryDate,
    this.willAutoRenew,
  });

  /// ネイティブ MethodChannel の戻り値（Map）からインスタンスを生成する。
  factory StoreEntitlement.fromMap(Map<dynamic, dynamic> map) {
    return StoreEntitlement(
      productId: map['productId'] as String,
      expiryDate: DateTime.fromMillisecondsSinceEpoch(
        map['expiryDateMs'] as int,
      ),
      willAutoRenew: map['willAutoRenew'] as bool?,
    );
  }

  @override
  String toString() =>
      'StoreEntitlement(productId: $productId, expiryDate: $expiryDate, '
      'willAutoRenew: $willAutoRenew)';
}
