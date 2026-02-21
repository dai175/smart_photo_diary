import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/fullscreen_photo_viewer.dart';
import '../../ui/components/photo_gallery.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';

/// 日記詳細の写真セクション
class DiaryDetailPhotoSection extends StatelessWidget {
  const DiaryDetailPhotoSection({
    super.key,
    required this.photoAssets,
    required this.l10n,
  });

  final List<AssetEntity> photoAssets;
  final AppLocalizations l10n;

  static const String _heroTagPrefix = 'diary-detail-asset';

  @override
  Widget build(BuildContext context) {
    return SlideInWidget(
      delay: AppConstants.microStaggerUnit,
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
            PhotoGallery(
              assets: photoAssets,
              multiplePhotoSize: 200,
              heroTagPrefix: _heroTagPrefix,
              onPhotoTap: _onPhotoTap,
            ),
          ],
        ),
      ),
    );
  }

  void _onPhotoTap(
    BuildContext context,
    AssetEntity asset,
    Uint8List imageData,
  ) {
    FullscreenPhotoViewer.show(
      context,
      asset: asset,
      heroTag: '$_heroTagPrefix-${asset.id}',
    );
  }
}
