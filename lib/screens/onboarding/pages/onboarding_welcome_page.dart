import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../components/onboarding_page_scaffold.dart';

/// オンボーディング ステップ1: ウェルカム
/// ビジュアル: 3枚の写真を扇状に重ねたフォトスタック
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingPageScaffold(
      eyebrow: l10n.onboardingStep1Eyebrow,
      headline: l10n.onboardingPhilosophyTitle,
      body: l10n.onboardingPhilosophySubtitle,
      visual: const _PhotoStack(),
    );
  }
}

class _PhotoStack extends StatelessWidget {
  const _PhotoStack();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _StackTile(
            src: 'assets/onboarding/sunset.jpg',
            dx: -86,
            dy: 0,
            rot: -12,
          ),
          _StackTile(
            src: 'assets/onboarding/cathedral.jpg',
            dx: 86,
            dy: 0,
            rot: 10,
          ),
          _StackTile(src: 'assets/onboarding/cat.jpg', dx: 0, dy: -16, rot: -2),
        ],
      ),
    );
  }
}

class _StackTile extends StatelessWidget {
  final String src;
  final double dx;
  final double dy;
  final double rot;

  static const double _w = 152;
  static const double _h = 196;

  const _StackTile({
    required this.src,
    required this.dx,
    required this.dy,
    required this.rot,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rot * math.pi / 180,
        child: Container(
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E231E1A),
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              src,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: isDark
                    ? AppColors.surfaceContainerHighestDark
                    : AppColors.glyphBg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
