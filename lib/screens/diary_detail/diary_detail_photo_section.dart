import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../ui/animations/micro_interactions.dart';

/// 日記詳細の写真セクション
class DiaryDetailPhotoSection extends StatelessWidget {
  const DiaryDetailPhotoSection({
    super.key,
    required this.photoAssets,
    required this.l10n,
  });

  final List<AssetEntity> photoAssets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SlideInWidget(
      delay: const Duration(milliseconds: 100),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppSpacing.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.diaryDetailPhotosSectionTitle(photoAssets.length),
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photoAssets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == photoAssets.length - 1
                          ? 0
                          : AppSpacing.md,
                    ),
                    child: _PhotoItem(
                      asset: photoAssets[index],
                      onTap: _showPhotoDialog,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.cardRadiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppSpacing.cardRadiusLarge,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Image.memory(imageData, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: MicroInteractions.bounceOnTap(
                  onTap: () {
                    MicroInteractions.hapticTap();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 写真アイテム（FutureをStatefulWidgetでキャッシュ）
class _PhotoItem extends StatefulWidget {
  const _PhotoItem({required this.asset, required this.onTap});

  final AssetEntity asset;
  final void Function(BuildContext context, Uint8List imageData) onTap;

  @override
  State<_PhotoItem> createState() => _PhotoItemState();
}

class _PhotoItemState extends State<_PhotoItem> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _loadThumbnail();
  }

  @override
  void didUpdateWidget(_PhotoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _thumbnailFuture = _loadThumbnail();
    }
  }

  Future<Uint8List?> _loadThumbnail() {
    return widget.asset.thumbnailDataWithSize(
      ThumbnailSize(
        (AppConstants.largeImageSize * 1.2).toInt(),
        (AppConstants.largeImageSize * 1.2).toInt(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 200,
            height: 200,
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

        return MicroInteractions.bounceOnTap(
          onTap: () {
            MicroInteractions.hapticTap();
            widget.onTap(context, snapshot.data!);
          },
          child: Container(
            width: 200,
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.photoRadius,
              child: RepaintBoundary(
                child: Image.memory(
                  snapshot.data!,
                  width: 200,
                  fit: BoxFit.contain,
                  cacheWidth: (200 * MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
