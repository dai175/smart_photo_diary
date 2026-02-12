import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/errors/error_handler.dart';
import '../core/errors/photo_error.dart';
import '../core/result/result.dart';
import 'interfaces/camera_service_interface.dart';
import 'interfaces/logging_service_interface.dart';

/// 今日の写真取得関数の型定義（フォールバック用）
typedef TodayPhotosProvider = Future<List<AssetEntity>> Function({int limit});

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
      _logger.debug('カメラ撮影を開始', context: 'CameraService.capturePhoto');

      // 権限状態の詳細チェック
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // 少し待機してiOSの権限状態が更新されるのを待つ
      final cameraStatus = await Permission.camera.status;
      _logger.debug(
        'カメラ権限状態をチェック: $cameraStatus (isGranted: ${cameraStatus.isGranted}, isDenied: ${cameraStatus.isDenied}, isPermanentlyDenied: ${cameraStatus.isPermanentlyDenied})',
        context: 'CameraService.capturePhoto',
      );

      // 永続的に拒否されている場合のみ事前にブロック
      if (cameraStatus.isPermanentlyDenied) {
        _logger.warning(
          'カメラ権限が永続的に拒否されています',
          context: 'CameraService.capturePhoto',
          data: 'status: $cameraStatus',
        );
        return Failure(PhotoError.cameraPermissionDenied());
      }

      // denied状態でも初回は image_picker を実行して権限ダイアログを表示させる
      _logger.debug(
        'image_pickerでカメラアクセスを実行（権限ダイアログ表示含む）',
        context: 'CameraService.capturePhoto',
        data: '現在の権限状態: $cameraStatus',
      );

      // image_pickerでカメラアクセス
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) {
        _logger.info('カメラ撮影がキャンセルされました', context: 'CameraService.capturePhoto');
        return const Success(null);
      }

      _logger.debug(
        'カメラ撮影完了',
        context: 'CameraService.capturePhoto',
        data: 'ファイルパス: ${photo.path}',
      );

      // 撮影した写真をフォトライブラリに手動保存
      _logger.debug(
        '撮影した写真をフォトライブラリに保存中',
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
          'カメラ撮影が完了し、フォトライブラリに保存されました',
          context: 'CameraService.capturePhoto',
          data: 'AssetID: ${savedAsset.id}',
        );
        return Success(savedAsset);
      } catch (e) {
        _logger.error(
          '撮影した写真の保存処理でエラー: $e',
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
          'カメラ権限がユーザーによって拒否されました',
          context: 'CameraService.capturePhoto',
          data: 'error: $e',
        );

        final statusAfterDenied = await Permission.camera.status;
        _logger.debug(
          '権限拒否後の状態: $statusAfterDenied',
          context: 'CameraService.capturePhoto',
        );

        return Failure(PhotoError.cameraPermissionDenied());
      }

      final appError = ErrorHandler.handleError(
        e,
        context: 'CameraService.capturePhoto',
      );
      _logger.error(
        'カメラ撮影エラー',
        context: 'CameraService.capturePhoto',
        error: appError,
      );
      return Failure(appError);
    }
  }

  /// 撮影した写真のフォールバック検索
  Future<Result<AssetEntity?>> _fallbackSearchCapturedPhoto() async {
    _logger.debug(
      'フォールバック: 従来の方法でAssetEntity検索',
      context: 'CameraService.capturePhoto',
    );

    // photo_managerに新しい写真が追加されるまで少し待つ
    await Future.delayed(const Duration(milliseconds: 1500));

    // 写真ライブラリを更新
    await PhotoManager.clearFileCache();

    // より広い範囲で最新の写真を取得
    final latestPhotos = await _getTodayPhotos(limit: 10);

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
        'フォールバック検索でAssetEntityを取得しました',
        context: 'CameraService.capturePhoto',
        data: 'AssetID: ${capturedAsset.id}',
      );
      return Success(capturedAsset);
    } else {
      _logger.warning(
        'フォールバック検索でもAssetEntityの取得に失敗しました',
        context: 'CameraService.capturePhoto',
      );
      return Failure(PhotoError.cameraAssetNotFound());
    }
  }

  @override
  Future<Result<bool>> requestCameraPermission() async {
    try {
      _logger.debug(
        'カメラ権限リクエスト開始',
        context: 'CameraService.requestCameraPermission',
      );

      var status = await Permission.camera.status;
      _logger.info(
        'カメラ権限の現在の状態: $status (isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
        context: 'CameraService.requestCameraPermission',
      );

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          _logger.warning(
            'カメラ権限が永続的に拒否されています。設定アプリでの許可が必要です。',
            context: 'CameraService.requestCameraPermission',
          );
          return const Success(false);
        }

        _logger.debug(
          'カメラ権限をリクエスト（現在の状態: $status）',
          context: 'CameraService.requestCameraPermission',
        );
        status = await Permission.camera.request();
        _logger.info(
          'リクエスト後のカメラ権限状態: $status (isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
          context: 'CameraService.requestCameraPermission',
        );
      }

      final granted = status.isGranted;
      _logger.info(
        granted ? 'カメラ権限が付与されました' : 'カメラ権限が拒否されました',
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
        'カメラ権限リクエストエラー',
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
        'カメラ権限拒否状態をチェック',
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
        'カメラ権限状態チェックエラー',
        context: 'CameraService.isCameraPermissionDenied',
        error: appError,
      );
      return Failure(appError);
    }
  }
}
