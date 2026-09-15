import 'dart:async';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/diary_entry.dart';
import '../models/diary_change.dart';
import '../models/diary_filter.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/diary_tag_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/hive_encryption_helper.dart';
import '../core/result/result.dart';
import 'diary_index_manager.dart';
import 'diary_crud_delegate.dart';
import 'diary_query_delegate.dart';

/// 日記の管理を担当するサービスクラス（Facade）
///
/// CRUD操作は[DiaryCrudDelegate]に、クエリ操作は[DiaryQueryDelegate]に委譲。
/// インデックス管理はDiaryIndexManagerに、タグ管理はIDiaryTagServiceに、
/// 統計はIDiaryStatisticsServiceに委譲。
class DiaryService implements IDiaryService {
  static const String diaryEntriesBoxName = 'diary_entries';
  Box<DiaryEntry>? _diaryBox;
  final ILoggingService _loggingService;
  final HiveAesCipher? _encryptionCipher;
  final DiaryEncryptionMigrationStore? _migrationStore;
  final _diaryChangeController = StreamController<DiaryChange>.broadcast();
  bool _disposed = false;

  // インデックス管理（DiaryIndexManagerに委譲）
  final _indexManager = DiaryIndexManager();

  // 内部委譲クラス（遅延初期化）
  late final DiaryCrudDelegate _crudDelegate;
  late final DiaryQueryDelegate _queryDelegate;

  // プライベートコンストラクタ（依存性注入用）
  DiaryService._({
    required ILoggingService logger,
    required IDiaryTagService tagService,
    HiveAesCipher? encryptionCipher,
    DiaryEncryptionMigrationStore? migrationStore,
  }) : _loggingService = logger,
       _tagService = tagService,
       _encryptionCipher = encryptionCipher,
       _migrationStore = migrationStore {
    _crudDelegate = DiaryCrudDelegate(
      getBox: () => _diaryBox!,
      ensureInitialized: _ensureInitialized,
      indexManager: _indexManager,
      changeController: _diaryChangeController,
      loggingService: _loggingService,
      getTagService: () => _tagService,
      isDisposed: () => _disposed,
    );
    _queryDelegate = DiaryQueryDelegate(
      getBox: () => _diaryBox!,
      ensureInitialized: _ensureInitialized,
      indexManager: _indexManager,
      loggingService: _loggingService,
    );
  }

  // 依存性注入用のファクトリメソッド
  static DiaryService createWithDependencies({
    required ILoggingService logger,
    required IDiaryTagService tagService,
    HiveAesCipher? encryptionCipher,
    DiaryEncryptionMigrationStore? migrationStore,
  }) {
    return DiaryService._(
      logger: logger,
      tagService: tagService,
      encryptionCipher: encryptionCipher,
      migrationStore: migrationStore,
    );
  }

  // 初期化メソッド（外部から呼び出し可能）
  Future<void> initialize() async {
    await _init();
  }

  // 変更ストリーム
  @override
  Stream<DiaryChange> get changes => _diaryChangeController.stream;

  /// タグサービス（コンストラクタ注入）
  final IDiaryTagService _tagService;

  // =================================================================
  // 初期化
  // =================================================================

  /// _diaryBoxが未初期化なら初期化する
  Future<void> _ensureInitialized() async {
    if (_diaryBox == null) {
      _loggingService.warning(
        '_diaryBox is not initialized. Reinitializing...',
      );
      await _init();
    }
  }

  static const String _metaBoxName = 'diary_meta';
  static const String _encryptionMigratedKey = 'encryption_migrated';

