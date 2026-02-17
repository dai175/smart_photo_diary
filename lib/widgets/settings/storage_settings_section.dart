import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../services/interfaces/storage_service_interface.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/storage_service.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../utils/dialog_utils.dart';
import 'settings_row.dart';
import 'storage_import_result_dialog.dart';

/// Storage and backup-related settings section.
///
/// Displays storage usage info and provides backup, restore,
/// and database optimization actions.
class StorageSettingsSection extends StatelessWidget {
  final StorageInfo? storageInfo;
  final VoidCallback onReloadSettings;

  const StorageSettingsSection({
    super.key,
    required this.storageInfo,
    required this.onReloadSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStorageInfo(context),
        _buildDivider(),
        _buildBackupAction(context),
        _buildDivider(),
        _buildRestoreAction(context),
        _buildDivider(),
        _buildOptimizeAction(context),
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

  Widget _buildStorageInfo(BuildContext context) {
    if (storageInfo == null) {
      return Container(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                Icons.storage_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsStorageSectionTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.l10n.commonLoading,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SettingsRow(
      icon: AppIcons.settingsStorage,

      title: context.l10n.settingsStorageAppDataTitle,
      subtitle: context.l10n.settingsStorageUsageValue(
        storageInfo!.formattedTotalSize,
      ),
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

  Widget _buildOptimizeAction(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsCleanup,

      title: context.l10n.settingsCleanupTitle,
      subtitle: context.l10n.settingsCleanupSubtitle,
      onTap: () => _optimizeDatabase(context),
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

  Future<void> _optimizeDatabase(BuildContext context) async {
    try {
      DialogUtils.showLoadingDialog(
        context,
        context.l10n.settingsOptimizeInProgress,
      );

      final storageService = ServiceRegistration.get<IStorageService>();
      final optimizeResult = await storageService.optimizeDatabaseResult();

      if (!context.mounted) return;
      Navigator.pop(context);

      if (optimizeResult.isSuccess && optimizeResult.value) {
        onReloadSettings();
        DialogUtils.showSuccessDialog(
          context,
          context.l10n.settingsOptimizeSuccessTitle,
          context.l10n.settingsOptimizeSuccessMessage,
        );
      } else {
        final errorMessage = optimizeResult.isFailure
            ? context.l10n.settingsOptimizeErrorWithDetails(
                optimizeResult.error.message,
              )
            : context.l10n.settingsOptimizeFailedMessage;
        DialogUtils.showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      ServiceRegistration.get<ILoggingService>().error(
        'Database optimization failed',
        context: 'StorageSettingsSection._optimizeDatabase',
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
