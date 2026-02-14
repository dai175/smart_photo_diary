import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'interfaces/photo_service_interface.dart';
import 'interfaces/photo_permission_service_interface.dart';
import 'interfaces/camera_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import 'photo_query_service.dart';
import 'photo_data_service.dart';

/// 写真の取得と管理を担当するサービスクラス（Facade）
///
/// 権限管理はIPhotoPermissionServiceに、カメラ撮影はICameraServiceに、
/// クエリはPhotoQueryServiceに、データ取得はPhotoDataServiceに委譲。
class PhotoService implements IPhotoService {
  final IPhotoPermissionService _permissionService;
  final PhotoQueryService _queryService;
  final PhotoDataService _dataService;

  PhotoService({
    required ILoggingService logger,
    required IPhotoPermissionService permissionService,
  }) : _permissionService = permissionService,
       _queryService = PhotoQueryService(
         logger: logger,
         requestPermission: permissionService.requestPermission,
       ),
       _dataService = PhotoDataService(logger: logger);

  /// カメラサービス（遅延解決 - 循環依存回避）
  ICameraService get _cameraService => serviceLocator.get<ICameraService>();

  // =================================================================
  // 権限管理メソッド（IPhotoPermissionServiceへの委譲）
  // =================================================================

  @override
  Future<bool> requestPermission() => _permissionService.requestPermission();

  @override
  Future<bool> isPermissionPermanentlyDenied() =>
      _permissionService.isPermissionPermanentlyDenied();

  @override
  Future<bool> presentLimitedLibraryPicker() =>
      _permissionService.presentLimitedLibraryPicker();

  @override
  Future<bool> isLimitedAccess() => _permissionService.isLimitedAccess();

  // =================================================================
  // カメラ撮影メソッド（ICameraServiceへの委譲）
  // =================================================================

  @override
  Future<Result<AssetEntity?>> capturePhoto() => _cameraService.capturePhoto();

  @override
  Future<Result<bool>> requestCameraPermission() =>
      _cameraService.requestCameraPermission();

  @override
  Future<Result<bool>> isCameraPermissionDenied() =>
      _cameraService.isCameraPermissionDenied();

  // =================================================================
  // クエリメソッド（PhotoQueryServiceへの委譲）
  // =================================================================

  @override
  Future<Result<List<AssetEntity>>> getTodayPhotos({int limit = 20}) =>
      _queryService.getTodayPhotos(limit: limit);

  @override
  Future<Result<List<AssetEntity>>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) => _queryService.getPhotosInDateRange(
    startDate: startDate,
    endDate: endDate,
    limit: limit,
  );

  @override
  Future<Result<List<AssetEntity>>> getPhotosForDate(
    DateTime date, {
    required int offset,
    required int limit,
  }) => _queryService.getPhotosForDate(date, offset: offset, limit: limit);

  @override
  Future<Result<List<AssetEntity>>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) => _queryService.getPhotosEfficient(
    startDate: startDate,
    endDate: endDate,
    offset: offset,
    limit: limit,
  );

  // =================================================================
  // ID指定での写真取得（PhotoDataServiceへの委譲）
  // =================================================================

  @override
  Future<Result<List<AssetEntity>>> getAssetsByIds(List<String> photoIds) =>
      _dataService.getAssetsByIds(photoIds);

  // =================================================================
  // データ取得メソッド（PhotoDataServiceへの委譲）
  // =================================================================

  @override
  Future<List<int>?> getPhotoData(AssetEntity asset) =>
      _dataService.getPhotoData(asset);

  @override
  Future<List<int>?> getThumbnailData(AssetEntity asset) =>
      _dataService.getThumbnailData(asset);

  @override
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  }) => _dataService.getThumbnail(asset, width: width, height: height);

  @override
  Future<Uint8List?> getOriginalFile(AssetEntity asset) =>
      _dataService.getOriginalFile(asset);
}
