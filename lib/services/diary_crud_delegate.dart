import 'dart:async';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/diary_change.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import 'interfaces/diary_tag_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'diary_index_manager.dart';

/// 日記のCRUD操作を担当する内部委譲クラス
class DiaryCrudDelegate {
  final Box<DiaryEntry> Function() _getBox;
  final Future<void> Function() _ensureInitialized;
  final DiaryIndexManager _indexManager;
  final StreamController<DiaryChange> _changeController;
  final ILoggingService _loggingService;
  final IDiaryTagService Function() _getTagService;
  final bool Function() _isDisposed;
  final _uuid = const Uuid();

  DiaryCrudDelegate({
    required Box<DiaryEntry> Function() getBox,
    required Future<void> Function() ensureInitialized,
    required DiaryIndexManager indexManager,
    required StreamController<DiaryChange> changeController,
    required ILoggingService loggingService,
    required IDiaryTagService Function() getTagService,
    required bool Function() isDisposed,
  }) : _getBox = getBox,
       _ensureInitialized = ensureInitialized,
       _indexManager = indexManager,
       _changeController = changeController,
       _loggingService = loggingService,
       _getTagService = getTagService,
       _isDisposed = isDisposed;

  /// 日記エントリーを保存
  Future<Result<DiaryEntry>> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) async {
    return _saveEntry(
      date: date,
      title: title,
      content: content,
      photoIds: photoIds,
      location: location,
      tags: tags,
      generateTags: (entry) => _getTagService().generateTagsInBackground(
        entry,
        onSearchIndexUpdate: _indexManager.updateSearchIndex,
      ),
      errorMessage: 'Failed to save diary',
      logContext: 'Diary save error',
    );
  }

  /// 過去の写真から日記エントリーを作成
  Future<Result<DiaryEntry>> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
    required Future<Result<List<DiaryEntry>>> Function(DateTime)
    getDiaryByPhotoDate,
  }) async {
    // 既存の日記との重複チェック（警告のみ、作成は続行）
    try {
      await _ensureInitialized();
      final existingResult = await getDiaryByPhotoDate(photoDate);
      if (existingResult.isSuccess && existingResult.value.isNotEmpty) {
        _loggingService.warning(
          'Diary already exists for ${photoDate.toString().split(' ')[0]}',
        );
      }
    } catch (_) {
      // 重複チェック失敗は無視して作成を続行
    }

    return _saveEntry(
      date: photoDate,
      title: title,
      content: content,
      photoIds: photoIds,
      location: location,
      tags: tags,
      generateTags: (entry) =>
          _getTagService().generateTagsInBackgroundForPastPhoto(
            entry,
            onSearchIndexUpdate: _indexManager.updateSearchIndex,
          ),
      errorMessage: 'Failed to create past photo diary',
      logContext: 'Past photo diary creation error',
    );
  }

  /// saveDiaryEntry と createDiaryForPastPhoto の共通ロジック
  Future<Result<DiaryEntry>> _saveEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
    required void Function(DiaryEntry) generateTags,
    required String errorMessage,
    required String logContext,
  }) async {
    try {
      await _ensureInitialized();

      final now = DateTime.now();
      final id = _uuid.v4();
      final box = _getBox();

      _loggingService.debug(
        'Creating DiaryEntry - ID: $id, date: $date, photoCount: ${photoIds.length}',
      );

      final entry = DiaryEntry(
        id: id,
        date: date,
        title: title,
        content: content,
        photoIds: photoIds,
        location: location,
        tags: tags,
        createdAt: now,
        updatedAt: now,
      );

      _loggingService.debug('Saving to Hive...');
      await box.put(entry.id, entry);
      _loggingService.info('Diary entry saved: ${entry.id}');

      // インデックスに挿入
      await _indexManager.ensureIndex(box);
      _indexManager.insertEntry(box, entry);

      // 変更イベント（作成）を通知
      if (!_isDisposed()) {
        _changeController.add(
          DiaryChange(
            type: DiaryChangeType.created,
            entryId: entry.id,
            addedPhotoIds: List<String>.from(photoIds),
          ),
        );
      }

      // バックグラウンドでタグを生成（失敗しても保存結果には影響しない）
      try {
        generateTags(entry);
      } catch (tagError, tagStack) {
        _loggingService.error(
          'Background tag generation failed',
          error: tagError,
          stackTrace: tagStack,
        );
      }

      return Success(entry);
    } catch (e, stackTrace) {
      _loggingService.error(logContext, error: e, stackTrace: stackTrace);
      return Failure(ServiceException(errorMessage, originalError: e));
    }
  }

  /// 日記エントリーを更新
  Future<Result<void>> updateDiaryEntry(DiaryEntry entry) async {
    try {
      await _ensureInitialized();
      final box = _getBox();
      final old = box.get(entry.id);
      if (old == null) {
        return Failure(ServiceException('Diary not found: ${entry.id}'));
      }
      await box.put(entry.id, entry);
      if (old.date != entry.date) {
        await _indexManager.ensureIndex(box);
        _indexManager.updateEntryDate(box, entry);
      }
      _indexManager.updateEntrySearchText(entry);
      final oldIds = Set<String>.from(old.photoIds);
      final newIds = Set<String>.from(entry.photoIds);
      final removed = oldIds.difference(newIds).toList();
      final added = newIds.difference(oldIds).toList();
      if (!_isDisposed()) {
        _changeController.add(
          DiaryChange(
            type: DiaryChangeType.updated,
            entryId: entry.id,
            addedPhotoIds: added,
            removedPhotoIds: removed,
          ),
        );
      }
      return const Success(null);
    } catch (e) {
      _loggingService.error('Diary update error', error: e);
      return Failure(
        ServiceException('Failed to update diary', originalError: e),
      );
    }
  }

  /// 日記エントリーを削除
  Future<Result<void>> deleteDiaryEntry(String id) async {
    try {
      await _ensureInitialized();
      final box = _getBox();
      final existing = box.get(id);
      await box.delete(id);
      if (_indexManager.indexBuilt) {
        _indexManager.removeEntry(id);
      }
      if (existing != null) {
        if (!_isDisposed()) {
          _changeController.add(
            DiaryChange(
              type: DiaryChangeType.deleted,
              entryId: id,
              removedPhotoIds: List<String>.from(existing.photoIds),
            ),
          );
        }
      }
      return const Success(null);
    } catch (e) {
      _loggingService.error('Diary delete error', error: e);
      return Failure(
        ServiceException('Failed to delete diary', originalError: e),
      );
    }
  }

  /// 写真付きで日記エントリーを保存（後方互換性）
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  }) async {
    final List<String> photoIds = photos.map((photo) => photo.id).toList();
    return await saveDiaryEntry(
      date: date,
      title: title,
      content: content,
      photoIds: photoIds,
    );
  }
}
