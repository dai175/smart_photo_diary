import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/animations/micro_interactions.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';

/// オンボーディング: フィロソフィーページ
class OnboardingPhilosophyPage extends StatelessWidget {
  const OnboardingPhilosophyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(children: _buildContent(context)),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildContent(context)),
      );
    }
  }

  List<Widget> _buildContent(BuildContext context) {
    final l10n = context.l10n;

    return [
      // アプリアイコン
      MicroInteractions.scaleTransition(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXxl),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xxxl),

      Text(
        l10n.onboardingPhilosophyTitle,
        style: AppTypography.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingPhilosophySubtitle,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}
