import 'package:flutter/material.dart';
import '../controllers/smart_fab_controller.dart';
import '../controllers/photo_selection_controller.dart';

/// スマートFABウィジェット
/// 写真選択状態に応じてカメラ撮影と日記作成を切り替える
class SmartFABWidget extends StatefulWidget {
  /// 写真選択コントローラー
  final PhotoSelectionController photoController;

  /// カメラ撮影処理コールバック
  final VoidCallback? onCameraPressed;

  /// 日記作成処理コールバック
  final VoidCallback? onCreateDiaryPressed;

  /// FAB表示制御（デフォルト: true）
  final bool visible;

  const SmartFABWidget({
    super.key,
    required this.photoController,
    this.onCameraPressed,
    this.onCreateDiaryPressed,
    this.visible = true,
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
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
          child: widget.visible && _fabController.shouldShow
              ? _buildFAB(context)
              : const SizedBox.shrink(key: ValueKey('fab_hidden')),
        );
      },
    );
  }

  /// FABを構築
  Widget _buildFAB(BuildContext context) {
    final theme = Theme.of(context);
    final state = _fabController.currentState;

    return FloatingActionButton(
      key: ValueKey('fab_${state.name}'),
      onPressed: _onPressed,
      backgroundColor: _fabController.getBackgroundColor(theme.colorScheme),
      foregroundColor: _fabController.getForegroundColor(theme.colorScheme),
      tooltip: _fabController.tooltip,
      shape: const CircleBorder(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          _fabController.icon,
          key: ValueKey('icon_${state.name}'),
          size: 24,
        ),
      ),
    );
  }

  /// FABがタップされた時の処理
  void _onPressed() {
    final state = _fabController.currentState;

    switch (state) {
      case SmartFABState.camera:
        widget.onCameraPressed?.call();
        break;
      case SmartFABState.createDiary:
        widget.onCreateDiaryPressed?.call();
        break;
    }
  }
}
