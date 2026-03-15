import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive_ce.dart';

/// Hiveボックスの暗号化を管理するヘルパークラス
///
/// 初回起動時に256bit AESキーを生成し、flutter_secure_storageに保存。
/// 2回目以降は保存済みキーを読み込む。
/// 既存の未暗号化ボックスから暗号化ボックスへのマイグレーションも提供。
class HiveEncryptionHelper {
  static const _keyStorageKey = 'hive_aes_encryption_key';
  static const _migrationFlagPrefix = 'hive_encryption_migrated_';

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

  /// 未暗号化ボックスから暗号化ボックスへマイグレーション
  ///
  /// 既存の未暗号化データがある場合のみ実行。
  /// マイグレーション完了後はフラグを保存し、以降はスキップ。
  Future<void> migrateBoxIfNeeded<T>(String boxName) async {
    final flagKey = '$_migrationFlagPrefix$boxName';
    final migrated = await _secureStorage.read(key: flagKey);
    if (migrated == 'true') return;

    try {
      // 未暗号化ボックスを開いてデータを読み出す
      final box = await Hive.openBox<T>(boxName);
      if (box.isNotEmpty) {
        final Map<dynamic, T> entries = {};
        for (final key in box.keys) {
          final value = box.get(key);
          if (value != null) {
            entries[key] = value;
          }
        }
        await box.close();
        await Hive.deleteBoxFromDisk(boxName);

        // 暗号化ボックスに書き戻す
        final encryptedBox = await Hive.openBox<T>(
          boxName,
          encryptionCipher: cipher,
        );
        for (final entry in entries.entries) {
          await encryptedBox.put(entry.key, entry.value);
        }
        await encryptedBox.close();
      } else {
        await box.close();
      }
    } catch (_) {
      // ボックスが存在しない、または既に暗号化済みの場合は無視
    }

    await _secureStorage.write(key: flagKey, value: 'true');
  }
}
