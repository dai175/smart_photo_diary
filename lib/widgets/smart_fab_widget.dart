import 'package:flutter/material.dart';
import '../controllers/smart_fab_controller.dart';
import '../controllers/photo_selection_controller.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../ui/design_system/app_colors.dart';

/// スマートFABウィジェット
/// 写真選択状態に応じてカメラFABと選択ピルバーを切り替える
class SmartFABWidget extends StatefulWidget {
  final PhotoSelectionController photoController;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onCreateDiaryPressed;
  final bool visible;
  final String? heroTag;

  const SmartFABWidget({
    super.key,
    required this.photoController,
    this.onCameraPressed,
    this.onCreateDiaryPressed,
    this.visible = true,
    this.heroTag,
  });

  @override
  State<SmartFABWidget> createState() => _SmartFABWidgetState();
}

class _SmartFABWidgetState extends State<SmartFABWidget> {
  late SmartFABController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = SmartFABController(
      photoController: widget.photoController,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: AppConstants.standardTransitionDuration,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: widget.visible && _fabController.shouldShow
              ? _buildFAB(context)
              : const SizedBox.shrink(key: ValueKey('fab_hidden')),
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return switch (_fabController.currentState) {
      SmartFABState.camera => _buildCameraFAB(context),
      SmartFABState.createDiary => _buildSelectionPill(context),
    };
  }

  Widget _buildCameraFAB(BuildContext context) {
    return FloatingActionButton(
      key: const ValueKey('fab_camera'),
      heroTag: widget.heroTag,
      onPressed: _onPressed,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      tooltip: context.l10n.fabTooltipTakePhoto,
      shape: const CircleBorder(),
      child: const Icon(Icons.photo_camera_rounded, size: 24),
    );
  }

  Widget _buildSelectionPill(BuildContext context) {
    final count = _fabController.selectedCount;
    return Container(
      key: const ValueKey('fab_selection_pill'),
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
            onPressed: widget.photoController.clearSelection,
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
            onPressed: _onPressed,
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

  void _onPressed() {
    switch (_fabController.currentState) {
      case SmartFABState.camera:
        widget.onCameraPressed?.call();
        break;
      case SmartFABState.createDiary:
        widget.onCreateDiaryPressed?.call();
        break;
    }
  }
}
