import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/errors/error_handler.dart';
import '../core/errors/photo_error.dart';
import '../core/result/result.dart';
import 'interfaces/camera_service_interface.dart';
import 'interfaces/logging_service_interface.dart';

/// 今日の写真取得関数の型定義（フォールバック用）
typedef TodayPhotosProvider =
    Future<Result<List<AssetEntity>>> Function({int limit});

/// カメラ撮影サービス
///
/// image_pickerを使用したカメラ撮影、権限管理を担当。
/// 撮影後のフォトライブラリ保存とフォールバック検索も含む。
class CameraService implements ICameraService {
  final ILoggingService _logger;
  final ImagePicker _imagePicker = ImagePicker();
  final TodayPhotosProvider _getTodayPhotos;

  CameraService({
    required ILoggingService logger,
    required TodayPhotosProvider getTodayPhotos,
  }) : _logger = logger,
       _getTodayPhotos = getTodayPhotos;

  @override
  Future<Result<AssetEntity?>> capturePhoto() async {
    try {
      _logger.debug(
        'Starting camera capture',
        context: 'CameraService.capturePhoto',
      );

      // 権限状態の詳細チェック
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // 少し待機してiOSの権限状態が更新されるのを待つ
      final cameraStatus = await Permission.camera.status;
      _logger.debug(
        'Checking camera permission status: $cameraStatus (isGranted: ${cameraStatus.isGranted}, isDenied: ${cameraStatus.isDenied}, isPermanentlyDenied: ${cameraStatus.isPermanentlyDenied})',
        context: 'CameraService.capturePhoto',
      );

      // 永続的に拒否されている場合のみ事前にブロック
      if (cameraStatus.isPermanentlyDenied) {
        _logger.warning(
          'Camera permission is permanently denied',
          context: 'CameraService.capturePhoto',
          data: 'status: $cameraStatus',
        );
        return Failure(PhotoError.cameraPermissionDenied());
      }

      // denied状態でも初回は image_picker を実行して権限ダイアログを表示させる
      _logger.debug(
        'Executing camera access via image_picker (including permission dialog)',
        context: 'CameraService.capturePhoto',
        data: 'Current permission status: $cameraStatus',
      );

      // image_pickerでカメラアクセス
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) {
        _logger.info(
          'Camera capture was cancelled',
          context: 'CameraService.capturePhoto',
        );
        return const Success(null);
      }

      _logger.debug(
        'Camera capture completed',
        context: 'CameraService.capturePhoto',
        data: 'File path: ${photo.path}',
      );

      // 撮影した写真をフォトライブラリに手動保存
      _logger.debug(
        'Saving captured photo to photo library',
        context: 'CameraService.capturePhoto',
      );

      try {
        final bytes = await photo.readAsBytes();
        final savedAsset = await PhotoManager.editor.saveImage(
          bytes,
          filename:
              'Smart_Photo_Diary_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        _logger.info(
          'Camera capture completed and saved to photo library',
          context: 'CameraService.capturePhoto',
          data: 'AssetID: ${savedAsset.id}',
        );
        return Success(savedAsset);
      } catch (e) {
        _logger.error(
          'Error saving captured photo: $e',
          context: 'CameraService.capturePhoto',
        );

        // フォールバック: 従来の方法で検索
        return _fallbackSearchCapturedPhoto();
      }
    } catch (e) {
      // image_pickerでの権限拒否エラーを特別処理
      if (e.toString().contains('camera_access_denied') ||
          e.toString().contains('Permission denied') ||
          e.toString().contains('User denied')) {
        _logger.warning(
          'Camera permission was denied by user',
          context: 'CameraService.capturePhoto',
          data: 'error: $e',
        );

        final statusAfterDenied = await Permission.camera.status;
        _logger.debug(
          'Permission status after denial: $statusAfterDenied',
          context: 'CameraService.capturePhoto',
        );

        return Failure(PhotoError.cameraPermissionDenied());
      }

      final appError = ErrorHandler.handleError(
        e,
        context: 'CameraService.capturePhoto',
      );
      _logger.error(
        'Camera capture error',
        context: 'CameraService.capturePhoto',
        error: appError,
      );
      return Failure(appError);
    }
  }

  /// 撮影した写真のフォールバック検索
  Future<Result<AssetEntity?>> _fallbackSearchCapturedPhoto() async {
    _logger.debug(
      'Fallback: Searching AssetEntity using legacy method',
      context: 'CameraService.capturePhoto',
    );

    // photo_managerに新しい写真が追加されるまで少し待つ
    await Future.delayed(const Duration(milliseconds: 1500));

    // 写真ライブラリを更新
    await PhotoManager.clearFileCache();

    // より広い範囲で最新の写真を取得
    final todayResult = await _getTodayPhotos(limit: 10);
    final latestPhotos = todayResult.getOrDefault([]);

    // 撮影時刻に最も近い写真を探す
    final captureTime = DateTime.now();
    AssetEntity? capturedAsset;

    for (final asset in latestPhotos) {
      final timeDiff = captureTime.difference(asset.createDateTime).abs();
      if (timeDiff.inMinutes < 5) {
        capturedAsset = asset;
        break;
      }
    }

    if (capturedAsset != null) {
      _logger.info(
        'AssetEntity retrieved via fallback search',
        context: 'CameraService.capturePhoto',
        data: 'AssetID: ${capturedAsset.id}',
      );
      return Success(capturedAsset);
    } else {
      _logger.warning(
        'Failed to retrieve AssetEntity even with fallback search',
        context: 'CameraService.capturePhoto',
      );
      return Failure(PhotoError.cameraAssetNotFound());
    }
  }

  @override
  Future<Result<bool>> requestCameraPermission() async {
    try {
      _logger.debug(
        'Starting camera permission request',
        context: 'CameraService.requestCameraPermission',
      );

      var status = await Permission.camera.status;
      _logger.info(
        'Current camera permission status: $status (isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
        context: 'CameraService.requestCameraPermission',
      );

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          _logger.warning(
            'Camera permission is permanently denied. Permission must be granted in Settings.',
            context: 'CameraService.requestCameraPermission',
          );
          return const Success(false);
        }

        _logger.debug(
          'Requesting camera permission (current status: $status)',
          context: 'CameraService.requestCameraPermission',
        );
        status = await Permission.camera.request();
        _logger.info(
          'Camera permission status after request: $status (isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
          context: 'CameraService.requestCameraPermission',
        );
      }

      final granted = status.isGranted;
      _logger.info(
        granted ? 'Camera permission granted' : 'Camera permission denied',
        context: 'CameraService.requestCameraPermission',
        data: 'status: $status',
      );

      return Success(granted);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'CameraService.requestCameraPermission',
      );
      _logger.error(
        'Camera permission request error',
        context: 'CameraService.requestCameraPermission',
        error: appError,
      );
      return Failure(appError);
    }
  }

  @override
  Future<Result<bool>> isCameraPermissionDenied() async {
    try {
      final status = await Permission.camera.status;
      final isDenied = status.isDenied || status.isPermanentlyDenied;

      _logger.debug(
        'Checking camera permission denied status',
        context: 'CameraService.isCameraPermissionDenied',
        data: 'status: $status, isDenied: $isDenied',
      );

      return Success(isDenied);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'CameraService.isCameraPermissionDenied',
      );
      _logger.error(
        'Camera permission status check error',
        context: 'CameraService.isCameraPermissionDenied',
        error: appError,
      );
      return Failure(appError);
    }
  }
}
