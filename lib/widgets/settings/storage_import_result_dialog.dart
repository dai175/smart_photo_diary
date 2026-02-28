import 'package:flutter/material.dart';
import '../../localization/localization_extensions.dart';
import '../../models/import_result.dart';
import '../../ui/components/custom_dialog.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

/// ストレージインポート結果ダイアログ
///
/// データ復元後の結果（成功件数・警告・エラー）を表示する。
class StorageImportResultDialog {
  StorageImportResultDialog._();

  /// インポート結果ダイアログを表示
  static void show(BuildContext context, ImportResult result) {
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
                _buildSummaryMessage(context, result),
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

  static Widget _buildStatisticsSection(
    BuildContext context,
    ImportResult result,
  ) {
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

  static Widget _buildWarningsSection(
    BuildContext context,
    ImportResult result,
  ) {
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
              const Icon(
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

  static Widget _buildErrorsSection(BuildContext context, ImportResult result) {
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
              const Icon(
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

  static String _buildSummaryMessage(
    BuildContext context,
    ImportResult result,
  ) {
    if (result.isCompletelySuccessful) {
      return context.l10n.settingsRestoreCompleteMessage(
        result.successfulImports,
      );
    }

    final parts = <String>[];
    if (result.successfulImports > 0) {
      parts.add(
        context.l10n.settingsRestoreSummarySuccess(result.successfulImports),
      );
    }
    if (result.skippedEntries > 0) {
      parts.add(
        context.l10n.settingsRestoreSummarySkipped(result.skippedEntries),
      );
    }
    if (result.failedImports > 0) {
      parts.add(
        context.l10n.settingsRestoreSummaryFailed(result.failedImports),
      );
    }

    return parts.join(', ');
  }

  static Widget _buildResultItem(
    BuildContext context,
    String label,
    String value,
  ) {
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
