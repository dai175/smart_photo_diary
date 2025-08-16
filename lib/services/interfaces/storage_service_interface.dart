import '../storage_service.dart';
import '../../models/import_result.dart';
import '../../core/result/result.dart';

/// ストレージサービスのインターフェース
abstract class IStorageService {
  /// ストレージ使用量を取得する
  Future<StorageInfo> getStorageInfo();

  /// データのエクスポート（保存先選択可能）
  Future<String?> exportData({DateTime? startDate, DateTime? endDate});

  /// データのインポート（リストア機能）
  Future<Result<ImportResult>> importData();

  /// データベースの最適化
  Future<bool> optimizeDatabase();

  // ========================================
  // Result<T>パターン版のメソッド（新規追加）
  // ========================================

  /// ストレージ使用量を取得する（Result版）
  Future<Result<StorageInfo>> getStorageInfoResult();

  /// データのエクスポート（Result版）
  Future<Result<String?>> exportDataResult({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// データベースの最適化（Result版）
  Future<Result<bool>> optimizeDatabaseResult();
}
