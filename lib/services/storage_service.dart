import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'diary_service.dart';

class StorageService {
  static StorageService? _instance;

  StorageService._();

  static StorageService getInstance() {
    _instance ??= StorageService._();
    return _instance!;
  }

  // ストレージ使用量を取得
  Future<StorageInfo> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int diaryDataSize = 0;
      int imageDataSize = 0;

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

      // 画像データのサイズを推定（実際の画像ファイルは photo_manager で管理）
      final diaryService = await DiaryService.getInstance();
      final entries = await diaryService.getSortedDiaryEntries();
      
      // 写真枚数を計算
      int totalPhotoCount = 0;
      for (final entry in entries) {
        totalPhotoCount += entry.photoIds.length;
      }
      
      // 画像データのサイズを推定（写真1枚あたり平均1.5MB）
      imageDataSize = totalPhotoCount * (1.5 * 1024 * 1024).round();

      // 合計は日記データと画像データの合計
      final totalSize = diaryDataSize + imageDataSize;

      return StorageInfo(
        totalSize: totalSize,
        diaryDataSize: diaryDataSize,
        imageDataSize: imageDataSize,
      );
    } catch (e) {
      return StorageInfo(totalSize: 0, diaryDataSize: 0, imageDataSize: 0);
    }
  }

  // データのエクスポート
  Future<String?> exportData({DateTime? startDate, DateTime? endDate}) async {
    try {
      final diaryService = await DiaryService.getInstance();
      var entries = await diaryService.getSortedDiaryEntries();

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
        'entries': entries.map((entry) => {
          'id': entry.id,
          'title': entry.title,
          'content': entry.content,
          'date': entry.date.toIso8601String(),
          'photoIds': entry.photoIds,
          // 'location': entry.location, // 将来実装
          'createdAt': entry.createdAt.toIso8601String(),
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // ファイルに保存
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'smart_diary_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  // データの最適化
  Future<bool> optimizeDatabase() async {
    try {
      // データベースの最適化（将来実装）
      // final diaryService = await DiaryService.getInstance();
      // await diaryService.box.compact();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class StorageInfo {
  final int totalSize;
  final int diaryDataSize;
  final int imageDataSize;

  StorageInfo({
    required this.totalSize,
    required this.diaryDataSize,
    required this.imageDataSize,
  });

  String get formattedTotalSize => _formatBytes(totalSize);
  String get formattedDiaryDataSize => _formatBytes(diaryDataSize);
  String get formattedImageDataSize => _formatBytes(imageDataSize);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}