import '../../core/result/result.dart';
import '../../models/plans/plan.dart';
import '../../models/subscription_status.dart';

/// サブスクリプション状態管理サービスのインターフェース
///
/// サブスクリプション状態のHive永続化、プラン情報取得、
/// 状態変更通知を担当する基盤サービス。
abstract class ISubscriptionStateService {
  /// サービスを初期化（Hiveボックスの初期化と初期データ作成）
  Future<Result<void>> initialize();

  /// サービスが初期化済みかどうか
  bool get isInitialized;

  /// 現在のサブスクリプション状態を取得
  /// デバッグモードでプラン強制設定がある場合、返り値のみプレミアムプランとして返す
  Future<Result<SubscriptionStatus>> getCurrentStatus();

  /// サブスクリプション状態を更新
  Future<Result<void>> updateStatus(SubscriptionStatus status);

  /// サブスクリプション状態をリロード（強制再読み込み）
  Future<Result<void>> refreshStatus();

  /// 指定されたプランでサブスクリプション状態を作成
  Future<Result<SubscriptionStatus>> createStatusForPlan(Plan plan);

  /// 特定のプラン情報を取得
  Result<Plan> getPlanClass(String planId);

  /// 現在のプランを取得
  Future<Result<Plan>> getCurrentPlanClass();

  /// サブスクリプションが有効かどうかをチェック
  bool isSubscriptionValid(SubscriptionStatus status);

  /// サブスクリプション状態変更を監視
  Stream<SubscriptionStatus> get statusStream;

  /// サービスを破棄
  Future<void> dispose();
}
