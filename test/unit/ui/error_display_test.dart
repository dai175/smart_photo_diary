import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations.dart';
import 'package:smart_photo_diary/ui/error_display/error_display.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ErrorDisplayService', () {
    late ErrorDisplayService service;

    setUp(() {
      service = ErrorDisplayService();
    });

    testWidgets('should show snackbar for warning error', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await service.showError(
                    context,
                    const ValidationException('テスト警告メッセージ'),
                    config: ErrorDisplayConfig.warning,
                  );
                },
                child: const Text('エラーを表示'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('テスト警告メッセージ'), findsOneWidget);
    });

    testWidgets('should show dialog for error', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await service.showError(
                    context,
                    const ServiceException('テストエラーメッセージ'),
                    config: ErrorDisplayConfig.error,
                  );
                },
                child: const Text('エラーを表示'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('テストエラーメッセージ'), findsOneWidget);
    });

    testWidgets('should show retry button when enabled', (tester) async {
      var retryPressed = false;
      late AppLocalizations l10n;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return ElevatedButton(
                onPressed: () async {
                  await service.showError(
                    context,
                    const NetworkException('ネットワークエラー'),
                    config: ErrorDisplayConfig.criticalWithRetry,
                    onRetry: () {
                      retryPressed = true;
                    },
                  );
                },
                child: const Text('エラーを表示'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n.commonRetry), findsOneWidget);

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('should show success message', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  service.showSuccessMessage(context, '成功メッセージ');
                },
                child: const Text('成功を表示'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('成功メッセージ'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show info message', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  service.showInfoMessage(context, '情報メッセージ');
                },
                child: const Text('情報を表示'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('情報メッセージ'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });

  group('ErrorDisplayWidgets', () {
    testWidgets('ErrorInlineWidget displays correctly', (tester) async {
      const error = ServiceException('インラインエラーテスト');
      var retryPressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: ErrorInlineWidget(
              error: error,
              config: ErrorDisplayConfig.inline,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ErrorInlineWidget)),
      );

      expect(find.text(l10n.errorSeverityError), findsOneWidget);
      expect(find.text('インラインエラーテスト'), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('SimpleErrorWidget displays correctly', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: SimpleErrorWidget(
              message: 'シンプルエラーテスト',
              onRetry: () {
                retryPressed = true;
              },
              retryButtonText: 'リトライ',
            ),
          ),
        ),
      );

      expect(find.text('シンプルエラーテスト'), findsOneWidget);
      expect(find.text('リトライ'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.text('リトライ'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });
  });

  group('ErrorDisplayConfig', () {
    test('predefined configs have correct properties', () {
      expect(ErrorDisplayConfig.info.severity, ErrorSeverity.info);
      expect(ErrorDisplayConfig.info.method, ErrorDisplayMethod.snackBar);
      expect(ErrorDisplayConfig.info.duration, const Duration(seconds: 3));
      expect(ErrorDisplayConfig.info.logError, isFalse);

      expect(ErrorDisplayConfig.warning.severity, ErrorSeverity.warning);
      expect(ErrorDisplayConfig.warning.method, ErrorDisplayMethod.snackBar);
      expect(ErrorDisplayConfig.warning.logError, isTrue);

      expect(ErrorDisplayConfig.error.severity, ErrorSeverity.error);
      expect(ErrorDisplayConfig.error.method, ErrorDisplayMethod.dialog);
      expect(ErrorDisplayConfig.error.logError, isTrue);

      expect(
        ErrorDisplayConfig.criticalWithRetry.severity,
        ErrorSeverity.critical,
      );
      expect(
        ErrorDisplayConfig.criticalWithRetry.method,
        ErrorDisplayMethod.dialog,
      );
      expect(ErrorDisplayConfig.criticalWithRetry.dismissible, isFalse);
      expect(ErrorDisplayConfig.criticalWithRetry.showRetryButton, isTrue);
      expect(ErrorDisplayConfig.criticalWithRetry.logError, isTrue);

      expect(ErrorDisplayConfig.inline.severity, ErrorSeverity.error);
      expect(ErrorDisplayConfig.inline.method, ErrorDisplayMethod.inline);
      expect(ErrorDisplayConfig.inline.showRetryButton, isTrue);
    });
  });

  group('ErrorSeverity', () {
    test('enum values exist', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.info));
      expect(ErrorSeverity.values, contains(ErrorSeverity.warning));
      expect(ErrorSeverity.values, contains(ErrorSeverity.error));
      expect(ErrorSeverity.values, contains(ErrorSeverity.critical));
    });
  });

  group('ErrorDisplayMethod', () {
    test('enum values exist', () {
      expect(ErrorDisplayMethod.values, contains(ErrorDisplayMethod.snackBar));
      expect(ErrorDisplayMethod.values, contains(ErrorDisplayMethod.inline));
      expect(ErrorDisplayMethod.values, contains(ErrorDisplayMethod.dialog));
      expect(
        ErrorDisplayMethod.values,
        contains(ErrorDisplayMethod.fullScreen),
      );
    });
  });
}
