import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/subscription_status.dart';
import '../models/subscription_plan.dart';
import '../constants/subscription_constants.dart';

/// SubscriptionService
/// 
/// サブスクリプション機能を管理するサービスクラス
/// Hiveを使用してローカルでサブスクリプション状態を管理し、
/// in_app_purchaseとの統合によりアプリ内課金機能を提供する
/// 
/// ## 主な機能
/// - サブスクリプション状態の管理
/// - AI生成回数の制限管理
/// - プラン別機能制限の判定
/// - 月次使用量リセット処理
/// 
/// ## 設計方針
/// - シングルトンパターンによるインスタンス管理
/// - Result<T>パターンによる関数型エラーハンドリング
/// - Hiveによる永続化でオフライン対応
/// - 将来のin_app_purchase統合準備
/// 
/// ## 実装状況
/// - Phase 1.3.1: 基本構造とシングルトンパターン ✅
/// - Phase 1.3.2: Hive操作実装 (予定)
/// - Phase 1.3.3: 使用量管理機能 (予定)
/// - Phase 1.3.4: アクセス権限チェック (予定)
class SubscriptionService {
  // シングルトンインスタンス
  static SubscriptionService? _instance;
  
  // Hiveボックス
  Box<SubscriptionStatus>? _subscriptionBox;
  
  // 初期化フラグ
  bool _isInitialized = false;
  
  // プライベートコンストラクタ
  SubscriptionService._();
  
  /// シングルトンインスタンスを取得
  /// 
  /// 初回呼び出し時に自動的に初期化処理を実行
  /// エラーが発生した場合は例外をスロー
  static Future<SubscriptionService> getInstance() async {
    if (_instance == null) {
      _instance = SubscriptionService._();
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  /// サービス初期化処理
  /// 
  /// Hiveボックスの初期化と初期データ作成を実行
  /// 既に初期化済みの場合は何もしない
  Future<void> _initialize() async {
    if (_isInitialized) {
      debugPrint('SubscriptionService: Already initialized');
      return;
    }
    
    try {
      debugPrint('SubscriptionService: Initializing...');
      
      // Hiveボックスを開く
      _subscriptionBox = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName
      );
      
      // 初期状態の作成（まだ状態が存在しない場合）
      await _ensureInitialStatus();
      
      _isInitialized = true;
      debugPrint('SubscriptionService: Initialization completed');
      
    } catch (e) {
      debugPrint('SubscriptionService: Initialization failed - $e');
      rethrow;
    }
  }
  
  /// 初期サブスクリプション状態の確保
  /// 
  /// サブスクリプション状態が存在しない場合、
  /// Basicプランの初期状態を作成する
  Future<void> _ensureInitialStatus() async {
    const statusKey = SubscriptionConstants.statusKey;
    
    if (_subscriptionBox?.get(statusKey) == null) {
      debugPrint('SubscriptionService: Creating initial Basic plan status');
      
      final initialStatus = SubscriptionStatus(
        planId: SubscriptionPlan.basic.id,
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: null, // Basicプランは期限なし
        autoRenewal: false,
        monthlyUsageCount: 0,
        lastResetDate: DateTime.now(),
        transactionId: null,
        lastPurchaseDate: null,
      );
      
      await _subscriptionBox?.put(statusKey, initialStatus);
      debugPrint('SubscriptionService: Initial status created successfully');
    } else {
      debugPrint('SubscriptionService: Existing status found, skipping creation');
    }
  }
  
  // =================================================================
  // 基本的なサービスメソッド（Phase 1.3.2以降で実装予定）
  // =================================================================
  
  /// 現在のサブスクリプション状態を取得
  /// TODO: Phase 1.3.2で実装
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    return Failure(ServiceException('Phase 1.3.2で実装予定'));
  }
  
  /// AI生成を使用できるかどうかをチェック
  /// TODO: Phase 1.3.3で実装
  Future<Result<bool>> canUseAiGeneration() async {
    return Failure(ServiceException('Phase 1.3.3で実装予定'));
  }
  
  /// プレミアム機能にアクセスできるかどうか
  /// TODO: Phase 1.3.4で実装
  Future<Result<bool>> canAccessPremiumFeatures() async {
    return Failure(ServiceException('Phase 1.3.4で実装予定'));
  }
  
  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================
  
  /// 初期化状態確認
  bool get isInitialized => _isInitialized;
  
  /// Hiveボックス取得（テスト用）
  @visibleForTesting
  Box<SubscriptionStatus>? get subscriptionBox => _subscriptionBox;
  
  /// テスト用のインスタンスリセット
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }
}