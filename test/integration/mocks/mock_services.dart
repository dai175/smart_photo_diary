import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';

/// Mock PhotoService for integration testing
class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}

/// Mock AiService for integration testing
class MockAiServiceInterface extends Mock implements AiServiceInterface {}

/// Mock AssetEntity for integration testing
class MockAssetEntity extends Mock implements AssetEntity {}

/// Mock AssetPathEntity for integration testing
class MockAssetPathEntity extends Mock implements AssetPathEntity {}

/// Mock classes for other dependencies can be added here as needed
class MockConnectivity extends Mock {}

class MockImageClassifier extends Mock {}

/// Helper to register fallback values for mocktail
void registerMockFallbacks() {
  registerFallbackValue(DateTime.now());
  registerFallbackValue(MockAssetEntity());
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(<AssetEntity>[]);
  registerFallbackValue(<String>[]);
  registerFallbackValue(<DateTime>[]);
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(<({Uint8List imageData, DateTime time})>[]);
}