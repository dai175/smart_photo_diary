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
          () => mockStorage.read(key: 'hive_diary_encryption_migrated'),
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

      test('generates key when missing and migration flag is false', () async {
        when(
          () => mockStorage.read(key: 'hive_aes_encryption_key'),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.read(key: 'hive_diary_encryption_migrated'),
        ).thenAnswer((_) async => 'false');
        when(
          () => mockStorage.write(
            key: 'hive_aes_encryption_key',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);
        await helper.initialize();

        verify(
          () => mockStorage.write(
            key: 'hive_aes_encryption_key',
            value: any(named: 'value'),
          ),
        ).called(1);
        expect(helper.cipher, isA<HiveAesCipher>());
      });

      test('mints replacement key when missing but migration is complete '
          '(recoverable boot; diaries will be empty)', () async {
        when(
          () => mockStorage.read(key: 'hive_aes_encryption_key'),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.read(key: 'hive_diary_encryption_migrated'),
        ).thenAnswer((_) async => 'true');
        when(
          () => mockStorage.write(
            key: 'hive_aes_encryption_key',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);
        await helper.initialize();

        expect(helper.recoveredFromMissingKey, isTrue);
        expect(helper.cipher, isA<HiveAesCipher>());
        verify(
          () => mockStorage.write(
            key: 'hive_aes_encryption_key',
            value: any(named: 'value'),
          ),
        ).called(1);
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

      test('returns same cipher after initialization', () async {
        final testKey = Hive.generateSecureKey();
        final encodedKey = base64Url.encode(testKey);

        when(
          () => mockStorage.read(key: 'hive_aes_encryption_key'),
        ).thenAnswer((_) async => encodedKey);

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);
        await helper.initialize();

        final cipher1 = helper.cipher;
        final cipher2 = helper.cipher;
        expect(identical(cipher1, cipher2), isTrue);
      });
    });

    group('diary encryption migration flag', () {
      test('isDiaryEncryptionMigrated returns false when unset', () async {
        when(
          () => mockStorage.read(key: 'hive_diary_encryption_migrated'),
        ).thenAnswer((_) async => null);

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);

        expect(await helper.isDiaryEncryptionMigrated(), isFalse);
        expect(await helper.isMigrated(), isFalse);
      });

      test('isDiaryEncryptionMigrated returns true when stored', () async {
        when(
          () => mockStorage.read(key: 'hive_diary_encryption_migrated'),
        ).thenAnswer((_) async => 'true');

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);

        expect(await helper.isDiaryEncryptionMigrated(), isTrue);
        expect(await helper.isMigrated(), isTrue);
      });

      test(
        'markDiaryEncryptionMigrated writes true to secure storage',
        () async {
          when(
            () => mockStorage.write(
              key: 'hive_diary_encryption_migrated',
              value: 'true',
            ),
          ).thenAnswer((_) async {});

          final helper = HiveEncryptionHelper(secureStorage: mockStorage);
          await helper.markDiaryEncryptionMigrated();

          verify(
            () => mockStorage.write(
              key: 'hive_diary_encryption_migrated',
              value: 'true',
            ),
          ).called(1);
        },
      );

      test('markMigrated delegates to markDiaryEncryptionMigrated', () async {
        when(
          () => mockStorage.write(
            key: 'hive_diary_encryption_migrated',
            value: 'true',
          ),
        ).thenAnswer((_) async {});

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);
        await helper.markMigrated();

        verify(
          () => mockStorage.write(
            key: 'hive_diary_encryption_migrated',
            value: 'true',
          ),
        ).called(1);
      });

      test('clearMigrated deletes durable migration flag', () async {
        when(
          () => mockStorage.delete(key: 'hive_diary_encryption_migrated'),
        ).thenAnswer((_) async {});

        final helper = HiveEncryptionHelper(secureStorage: mockStorage);
        await helper.clearMigrated();

        verify(
          () => mockStorage.delete(key: 'hive_diary_encryption_migrated'),
        ).called(1);
      });
    });
  });
}
