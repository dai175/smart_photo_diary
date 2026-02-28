import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// ページ遷移アニメーションの定義
class PageTransitions {
  PageTransitions._();

  /// フェードトランジション
  static PageRouteBuilder<T> fadeTransition<T>(
    Widget page, {
    Duration duration = AppConstants.defaultAnimationDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// スライドトランジション（右から左）
  static PageRouteBuilder<T> slideTransition<T>(
    Widget page, {
    Duration duration = AppConstants.defaultAnimationDuration,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// スケールトランジション
  static PageRouteBuilder<T> scaleTransition<T>(
    Widget page, {
    Duration duration = AppConstants.defaultAnimationDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation =
            Tween<double>(
              begin: AppConstants.scaleEntranceStart,
              end: 1.0,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }

  /// カスタムトランジション（フェード + スライド）
  static PageRouteBuilder<T> customTransition<T>(
    Widget page, {
    Duration duration = AppConstants.mediumAnimationDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }

  /// ボトムシート風のトランジション
  static PageRouteBuilder<T> bottomSheetTransition<T>(
    Widget page, {
    Duration duration = AppConstants.slowAnimationDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }
}