  // 初期化処理
  Future<void> _init() async {
    try {
      // 暗号化が有効な場合、未マイグレーションのデータを先に移行する
      // NOTE: Hive CEは暗号化不一致時に例外を投げず、クラッシュリカバリで
      // サイレントにデータを破棄するため、暗号化で開く前にチェックが必要。
      // Never open plaintext if durable/meta flags say we already migrated.
      if (_encryptionCipher != null) {
        final metaBox = await Hive.openBox(_metaBoxName);
        final metaMigrated =
            metaBox.get(_encryptionMigratedKey, defaultValue: false) == true;
        final durableMigrated = await _migrationStore?.isMigrated() ?? false;
        final migrated = metaMigrated || durableMigrated;

        if (migrated) {
          // Already encrypted: open with cipher only; backfill missing flags.
          await metaBox.put(_encryptionMigratedKey, true);
          await metaBox.close();
          await _migrationStore?.markMigrated();

          _diaryBox = await Hive.openBox<DiaryEntry>(
            diaryEntriesBoxName,
            encryptionCipher: _encryptionCipher,
          );
          _loggingService.info(
            'Hive box initialization completed: '
            '${_diaryBox?.length ?? 0} entries',
          );
          await _indexManager.buildIndex(_diaryBox!);
          return;
        }

        // First-time path only (neither meta nor durable flag set)
        await _migrateToEncrypted(metaBox);
        return;
      }

      _diaryBox = await Hive.openBox<DiaryEntry>(
        diaryEntriesBoxName,
        encryptionCipher: _encryptionCipher,
      );
      _loggingService.info(
        'Hive box initialization completed: ${_diaryBox?.length ?? 0} entries',
      );
      await _indexManager.buildIndex(_diaryBox!);
    } on HiveError catch (e) {
      // Never delete the box on schema errors. Wipe-recovery destroys user data.
      _loggingService.error(
        'Hive schema error during diary box init',
        error: e,
      );
      rethrow;
    } on TypeError catch (e) {
      // Never delete the box on type mismatch. Wipe-recovery destroys user data.
      _loggingService.error(
        'Hive type mismatch during diary box init',
        error: e,
      );
      rethrow;
    }
  }

  /// 未暗号化ボックスから暗号化ボックスへマイグレーション（plaintext-first）。
  ///
  /// Only called when neither Hive meta nor the durable migration store
  /// reports migration complete. Cipher-first probes wipe plaintext boxes
  /// under Hive CE, so first-time migration must open without cipher.
  Future<void> _migrateToEncrypted(Box metaBox) async {
    try {
      // 1) Open WITHOUT cipher (plaintext-first for real first-time migrate)
      final unencryptedBox = await Hive.openBox<DiaryEntry>(
        diaryEntriesBoxName,
      );

      if (unencryptedBox.isNotEmpty) {
        final entries = unencryptedBox.toMap();
        final expectedCount = entries.length;
        final boxPath = unencryptedBox.path;
        _loggingService.info(
          'Starting encryption migration: $expectedCount entries found',
        );
        await unencryptedBox.close();

        File? backupFile;
        if (boxPath != null) {
          backupFile = File('$boxPath.bak_pre_enc');
          try {
            await File(boxPath).copy(backupFile.path);
          } catch (e) {
            _loggingService.error(
              'Failed to create pre-encryption backup of diary box',
              error: e,
            );
            rethrow;
          }
        }

        await Hive.deleteBoxFromDisk(diaryEntriesBoxName);

        try {
          // NOTE: HiveObject keeps a reference to its box; copyWith() before put.
          _diaryBox = await Hive.openBox<DiaryEntry>(
            diaryEntriesBoxName,
            encryptionCipher: _encryptionCipher,
          );
          await _diaryBox!.putAll(
            entries.map((k, v) => MapEntry(k, v.copyWith())),
          );
          if (_diaryBox!.length != expectedCount) {
            throw StateError(
              'Encryption migration verification failed: '
              'expected $expectedCount entries, got ${_diaryBox!.length}',
            );
          }
          _loggingService.info(
            'Encryption migration completed: ${_diaryBox!.length} entries',
          );

          if (backupFile != null) {
            try {
              if (await backupFile.exists()) {
                await backupFile.delete();
              }
            } catch (e) {
              _loggingService.error(
                'Failed to delete pre-encryption backup after successful migration',
                error: e,
              );
            }
          }

          await _markMigrationComplete(metaBox);
          await _indexManager.buildIndex(_diaryBox!);
          return;
        } catch (e) {
          await _restorePlaintextAfterFailedMigration(
            entries: entries,
            boxPath: boxPath,
            backupFile: backupFile,
          );
          rethrow;
        }
      }

      // 2) Empty plaintext: do NOT deleteBoxFromDisk. Open encrypted fresh.
      await unencryptedBox.close();
      _diaryBox = await Hive.openBox<DiaryEntry>(
        diaryEntriesBoxName,
        encryptionCipher: _encryptionCipher,
      );
      await _markMigrationComplete(metaBox);
      _loggingService.info(
        'Encryption migration marked complete on empty box: '
        '${_diaryBox!.length} entries',
      );
      await _indexManager.buildIndex(_diaryBox!);
    } catch (e) {
      _loggingService.error('Encryption migration failed', error: e);
      rethrow;
    }
  }

