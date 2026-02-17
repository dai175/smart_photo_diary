import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../design_system/app_spacing.dart';
import '../animations/micro_interactions.dart';

/// 写真サムネイルウィジェット（futureをキャッシュして再ビルド時の再取得を防止）
///
/// 日記詳細・日記プレビュー等で共通使用する。
class PhotoThumbnailWidget extends StatefulWidget {
  const PhotoThumbnailWidget({
    super.key,
    required this.asset,
    this.size = 120,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final AssetEntity asset;

  /// サムネイルの表示サイズ（正方形の場合は幅・高さ両方に使用）
  final double size;

  /// 画像のフィット方法
  final BoxFit fit;

  /// タップ時のコールバック（画像データを渡す）
  final void Function(BuildContext context, Uint8List imageData)? onTap;

  @override
  State<PhotoThumbnailWidget> createState() => _PhotoThumbnailWidgetState();
}

class _PhotoThumbnailWidgetState extends State<PhotoThumbnailWidget> {
  late Future<Uint8List?> _thumbnailFuture;

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

  Future<Uint8List?> _loadThumbnail() {
    // サイズに応じてサムネイル解像度を選択
    final requestSize = widget.size > AppConstants.previewImageSize
        ? (AppConstants.largeImageSize * 1.2).toInt()
        : (AppConstants.previewImageSize * 1.2).toInt();
    return widget.asset.thumbnailDataWithSize(
      ThumbnailSize(requestSize, requestSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        final imageWidget = Container(
          width: widget.size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppSpacing.photoRadius,
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.photoRadius,
            child: RepaintBoundary(
              child: Image.memory(
                snapshot.data!,
                width: widget.size,
                height: widget.fit == BoxFit.cover ? widget.size : null,
                fit: widget.fit,
                cacheWidth:
                    (widget.size * MediaQuery.of(context).devicePixelRatio)
                        .round(),
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        );

        if (widget.onTap != null) {
          return MicroInteractions.bounceOnTap(
            onTap: () {
              MicroInteractions.hapticTap();
              widget.onTap!(context, snapshot.data!);
            },
            child: imageWidget,
          );
        }

        return imageWidget;
      },
    );
  }
}
