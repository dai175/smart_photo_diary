import 'dart:async';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/diary_entry.dart';
import '../models/diary_change.dart';
import '../models/diary_filter.dart';
import 'interfaces/diary_service_interface.dart';
import 'interfaces/diary_tag_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
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
  static const String _boxName = 'diary_entries';
  Box<DiaryEntry>? _diaryBox;
  final ILoggingService _loggingService;
  final HiveAesCipher? _encryptionCipher;
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
  }) : _loggingService = logger,
       _tagService = tagService,
       _encryptionCipher = encryptionCipher {
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
  }) {
    return DiaryService._(
      logger: logger,
      tagService: tagService,
      encryptionCipher: encryptionCipher,
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
      // サイレントにデータを破棄するため、暗号化で開く前にチェックが必要
      if (_encryptionCipher != null && !await _isEncryptionMigrated()) {
        await _migrateToEncrypted();
        return;
      }

      _diaryBox = await Hive.openBox<DiaryEntry>(
        _boxName,
        encryptionCipher: _encryptionCipher,
      );
      _loggingService.info(
        'Hive box initialization completed: ${_diaryBox?.length ?? 0} entries',
      );
      await _indexManager.buildIndex(_diaryBox!);
    } on HiveError catch (e) {
      _loggingService.error('Hive schema error, recreating box', error: e);
      await _recreateBox();
    } on TypeError catch (e) {
      _loggingService.error(
        'Hive type mismatch error, recreating box',
        error: e,
      );
      await _recreateBox();
    }
  }

  /// 暗号化マイグレーション済みかどうかをメタボックスで確認
  Future<bool> _isEncryptionMigrated() async {
    try {
      final metaBox = await Hive.openBox(_metaBoxName);
      final migrated = metaBox.get(_encryptionMigratedKey, defaultValue: false);
      return migrated == true;
    } catch (e) {
      _loggingService.warning(
        'Failed to read migration meta, assuming not migrated',
        data: e.toString(),
      );
      return false;
    }
  }

  /// 暗号化マイグレーション完了をメタボックスに記録
  Future<void> _markEncryptionMigrated() async {
    try {
      final metaBox = await Hive.openBox(_metaBoxName);
      await metaBox.put(_encryptionMigratedKey, true);
    } catch (e) {
      _loggingService.warning(
        'Failed to write migration meta',
        data: e.toString(),
      );
    }
  }

  /// 未暗号化ボックスから暗号化ボックスへマイグレーション
  Future<void> _migrateToEncrypted() async {
    try {
      // 未暗号化で開いてデータを読み出す
      final unencryptedBox = await Hive.openBox<DiaryEntry>(_boxName);
      final entries = unencryptedBox.toMap();
      final entryCount = entries.length;
      _loggingService.info(
        'Starting encryption migration: $entryCount entries found',
      );
      await unencryptedBox.close();
      await Hive.deleteBoxFromDisk(_boxName);

      // 暗号化ボックスに書き込み
      // NOTE: HiveObjectは元のボックスへの参照を持つため、
      // copyWith()で新しいインスタンスを作成してから書き込む
      _diaryBox = await Hive.openBox<DiaryEntry>(
        _boxName,
        encryptionCipher: _encryptionCipher,
      );
      if (entries.isNotEmpty) {
        final copied = <dynamic, DiaryEntry>{};
        for (final entry in entries.entries) {
          copied[entry.key] = entry.value.copyWith();
        }
        await _diaryBox!.putAll(copied);
      }
      _loggingService.info(
        'Encryption migration completed: ${_diaryBox!.length} entries',
      );

      await _markEncryptionMigrated();
      await _indexManager.buildIndex(_diaryBox!);
    } catch (e) {
      _loggingService.error('Encryption migration failed', error: e);
      await _recreateBox();
    }
  }

  /// スキーマ不整合時のみボックスを削除して再作成する
  Future<void> _recreateBox() async {
    try {
      await Hive.deleteBoxFromDisk(_boxName);
      _loggingService.warning('Old box deleted');
      _diaryBox = await Hive.openBox<DiaryEntry>(
        _boxName,
        encryptionCipher: _encryptionCipher,
      );
      _loggingService.info('New box created');
      await _indexManager.buildIndex(_diaryBox!);
    } catch (deleteError) {
      _loggingService.error('Box recreation error', error: deleteError);
      rethrow;
    }
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
