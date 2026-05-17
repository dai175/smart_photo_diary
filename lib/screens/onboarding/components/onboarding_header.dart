import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';

/// オンボーディング画面上部のクロム:
/// 4セグメントの進行トラック + スキップボタン（最後のステップでは非表示）
class OnboardingHeader extends StatelessWidget {
  final int step;
  final int total;
  final bool isLastStep;
  final VoidCallback onSkip;

  const OnboardingHeader({
    super.key,
    required this.step,
    required this.total,
    required this.isLastStep,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.accentLight : AppColors.accentDark;
    final empty = Theme.of(context).colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 14, 8),
      child: Row(
        children: [
          for (int i = 0; i < total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 3,
                decoration: BoxDecoration(
                  color: i < step ? fill : empty,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 5),
          ],
          if (!isLastStep) ...[
            const SizedBox(width: 14),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(context.l10n.onboardingSkip),
            ),
          ],
        ],
      ),
    );
  }
}
