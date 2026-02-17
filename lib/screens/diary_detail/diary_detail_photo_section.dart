import 'dart:math' as math;
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

  /// 写真の表示高さを計算する（幅に応じたアスペクト比計算）
  double _calcPhotoHeight(AssetEntity asset, double displayWidth) {
    if (asset.width == 0 || asset.height == 0) return displayWidth;
    return displayWidth * asset.height / asset.width;
  }

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
            if (photoAssets.length == 1)
              _buildSinglePhoto(context)
            else
              _buildMultiplePhotos(context),
          ],
        ),
      ),
    );
  }

  /// 写真1枚: アスペクト比に応じた表示
  Widget _buildSinglePhoto(BuildContext context) {
    final asset = photoAssets.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final height = _calcPhotoHeight(asset, cardWidth).clamp(120.0, 240.0);
        final actualWidth = (asset.width > 0 && asset.height > 0)
            ? math.min(cardWidth, height * asset.width / asset.height)
            : cardWidth;
        return Center(
          child: SizedBox(
            height: height,
            child: _PhotoItem(
              asset: asset,
              onTap: _showPhotoDialog,
              displayWidth: actualWidth,
            ),
          ),
        );
      },
    );
  }

  /// 複数写真: 正方形サムネイルで水平スクロール
  Widget _buildMultiplePhotos(BuildContext context) {
    const itemSize = 200.0;

    return SizedBox(
      height: itemSize,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoAssets.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == photoAssets.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _PhotoItem(
              asset: photoAssets[index],
              onTap: _showPhotoDialog,
              displayWidth: itemSize,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                    child: Image.memory(
                      imageData,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
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
  const _PhotoItem({
    required this.asset,
    required this.onTap,
    this.displayWidth = 200,
    this.fit = BoxFit.contain,
  });

  final AssetEntity asset;
  final void Function(BuildContext context, Uint8List imageData) onTap;
  final double displayWidth;
  final BoxFit fit;

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
            width: widget.displayWidth,
            height: widget.displayWidth,
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
            width: widget.displayWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.photoRadius,
              child: RepaintBoundary(
                child: Image.memory(
                  snapshot.data!,
                  width: widget.displayWidth,
                  height: widget.fit == BoxFit.cover
                      ? widget.displayWidth
                      : null,
                  fit: widget.fit,
                  cacheWidth:
                      (widget.displayWidth *
                              MediaQuery.of(context).devicePixelRatio)
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
