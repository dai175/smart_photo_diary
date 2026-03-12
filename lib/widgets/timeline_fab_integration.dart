import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../controllers/photo_selection_controller.dart';
import '../controllers/scroll_signal.dart';
import '../core/service_registration.dart';
import '../models/timeline_callbacks.dart';
import '../models/writing_prompt.dart';
import '../screens/diary_preview_screen.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../widgets/prompt_selection_modal.dart';
import '../widgets/smart_fab_widget.dart';
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
          showFAB: false, // FABは別途管理
          scrollSignal: scrollSignal,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SmartFABWidget(
            photoController: controller,
            onCameraPressed: callbacks.onCameraPressed,
            onCreateDiaryPressed: () => _onCreateDiaryPressed(context),
            heroTag: null,
          ),
        ),
      ],
    );
  }

  /// 日記作成ボタンがタップされた時の処理
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

      // プロンプト選択モーダルを表示
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
              contextText: contextText,
            );
          },
          onSkip: (contextText) {
            Navigator.of(dialogContext).pop();
            _navigateToDiaryPreview(
              context,
              selectedPhotos,
              null,
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

  /// 日記プレビュー画面に遷移
  void _navigateToDiaryPreview(
    BuildContext context,
    List<AssetEntity> selectedPhotos,
    WritingPrompt? selectedPrompt, {
    String? contextText,
  }) {
    final logger = ServiceRegistration.get<ILoggingService>();

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
        // 日記作成完了後に選択をクリアし、コールバックを実行
        controller.clearSelection();
        callbacks.onDiaryCreated?.call();
      }
    });
  }
}
