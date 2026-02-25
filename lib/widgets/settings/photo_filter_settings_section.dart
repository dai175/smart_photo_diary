import 'package:flutter/material.dart';
import '../../localization/localization_extensions.dart';
import '../../models/photo_type_filter.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/settings_service_interface.dart';
import '../../utils/dialog_utils.dart';
import 'settings_row.dart';

/// Photo filter settings section for photo type filter selection.
class PhotoFilterSettingsSection extends StatelessWidget {
  final ISettingsService settingsService;
  final ILoggingService logger;
  final VoidCallback onStateChanged;

  const PhotoFilterSettingsSection({
    super.key,
    required this.settingsService,
    required this.logger,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPhotoTypeFilterSelector(context);
  }

  Widget _buildPhotoTypeFilterSelector(BuildContext context) {
    final currentLabel = _getPhotoTypeFilterLabel(
      context,
      settingsService.photoTypeFilter,
    );

    return SettingsRow(
      icon: Icons.photo_library_outlined,
      title: context.l10n.photoTypeFilterTitle,
      subtitle: currentLabel,
      onTap: () => _showPhotoTypeFilterDialog(context),
      semanticLabel: context.l10n.settingsSectionSemanticLabel(
        context.l10n.photoTypeFilterTitle,
        currentLabel,
      ),
    );
  }

  String _getPhotoTypeFilterLabel(
    BuildContext context,
    PhotoTypeFilter filter,
  ) {
    return switch (filter) {
      PhotoTypeFilter.all => context.l10n.photoTypeFilterAll,
      PhotoTypeFilter.photosOnly => context.l10n.photoTypeFilterPhotosOnly,
    };
  }

  Future<void> _showPhotoTypeFilterDialog(BuildContext context) async {
    final selected =
        await DialogUtils.showRadioSelectionDialog<PhotoTypeFilter>(
          context,
          context.l10n.photoTypeFilterDialogTitle,
          PhotoTypeFilter.values,
          settingsService.photoTypeFilter,
          (filter) => _getPhotoTypeFilterLabel(context, filter),
        );

    if (selected != null && selected != settingsService.photoTypeFilter) {
      final result = await settingsService.setPhotoTypeFilter(selected);
      if (result.isFailure) {
        logger.error(
          'Failed to update photo type filter preference',
          error: result.error,
          context: 'PhotoFilterSettingsSection',
        );
        return;
      }
      onStateChanged();
    }
  }
}
