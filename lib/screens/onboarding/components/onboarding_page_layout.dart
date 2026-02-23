import 'package:flutter/material.dart';

import '../../../ui/design_system/app_spacing.dart';

/// オンボーディングページ共通のレイアウトウィジェット
///
/// Portrait/Landscape で異なるレイアウトを提供する。
/// - Portrait: [scrollableInPortrait] が true なら ScrollView、false なら中央寄せ Column
/// - Landscape: 常に ScrollView
class OnboardingPageLayout extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry portraitPadding;
  final EdgeInsetsGeometry landscapePadding;

  /// Portrait 時にスクロール可能にするか（false の場合は中央寄せ Column）
  final bool scrollableInPortrait;

  /// Portrait + scrollableInPortrait 時に Center でラップするか
  final bool centerInPortrait;

  const OnboardingPageLayout({
    super.key,
    required this.children,
    this.portraitPadding = const EdgeInsets.all(AppSpacing.xl),
    this.landscapePadding = const EdgeInsets.all(AppSpacing.xl),
    this.scrollableInPortrait = false,
    this.centerInPortrait = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (!isPortrait) {
      return SingleChildScrollView(
        padding: landscapePadding,
        child: Column(children: children),
      );
    }

    if (scrollableInPortrait) {
      if (centerInPortrait) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: portraitPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      portraitPadding
                          .resolve(Directionality.of(context))
                          .vertical,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
              ),
            );
          },
        );
      }
      return SingleChildScrollView(
        padding: portraitPadding,
        child: Column(children: children),
      );
    }

    return Padding(
      padding: portraitPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
