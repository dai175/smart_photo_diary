import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';

/// オンボーディング: 権限リクエストページ
class OnboardingPermissionPage extends StatelessWidget {
  const OnboardingPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildContent(context),
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
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.security_rounded, size: 50, color: AppColors.info),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingPermissionTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingPermissionDescription,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      // プライバシー保護の強調
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.onboardingPrivacyTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.onboardingPrivacyDescription,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
  }
}
