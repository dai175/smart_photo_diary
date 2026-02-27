import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../localization/localization_utils.dart';
import '../models/import_result.dart';
import 'interfaces/diary_service_interface.dart';

/// インポートロジックを担当する内部委譲クラス
class StorageImportDelegate {
  final Future<IDiaryService> Function() _getDiaryService;
  final Future<Locale> Function() _resolveLocale;

  StorageImportDelegate({
    required Future<IDiaryService> Function() getDiaryService,
    required Future<Locale> Function() resolveLocale,
  }) : _getDiaryService = getDiaryService,
       _resolveLocale = resolveLocale;

  /// データのインポート（リストア機能）
  Future<Result<ImportResult?>> importData() async {
    try {
      // ファイル選択
      final l10n = LocalizationUtils.resolveFor(await _resolveLocale());
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: l10n.settingsRestoreDialogTitle,
      );

      if (result == null || result.files.single.path == null) {
        return const Success(null);
      }

      final filePath = result.files.single.path!;
      return await _processImportFile(filePath);
    } catch (e) {
      return Failure(
        ServiceException(
          'An error occurred during file selection',
          originalError: e,
        ),
      );
    }
  }

  /// インポートファイルの処理
  Future<Result<ImportResult>> _processImportFile(String filePath) async {
    try {
      // ファイルを読み込み
      final file = File(filePath);
      if (!await file.exists()) {
        return const Failure(ServiceException('Selected file does not exist'));
      }

      final jsonContent = await file.readAsString();
      final Map<String, dynamic> data;

      try {
        data = jsonDecode(jsonContent) as Map<String, dynamic>;
      } catch (e) {
        return const Failure(
          ServiceException(
            'Invalid JSON file. Please select a valid backup file',
          ),
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
      return Failure(
        ServiceException(
          'An error occurred during file processing',
          originalError: e,
        ),
      );
    }
  }

  /// インポートデータの検証
  Result<void> _validateImportData(Map<String, dynamic> data) {
    // 必須フィールドの確認
    if (!data.containsKey('app_name') ||
        data['app_name'] != 'Smart Photo Diary') {
      return const Failure(
        ServiceException('Not a Smart Photo Diary backup file'),
      );
    }

    if (!data.containsKey('entries') || data['entries'] is! List) {
      return const Failure(
        ServiceException('Invalid backup file format (entries not found)'),
      );
    }

    // バージョン互換性チェック（将来的な拡張用）
    if (data.containsKey('version')) {
      final version = data['version'] as String?;
      if (version != null && !_isVersionCompatible(version)) {
        return const Failure(
          ServiceException('This backup file version is not supported'),
        );
      }
    }

    return const Success(null);
  }

  /// バージョン互換性チェック
  bool _isVersionCompatible(String version) {
    // 現在は v1.0.0 のみサポート
    return version.startsWith('1.');
  }

  /// 日記エントリーのインポート
  Future<Result<ImportResult>> _importDiaryEntries(
    Map<String, dynamic> data,
  ) async {
    try {
      final diaryService = await _getDiaryService();
      final entries = data['entries'] as List<dynamic>;

      final int totalEntries = entries.length;
      int successfulImports = 0;
      int skippedEntries = 0;
      int failedImports = 0;
      final List<String> errors = [];
      final List<String> warnings = [];

      // パフォーマンス最適化: 既存エントリーを一度だけ取得
      final existingResult = await diaryService.getSortedDiaryEntries();
      if (existingResult.isFailure) {
        throw StorageException(
          'Failed to retrieve existing diary data: ${existingResult.error.message}',
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
              warnings.add(
                'Entry "${entryData['title']}" was skipped due to duplicate',
              );
            }
          } else {
            failedImports++;
            errors.add('Entry ${i + 1}: ${result.error.message}');
          }
        } catch (e) {
          failedImports++;
          errors.add('Entry ${i + 1}: An error occurred during import: $e');
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
      return Failure(
        ServiceException(
          'An error occurred during import processing',
          originalError: e,
        ),
      );
    }
  }

  /// 単一エントリーのインポート
  Future<Result<String>> _importSingleEntry(
    dynamic entryData,
    IDiaryService diaryService,
    List<dynamic> existingEntries,
  ) async {
    try {
      if (entryData is! Map<String, dynamic>) {
        return const Failure(ServiceException('Invalid entry format'));
      }

      // 必須フィールドの確認
      final requiredFields = ['id', 'title', 'content', 'date'];
      for (final field in requiredFields) {
        if (!entryData.containsKey(field)) {
          return Failure(ServiceException('Required field $field not found'));
        }
      }

      // 日付の解析
      final DateTime date;
      try {
        date = DateTime.parse(entryData['date'] as String);
      } catch (e) {
        return const Failure(ServiceException('Invalid date format'));
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
              // 写真が見つからない場合はスキップ
            }
          }
        }
      }

      // 既存エントリーの重複チェック（パフォーマンス最適化済み）
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
        throw StorageException(
          'Failed to save entry: ${saveResult.error.message}',
        );
      }

      return const Success('imported');
    } catch (e) {
      return Failure(
        ServiceException(
          'An error occurred during entry processing',
          originalError: e,
        ),
      );
    }
  }
}
