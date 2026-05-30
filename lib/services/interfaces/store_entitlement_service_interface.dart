import '../../core/result/result.dart';
import '../../models/store_entitlement.dart';

/// StoreKit2 のエンタイトルメント（Apple 管理の実有効期限）を取得するサービス。
///
/// 戻り値の3状態を区別する点が重要:
/// - `Success(StoreEntitlement)`: 現在有効な購読がある
/// - `Success(null)`: 有効な購読が無い（失効・解約・返金・未購入）→ Basic 降格の根拠
/// - `Failure`: 取得自体に失敗（非iOS・チャネル未登録・通信不可等）→ 状態は変更しない
abstract class IStoreEntitlementService {
  /// 現在有効な自動更新サブスクリプションのエンタイトルメントを返す。
  Future<Result<StoreEntitlement?>> getActiveSubscription();
}