  /// Best-effort plaintext restore after delete+encrypt failed.
  /// Leaves migration unmarked so a later launch can retry.
  Future<void> _restorePlaintextAfterFailedMigration({
    required Map<dynamic, DiaryEntry> entries,
    required String? boxPath,
    required File? backupFile,
  }) async {
    try {
      if (_diaryBox != null) {
        if (_diaryBox!.isOpen) {
          await _diaryBox!.close();
        }
        _diaryBox = null;
      }
    } catch (e) {
      _loggingService.error(
        'Failed to close encrypted box during migration restore',
        error: e,
      );
    }

    try {
      await Hive.deleteBoxFromDisk(diaryEntriesBoxName);
    } catch (e) {
      _loggingService.error(
        'Failed to remove partial encrypted box during migration restore',
        error: e,
      );
    }

    try {
      if (backupFile != null && boxPath != null && await backupFile.exists()) {
        await backupFile.copy(boxPath);
        try {
          await backupFile.delete();
        } catch (e) {
          _loggingService.error(
            'Failed to delete pre-encryption backup after restore',
            error: e,
          );
        }
        _diaryBox = await Hive.openBox<DiaryEntry>(diaryEntriesBoxName);
        _loggingService.info(
          'Restored plaintext diary box from pre-encryption backup '
          '(${_diaryBox!.length} entries)',
        );
        return;
      }

      _diaryBox = await Hive.openBox<DiaryEntry>(diaryEntriesBoxName);
      await _diaryBox!.putAll(entries.map((k, v) => MapEntry(k, v.copyWith())));
      _loggingService.info(
        'Restored plaintext diary box from in-memory entries '
        '(${_diaryBox!.length} entries)',
      );
    } catch (e) {
      _loggingService.error(
        'Failed to restore plaintext diary box after encryption migration failure',
        error: e,
      );
    }
  }

  Future<void> _markMigrationComplete(Box metaBox) async {
    await metaBox.put(_encryptionMigratedKey, true);
    await metaBox.close();
    await _migrationStore?.markMigrated();
  }

  // =================================================================
  // CRUD メソッド（DiaryCrudDelegateに委譲）
  // =================================================================

  @override
  Future<Result<DiaryEntry>> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) => _crudDelegate.saveDiaryEntry(
    date: date,
    title: title,
    content: content,
    photoIds: photoIds,
    location: location,
    tags: tags,
  );

  @override
  Future<Result<void>> updateDiaryEntry(DiaryEntry entry) =>
      _crudDelegate.updateDiaryEntry(entry);

  @override
  Future<Result<void>> deleteDiaryEntry(String id) =>
      _crudDelegate.deleteDiaryEntry(id);

  @override
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  }) => _crudDelegate.saveDiaryEntryWithPhotos(
    date: date,
    title: title,
    content: content,
    photos: photos,
  );

  @override
  Future<Result<DiaryEntry>> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  }) => _crudDelegate.createDiaryForPastPhoto(
    photoDate: photoDate,
    title: title,
    content: content,
    photoIds: photoIds,
    location: location,
    tags: tags,
    getDiaryByPhotoDate: getDiaryByPhotoDate,
  );

  // =================================================================
  // クエリメソッド（DiaryQueryDelegateに委譲）
  // =================================================================

  @override
  Future<Result<List<DiaryEntry>>> getSortedDiaryEntries({
    bool descending = true,
  }) => _queryDelegate.getSortedDiaryEntries(descending: descending);

  @override
  Future<Result<DiaryEntry?>> getDiaryEntry(String id) =>
      _queryDelegate.getDiaryEntry(id);

  @override
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntries(
    DiaryFilter filter,
  ) => _queryDelegate.getFilteredDiaryEntries(filter);

  @override
  Future<Result<List<DiaryEntry>>> getFilteredDiaryEntriesPage(
    DiaryFilter filter, {
    required int offset,
    required int limit,
  }) => _queryDelegate.getFilteredDiaryEntriesPage(
    filter,
    offset: offset,
    limit: limit,
  );

  @override
  Future<Result<List<DiaryEntry>>> getDiaryByPhotoDate(DateTime photoDate) =>
      _queryDelegate.getDiaryByPhotoDate(photoDate);

  @override
  Future<Result<DiaryEntry?>> getDiaryEntryByPhotoId(String photoId) =>
      _queryDelegate.getDiaryEntryByPhotoId(photoId);

  // =================================================================
  // その他
  // =================================================================

  // データベースの最適化（StorageServiceから呼び出し用）
  @override
  Future<void> compactDatabase() async {
    await _ensureInitialized();
    if (_diaryBox != null) {
      await _diaryBox!.compact();
    }
  }

  /// リソースを解放する
  @override
  void dispose() {
    _disposed = true;
    _diaryChangeController.close();
  }
}
