import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../ui/component_constants.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/components/drag_handle.dart';
import '../../ui/design_system/app_spacing.dart';

class DiaryDetailActionBar extends StatelessWidget {
  final bool canShowActions;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiaryDetailActionBar({
    super.key,
    required this.canShowActions,
    required this.onBack,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: Row(
        children: [
          _FloatingButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const Spacer(),
          if (canShowActions) ...[
            _FloatingButton(icon: Icons.share_rounded, onTap: onShare),
            const SizedBox(width: 8),
            _FloatingButton(icon: Icons.edit_rounded, onTap: onEdit),
            const SizedBox(width: 8),
            _FloatingButton(
              icon: Icons.more_horiz_rounded,
              onTap: () => _showDeleteMenu(context, l10n, onDelete),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showDeleteMenu(
  BuildContext context,
  AppLocalizations l10n,
  VoidCallback onDelete,
) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(BottomSheetConstants.radius),
      ),
    ),
    builder: (ctx) {
      final errorColor = Theme.of(ctx).colorScheme.error;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const DragHandle(),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xs,
            ),
            leading: Icon(Icons.delete_rounded, color: errorColor),
            title: Text(l10n.commonDelete, style: TextStyle(color: errorColor)),
            onTap: () {
              MicroInteractions.hapticTap(intensity: VibrationIntensity.medium);
              Navigator.of(ctx).pop();
              onDelete();
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      );
    },
  );
}

class _FloatingButton extends StatelessWidget {
  // Semi-transparent black ensures visibility over any photo content in
  // both light and dark modes; 0x73 ≈ 0.45 alpha.
  static const _bg = Color(0x73000000);

  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CircularIconButton(
      onPressed: onTap,
      icon: icon,
      backgroundColor: _bg,
      foregroundColor: Colors.white,
      size: 36,
    );
  }
}
