import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../controllers/scroll_signal.dart';
import '../core/service_registration.dart';
import '../localization/localization_extensions.dart';
import '../models/timeline_callbacks.dart';
import '../models/writing_prompt.dart';
import '../screens/diary_preview_screen.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/design_system/app_colors.dart';
import '../widgets/prompt_selection_modal.dart';
import '../widgets/timeline_photo_widget.dart';

/// タイムライン表示とスマートFABを統合したウィジェット
class TimelineFABIntegration extends StatelessWidget {
  /// 写真選択コントローラー
  final PhotoSelectionController controller;

  /// タイムライン関連コールバック群
  final TimelineCallbacks callbacks;

  /// 外部から先頭へスクロールさせるためのシグナル
  final ScrollSignal? scrollSignal;

  const TimelineFABIntegration({
    super.key,
    required this.controller,
    this.callbacks = const TimelineCallbacks(),
    this.scrollSignal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TimelinePhotoWidget(
          controller: controller,
          callbacks: callbacks,
          showFAB: false,
          scrollSignal: scrollSignal,
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            final isSelecting = controller.selectedCount > 0;
            return Stack(
              children: [
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AnimatedOpacity(
                    opacity: isSelecting ? 0.0 : 1.0,
                    duration: AppConstants.standardTransitionDuration,
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: isSelecting,
                      child: FloatingActionButton(
                        heroTag: null,
                        onPressed: callbacks.onCameraPressed,
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        tooltip: context.l10n.fabTooltipTakePhoto,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.photo_camera_rounded, size: 24),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: AnimatedOpacity(
                    opacity: isSelecting ? 1.0 : 0.0,
                    duration: AppConstants.standardTransitionDuration,
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: !isSelecting,
                      child: _buildSelectionPill(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectionPill(BuildContext context) {
    final count = controller.selectedCount;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.homeSelectionCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: controller.clearSelection,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(context.l10n.homeSelectionClearAll),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _onCreateDiaryPressed(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(context.l10n.fabCreateDiaryShort),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreateDiaryPressed(BuildContext context) async {
    final logger = ServiceRegistration.get<ILoggingService>();

    try {
      final selectedPhotos = controller.selectedPhotos;

      logger.info(
        'Starting diary creation (from smart FAB)',
        context: 'TimelineFABIntegration._onCreateDiaryPressed',
        data: 'Selected photos: ${selectedPhotos.length}',
      );

      if (selectedPhotos.isEmpty) {
        logger.warning(
          'Diary creation: no photos selected',
          context: 'TimelineFABIntegration._onCreateDiaryPressed',
        );
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PromptSelectionModal(
          onPromptSelected: (prompt, contextText) {
            Navigator.of(dialogContext).pop();
            _navigateToDiaryPreview(
              context,
              selectedPhotos,
              prompt,
              logger: logger,
              contextText: contextText,
            );
          },
          onSkip: (contextText) {
            Navigator.of(dialogContext).pop();
            _navigateToDiaryPreview(
              context,
              selectedPhotos,
              null,
              logger: logger,
              contextText: contextText,
            );
          },
        ),
      );
    } catch (e) {
      logger.error(
        'Error during diary creation process',
        context: 'TimelineFABIntegration._onCreateDiaryPressed',
        error: e,
      );
    }
  }

  void _navigateToDiaryPreview(
    BuildContext context,
    List<AssetEntity> selectedPhotos,
    WritingPrompt? selectedPrompt, {
    required ILoggingService logger,
    String? contextText,
  }) {
    logger.info(
      'Navigating to diary preview screen',
      context: 'TimelineFABIntegration._navigateToDiaryPreview',
      data:
          'Prompt: ${selectedPrompt?.text ?? "none"}, hasContext: ${contextText != null}, Photos: ${selectedPhotos.length}',
    );

    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: selectedPhotos,
          selectedPrompt: selectedPrompt,
          contextText: contextText,
        ),
      ),
    ).then((created) {
      if (created == true) {
        controller.clearSelection();
        callbacks.onDiaryCreated?.call();
      }
    });
  }
}
