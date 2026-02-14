import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../core/result/result.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../ui/design_system/app_spacing.dart';
import 'photo_grid_components.dart';

/// 写真グリッド表示ウィジェット
class PhotoGridWidget extends StatelessWidget {
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onDifferentDateSelected;

  const PhotoGridWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPhotoGrid(context),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: PhotoGridSelectionCounter(
                selectedCount: controller.selectedCount,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final crossAxisCount = PhotoGridLayout.getCrossAxisCount();
    final gridHeight = PhotoGridLayout.getGridHeight(
      context,
      crossAxisCount: crossAxisCount,
      rowCount: 3,
    );

    if (controller.isLoading) {
      return PhotoGridShimmer(
        crossAxisCount: crossAxisCount,
        height: gridHeight,
      );
    }

    if (!controller.hasPermission) {
      return SizedBox(
        height: gridHeight,
        child: PhotoGridPermissionRequest(
          onRequestPermission: onRequestPermission,
        ),
      );
    }

    if (controller.photoAssets.isEmpty) {
      return SizedBox(height: gridHeight, child: const PhotoGridEmptyState());
    }

    return SizedBox(height: gridHeight, child: _buildGrid(context));
  }

  Widget _buildGrid(BuildContext context) {
    final crossAxisCount = PhotoGridLayout.getCrossAxisCount();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: PhotoGridLayout.getMaxGridWidth(context),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: PhotoGridLayout.gridDelegate(
            crossAxisCount: crossAxisCount,
          ),
          itemCount: controller.photoAssets.length,
          itemBuilder: (context, index) => _buildPhotoItem(context, index),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, int index) {
    final isSelected = controller.selected[index];
    final isUsed = controller.isPhotoUsed(index);

    return PhotoGridItemWrapper(
      index: index,
      isSelected: isSelected,
      isUsed: isUsed,
      onTap: () => _handlePhotoTap(index),
      thumbnail: _buildPhotoThumbnail(context, index),
    );
  }

  Widget _buildPhotoThumbnail(BuildContext context, int index) {
    return ClipRRect(
      borderRadius: AppSpacing.photoRadius,
      child: FutureBuilder<Result<Uint8List>>(
        future: ServiceRegistration.get<IPhotoService>().getThumbnail(
          controller.photoAssets[index],
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data!.isSuccess) {
            return RepaintBoundary(
              child: Image.memory(
                snapshot.data!.value,
                height: AppConstants.photoThumbnailSize,
                width: AppConstants.photoThumbnailSize,
                fit: BoxFit.cover,
                cacheHeight:
                    (AppConstants.photoThumbnailSize *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
                cacheWidth:
                    (AppConstants.photoThumbnailSize *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            );
          }
          return const PhotoThumbnailPlaceholder();
        },
      ),
    );
  }

  void _handlePhotoTap(int index) {
    handlePhotoTap(
      index: index,
      controller: controller,
      onUsedPhotoSelected: onUsedPhotoSelected,
      onSelectionLimitReached: onSelectionLimitReached,
      onDifferentDateSelected: onDifferentDateSelected,
    );
  }
}
