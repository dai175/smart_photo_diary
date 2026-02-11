import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/errors/error_handler.dart';
import 'interfaces/photo_permission_service_interface.dart';
import 'interfaces/logging_service_interface.dart';

/// 写真アクセス権限管理サービス
///
/// PhotoManager/permission_handlerを使用した
/// 写真ライブラリの権限リクエスト・状態チェックを担当
class PhotoPermissionService implements IPhotoPermissionService {
  final ILoggingService _logger;

  PhotoPermissionService({required ILoggingService logger}) : _logger = logger;

  @override
  Future<bool> requestPermission() async {
    try {
      _logger.debug(
        '権限リクエスト開始',
        context: 'PhotoPermissionService.requestPermission',
      );

      // まずはPhotoManagerで権限リクエスト（これがメイン）
      final pmState = await PhotoManager.requestPermissionExtend();
      _logger.debug(
        'PhotoManager権限状態: $pmState',
        context: 'PhotoPermissionService.requestPermission',
      );

      if (pmState.isAuth) {
        _logger.info(
          '写真アクセス権限が付与されました',
          context: 'PhotoPermissionService.requestPermission',
        );
        return true;
      }

      // Limited access の場合も部分的に許可とみなす（iOS専用）
      if (pmState == PermissionState.limited) {
        _logger.info(
          '制限つき写真アクセスが許可されました',
          context: 'PhotoPermissionService.requestPermission',
        );
        return true;
      }

      // PhotoManagerで権限が拒否された場合、Androidでは追加でpermission_handlerを試す
      if (defaultTargetPlatform == TargetPlatform.android) {
        _logger.debug(
          'Android: permission_handlerで追加の権限チェックを実行',
          context: 'PhotoPermissionService.requestPermission',
        );

        // Android 13以降は Permission.photos、それ以前は Permission.storage
        Permission permission = Permission.photos;

        var status = await permission.status;
        _logger.debug(
          'permission_handler権限状態: $status',
          context: 'PhotoPermissionService.requestPermission',
        );

        // 権限が未決定または拒否の場合は明示的にリクエスト
        if (status.isDenied) {
          _logger.debug(
            'Android: 権限を明示的にリクエストします',
            context: 'PhotoPermissionService.requestPermission',
          );
          status = await permission.request();
          _logger.debug(
            'Android: リクエスト後の権限状態: $status',
            context: 'PhotoPermissionService.requestPermission',
          );

          if (status.isGranted) {
            _logger.info(
              'Android: 権限が付与されました',
              context: 'PhotoPermissionService.requestPermission',
            );
            // PhotoManagerで再度確認
            final pmStateAfter = await PhotoManager.requestPermissionExtend();
            _logger.debug(
              'Android: PhotoManager再確認結果: $pmStateAfter',
              context: 'PhotoPermissionService.requestPermission',
            );
            return pmStateAfter.isAuth;
          }
        }

        // 永続的に拒否されている場合
        if (status.isPermanentlyDenied) {
          _logger.warning(
            'Android: 権限が永続的に拒否されています',
            context: 'PhotoPermissionService.requestPermission',
          );
          return false;
        }
      }

      _logger.warning(
        '写真アクセス権限が拒否されました',
        context: 'PhotoPermissionService.requestPermission',
        data: 'pmState: $pmState',
      );
      return false;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoPermissionService.requestPermission',
      );
      _logger.error(
        '権限リクエストエラー',
        context: 'PhotoPermissionService.requestPermission',
        error: appError,
      );
      return false;
    }
  }

  @override
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final currentStatus = await Permission.photos.status;
      return currentStatus.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> presentLimitedLibraryPicker() async {
    try {
      await PhotoManager.presentLimited();
      return true;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoPermissionService.presentLimitedLibraryPicker',
      );
      _logger.error(
        'Limited Library Picker表示エラー',
        context: 'PhotoPermissionService.presentLimitedLibraryPicker',
        error: appError,
      );
      return false;
    }
  }

  @override
  Future<bool> isLimitedAccess() async {
    try {
      final pmState = await PhotoManager.requestPermissionExtend();
      return pmState == PermissionState.limited;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoPermissionService.isLimitedAccess',
      );
      _logger.error(
        '権限状態チェックエラー',
        context: 'PhotoPermissionService.isLimitedAccess',
        error: appError,
      );
      return false;
    }
  }
}
