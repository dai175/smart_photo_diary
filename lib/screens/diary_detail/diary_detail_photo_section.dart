import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/component_constants.dart';
import '../../ui/components/fullscreen_photo_viewer.dart';

/// 日記詳細のヒーロー写真セクション（4:3 フルブリード）
class DiaryDetailPhotoSection extends StatefulWidget {
  const DiaryDetailPhotoSection({super.key, required this.photoAssets});

  final List<AssetEntity> photoAssets;

  @override
  State<DiaryDetailPhotoSection> createState() =>
      _DiaryDetailPhotoSectionState();
}

class _DiaryDetailPhotoSectionState extends State<DiaryDetailPhotoSection> {
  static const String _heroTagPrefix = 'diary-detail-asset';

  late final IPhotoCacheService _photoCacheService;
  late Future<Result<Uint8List>> _heroThumbnailFuture;

  @override
  void initState() {
    super.initState();
    _photoCacheService = serviceLocator.get<IPhotoCacheService>();
    _heroThumbnailFuture = _loadHeroThumbnail();
  }

  @override
  void didUpdateWidget(DiaryDetailPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFirst = oldWidget.photoAssets.isNotEmpty
        ? oldWidget.photoAssets.first.id
        : null;
    final newFirst = widget.photoAssets.isNotEmpty
        ? widget.photoAssets.first.id
        : null;
    if (oldFirst != newFirst) {
      _heroThumbnailFuture = _loadHeroThumbnail();
    }
  }

  Future<Result<Uint8List>> _loadHeroThumbnail() {
    if (widget.photoAssets.isEmpty) {
      return Future.value(
        const Failure(PhotoAccessException('No photo assets')),
      );
    }
    return _photoCacheService.getThumbnail(
      widget.photoAssets.first,
      width: 800,
      height: 600,
      quality: 85,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalCount = widget.photoAssets.length;

    return GestureDetector(
      onTap: () => _onPhotoTap(context),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Result<Uint8List>>(
              future: _heroThumbnailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(color: colorScheme.surfaceContainerHighest);
                }
                final result = snapshot.data;
                if (result is Success<Uint8List>) {
                  return Image.memory(
                    result.value,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                }
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                );
              },
            ),
            const Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.45,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x40000000)),
                ),
              ),
            ),
            if (totalCount > 1)
              Positioned(
                bottom: 14,
                right: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: BlurConstants.defaultBlur,
                      sigmaY: BlurConstants.defaultBlur,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: Colors.black54,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.photoCountIndicator(1, totalCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onPhotoTap(BuildContext context) {
    if (widget.photoAssets.isEmpty) return;
    FullscreenPhotoViewer.show(
      context,
      asset: widget.photoAssets.first,
      heroTag: '$_heroTagPrefix-${widget.photoAssets.first.id}',
    );
  }
}
