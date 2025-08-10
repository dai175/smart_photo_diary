import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/photo_result_helper.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/ui/error_display/error_display.dart';
import 'package:smart_photo_diary/ui/components/custom_dialog.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}

void main() {
  group('Result<T> Error Handling Integration Tests', () {
    late MockPhotoServiceInterface mockPhotoService;
    late ErrorDisplayService errorDisplayService;

    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
      
      mockPhotoService = MockPhotoServiceInterface();
      errorDisplayService = ErrorDisplayService();
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    group('PhotoService Result<T> Error Display Integration', () {
      testWidgets('should display error dialog when PhotoPermissionDeniedException occurs', (tester) async {
        // Arrange
        const error = PhotoPermissionDeniedException('写真アクセス権限が拒否されました');
        when(() => mockPhotoService.requestPermissionResult())
            .thenAnswer((_) async => const Failure(error));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      final result = await mockPhotoService.requestPermissionResult();
                      result.fold(
                        (granted) => null,
                        (error) async {
                          await errorDisplayService.showError(
                            context,
                            error,
                            config: ErrorDisplayConfig.error,
                          );
                        },
                      );
                    },
                    child: const Text('権限リクエスト'),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CustomDialog), findsOneWidget);
        expect(find.text('写真アクセス権限が必要です。設定から権限を許可してください。'), findsOneWidget);
        verify(() => mockPhotoService.requestPermissionResult()).called(1);
      });

      testWidgets('should display snackbar for warning-level Result<T> errors', (tester) async {
        // Arrange
        const error = ValidationException('写真取得パラメータが無効です');
        when(() => mockPhotoService.getTodayPhotosResult(limit: any(named: 'limit')))
            .thenAnswer((_) async => const Failure(error));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      final result = await mockPhotoService.getTodayPhotosResult(limit: 10);
                      result.fold(
                        (photos) => null,
                        (error) async {
                          await errorDisplayService.showError(
                            context,
                            error,
                            config: ErrorDisplayConfig.warning,
                          );
                        },
                      );
                    },
                    child: const Text('今日の写真取得'),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('写真取得パラメータが無効です'), findsOneWidget);
      });

      testWidgets('should show retry button for retryable Result<T> errors', (tester) async {
        // Arrange
        const error = NetworkException('ネットワークエラーが発生しました');
        var callCount = 0;
        when(() => mockPhotoService.requestPermissionResult()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Failure(error);
          } else {
            return const Success(true);
          }
        });

        var retryPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      final result = await mockPhotoService.requestPermissionResult();
                      result.fold(
                        (granted) {
                          // Success case
                        },
                        (error) async {
                          await errorDisplayService.showError(
                            context,
                            error,
                            config: ErrorDisplayConfig.criticalWithRetry,
                            onRetry: () async {
                              retryPressed = true;
                              // Retry the operation
                              final retryResult = await mockPhotoService.requestPermissionResult();
                              retryResult.fold(
                                (granted) => Navigator.of(context).pop(),
                                (error) => null,
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text('権限リクエスト'),
                  );
                },
              ),
            ),
          ),
        );

        // Act - First request (fails)
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - Error dialog with retry button
        expect(find.byType(CustomDialog), findsOneWidget);
        expect(find.text('ネットワークエラーが発生しました'), findsOneWidget);
        expect(find.text('もう一度試す'), findsOneWidget);

        // Act - Retry
        await tester.tap(find.text('もう一度試す'));
        await tester.pumpAndSettle();

        // Assert - Retry was executed
        expect(retryPressed, isTrue);
        verify(() => mockPhotoService.requestPermissionResult()).called(2);
      });
    });

    group('End-to-End Result<T> Error Flow Integration', () {
      testWidgets('should handle complete error flow from service to UI', (tester) async {
        // Arrange - Chain of Result<T> operations
        const permissionError = PhotoPermissionDeniedException('権限が必要です');
        when(() => mockPhotoService.requestPermissionResult())
            .thenAnswer((_) async => const Failure(permissionError));

        bool errorHandled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      // Complete flow: permission -> photos -> data -> UI error display
                      final permissionResult = await mockPhotoService.requestPermissionResult();
                      
                      await permissionResult.fold(
                        (granted) async {
                          // This won't be called due to our mock
                        },
                        (error) async {
                          errorHandled = true;
                          await errorDisplayService.showError(
                            context,
                            error,
                            config: ErrorDisplayConfig.error,
                          );
                        },
                      );
                    },
                    child: const Text('完全フロー実行'),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(errorHandled, isTrue);
        expect(find.byType(CustomDialog), findsOneWidget);
        expect(find.text('写真アクセス権限が必要です。設定から権限を許可してください。'), findsOneWidget);
      });

      testWidgets('should handle cascading Result<T> operations with mixed success/failure', (tester) async {
        // Arrange
        when(() => mockPhotoService.requestPermissionResult())
            .thenAnswer((_) async => const Success(true));
        when(() => mockPhotoService.getTodayPhotosResult(limit: any(named: 'limit')))
            .thenAnswer((_) async => const Failure(PhotoAccessException('写真取得エラー')));

        var finalErrorMessage = '';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      final permissionResult = await mockPhotoService.requestPermissionResult();
                      
                      await permissionResult.fold(
                        (granted) async {
                          if (granted) {
                            // Step 2: Try to get photos
                            final photosResult = await mockPhotoService.getTodayPhotosResult(limit: 10);
                            
                            await photosResult.fold(
                              (photos) async {
                                // Won't be called due to our mock
                              },
                              (error) async {
                                finalErrorMessage = error.message;
                                await errorDisplayService.showError(
                                  context,
                                  error,
                                  config: ErrorDisplayConfig.warning,
                                );
                              },
                            );
                          }
                        },
                        (error) async {
                          // Won't be called due to our mock
                        },
                      );
                    },
                    child: const Text('段階的処理実行'),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(finalErrorMessage, equals('写真取得エラー'));
        expect(find.byType(SnackBar), findsOneWidget);
        verify(() => mockPhotoService.requestPermissionResult()).called(1);
        verify(() => mockPhotoService.getTodayPhotosResult(limit: 10)).called(1);
      });
    });

    group('Result<T> Success Flow Integration', () {
      testWidgets('should handle successful Result<T> operations without errors', (tester) async {
        // Arrange
        when(() => mockPhotoService.requestPermissionResult())
            .thenAnswer((_) async => const Success(true));
        when(() => mockPhotoService.getTodayPhotosResult(limit: any(named: 'limit')))
            .thenAnswer((_) async => const Success([]));

        var operationCompleted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      final permissionResult = await mockPhotoService.requestPermissionResult();
                      
                      await permissionResult.fold(
                        (granted) async {
                          if (granted) {
                            final photosResult = await mockPhotoService.getTodayPhotosResult(limit: 10);
                            
                            await photosResult.fold(
                              (photos) async {
                                operationCompleted = true;
                                // Show success message
                                errorDisplayService.showSuccessMessage(context, '写真の取得が完了しました');
                              },
                              (error) async {
                                // Won't be called
                              },
                            );
                          }
                        },
                        (error) async {
                          // Won't be called
                        },
                      );
                    },
                    child: const Text('成功フロー実行'),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(operationCompleted, isTrue);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('写真の取得が完了しました'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });
  });
}