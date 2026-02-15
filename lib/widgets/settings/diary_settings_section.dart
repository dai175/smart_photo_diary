import 'package:flutter/material.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_length.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/settings_service_interface.dart';
import '../../ui/design_system/app_colors.dart';
import '../../utils/dialog_utils.dart';
import 'settings_row.dart';

/// Diary settings section for diary length selection.
class DiarySettingsSection extends StatelessWidget {
  final ISettingsService settingsService;
  final ILoggingService logger;
  final VoidCallback onStateChanged;

  const DiarySettingsSection({
    super.key,
    required this.settingsService,
    required this.logger,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _buildDiaryLengthSelector(context);
  }

  Widget _buildDiaryLengthSelector(BuildContext context) {
    final currentLabel = _getDiaryLengthLabel(
      context,
      settingsService.diaryLength,
    );

    return SettingsRow(
      icon: Icons.text_fields_rounded,
      iconColor: AppColors.primary,
      title: context.l10n.settingsDiaryLengthTitle,
      subtitle: currentLabel,
      onTap: () => _showDiaryLengthDialog(context),
      semanticLabel: context.l10n.settingsSectionSemanticLabel(
        context.l10n.settingsDiaryLengthTitle,
        currentLabel,
      ),
    );
  }

  String _getDiaryLengthLabel(BuildContext context, DiaryLength length) {
    return switch (length) {
      DiaryLength.short => context.l10n.diaryLengthShort,
      DiaryLength.standard => context.l10n.diaryLengthStandard,
    };
  }

  Future<void> _showDiaryLengthDialog(BuildContext context) async {
    final selected = await DialogUtils.showRadioSelectionDialog<DiaryLength>(
      context,
      context.l10n.settingsDiaryLengthDialogTitle,
      DiaryLength.values,
      settingsService.diaryLength,
      (length) => _getDiaryLengthLabel(context, length),
    );

    if (selected != null && selected != settingsService.diaryLength) {
      final result = await settingsService.setDiaryLength(selected);
      if (result.isFailure) {
        logger.error(
          'Failed to update diary length preference',
          error: result.error,
          context: 'DiarySettingsSection',
        );
        return;
      }
      onStateChanged();
    }
  }
}
