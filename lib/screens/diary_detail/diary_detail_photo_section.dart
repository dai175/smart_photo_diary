import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/photo_gallery.dart';
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
            PhotoGallery(
              assets: photoAssets,
              multiplePhotoSize: 200,
              onPhotoTap: _showPhotoDialog,
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
