import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/settings_service_interface.dart';
import 'interfaces/storage_service_interface.dart';
import '../core/service_locator.dart';
import '../models/import_result.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import 'storage_export_delegate.dart';
import 'storage_import_delegate.dart';

class StorageService implements IStorageService {
  final IDiaryService? _diaryService;
  final ISettingsService? _settingsService;

  late final StorageExportDelegate _exportDelegate;
  late final StorageImportDelegate _importDelegate;

  StorageService({
    IDiaryService? diaryService,
    ISettingsService? settingsService,
  }) : _diaryService = diaryService,
       _settingsService = settingsService {
    _exportDelegate = StorageExportDelegate(
      getDiaryService: _getDiaryService,
      resolveLocale: _resolveLocale,
    );
    _importDelegate = StorageImportDelegate(
      getDiaryService: _getDiaryService,
      resolveLocale: _resolveLocale,
    );
  }

  /// DiaryService を取得（コンストラクタ注入 or ServiceLocator フォールバック）
  Future<IDiaryService> _getDiaryService() async {
    return _diaryService ?? await serviceLocator.getAsync<IDiaryService>();
  }

  /// 現在のロケールを解決する
  Future<Locale> _resolveLocale() async {
    try {
      final settingsService =
          _settingsService ?? await serviceLocator.getAsync<ISettingsService>();
      return settingsService.locale ?? PlatformDispatcher.instance.locale;
    } catch (_) {
      return PlatformDispatcher.instance.locale;
    }
  }

  // ストレージ使用量を取得
  @override
  Future<StorageInfo> getStorageInfo() async {
    final appDir = await getApplicationDocumentsDirectory();
    int diaryDataSize = 0;

    // Hiveデータベースのサイズを計算
    final hiveDir = Directory(appDir.path);
    if (await hiveDir.exists()) {
      await for (final entity in hiveDir.list(recursive: true)) {
        if (entity is File && entity.path.contains('.hive')) {
          final size = await entity.length();
          diaryDataSize += size;
        }
      }
    }

    return StorageInfo(totalSize: diaryDataSize, diaryDataSize: diaryDataSize);
  }

  // データのエクスポート（保存先選択可能）
  @override
  Future<String?> exportData({DateTime? startDate, DateTime? endDate}) async {
    return _exportDelegate.exportData(startDate: startDate, endDate: endDate);
  }

  // データのインポート（リストア機能）
  @override
  Future<Result<ImportResult?>> importData() async {
    return _importDelegate.importData();
  }

  // データの最適化
  @override
  Future<bool> optimizeDatabase() async {
    final diaryService = await _getDiaryService();

    // Hiveデータベースのコンパクト（断片化を解消）
    await diaryService.compactDatabase();

    // 一時ファイルを削除
    await _cleanupTempFiles();

    return true;
  }

  // 一時ファイルの削除
  Future<void> _cleanupTempFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDir.path}/temp');

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      // キャッシュディレクトリの古いファイルを削除
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      // エラーがあっても続行
    }
  }

  // ========================================
  // Result<T>パターン版のメソッド実装
  // ========================================

  /// ストレージ使用量を取得する（Result版）
  @override
  Future<Result<StorageInfo>> getStorageInfoResult() async {
    try {
      final result = await getStorageInfo();
      return Success(result);
    } catch (e) {
      return Failure(
        ServiceException(
          'Failed to retrieve storage information',
          originalError: e,
        ),
      );
    }
  }

  /// データのエクスポート（Result版）
  @override
  Future<Result<String?>> exportDataResult({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await exportData(startDate: startDate, endDate: endDate);
      return Success(result);
    } catch (e) {
      return Failure(
        ServiceException('Failed to export data', originalError: e),
      );
    }
  }

  /// データベースの最適化（Result版）
  @override
  Future<Result<bool>> optimizeDatabaseResult() async {
    try {
      final result = await optimizeDatabase();
      return Success(result);
    } catch (e) {
      return Failure(
        ServiceException('Failed to optimize database', originalError: e),
      );
    }
  }
}

class StorageInfo {
  final int totalSize;
  final int diaryDataSize;

  const StorageInfo({required this.totalSize, required this.diaryDataSize});

  String get formattedTotalSize => _formatBytes(totalSize);
  String get formattedDiaryDataSize => _formatBytes(diaryDataSize);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
