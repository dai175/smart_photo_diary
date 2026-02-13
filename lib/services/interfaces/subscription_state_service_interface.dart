import '../../core/result/result.dart';
import '../../models/plans/plan.dart';
import '../../models/subscription_status.dart';

/// サブスクリプション状態管理サービスのインターフェース
///
/// サブスクリプション状態のHive永続化、プラン情報取得、
/// 状態変更通知を担当する基盤サービス。
abstract class ISubscriptionStateService {
  /// サービスを初期化（Hiveボックスの初期化と初期データ作成）
  ///
  /// Returns:
  /// - Success: 初期化に成功
  /// - Failure: [ServiceException] Hiveボックスの初期化に失敗した場合
  Future<Result<void>> initialize();

  /// サービスが初期化済みかどうか
  ///
  /// 戻り値: 初期化済みの場合true、未初期化の場合false。
  bool get isInitialized;

  /// 現在のサブスクリプション状態を取得
  ///
  /// デバッグモードでプラン強制設定がある場合、返り値のみプレミアムプランとして返す。
  ///
  /// Returns:
  /// - Success: 現在のサブスクリプション状態
  /// - Failure: [ServiceException] サービスが未初期化、またはデータ取得に失敗した場合
  Future<Result<SubscriptionStatus>> getCurrentStatus();

  /// サブスクリプション状態を更新
  ///
  /// [status]: 更新するサブスクリプション状態
  ///
  /// Returns:
  /// - Success: 状態の更新に成功
  /// - Failure: [ServiceException] サービスが未初期化、または保存に失敗した場合
  Future<Result<void>> updateStatus(SubscriptionStatus status);

  /// サブスクリプション状態をリロード（強制再読み込み）
  ///
  /// Returns:
  /// - Success: 状態の再読み込みに成功
  /// - Failure: [ServiceException] サービスが未初期化、またはデータ取得に失敗した場合
  Future<Result<void>> refreshStatus();

  /// 指定されたプランでサブスクリプション状態を作成
  ///
  /// [plan]: 作成対象のプラン
  ///
  /// Returns:
  /// - Success: 指定プランに基づく新しいサブスクリプション状態
  /// - Failure: [ServiceException] サービスが未初期化、または状態作成に失敗した場合
  Future<Result<SubscriptionStatus>> createStatusForPlan(Plan plan);

  /// 特定のプラン情報を取得
  ///
  /// [planId]: 取得対象のプランID
  ///
  /// Returns:
  /// - Success: 該当するPlanオブジェクト
  /// - Failure: [ServiceException] 指定されたプランIDが見つからない場合
  Result<Plan> getPlanClass(String planId);

  /// 現在のプランを取得
  ///
  /// Returns:
  /// - Success: 現在アクティブなPlanオブジェクト
  /// - Failure: [ServiceException] サービスが未初期化、または状態取得に失敗した場合
  Future<Result<Plan>> getCurrentPlanClass();

  /// サブスクリプションが有効かどうかをチェック
  ///
  /// [status]: チェック対象のサブスクリプション状態
  /// 戻り値: サブスクリプションが有効な場合true、無効な場合false。
  bool isSubscriptionValid(SubscriptionStatus status);

  /// サブスクリプション状態変更を監視
  ///
  /// 戻り値: サブスクリプション状態が変更されるたびにイベントを発行するStream。
  Stream<SubscriptionStatus> get statusStream;

  /// サービスを破棄
  ///
  /// StreamControllerやHiveボックスのクリーンアップを行う。
  Future<void> dispose();
}
