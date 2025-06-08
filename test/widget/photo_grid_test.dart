import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/widgets/photo_grid_widget.dart';
import 'package:smart_photo_diary/controllers/photo_selection_controller.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
import '../test_helpers/widget_test_helpers.dart';
import '../test_helpers/widget_test_service_setup.dart';
import '../integration/mocks/mock_services.dart';

// Mock classes
class MockPhotoSelectionController extends Mock implements PhotoSelectionController {}
class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('PhotoGridWidget', () {
    late MockPhotoSelectionController mockController;
    late MockPhotoServiceInterface mockPhotoService;
    late ServiceLocator serviceLocator;

    setUpAll(() async {
      // Initialize widget test environment with unified service mocks
      WidgetTestServiceSetup.initializeForWidgetTests();
      await WidgetTestHelpers.setUpTestEnvironment();
    });

    tearDownAll(() async {
      await WidgetTestHelpers.tearDownTestEnvironment();
      TestServiceSetup.clearAllMocks();
    });

    setUp(() {
      mockController = MockPhotoSelectionController();
      
      // Setup global service registration for widgets that use ServiceRegistration.get<T>()
      WidgetTestServiceSetup.setupGlobalServiceRegistration();
      
      // Use unified service mock system
      serviceLocator = WidgetTestServiceSetup.setupServiceLocatorForWidget();
      mockPhotoService = serviceLocator.get<PhotoServiceInterface>() as MockPhotoServiceInterface;
      
      // Setup default mock behavior - ensure selected length matches photoAssets
      when(() => mockController.photoAssets).thenReturn([]);
      when(() => mockController.selected).thenReturn([]);
      when(() => mockController.selectedCount).thenReturn(0);
      when(() => mockController.isLoading).thenReturn(false);
      when(() => mockController.hasPermission).thenReturn(true);
      when(() => mockController.isPhotoUsed(any())).thenReturn(false);
      when(() => mockController.canSelectPhoto(any())).thenReturn(true);
      
      // PhotoService already has default mock behavior from TestServiceSetup
      // Override specific behavior if needed for this test
      when(() => mockPhotoService.getThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
      )).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4, 5]));
    });

    tearDown(() {
      serviceLocator.clear();
      TestServiceSetup.clearAllMocks();
    });

    group('Basic Rendering', () {
      testWidgets('should render photo grid widget', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(PhotoGridWidget), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
      });

      testWidgets('should display header with title and photo count', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity(), MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false, false]); // Match asset count

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists(AppConstants.newPhotosTitle);
        expect(find.text('2'), findsOneWidget); // Photo count
        expect(find.byType(Container), findsAtLeastNWidgets(1)); // Count badge
      });

      testWidgets('should display selection counter', (WidgetTester tester) async {
        // Arrange
        when(() => mockController.selectedCount).thenReturn(3);

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('選択された写真: 3'), findsOneWidget);
        expect(find.textContaining('${AppConstants.maxPhotosSelection}枚'), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        // Arrange
        when(() => mockController.isLoading).thenReturn(true);

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(GridView), findsNothing);
      });

      testWidgets('should show permission request when no permission', (WidgetTester tester) async {
        // Arrange
        when(() => mockController.hasPermission).thenReturn(false);
        when(() => mockController.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byIcon(Icons.no_photography), findsOneWidget);
        WidgetTestHelpers.expectTextExists(AppConstants.permissionMessage);
        expect(find.byType(ElevatedButton), findsOneWidget);
        WidgetTestHelpers.expectTextExists(AppConstants.requestPermissionButton);
      });

      testWidgets('should show no photos message when empty', (WidgetTester tester) async {
        // Arrange
        when(() => mockController.hasPermission).thenReturn(true);
        when(() => mockController.isLoading).thenReturn(false);
        when(() => mockController.photoAssets).thenReturn([]);

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists(AppConstants.noPhotosMessage);
        expect(find.byType(GridView), findsNothing);
      });
    });

    group('Photo Grid Display', () {
      testWidgets('should display grid when photos available', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity(), MockAssetEntity(), MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false, false, false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(GestureDetector), findsNWidgets(3));
      });

      testWidgets('should display photo thumbnails', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(FutureBuilder), findsAtLeastNWidgets(1));
        expect(find.byType(ClipRRect), findsAtLeastNWidgets(1));
      });

      testWidgets('should show selection indicators', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity(), MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([true, false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(CircleAvatar), findsNWidgets(2));
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      });

      testWidgets('should show used photo labels', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockController.isPhotoUsed(0)).thenReturn(true);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists(AppConstants.usedPhotoLabel);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('should call onRequestPermission when permission button tapped', (WidgetTester tester) async {
        // Arrange
        bool permissionRequested = false;
        when(() => mockController.hasPermission).thenReturn(false);
        when(() => mockController.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(
              controller: mockController,
              onRequestPermission: () {
                permissionRequested = true;
              },
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);
        
        await WidgetTestHelpers.tapAndPump(tester, find.byType(ElevatedButton));

        // Assert
        expect(permissionRequested, isTrue);
      });

      testWidgets('should toggle photo selection when photo tapped', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);
        
        await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector).first);

        // Assert
        verify(() => mockController.toggleSelect(0)).called(1);
      });

      testWidgets('should call onUsedPhotoSelected when used photo tapped', (WidgetTester tester) async {
        // Arrange
        bool usedPhotoTapped = false;
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockController.isPhotoUsed(0)).thenReturn(true);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(
              controller: mockController,
              onUsedPhotoSelected: () {
                usedPhotoTapped = true;
              },
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);
        
        await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector).first);

        // Assert
        expect(usedPhotoTapped, isTrue);
        verifyNever(() => mockController.toggleSelect(any()));
      });

      testWidgets('should call onSelectionLimitReached when limit exceeded', (WidgetTester tester) async {
        // Arrange
        bool limitReached = false;
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockController.canSelectPhoto(0)).thenReturn(false);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(
              controller: mockController,
              onSelectionLimitReached: () {
                limitReached = true;
              },
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);
        
        await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector).first);

        // Assert
        expect(limitReached, isTrue);
        verifyNever(() => mockController.toggleSelect(any()));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null callbacks gracefully', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap photo
        await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector).first);

        // Assert - Should not throw
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle large number of photos', (WidgetTester tester) async {
        // Arrange
        final mockAssets = List.generate(50, (index) => MockAssetEntity());
        final selectedStates = List.generate(50, (index) => false);
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn(selectedStates);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('50'), findsOneWidget); // Photo count
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle photo service errors gracefully', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockPhotoService.getThumbnail(any())).thenThrow(
          Exception('Photo service error'),
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert - Should still render without crashing
        expect(find.byType(PhotoGridWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity(), MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false, false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act - Test with different screen sizes
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMediaQuery(
            WidgetTestHelpers.wrapWithMaterialApp(
              PhotoGridWidget(controller: mockController),
            ),
            size: const Size(400, 800), // Phone size
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(GridView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should maintain grid spacing', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity(), MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false, false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisSpacing, equals(AppConstants.photoGridSpacing));
        expect(delegate.mainAxisSpacing, equals(AppConstants.photoGridSpacing));
        expect(delegate.crossAxisCount, equals(AppConstants.photoGridCrossAxisCount));
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        await WidgetTestHelpers.testAccessibility(tester);
      });

      testWidgets('should have semantic information for photos', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final gestureDetectors = find.byType(GestureDetector);
        expect(gestureDetectors, findsAtLeastNWidgets(1));
      });
    });

    group('Performance', () {
      testWidgets('should render efficiently with many photos', (WidgetTester tester) async {
        // Arrange
        final mockAssets = List.generate(20, (index) => MockAssetEntity());
        final selectedStates = List.generate(20, (index) => false);
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn(selectedStates);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should render within 2 seconds
        expect(find.byType(PhotoGridWidget), findsOneWidget);
      });

      testWidgets('should handle rapid selection changes', (WidgetTester tester) async {
        // Arrange
        final mockAssets = [MockAssetEntity(), MockAssetEntity()];
        when(() => mockController.photoAssets).thenReturn(mockAssets);
        when(() => mockController.selected).thenReturn([false, false]);
        when(() => mockPhotoService.getThumbnail(any())).thenAnswer(
          (_) async => null,
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            PhotoGridWidget(controller: mockController),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Rapid tapping
        for (int i = 0; i < 5; i++) {
          await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector).first);
        }

        // Assert
        verify(() => mockController.toggleSelect(0)).called(5);
        expect(tester.takeException(), isNull);
      });
    });
  });
}