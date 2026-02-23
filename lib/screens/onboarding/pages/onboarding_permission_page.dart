import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';
import '../components/onboarding_page_layout.dart';

/// オンボーディング: 権限リクエストページ
class OnboardingPermissionPage extends StatelessWidget {
  const OnboardingPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return OnboardingPageLayout(
      children: [
        Text(
          l10n.onboardingPermissionTitle,
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          l10n.onboardingPermissionSubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
