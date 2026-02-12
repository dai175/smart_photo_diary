import 'dart:typed_data' as typed_data;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';

/// 写真サムネイルウィジェット（future をキャッシュして再ビルド時の再取得を防止）
class PhotoThumbnailWidget extends StatefulWidget {
  final AssetEntity asset;

  const PhotoThumbnailWidget({super.key, required this.asset});

  @override
  State<PhotoThumbnailWidget> createState() => _PhotoThumbnailWidgetState();
}

class _PhotoThumbnailWidgetState extends State<PhotoThumbnailWidget> {
  late Future<typed_data.Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _loadThumbnail();
  }

  @override
  void didUpdateWidget(PhotoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _thumbnailFuture = _loadThumbnail();
    }
  }

  Future<typed_data.Uint8List?> _loadThumbnail() {
    return widget.asset.thumbnailDataWithSize(
      ThumbnailSize(
        (AppConstants.previewImageSize * 1.2).toInt(),
        (AppConstants.previewImageSize * 1.2).toInt(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: AppSpacing.photoRadius),
      child: ClipRRect(
        borderRadius: AppSpacing.photoRadius,
        child: FutureBuilder<typed_data.Uint8List?>(
          future: _thumbnailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppSpacing.photoRadius,
                ),
                child: ClipRRect(
                  borderRadius: AppSpacing.photoRadius,
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    width: 120,
                    height: 120,
                  ),
                ),
              );
            }
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppSpacing.photoRadius,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
