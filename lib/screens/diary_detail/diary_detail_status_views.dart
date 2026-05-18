import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../ui/animations/list_animations.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/loading_state_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

class DiaryDetailLoadingView extends StatelessWidget {
  const DiaryDetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: FadeInWidget(
        child: LoadingStateCard(
          title: l10n.diaryDetailLoadingTitle,
          subtitle: l10n.diaryDetailLoadingSubtitle,
          indicatorColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class DiaryDetailErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onBack;

  const DiaryDetailErrorView({
    super.key,
    required this.errorMessage,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _InfoCard(
      iconData: Icons.error_outline_rounded,
      iconColor: cs.error,
      iconBgColor: cs.errorContainer.withValues(alpha: 0.3),
      title: context.l10n.commonErrorOccurred,
      subtitle: errorMessage,
      subtitleColor: cs.error,
      onBack: onBack,
    );
  }
}

class DiaryDetailNotFoundView extends StatelessWidget {
  final VoidCallback onBack;

  const DiaryDetailNotFoundView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _InfoCard(
      iconData: Icons.search_off_rounded,
      iconColor: cs.secondary,
      iconBgColor: cs.secondaryContainer.withValues(alpha: 0.3),
      title: context.l10n.diaryNotFoundMessage,
      subtitle: context.l10n.diaryNotFoundSubtitle,
      subtitleColor: cs.onSurfaceVariant,
      onBack: onBack,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onBack;

  const _InfoCard({
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(onPressed: onBack, text: context.l10n.commonBack),
            ],
          ),
        ),
      ),
    );
  }
}
