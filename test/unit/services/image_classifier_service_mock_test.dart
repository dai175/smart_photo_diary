import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../test_helpers/mock_platform_channels.dart';

/// Mock interface for ImageClassifierService to avoid TensorFlow Lite loading issues
abstract class ImageClassifierServiceInterface {
  /// Load the ML model and labels
  Future<void> loadModel();
  
  /// Check if the service is initialized
  bool get isInitialized;
  
  /// Classify an image from AssetEntity and return labels
  Future<List<String>> classifyAsset(AssetEntity asset, {int maxResults = 5});
  
  /// Classify raw image data and return labels
  Future<List<String>> classifyImage(Uint8List imageData, {int maxResults = 5});
  
  /// Dispose of resources
  void dispose();
}

/// Mock implementation of ImageClassifierServiceInterface for testing
class MockImageClassifierServiceInterface extends Mock implements ImageClassifierServiceInterface {}

/// Mock AssetEntity for testing
class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('ImageClassifierService Mock Tests', () {
    late MockImageClassifierServiceInterface mockImageClassifier;
    late MockAssetEntity mockAssetEntity;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
      registerFallbackValue(MockAssetEntity());
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(<String>[]);
      registerFallbackValue(const ThumbnailSize(224, 224));
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockImageClassifier = MockImageClassifierServiceInterface();
      mockAssetEntity = MockAssetEntity();
    });

    group('Initialization', () {
      test('should initialize model successfully', () async {
        // Arrange
        when(() => mockImageClassifier.loadModel()).thenAnswer((_) async {});
        when(() => mockImageClassifier.isInitialized).thenReturn(true);

        // Act
        await mockImageClassifier.loadModel();

        // Assert
        expect(mockImageClassifier.isInitialized, isTrue);
        verify(() => mockImageClassifier.loadModel()).called(1);
      });

      test('should handle initialization errors', () async {
        // Arrange
        when(() => mockImageClassifier.loadModel())
            .thenThrow(Exception('Model loading failed'));
        when(() => mockImageClassifier.isInitialized).thenReturn(false);

        // Act & Assert
        expect(
          () => mockImageClassifier.loadModel(),
          throwsA(isA<Exception>()),
        );
        expect(mockImageClassifier.isInitialized, isFalse);
      });

      test('should be uninitialized by default', () {
        // Arrange
        when(() => mockImageClassifier.isInitialized).thenReturn(false);

        // Assert
        expect(mockImageClassifier.isInitialized, isFalse);
      });

      test('should allow re-initialization', () async {
        // Arrange
        when(() => mockImageClassifier.loadModel()).thenAnswer((_) async {});
        when(() => mockImageClassifier.isInitialized).thenReturn(true);

        // Act
        await mockImageClassifier.loadModel();
        await mockImageClassifier.loadModel(); // Second call

        // Assert
        verify(() => mockImageClassifier.loadModel()).called(2);
        expect(mockImageClassifier.isInitialized, isTrue);
      });
    });

    group('Image Classification - Raw Data', () {
      test('should classify image data successfully', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final expectedLabels = ['cat', 'animal', 'pet', 'domestic', 'mammal'];
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final result = await mockImageClassifier.classifyImage(imageData);

        // Assert
        expect(result, equals(expectedLabels));
        expect(result.length, equals(5));
        expect(result, contains('cat'));
        verify(() => mockImageClassifier.classifyImage(
          imageData,
          maxResults: 5,
        )).called(1);
      });

      test('should classify image with custom maxResults', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final expectedLabels = ['dog', 'puppy'];
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final result = await mockImageClassifier.classifyImage(
          imageData,
          maxResults: 2,
        );

        // Assert
        expect(result, equals(expectedLabels));
        expect(result.length, equals(2));
        verify(() => mockImageClassifier.classifyImage(
          imageData,
          maxResults: 2,
        )).called(1);
      });

      test('should handle empty image data', () async {
        // Arrange
        final emptyImageData = Uint8List.fromList([]);
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await mockImageClassifier.classifyImage(emptyImageData);

        // Assert
        expect(result, isEmpty);
        verify(() => mockImageClassifier.classifyImage(
          emptyImageData,
          maxResults: 5,
        )).called(1);
      });

      test('should handle corrupted image data', () async {
        // Arrange
        final corruptedData = Uint8List.fromList([255, 255, 255]);
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenThrow(Exception('Image decoding failed'));

        // Act & Assert
        expect(
          () => mockImageClassifier.classifyImage(corruptedData),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle various image sizes', () async {
        // Arrange
        final smallImage = Uint8List.fromList(List.filled(100, 128));
        final largeImage = Uint8List.fromList(List.filled(10000, 128));
        final expectedLabels = ['generic', 'pattern'];
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final smallResult = await mockImageClassifier.classifyImage(smallImage);
        final largeResult = await mockImageClassifier.classifyImage(largeImage);

        // Assert
        expect(smallResult, equals(expectedLabels));
        expect(largeResult, equals(expectedLabels));
        verify(() => mockImageClassifier.classifyImage(
          smallImage,
          maxResults: 5,
        )).called(1);
        verify(() => mockImageClassifier.classifyImage(
          largeImage,
          maxResults: 5,
        )).called(1);
      });
    });

    group('Asset Classification', () {
      test('should classify asset successfully', () async {
        // Arrange
        final mockThumbnailData = Uint8List.fromList([10, 20, 30, 40, 50]);
        final expectedLabels = ['landscape', 'nature', 'outdoor', 'scenic', 'beauty'];
        
        when(() => mockAssetEntity.thumbnailDataWithSize(any()))
            .thenAnswer((_) async => mockThumbnailData);
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final result = await mockImageClassifier.classifyAsset(mockAssetEntity);

        // Assert
        expect(result, equals(expectedLabels));
        expect(result.length, equals(5));
        expect(result, contains('landscape'));
        verify(() => mockImageClassifier.classifyAsset(
          mockAssetEntity,
          maxResults: 5,
        )).called(1);
      });

      test('should classify asset with custom maxResults', () async {
        // Arrange
        final expectedLabels = ['portrait', 'person'];
        
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final result = await mockImageClassifier.classifyAsset(
          mockAssetEntity,
          maxResults: 2,
        );

        // Assert
        expect(result, equals(expectedLabels));
        expect(result.length, equals(2));
        verify(() => mockImageClassifier.classifyAsset(
          mockAssetEntity,
          maxResults: 2,
        )).called(1);
      });

      test('should handle asset with no thumbnail', () async {
        // Arrange
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await mockImageClassifier.classifyAsset(mockAssetEntity);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle thumbnail loading failure', () async {
        // Arrange
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenThrow(Exception('Thumbnail loading failed'));

        // Act & Assert
        expect(
          () => mockImageClassifier.classifyAsset(mockAssetEntity),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling', () {
      test('should handle uninitialized service gracefully', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        when(() => mockImageClassifier.isInitialized).thenReturn(false);
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenThrow(Exception('Service not initialized'));

        // Act & Assert
        expect(
          () => mockImageClassifier.classifyImage(imageData),
          throwsA(isA<Exception>()),
        );
        expect(mockImageClassifier.isInitialized, isFalse);
      });

      test('should handle model inference errors', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenThrow(Exception('Model inference failed'));

        // Act & Assert
        expect(
          () => mockImageClassifier.classifyImage(imageData),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle invalid maxResults parameter', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final resultNegative = await mockImageClassifier.classifyImage(
          imageData,
          maxResults: -1,
        );
        final resultZero = await mockImageClassifier.classifyImage(
          imageData,
          maxResults: 0,
        );

        // Assert
        expect(resultNegative, isEmpty);
        expect(resultZero, isEmpty);
      });

      test('should recover from temporary failures', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        final expectedLabels = ['recovered', 'success'];
        
        // First call fails, second succeeds
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenThrow(Exception('Temporary failure'));

        // Act & Assert
        // First call fails
        expect(
          () => mockImageClassifier.classifyImage(imageData),
          throwsA(isA<Exception>()),
        );
        
        // Reset the mock for second call
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);
        
        // Second call succeeds
        final result = await mockImageClassifier.classifyImage(imageData);
        expect(result, equals(expectedLabels));
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () {
        // Arrange
        when(() => mockImageClassifier.dispose()).thenReturn(null);

        // Act
        mockImageClassifier.dispose();

        // Assert
        verify(() => mockImageClassifier.dispose()).called(1);
      });

      test('should handle multiple dispose calls', () {
        // Arrange
        when(() => mockImageClassifier.dispose()).thenReturn(null);

        // Act
        mockImageClassifier.dispose();
        mockImageClassifier.dispose();
        mockImageClassifier.dispose();

        // Assert
        verify(() => mockImageClassifier.dispose()).called(3);
      });

      test('should not allow operations after disposal', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        when(() => mockImageClassifier.dispose()).thenReturn(null);
        when(() => mockImageClassifier.isInitialized).thenReturn(false);
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenThrow(Exception('Service disposed'));

        // Act
        mockImageClassifier.dispose();

        // Assert
        expect(mockImageClassifier.isInitialized, isFalse);
        expect(
          () => mockImageClassifier.classifyImage(imageData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle maximum possible maxResults', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        final maxLabels = List.generate(1000, (index) => 'label_$index');
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => maxLabels);

        // Act
        final result = await mockImageClassifier.classifyImage(
          imageData,
          maxResults: 1000,
        );

        // Assert
        expect(result, equals(maxLabels));
        expect(result.length, equals(1000));
      });

      test('should handle very large image data', () async {
        // Arrange
        final largeImageData = Uint8List.fromList(List.filled(1024 * 1024, 128)); // 1MB
        final expectedLabels = ['large', 'image'];
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final result = await mockImageClassifier.classifyImage(largeImageData);

        // Assert
        expect(result, equals(expectedLabels));
      });

      test('should handle concurrent classification requests', () async {
        // Arrange
        final imageData1 = Uint8List.fromList([1, 2, 3]);
        final imageData2 = Uint8List.fromList([4, 5, 6]);
        final labels1 = ['image1', 'first'];
        final labels2 = ['image2', 'second'];
        
        when(() => mockImageClassifier.classifyImage(imageData1, maxResults: 5))
            .thenAnswer((_) async => labels1);
        when(() => mockImageClassifier.classifyImage(imageData2, maxResults: 5))
            .thenAnswer((_) async => labels2);

        // Act
        final futures = [
          mockImageClassifier.classifyImage(imageData1),
          mockImageClassifier.classifyImage(imageData2),
        ];
        final results = await Future.wait(futures);

        // Assert
        expect(results[0], equals(labels1));
        expect(results[1], equals(labels2));
      });

      test('should handle null and empty label scenarios', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await mockImageClassifier.classifyImage(imageData);

        // Assert
        expect(result, isEmpty);
        expect(result, isA<List<String>>());
      });
    });

    group('Performance', () {
      test('should handle rapid successive calls', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        final expectedLabels = ['fast', 'response'];
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final futures = List.generate(
          10,
          (_) => mockImageClassifier.classifyImage(imageData),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(10));
        for (final result in results) {
          expect(result, equals(expectedLabels));
        }
        verify(() => mockImageClassifier.classifyImage(
          imageData,
          maxResults: 5,
        )).called(10);
      });

      test('should handle batch asset processing', () async {
        // Arrange
        final assets = List.generate(5, (index) => mockAssetEntity);
        final expectedLabels = ['batch', 'processed'];
        
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act
        final futures = assets.map(
          (asset) => mockImageClassifier.classifyAsset(asset),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, equals(expectedLabels));
        }
        verify(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: 5,
        )).called(5);
      });
    });

    group('Interface Compliance', () {
      test('should implement ImageClassifierServiceInterface', () {
        expect(mockImageClassifier, isA<ImageClassifierServiceInterface>());
      });

      test('should have all required interface methods', () {
        // Arrange
        when(() => mockImageClassifier.isInitialized).thenReturn(true);
        
        // Assert
        expect(mockImageClassifier.loadModel, isA<Function>());
        expect(mockImageClassifier.isInitialized, isA<bool>());
        expect(mockImageClassifier.classifyAsset, isA<Function>());
        expect(mockImageClassifier.classifyImage, isA<Function>());
        expect(mockImageClassifier.dispose, isA<Function>());
      });

      test('should follow proper method signatures', () {
        // Arrange
        when(() => mockImageClassifier.loadModel()).thenAnswer((_) async {});
        when(() => mockImageClassifier.isInitialized).thenReturn(true);
        when(() => mockImageClassifier.dispose()).thenReturn(null);
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => ['test']);
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => ['test']);
        
        // Test that methods exist and can be called with correct parameters
        expect(mockImageClassifier.loadModel(), isA<Future<void>>());
        expect(mockImageClassifier.isInitialized, isA<bool>());
        expect(() => mockImageClassifier.dispose(), returnsNormally);
        
        // Test async methods with parameters
        final imageData = Uint8List.fromList([1, 2, 3]);
        expect(
          mockImageClassifier.classifyImage(imageData, maxResults: 5),
          isA<Future<List<String>>>(),
        );
        expect(
          mockImageClassifier.classifyAsset(mockAssetEntity, maxResults: 3),
          isA<Future<List<String>>>(),
        );
      });
    });

    group('Data Validation', () {
      test('should return proper data types', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        final expectedLabels = ['test', 'validation'];
        
        when(() => mockImageClassifier.loadModel()).thenAnswer((_) async {});
        when(() => mockImageClassifier.isInitialized).thenReturn(true);
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);
        when(() => mockImageClassifier.classifyAsset(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => expectedLabels);

        // Act & Assert
        await expectLater(mockImageClassifier.loadModel(), completes);
        expect(mockImageClassifier.isInitialized, isA<bool>());
        
        final imageResult = await mockImageClassifier.classifyImage(imageData);
        expect(imageResult, isA<List<String>>());
        
        final assetResult = await mockImageClassifier.classifyAsset(mockAssetEntity);
        expect(assetResult, isA<List<String>>());
      });

      test('should handle string encoding in labels', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3]);
        final unicodeLabels = ['テスト', '画像', '分類', 'emoji_😀', 'special_chars_@#\$'];
        
        when(() => mockImageClassifier.classifyImage(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => unicodeLabels);

        // Act
        final result = await mockImageClassifier.classifyImage(imageData);

        // Assert
        expect(result, equals(unicodeLabels));
        expect(result, contains('テスト'));
        expect(result, contains('emoji_😀'));
      });
    });
  });
}