import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
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
    if (oldWidget.photoAssets.isEmpty ||
        widget.photoAssets.isEmpty ||
        oldWidget.photoAssets.first.id != widget.photoAssets.first.id) {
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x80000000), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            if (totalCount > 1)
              Positioned(
                bottom: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      color: Colors.black54,
                      child: Text(
                        '1 / $totalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
