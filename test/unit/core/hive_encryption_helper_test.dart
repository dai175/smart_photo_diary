import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_photo_diary/core/hive_encryption_helper.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
  });

  group('HiveEncryptionHelper', () {
    group('initialize', () {
      test('generates and stores new key when none exists', () async {
        // Arrange
        when(
          () => mockStorage.read(key: 'hive_aes_encryption_key'),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.write(
            key: 'hive_aes_encryption_key',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);

        // Act
        await helper.initialize();

        // Assert
        verify(
          () => mockStorage.write(
            key: 'hive_aes_encryption_key',
            value: any(named: 'value'),
          ),
        ).called(1);
        expect(helper.cipher, isA<HiveAesCipher>());
      });

      test('loads existing key from storage', () async {
        // Arrange
        final testKey = Hive.generateSecureKey();
        final encodedKey = base64Url.encode(testKey);

        when(
          () => mockStorage.read(key: 'hive_aes_encryption_key'),
        ).thenAnswer((_) async => encodedKey);

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);

        // Act
        await helper.initialize();

        // Assert
        verifyNever(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
        expect(helper.cipher, isA<HiveAesCipher>());
      });
    });

    group('cipher', () {
      test('throws StateError when not initialized', () {
        final helper = HiveEncryptionHelper(secureStorage: mockStorage);

        expect(() => helper.cipher, throwsStateError);
      });
    });

    group('migrateBoxIfNeeded', () {
      test('skips migration when flag is already set', () async {
        // Arrange
        when(
          () => mockStorage.read(key: 'hive_encryption_migrated_test_box'),
        ).thenAnswer((_) async => 'true');

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);

        // Act — should return without doing anything
        await helper.migrateBoxIfNeeded<String>('test_box');

        // Assert — no write called (migration skipped)
        verifyNever(
          () => mockStorage.write(
            key: 'hive_encryption_migrated_test_box',
            value: any(named: 'value'),
          ),
        );
      });

      test('does not mark migration complete when box open fails', () async {
        // Arrange
        when(
          () => mockStorage.read(key: 'hive_encryption_migrated_test_box'),
        ).thenAnswer((_) async => null);

        // Initialize with a key so cipher is available
        final testKey = Hive.generateSecureKey();
        when(
          () => mockStorage.read(key: 'hive_aes_encryption_key'),
        ).thenAnswer((_) async => base64Url.encode(testKey));

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);
        await helper.initialize();

        // Act — box doesn't exist (Hive not initialized), catches error
        await helper.migrateBoxIfNeeded<String>('test_box');

        // Assert — flag should NOT be written so migration can be retried
        verifyNever(
          () => mockStorage.write(
            key: 'hive_encryption_migrated_test_box',
            value: any(named: 'value'),
          ),
        );
      });
    });
  });
}
