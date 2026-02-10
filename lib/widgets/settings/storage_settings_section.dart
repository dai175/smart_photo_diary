import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../models/import_result.dart';
import '../../services/interfaces/storage_service_interface.dart';
import '../../services/logging_service.dart';
import '../../services/storage_service.dart';
import '../../ui/components/custom_dialog.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../utils/dialog_utils.dart';
import 'settings_row.dart';

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
      iconColor: AppColors.info,
      title: context.l10n.settingsStorageAppDataTitle,
      subtitle: context.l10n.settingsStorageUsageValue(
        storageInfo!.formattedTotalSize,
      ),
    );
  }

  Widget _buildBackupAction(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsExport,
      iconColor: AppColors.success,
      title: context.l10n.settingsBackupTitle,
      subtitle: context.l10n.settingsBackupSubtitle,
      onTap: () => _exportData(context),
    );
  }

  Widget _buildRestoreAction(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsImport,
      iconColor: AppColors.primary,
      title: context.l10n.settingsRestoreTitle,
      subtitle: context.l10n.settingsRestoreSubtitle,
      onTap: () => _restoreData(context),
    );
  }

  Widget _buildOptimizeAction(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsCleanup,
      iconColor: AppColors.error,
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
        } else {
          DialogUtils.showErrorDialog(
            context,
            context.l10n.settingsBackupCancelledMessage,
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
      ServiceRegistration.get<LoggingService>().error(
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
          _showImportResultDialog(context, importResult);
        },
        (error) {
          DialogUtils.showErrorDialog(
            context,
            context.l10n.commonErrorWithMessage(error.message),
          );
        },
      );
    } catch (e) {
      ServiceRegistration.get<LoggingService>().error(
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
      ServiceRegistration.get<LoggingService>().error(
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

  void _showImportResultDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        icon: result.isCompletelySuccessful
            ? Icons.check_circle_rounded
            : result.hasErrors
            ? Icons.warning_rounded
            : Icons.info_rounded,
        iconColor: result.isCompletelySuccessful
            ? AppColors.success
            : result.hasErrors
            ? AppColors.warning
            : AppColors.info,
        title: context.l10n.settingsRestoreResultTitle,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.summaryMessage,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (result.totalEntries > 0) ...[
                _buildStatisticsSection(context, result),
                const SizedBox(height: AppSpacing.md),
              ],
              if (result.hasWarnings) ...[
                _buildWarningsSection(context, result),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (result.hasErrors) _buildErrorsSection(context, result),
            ],
          ),
        ),
        actions: [
          CustomDialogAction(
            text: context.l10n.commonOk,
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, ImportResult result) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        children: [
          _buildResultItem(
            context,
            context.l10n.settingsRestoreTotalEntriesLabel,
            context.l10n.settingsRestoreEntriesCount(result.totalEntries),
          ),
          _buildResultItem(
            context,
            context.l10n.settingsRestoreSuccessLabel,
            context.l10n.settingsRestoreEntriesCount(result.successfulImports),
          ),
          if (result.skippedEntries > 0)
            _buildResultItem(
              context,
              context.l10n.settingsRestoreSkippedLabel,
              context.l10n.settingsRestoreEntriesCount(result.skippedEntries),
            ),
          if (result.failedImports > 0)
            _buildResultItem(
              context,
              context.l10n.settingsRestoreFailedLabel,
              context.l10n.settingsRestoreEntriesCount(result.failedImports),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection(BuildContext context, ImportResult result) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: AppSpacing.iconSm,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.errorSeverityWarning,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...result.warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                '• $warning',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection(BuildContext context, ImportResult result) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_rounded,
                size: AppSpacing.iconSm,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.errorSeverityError,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...result.errors
              .take(3)
              .map(
                (error) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    '• $error',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          if (result.errors.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                context.l10n.settingsRestoreAdditionalErrors(
                  result.errors.length - 3,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
