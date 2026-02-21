import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// リストアニメーションの定義
class ListAnimations {
  ListAnimations._();

  /// リストアイテムの順次表示アニメーション（簡略化版）
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration delay = AppConstants.microStaggerUnit,
    Duration duration = AppConstants.xSlowAnimationDuration,
  }) {
    // 簡略化のため、基本的なSlideInWidgetとして実装
    return SlideInWidget(
      delay: Duration(milliseconds: delay.inMilliseconds * index),
      duration: duration,
      begin: const Offset(0, 0.3),
      child: child,
    );
  }

  /// リストの削除アニメーション
  static Widget removeListItem({
    required Widget child,
    required Animation<double> animation,
  }) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// リストアイテムの追加アニメーション
  static Widget insertListItem({
    required Widget child,
    required Animation<double> animation,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// アニメーション付きリストビルダー
class AnimatedListBuilder extends StatefulWidget {
  const AnimatedListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.physics,
    this.staggerDelay = AppConstants.microStaggerUnit,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Duration staggerDelay;
  final Duration animationDuration;

  @override
  State<AnimatedListBuilder> createState() => _AnimatedListBuilderState();
}

class _AnimatedListBuilderState extends State<AnimatedListBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds:
            widget.animationDuration.inMilliseconds +
            (widget.staggerDelay.inMilliseconds * widget.itemCount),
      ),
      vsync: this,
    );

    // アニメーション開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return ListAnimations.staggeredListItem(
          index: index,
          delay: widget.staggerDelay,
          duration: widget.animationDuration,
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}

/// フェードイン効果付きウィジェット
class FadeInWidget extends StatefulWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppConstants.slowAnimationDuration,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // 遅延後にアニメーション開始
    _delayTimer = Timer(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

/// スライドイン効果付きウィジェット
class SlideInWidget extends StatefulWidget {
  const SlideInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppConstants.mediumAnimationDuration,
    this.curve = Curves.easeOutQuart,
    this.begin = const Offset(0.0, 0.2),
    this.end = Offset.zero,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset begin;
  final Offset end;

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // 遅延後にアニメーション開始
    _delayTimer = Timer(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}
