import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../services/photo_service.dart';

/// 写真グリッド表示ウィジェット
class PhotoGridWidget extends StatelessWidget {
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onRequestPermission;

  const PhotoGridWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppConstants.smallPadding),
            _buildPhotoGrid(context),
            const SizedBox(height: AppConstants.smallPadding),
            _buildSelectionCounter(context),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          AppConstants.newPhotosTitle,
          style: TextStyle(
            fontSize: AppConstants.sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.smallPadding,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${controller.photoAssets.length}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    return SizedBox(
      height: AppConstants.photoGridHeight,
      child: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !controller.hasPermission
              ? _buildPermissionRequest()
              : controller.photoAssets.isNotEmpty
                  ? _buildGrid()
                  : const Center(
                      child: Text(AppConstants.noPhotosMessage),
                    ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          const Text(AppConstants.permissionMessage),
          const SizedBox(height: AppConstants.smallPadding),
          ElevatedButton(
            onPressed: onRequestPermission,
            child: const Text(AppConstants.requestPermissionButton),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.photoGridCrossAxisCount,
        crossAxisSpacing: AppConstants.photoGridSpacing,
        mainAxisSpacing: AppConstants.photoGridSpacing,
      ),
      itemCount: controller.photoAssets.length,
      itemBuilder: (context, index) => _buildPhotoItem(index),
    );
  }

  Widget _buildPhotoItem(int index) {
    return GestureDetector(
      onTap: () => _handlePhotoTap(index),
      child: Stack(
        children: [
          _buildPhotoThumbnail(index),
          _buildSelectionIndicator(index),
          if (controller.isPhotoUsed(index)) _buildUsedLabel(),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.photoCornerRadius),
      child: FutureBuilder<dynamic>(
        future: PhotoService.getThumbnail(controller.photoAssets[index]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: AppConstants.photoThumbnailSize,
              width: AppConstants.photoThumbnailSize,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              height: AppConstants.photoThumbnailSize,
              width: AppConstants.photoThumbnailSize,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSelectionIndicator(int index) {
    return Positioned(
      top: 4,
      right: 4,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.white,
        child: _getSelectionIcon(index),
      ),
    );
  }

  Widget _getSelectionIcon(int index) {
    if (controller.isPhotoUsed(index)) {
      return const Icon(
        Icons.check,
        color: Colors.orange,
        size: 22,
      );
    } else {
      return Icon(
        controller.selected[index]
            ? Icons.check_circle
            : Icons.radio_button_unchecked,
        color: controller.selected[index] ? Colors.green : Colors.grey,
        size: 22,
      );
    }
  }

  Widget _buildUsedLabel() {
    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          AppConstants.usedPhotoLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: AppConstants.smallCaptionFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCounter(BuildContext context) {
    return Text(
      '選択された写真: ${controller.selectedCount}/${AppConstants.maxPhotosSelection}枚',
      style: TextStyle(
        fontSize: AppConstants.captionFontSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _handlePhotoTap(int index) {
    if (controller.isPhotoUsed(index)) {
      onUsedPhotoSelected?.call();
      return;
    }

    if (!controller.canSelectPhoto(index)) {
      onSelectionLimitReached?.call();
      return;
    }

    controller.toggleSelect(index);
  }
}