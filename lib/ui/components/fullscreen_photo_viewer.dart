import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
import '../component_constants.dart';

/// フルスクリーン写真ビューアー
///
/// Hero アニメーション + ピンチズーム + 大サイズプレビュー画像（1200px）を表示する。
/// ホーム画面・日記詳細画面で共通使用する。
class FullscreenPhotoViewer {
  FullscreenPhotoViewer._();

  /// フルスクリーンで大サイズプレビュー写真を表示する
  static void show(
    BuildContext context, {
    required AssetEntity asset,
    required String heroTag,
  }) {
    final cacheService = serviceLocator.get<IPhotoCacheService>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.commonClose,
      barrierColor: Colors.black.withValues(alpha: AppConstants.opacityHigh),
      transitionDuration: AppConstants.defaultAnimationDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        final screenSize = MediaQuery.of(context).size;
        return GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: InteractiveViewer(
            minScale: ViewerConstants.minScale,
            maxScale: ViewerConstants.maxScale,
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: FutureBuilder<Result<Uint8List>>(
                    future: cacheService.getThumbnail(
                      asset,
                      width: PhotoPreviewConstants.previewSizePx,
                      height: PhotoPreviewConstants.previewSizePx,
                      quality: PhotoPreviewConstants.previewQuality,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth:
                                PhotoPreviewConstants.progressStrokeWidth,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isFailure) {
                        return const SizedBox.shrink();
                      }
                      return Image.memory(
                        snapshot.data!.value,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
