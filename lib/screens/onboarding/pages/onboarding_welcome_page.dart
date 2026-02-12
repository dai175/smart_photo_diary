import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/animations/micro_interactions.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';

/// オンボーディング: ウェルカムページ
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: isPortrait
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: _buildContent(context),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final l10n = context.l10n;

    return [
      // アプリアイコン
      MicroInteractions.scaleTransition(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      Text(
        l10n.onboardingWelcomeTitle,
        style: AppTypography.headlineMedium.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingWelcomeSubtitle,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}
