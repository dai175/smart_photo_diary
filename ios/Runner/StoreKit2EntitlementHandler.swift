import Flutter
import StoreKit

/// StoreKit2 を用いて現在有効なサブスクリプションの実有効期限を返すハンドラ。
///
/// in_app_purchase プラグインは Apple が管理する本当の expirationDate を公開しない。
/// 失効・解約・返金（revocation）の正確な判定には、このチャネル経由で StoreKit2 の
/// Transaction.currentEntitlements を直接参照する必要がある。
///
/// デプロイターゲットは iOS 16.4+ のため StoreKit2 API は常に利用可能（@available 不要）。
final class StoreKit2EntitlementHandler {
  static let channelName = "smart_photo_diary/storekit2"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = StoreKit2EntitlementHandler()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getActiveSubscription":
      let args = call.arguments as? [String: Any]
      let productIds = args?["productIds"] as? [String] ?? []
      Task {
        let entitlement = await Self.activeSubscription(productIds: Set(productIds))
        // FlutterResult はプラットフォーム（メイン）スレッドで返す
        await MainActor.run { result(entitlement) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 指定 productId 群のうち、現在有効な自動更新購読を1件返す。
  ///
  /// - 有効な購読が無い（失効・解約・未購入）: nil
  /// - 複数有効: expirationDate が最も先のものを採用（月→年アップグレード直後など）
  private static func activeSubscription(productIds: Set<String>) async -> [String: Any]? {
    var best: (productId: String, expiry: Date)?

    for await verificationResult in Transaction.currentEntitlements {
      guard case .verified(let transaction) = verificationResult else { continue }
      guard transaction.productType == .autoRenewable else { continue }
      guard productIds.isEmpty || productIds.contains(transaction.productID) else { continue }
      guard transaction.revocationDate == nil else { continue }
      guard let expiry = transaction.expirationDate, expiry > Date() else { continue }

      if best == nil || expiry > best!.expiry {
        best = (transaction.productID, expiry)
      }
    }

    guard let best else { return nil }

    var payload: [String: Any] = [
      "productId": best.productId,
      "expiryDateMs": Int(best.expiry.timeIntervalSince1970 * 1000),
    ]
    // 取得不能時はキーを省略し、Dart 側で既存値を保持する（キャンセル状態の誤上書き防止）。
    if let willAutoRenew = await Self.willAutoRenew(for: best.productId) {
      payload["willAutoRenew"] = willAutoRenew
    }
    return payload
  }

  /// 指定商品の自動更新意思 (willAutoRenew) を返す。取得できない場合は nil。
  ///
  /// ユーザーが解約しても有効期限までは currentEntitlements に残るため、
  /// この値を見ないと「解約済みだが期限内」の状態を判別できない。
  private static func willAutoRenew(for productId: String) async -> Bool? {
    do {
      let products = try await Product.products(for: [productId])
      guard let subscription = products.first?.subscription else { return nil }
      let statuses = try await subscription.status

      for status in statuses {
        guard case .verified(let renewalInfo) = status.renewalInfo else { continue }
        if renewalInfo.currentProductID == productId {
          return renewalInfo.willAutoRenew
        }
      }
      // 対象商品に一致しない場合のフォールバック（同一サブスクグループ内のプラン変更時など）
      for status in statuses {
        if case .verified(let renewalInfo) = status.renewalInfo {
          return renewalInfo.willAutoRenew
        }
      }
      return nil
    } catch {
      return nil
    }
  }
}
