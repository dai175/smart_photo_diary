import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';
import '../widgets/smart_fab_widget.dart';
import '../services/diary_creation_service.dart';
import '../widgets/timeline_photo_widget.dart';

/// タイムライン表示とスマートFABを統合したウィジェット
class TimelineFABIntegration extends StatelessWidget {
  /// 写真選択コントローラー
  final PhotoSelectionController controller;

  /// 選択上限到達時のコールバック
  final VoidCallback? onSelectionLimitReached;

  /// 使用済み写真選択時のコールバック
  final VoidCallback? onUsedPhotoSelected;

  /// 権限要求コールバック
  final VoidCallback? onRequestPermission;

  /// 異なる日付選択時のコールバック
  final VoidCallback? onDifferentDateSelected;

  /// カメラ撮影コールバック
  final VoidCallback? onCameraPressed;

  /// 日記作成完了時のコールバック
  final VoidCallback? onDiaryCreated;

  const TimelineFABIntegration({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onCameraPressed,
    this.onDiaryCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TimelinePhotoWidget(
          controller: controller,
          onSelectionLimitReached: onSelectionLimitReached,
          onUsedPhotoSelected: onUsedPhotoSelected,
          onRequestPermission: onRequestPermission,
          onDifferentDateSelected: onDifferentDateSelected,
          onCameraPressed: onCameraPressed,
          showFAB: false, // FABは別途管理
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
    final diaryService = DiaryCreationService();
    await diaryService.startDiaryCreation(
      context: context,
      selectedPhotos: controller.selectedPhotos,
      onCompleted: () {
        // 日記作成完了後に選択をクリアし、コールバックを実行
        controller.clearSelection();
        onDiaryCreated?.call();
      },
    );
  }
}
