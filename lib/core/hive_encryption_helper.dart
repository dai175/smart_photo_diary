import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive_ce.dart';

/// Durable store for diary box encryption migration state.
///
/// Lives beside the AES key in secure storage so a lost Hive `diary_meta`
/// box cannot force a plaintext probe of an already-encrypted diary box.
/// DiaryService must consult this before opening without a cipher.
abstract class DiaryEncryptionMigrationStore {
  Future<bool> isMigrated();
  Future<void> markMigrated();
}

/// Hiveボックスの暗号化キーを管理するヘルパークラス
///
/// 初回起動時に256bit AESキーを生成し、flutter_secure_storageに保存。
/// 2回目以降は保存済みキーを読み込む。
///
/// NOTE: 暗号化マイグレーション（未暗号化→暗号化）は DiaryService が担当。
/// Hive CEは暗号化不一致時に例外を投げずクラッシュリカバリで
/// サイレントにデータを破棄するため、マイグレーション前のデータ確認が必要で、
/// DiaryEntry固有のcopyWith()が必要なため、ジェネリックな実装は不適切。
///
/// Also stores [DiaryEncryptionMigrationStore] so meta-box loss cannot force
/// a plaintext open of ciphertext (Hive CE wipes on cipher mismatch).
class HiveEncryptionHelper implements DiaryEncryptionMigrationStore {
  static const _keyStorageKey = 'hive_aes_encryption_key';
  static const _diaryEncryptionMigratedKey = 'hive_diary_encryption_migrated';

  final FlutterSecureStorage _secureStorage;
  HiveAesCipher? _cipher;

  HiveEncryptionHelper({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 暗号化キーを初期化（生成または読み込み）
  Future<void> initialize() async {
    var encodedKey = await _secureStorage.read(key: _keyStorageKey);

    if (encodedKey == null) {
      final key = Hive.generateSecureKey();
      encodedKey = base64Url.encode(key);
      await _secureStorage.write(key: _keyStorageKey, value: encodedKey);
    }

    final key = base64Url.decode(encodedKey);
    _cipher = HiveAesCipher(key);
  }

  /// 暗号化用の cipher を取得（initialize() 後に使用可能）
  HiveAesCipher get cipher {
    if (_cipher == null) {
      throw StateError(
        'HiveEncryptionHelper is not initialized. Call initialize() first.',
      );
    }
    return _cipher!;
  }

  /// Whether diary_entries has completed plaintext→encrypted migration.
  Future<bool> isDiaryEncryptionMigrated() async {
    final value = await _secureStorage.read(key: _diaryEncryptionMigratedKey);
    return value == 'true';
  }

  /// Persist that diary_entries encryption migration has completed.
  Future<void> markDiaryEncryptionMigrated() async {
    await _secureStorage.write(key: _diaryEncryptionMigratedKey, value: 'true');
  }

  @override
  Future<bool> isMigrated() => isDiaryEncryptionMigrated();

  @override
  Future<void> markMigrated() => markDiaryEncryptionMigrated();
}
