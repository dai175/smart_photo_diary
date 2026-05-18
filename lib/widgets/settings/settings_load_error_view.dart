import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

class SettingsLoadErrorView extends StatelessWidget {
  const SettingsLoadErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height:
              MediaQuery.sizeOf(context).height *
              AppConstants.loadingCenterHeightRatio,
        ),
        Center(
          child: CustomCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer
                        .withValues(alpha: AppConstants.opacityXLow),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.errorDefault,
                    color: Theme.of(context).colorScheme.error,
                    size: AppSpacing.iconLg,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.commonErrorOccurred,
                  style: AppTypography.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.settingsLoadErrorSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
