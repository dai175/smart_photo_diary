import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/design_system/app_spacing.dart';

class DiaryDetailEditBottomBar extends StatelessWidget {
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const DiaryDetailEditBottomBar({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? AppSpacing.bottomBarShadowDark
              : AppSpacing.bottomBarShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: onCancel,
                text: l10n.commonCancel,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(onPressed: onSave, text: l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
