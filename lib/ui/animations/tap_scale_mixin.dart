import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// タップ時のスケールアニメーションを提供する mixin
///
/// [SingleTickerProviderStateMixin] または [TickerProviderStateMixin] と
/// 組み合わせて使用します。
///
/// ## 使用例
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin, TapScaleMixin {
///   @override
///   void initState() {
///     super.initState();
///     initTapScale(vsync: this, duration: duration);
///   }
///
///   @override
///   void dispose() {
///     disposeTapScale();
///     super.dispose();
///   }
/// }
/// ```
mixin TapScaleMixin {
  /// タップスケール用のアニメーションコントローラ
  late AnimationController tapScaleController;

  /// タップスケール用のアニメーション
  late Animation<double> tapScaleAnimation;

  /// タップスケールアニメーションを初期化
  void initTapScale({
    required TickerProvider vsync,
    required Duration duration,
    double scaleFactor = AppConstants.scalePressed,
  }) {
    tapScaleController = AnimationController(duration: duration, vsync: vsync);
    tapScaleAnimation = Tween<double>(begin: 1.0, end: scaleFactor).animate(
      CurvedAnimation(parent: tapScaleController, curve: Curves.easeInOut),
    );
  }

  /// タップスケールアニメーションを破棄
  void disposeTapScale() {
    tapScaleController.dispose();
  }

  /// タップダウン時にスケールアニメーションを開始
  void handleTapScaleDown() {
    tapScaleController.forward();
  }

  /// タップアップ時にスケールアニメーションを戻す
  void handleTapScaleUp() {
    tapScaleController.reverse();
  }

  /// タップキャンセル時にスケールアニメーションを戻す
  void handleTapScaleCancel() {
    tapScaleController.reverse();
  }
}
