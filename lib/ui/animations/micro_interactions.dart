import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';

/// マイクロインタラクション用のアニメーション効果
class MicroInteractions {
  MicroInteractions._();

  /// ハプティックフィードバック付きのタップ効果
  static void hapticTap({
    VibrationIntensity intensity = VibrationIntensity.light,
  }) {
    switch (intensity) {
      case VibrationIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case VibrationIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case VibrationIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// 選択時のハプティックフィードバック
  static void hapticSelection() {
    HapticFeedback.selectionClick();
  }

  /// バウンス効果
  static Widget bounceOnTap({
    required Widget child,
    required VoidCallback onTap,
    bool enableHaptic = true,
    double scaleFactor = AppConstants.scaleTapSmall,
    Duration duration = AppConstants.microFastAnimationDuration,
  }) {
    return _BounceWrapper(
      onTap: onTap,
      enableHaptic: enableHaptic,
      scaleFactor: scaleFactor,
      duration: duration,
      child: child,
    );
  }

  /// スケールタップ効果（bounceOnTapのエイリアス）
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    bool enableHaptic = true,
    double scaleFactor = AppConstants.scaleTapSmall,
    Duration duration = AppConstants.microFastAnimationDuration,
  }) {
    return bounceOnTap(
      child: child,
      onTap: onTap,
      enableHaptic: enableHaptic,
      scaleFactor: scaleFactor,
      duration: duration,
    );
  }

  /// プルリフレッシュ効果
  static Widget pullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color,
      strokeWidth: 2.5,
      displacement: 60,
      child: child,
    );
  }

  /// シェイク効果
  static Widget shake({
    required Widget child,
    required AnimationController controller,
    double offset = 10.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            offset * controller.value * (controller.value < 0.5 ? 1 : -1),
            0,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// グロー効果
  static Widget glow({
    required Widget child,
    Color? glowColor,
    double blurRadius = 10.0,
    bool enabled = true,
  }) {
    if (!enabled) return child;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color:
                glowColor ??
                Colors.blue.withValues(alpha: AppConstants.opacityXLow),
            blurRadius: blurRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  /// スケール遷移効果
  static Widget scaleTransition({
    required Widget child,
    Duration duration = AppConstants.defaultAnimationDuration,
    Curve curve = Curves.easeOutBack,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
}

/// 振動の強度
enum VibrationIntensity { light, medium, heavy }

/// バウンス効果のラッパーウィジェット
class _BounceWrapper extends StatefulWidget {
  const _BounceWrapper({
    required this.child,
    required this.onTap,
    this.enableHaptic = true,
    this.scaleFactor = AppConstants.scalePressed,
    this.duration = AppConstants.microBaseAnimationDuration,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enableHaptic;
  final double scaleFactor;
  final Duration duration;

  @override
  State<_BounceWrapper> createState() => _BounceWrapperState();
}

class _BounceWrapperState extends State<_BounceWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableHaptic) {
      MicroInteractions.hapticTap();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// パルス効果付きウィジェット
class PulseWidget extends StatefulWidget {
  const PulseWidget({
    super.key,
    required this.child,
    this.duration = AppConstants.longAnimationDuration,
    this.minScale = AppConstants.scalePressed,
    this.maxScale = 1.05,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool enabled;

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// フロート効果付きウィジェット
class FloatingWidget extends StatefulWidget {
  const FloatingWidget({
    super.key,
    required this.child,
    this.duration = AppConstants.xLongAnimationDuration,
    this.offset = 10.0,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final double offset;
  final bool enabled;

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _offsetAnimation = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetAnimation.value),
          child: widget.child,
        );
      },
    );
  }
}

/// ブリーズ効果（透明度変化）
class BreatheWidget extends StatefulWidget {
  const BreatheWidget({
    super.key,
    required this.child,
    this.duration = AppConstants.xLongAnimationDuration,
    this.minOpacity = AppConstants.opacityLow,
    this.maxOpacity = 1.0,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;
  final bool enabled;

  @override
  State<BreatheWidget> createState() => _BreatheWidgetState();
}

class _BreatheWidgetState extends State<BreatheWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _opacityAnimation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreatheWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(opacity: _opacityAnimation.value, child: widget.child);
      },
    );
  }
}
