import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/storage_service_interface.dart';
import '../core/service_locator.dart';
import '../models/import_result.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';

class StorageService implements IStorageService {
  static StorageService? _instance;

  StorageService._();

  static StorageService getInstance() {
    _instance ??= StorageService._();
    return _instance!;
  }

  // ストレージ使用量を取得
  @override
  Future<StorageInfo> getStorageInfo() async {
    try {
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

      return StorageInfo(
        totalSize: diaryDataSize,
        diaryDataSize: diaryDataSize,
      );
    } catch (e) {
      return StorageInfo(totalSize: 0, diaryDataSize: 0);
    }
  }

  // データのエクスポート（保存先選択可能）
  @override
  Future<String?> exportData({DateTime? startDate, DateTime? endDate}) async {
    try {
      final diaryService = await ServiceLocator().getAsync<IDiaryService>();
      final result = await diaryService.getSortedDiaryEntries();

      if (result.isFailure) {
        throw StorageException('日記データの取得に失敗しました: ${result.error.message}');
      }

      var entries = result.value;

      // 期間フィルター
      if (startDate != null || endDate != null) {
        entries = entries.where((entry) {
          if (startDate != null && entry.date.isBefore(startDate)) return false;
          if (endDate != null && entry.date.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // JSON形式でエクスポート
      final exportData = {
        'app_name': 'Smart Photo Diary',
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'entries': entries
            .map(
              (entry) => {
                'id': entry.id,
                'title': entry.title,
                'content': entry.content,
                'date': entry.date.toIso8601String(),
                'photoIds': entry.photoIds,
                'tags': entry.tags, // タグも含める
                'createdAt': entry.createdAt.toIso8601String(),
                'updatedAt': entry.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // ファイル保存先を選択
      final fileName =
          'smart_diary_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '日記のバックアップを保存',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonString),
      );

      return outputFile;
    } catch (e) {
      return null;
    }
  }

  // データのインポート（リストア機能）
  @override
  Future<Result<ImportResult>> importData() async {
    try {
      // ファイル選択
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'バックアップファイルを選択',
      );

      if (result == null || result.files.single.path == null) {
        return const Failure(ServiceException('ファイルが選択されませんでした'));
      }

      final filePath = result.files.single.path!;
      return await _processImportFile(filePath);
    } catch (e) {
      return Failure(ServiceException('ファイル選択中にエラーが発生しました', originalError: e));
    }
  }

  // インポートファイルの処理
  Future<Result<ImportResult>> _processImportFile(String filePath) async {
    try {
      // ファイルを読み込み
      final file = File(filePath);
      if (!await file.exists()) {
        return const Failure(ServiceException('選択されたファイルが存在しません'));
      }

      final jsonContent = await file.readAsString();
      final Map<String, dynamic> data;

      try {
        data = jsonDecode(jsonContent) as Map<String, dynamic>;
      } catch (e) {
        return const Failure(
          ServiceException('無効なJSONファイルです。正しいバックアップファイルを選択してください'),
        );
      }

      // データ検証
      final validationResult = _validateImportData(data);
      if (validationResult.isFailure) {
        return Failure(validationResult.error);
      }

      // データをインポート
      return await _importDiaryEntries(data);
    } catch (e) {
      return Failure(ServiceException('ファイル処理中にエラーが発生しました', originalError: e));
    }
  }

  // インポートデータの検証
  Result<void> _validateImportData(Map<String, dynamic> data) {
    // 必須フィールドの確認
    if (!data.containsKey('app_name') ||
        data['app_name'] != 'Smart Photo Diary') {
      return const Failure(
        ServiceException('Smart Photo Diaryのバックアップファイルではありません'),
      );
    }

    if (!data.containsKey('entries') || data['entries'] is! List) {
      return const Failure(
        ServiceException('バックアップファイルの形式が正しくありません（entriesが見つかりません）'),
      );
    }

    // バージョン互換性チェック（将来的な拡張用）
    if (data.containsKey('version')) {
      final version = data['version'] as String?;
      if (version != null && !_isVersionCompatible(version)) {
        return const Failure(
          ServiceException('このバックアップファイルのバージョンはサポートされていません'),
        );
      }
    }

    return const Success(null);
  }

  // バージョン互換性チェック
  bool _isVersionCompatible(String version) {
    // 現在は v1.0.0 のみサポート
    // 将来的にマイナーバージョンアップに対応可能
    return version.startsWith('1.');
  }

  // 日記エントリーのインポート
  Future<Result<ImportResult>> _importDiaryEntries(
    Map<String, dynamic> data,
  ) async {
    try {
      final diaryService = await ServiceLocator().getAsync<IDiaryService>();
      final entries = data['entries'] as List<dynamic>;

      int totalEntries = entries.length;
      int successfulImports = 0;
      int skippedEntries = 0;
      int failedImports = 0;
      final List<String> errors = [];
      final List<String> warnings = [];

      // パフォーマンス最適化: 既存エントリーを一度だけ取得
      final existingResult = await diaryService.getSortedDiaryEntries();
      if (existingResult.isFailure) {
        throw StorageException(
          '既存日記データの取得に失敗しました: ${existingResult.error.message}',
        );
      }
      final existingEntries = existingResult.value;

      for (int i = 0; i < entries.length; i++) {
        final entryData = entries[i];

        try {
          final result = await _importSingleEntry(
            entryData,
            diaryService,
            existingEntries,
          );
          if (result.isSuccess) {
            final importStatus = result.value;
            if (importStatus == 'imported') {
              successfulImports++;
            } else if (importStatus == 'skipped') {
              skippedEntries++;
              warnings.add('エントリー "${entryData['title']}" は重複のためスキップされました');
            }
          } else {
            failedImports++;
            errors.add('エントリー ${i + 1}: ${result.error.message}');
          }
        } catch (e) {
          failedImports++;
          errors.add('エントリー ${i + 1}: インポート中にエラーが発生しました: $e');
        }
      }

      final importResult = ImportResult(
        totalEntries: totalEntries,
        successfulImports: successfulImports,
        skippedEntries: skippedEntries,
        failedImports: failedImports,
        errors: errors,
        warnings: warnings,
      );

      return Success(importResult);
    } catch (e) {
      return Failure(ServiceException('インポート処理中にエラーが発生しました', originalError: e));
    }
  }

  // 単一エントリーのインポート
  Future<Result<String>> _importSingleEntry(
    dynamic entryData,
    IDiaryService diaryService,
    List<dynamic> existingEntries,
  ) async {
    try {
      if (entryData is! Map<String, dynamic>) {
        return const Failure(ServiceException('無効なエントリー形式です'));
      }

      // 必須フィールドの確認
      final requiredFields = ['id', 'title', 'content', 'date'];
      for (final field in requiredFields) {
        if (!entryData.containsKey(field)) {
          return Failure(ServiceException('必須フィールド $field が見つかりません'));
        }
      }

      // 日付の解析
      final DateTime date;
      try {
        date = DateTime.parse(entryData['date'] as String);
      } catch (e) {
        return const Failure(ServiceException('無効な日付形式です'));
      }

      // 写真IDの検証
      final photoIds = <String>[];
      if (entryData.containsKey('photoIds') && entryData['photoIds'] is List) {
        final rawPhotoIds = entryData['photoIds'] as List<dynamic>;
        for (final photoId in rawPhotoIds) {
          if (photoId is String) {
            // 写真の存在確認
            try {
              final asset = await AssetEntity.fromId(photoId);
              if (asset != null) {
                photoIds.add(photoId);
              }
            } catch (e) {
              // 写真が見つからない場合はスキップ（警告として記録）
            }
          }
        }
      }

      // 既存エントリーの重複チェック（パフォーマンス最適化済み）
      // IDベースの重複チェック
      final idDuplicate = existingEntries.any(
        (entry) => entry.id == entryData['id'],
      );
      if (idDuplicate) {
        return const Success('skipped');
      }

      // 時刻ベースの重複チェック（同じ時刻の場合は重複とする）
      final timeDuplicate = existingEntries.any(
        (entry) => entry.date.isAtSameMomentAs(date),
      );

      if (timeDuplicate) {
        return const Success('skipped');
      }

      // エントリーを保存
      final saveResult = await diaryService.saveDiaryEntry(
        date: date,
        title: entryData['title'] as String,
        content: entryData['content'] as String,
        photoIds: photoIds,
        location: entryData['location'] as String?,
        tags: entryData.containsKey('tags') && entryData['tags'] is List
            ? (entryData['tags'] as List<dynamic>).cast<String>()
            : null,
      );

      if (saveResult.isFailure) {
        throw StorageException('エントリーの保存に失敗しました: ${saveResult.error.message}');
      }

      return const Success('imported');
    } catch (e) {
      return Failure(
        ServiceException('エントリーの処理中にエラーが発生しました', originalError: e),
      );
    }
  }

  // データの最適化
  @override
  Future<bool> optimizeDatabase() async {
    try {
      final diaryService = await ServiceLocator().getAsync<IDiaryService>();

      // Hiveデータベースのコンパクト（断片化を解消）
      await diaryService.compactDatabase();

      // 一時ファイルを削除
      await _cleanupTempFiles();

      return true;
    } catch (e) {
      return false;
    }
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
      return Failure(ServiceException('ストレージ情報の取得に失敗しました', originalError: e));
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
      return Failure(ServiceException('データエクスポートに失敗しました', originalError: e));
    }
  }

  /// データベースの最適化（Result版）
  @override
  Future<Result<bool>> optimizeDatabaseResult() async {
    try {
      final result = await optimizeDatabase();
      return Success(result);
    } catch (e) {
      return Failure(ServiceException('データベース最適化に失敗しました', originalError: e));
    }
  }
}

class StorageInfo {
  final int totalSize;
  final int diaryDataSize;

  StorageInfo({required this.totalSize, required this.diaryDataSize});

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
