import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/import_result.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/widgets/settings/storage_settings_section.dart';

import '../../../integration/mocks/mock_services.dart';
import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  late MockStorageService mockStorage;
  late MockILoggingService mockLogger;
  var reloadCount = 0;

  setUpAll(() {
    registerMockFallbacks();
  });

  setUp(() {
    reloadCount = 0;
    serviceLocator.clear();
    mockStorage = TestServiceSetup.getStorageService();
    mockLogger = TestServiceSetup.getLoggingService();

    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  Widget buildWidget() {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: StorageSettingsSection(onReloadSettings: () => reloadCount++),
      ),
    );
  }

  group('StorageSettingsSection', () {
    group('rendering', () {
      testWidgets('shows backup title and subtitle', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('Backup'), findsOneWidget);
        expect(find.text('Save your diaries to a file'), findsOneWidget);
      });

      testWidgets('shows restore title and subtitle', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('Restore'), findsOneWidget);
        expect(find.text('Import diaries from a file'), findsOneWidget);
      });
    });

    group('backup action', () {
      testWidgets('shows success dialog when export succeeds with file path', (
        tester,
      ) async {
        serviceLocator.registerAsyncFactory<IStorageService>(
          () async => mockStorage,
        );
        when(
          () => mockStorage.exportDataResult(),
        ).thenAnswer((_) async => const Success('/tmp/backup.zip'));

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Backup'));
        await tester.pumpAndSettle();

        expect(find.text('Backup complete'), findsOneWidget);
      });

      testWidgets('shows no dialog when user cancels file picker (null path)', (
        tester,
      ) async {
        serviceLocator.registerAsyncFactory<IStorageService>(
          () async => mockStorage,
        );
        when(
          () => mockStorage.exportDataResult(),
        ).thenAnswer((_) async => const Success(null));

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Backup'));
        await tester.pumpAndSettle();

        expect(find.text('Backup complete'), findsNothing);
      });
    });

    group('restore action', () {
      testWidgets('calls onReloadSettings after successful import', (
        tester,
      ) async {
        serviceLocator.registerAsyncFactory<IStorageService>(
          () async => mockStorage,
        );
        when(() => mockStorage.importData()).thenAnswer(
          (_) async => Success(
            ImportResult(
              totalEntries: 3,
              successfulImports: 3,
              skippedEntries: 0,
              failedImports: 0,
              errors: [],
              warnings: [],
            ),
          ),
        );

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Restore'));
        await tester.pumpAndSettle();

        expect(reloadCount, 1);
      });

      testWidgets('shows error dialog when import fails', (tester) async {
        serviceLocator.registerAsyncFactory<IStorageService>(
          () async => mockStorage,
        );
        when(() => mockStorage.importData()).thenAnswer(
          (_) async => const Failure(StorageException('Import failed')),
        );

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Restore'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Import failed'), findsOneWidget);
        expect(reloadCount, 0);
      });
    });
  });
}
