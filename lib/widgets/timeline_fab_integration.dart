import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../controllers/photo_selection_controller.dart';
import '../controllers/scroll_signal.dart';
import '../core/service_registration.dart';
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

  /// 選択上限到達時のコールバック
  final VoidCallback? onSelectionLimitReached;

  /// 使用済み写真選択時のコールバック
  final VoidCallback? onUsedPhotoSelected;

  /// 使用済み写真詳細表示コールバック
  final Function(String photoId)? onUsedPhotoDetail;

  /// 権限要求コールバック
  final VoidCallback? onRequestPermission;

  /// 異なる日付選択時のコールバック
  final VoidCallback? onDifferentDateSelected;

  /// カメラ撮影コールバック
  final VoidCallback? onCameraPressed;

  /// 日記作成完了時のコールバック
  final VoidCallback? onDiaryCreated;

  /// 追加写真読み込み要求コールバック
  final VoidCallback? onLoadMorePhotos;

  /// バックグラウンド先読み要求コールバック
  final VoidCallback? onPreloadMorePhotos;

  /// 外部から先頭へスクロールさせるためのシグナル
  final ScrollSignal? scrollSignal;

  const TimelineFABIntegration({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onUsedPhotoDetail,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onCameraPressed,
    this.onDiaryCreated,
    this.onLoadMorePhotos,
    this.onPreloadMorePhotos,
    this.scrollSignal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TimelinePhotoWidget(
          controller: controller,
          onSelectionLimitReached: onSelectionLimitReached,
          onUsedPhotoSelected: onUsedPhotoSelected,
          onUsedPhotoDetail: onUsedPhotoDetail,
          onRequestPermission: onRequestPermission,
          onDifferentDateSelected: onDifferentDateSelected,
          onCameraPressed: onCameraPressed,
          onLoadMorePhotos: onLoadMorePhotos,
          onPreloadMorePhotos: onPreloadMorePhotos,
          showFAB: false, // FABは別途管理
          scrollSignal: scrollSignal,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SmartFABWidget(
            photoController: controller,
            onCameraPressed: onCameraPressed,
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
        '日記作成開始（スマートFABから）',
        context: 'TimelineFABIntegration._onCreateDiaryPressed',
        data: '選択写真数: ${selectedPhotos.length}',
      );

      if (selectedPhotos.isEmpty) {
        logger.warning(
          '日記作成: 写真が選択されていません',
          context: 'TimelineFABIntegration._onCreateDiaryPressed',
        );
        return;
      }

      // プロンプト選択モーダルを表示
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PromptSelectionModal(
          onPromptSelected: (prompt) {
            Navigator.of(dialogContext).pop();
            _navigateToDiaryPreview(context, selectedPhotos, prompt);
          },
          onSkip: () {
            Navigator.of(dialogContext).pop();
            _navigateToDiaryPreview(context, selectedPhotos, null);
          },
        ),
      );
    } catch (e) {
      logger.error(
        '日記作成処理中にエラーが発生',
        context: 'TimelineFABIntegration._onCreateDiaryPressed',
        error: e,
      );
    }
  }

  /// 日記プレビュー画面に遷移
  void _navigateToDiaryPreview(
    BuildContext context,
    List<AssetEntity> selectedPhotos,
    WritingPrompt? selectedPrompt,
  ) {
    final logger = ServiceRegistration.get<ILoggingService>();

    logger.info(
      '日記プレビュー画面に遷移',
      context: 'TimelineFABIntegration._navigateToDiaryPreview',
      data:
          'プロンプト: ${selectedPrompt?.text ?? "なし"}, 写真数: ${selectedPhotos.length}',
    );

    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: selectedPhotos,
          selectedPrompt: selectedPrompt,
        ),
      ),
    ).then((created) {
      if (created == true) {
        // 日記作成完了後に選択をクリアし、コールバックを実行
        controller.clearSelection();
        onDiaryCreated?.call();
      }
    });
  }
}
