import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../services/interfaces/storage_service_interface.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../utils/dialog_utils.dart';
import 'settings_row.dart';
import 'storage_import_result_dialog.dart';

/// Storage and backup-related settings section.
///
/// Displays backup and restore actions.
class StorageSettingsSection extends StatelessWidget {
  final VoidCallback onReloadSettings;

  const StorageSettingsSection({super.key, required this.onReloadSettings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBackupAction(context),
        _buildDivider(),
        _buildRestoreAction(context),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.outline.withValues(alpha: 0.1),
    );
  }

  Widget _buildBackupAction(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsExport,

      title: context.l10n.settingsBackupTitle,
      subtitle: context.l10n.settingsBackupSubtitle,
      onTap: () => _exportData(context),
    );
  }

  Widget _buildRestoreAction(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsImport,

      title: context.l10n.settingsRestoreTitle,
      subtitle: context.l10n.settingsRestoreSubtitle,
      onTap: () => _restoreData(context),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      DialogUtils.showLoadingDialog(
        context,
        context.l10n.settingsBackupInProgress,
      );

      final storageService = ServiceRegistration.get<IStorageService>();
      final exportResult = await storageService.exportDataResult();

      if (!context.mounted) return;
      Navigator.pop(context);

      if (exportResult.isSuccess) {
        final filePath = exportResult.value;
        // filePath == null means user cancelled the file picker; no action needed.
        if (filePath != null) {
          DialogUtils.showSuccessDialog(
            context,
            context.l10n.settingsBackupSuccessTitle,
            context.l10n.settingsBackupSuccessMessage,
          );
        }
      } else {
        DialogUtils.showErrorDialog(
          context,
          context.l10n.settingsBackupErrorWithDetails(
            exportResult.error.message,
          ),
        );
      }
    } catch (e) {
      ServiceRegistration.get<ILoggingService>().error(
        'Data export failed',
        context: 'StorageSettingsSection._exportData',
        error: e,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      DialogUtils.showErrorDialog(
        context,
        context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
      );
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    try {
      DialogUtils.showLoadingDialog(
        context,
        context.l10n.settingsRestoreInProgress,
      );

      final storageService = ServiceRegistration.get<IStorageService>();
      final result = await storageService.importData();

      if (!context.mounted) return;
      Navigator.pop(context);

      result.fold(
        (importResult) {
          if (importResult == null) return;
          onReloadSettings();
          StorageImportResultDialog.show(context, importResult);
        },
        (error) {
          DialogUtils.showErrorDialog(
            context,
            context.l10n.settingsRestoreErrorWithDetails(error.message),
          );
        },
      );
    } catch (e) {
      ServiceRegistration.get<ILoggingService>().error(
        'Data restore failed',
        context: 'StorageSettingsSection._restoreData',
        error: e,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      DialogUtils.showErrorDialog(
        context,
        context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
      );
    }
  }
}
