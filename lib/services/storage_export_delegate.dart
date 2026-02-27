import 'dart:convert';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';

import '../core/errors/app_exceptions.dart';
import '../localization/localization_utils.dart';
import 'interfaces/diary_service_interface.dart';

/// エクスポートロジックを担当する内部委譲クラス
class StorageExportDelegate {
  final Future<IDiaryService> Function() _getDiaryService;
  final Future<Locale> Function() _resolveLocale;

  StorageExportDelegate({
    required Future<IDiaryService> Function() getDiaryService,
    required Future<Locale> Function() resolveLocale,
  }) : _getDiaryService = getDiaryService,
       _resolveLocale = resolveLocale;

  /// データのエクスポート（保存先選択可能）
  Future<String?> exportData({DateTime? startDate, DateTime? endDate}) async {
    final diaryService = await _getDiaryService();
    final result = await diaryService.getSortedDiaryEntries();

    if (result.isFailure) {
      throw StorageException(
        'Failed to retrieve diary data: ${result.error.message}',
      );
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
    final jsonData = {
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
              'tags': entry.effectiveTags,
              'createdAt': entry.createdAt.toIso8601String(),
              'updatedAt': entry.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // ファイル保存先を選択
    final fileName =
        'smart_diary_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final l10n = LocalizationUtils.resolveFor(await _resolveLocale());
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: l10n.settingsBackupDialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonString),
    );

    return outputFile;
  }
}
