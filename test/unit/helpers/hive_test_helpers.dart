import 'package:hive/hive.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'dart:io';

/// Hiveテスト用のヘルパークラス
/// 
/// テスト環境でのHiveセットアップ・クリーンアップを支援
class HiveTestHelpers {
  static bool _isInitialized = false;
  
  /// Hiveをテスト用に初期化
  static Future<void> setupHiveForTesting() async {
    if (_isInitialized) return;
    
    // テスト用の一時ディレクトリを設定
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    
    // TypeAdapterを登録
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SubscriptionStatusAdapter());
    }
    
    _isInitialized = true;
  }
  
  /// サブスクリプションボックスをクリア
  static Future<void> clearSubscriptionBox() async {
    try {
      final box = await Hive.openBox<SubscriptionStatus>(
        SubscriptionConstants.hiveBoxName
      );
      await box.clear();
      await box.close();
    } catch (e) {
      // ボックスが存在しない場合は無視
    }
  }
  
  /// 全てのHiveボックスを閉じる
  static Future<void> closeHive() async {
    await Hive.close();
    _isInitialized = false;
  }
  
  /// テスト用のサブスクリプション状態を作成
  static SubscriptionStatus createTestStatus({
    String? planId,
    bool? isActive,
    DateTime? startDate,
    DateTime? expiryDate,
    int? monthlyUsageCount,
    bool? autoRenewal,
    String? transactionId,
  }) {
    return SubscriptionStatus(
      planId: planId ?? SubscriptionConstants.basicPlanId,
      isActive: isActive ?? true,
      startDate: startDate ?? DateTime.now(),
      expiryDate: expiryDate,
      monthlyUsageCount: monthlyUsageCount ?? 0,
      autoRenewal: autoRenewal ?? false,
      transactionId: transactionId,
    );
  }
}