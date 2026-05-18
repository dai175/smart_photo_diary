import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../localization/localization_extensions.dart';
import '../../models/subscription_info_v2.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/settings_service_interface.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import 'about_settings_section.dart';
import 'appearance_settings_section.dart';
import 'diary_settings_section.dart';
import 'photo_filter_settings_section.dart';
import 'plan_status_card.dart';
import 'storage_settings_section.dart';

class SettingsContentBody extends StatelessWidget {
  final ISettingsService settingsService;
  final ILoggingService logger;
  final Locale? selectedLocale;
  final SubscriptionInfoV2? subscriptionInfo;
  final PackageInfo? packageInfo;
  final Function(ThemeMode)? onThemeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final VoidCallback onStateChanged;
  final VoidCallback onUpgradePressed;
  final VoidCallback onReloadSettings;

  const SettingsContentBody({
    super.key,
    required this.settingsService,
    required this.logger,
    required this.selectedLocale,
    required this.subscriptionInfo,
    required this.packageInfo,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onStateChanged,
    required this.onUpgradePressed,
    required this.onReloadSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        PlanStatusCard(
          info: subscriptionInfo,
          onUpgradePressed: onUpgradePressed,
        ),
        _sectionHeader(context, context.l10n.settingsGroupAppearance),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: AppearanceSettingsSection(
            settingsService: settingsService,
            logger: logger,
            selectedLocale: selectedLocale,
            onThemeChanged: onThemeChanged,
            onLocaleChanged: onLocaleChanged,
            onStateChanged: onStateChanged,
          ),
        ),
        _sectionHeader(context, context.l10n.settingsGroupDiaryPhotos),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: Column(
            children: [
              DiarySettingsSection(
                settingsService: settingsService,
                logger: logger,
                onStateChanged: onStateChanged,
                showBottomDivider: true,
              ),
              PhotoFilterSettingsSection(
                settingsService: settingsService,
                logger: logger,
                onStateChanged: onStateChanged,
              ),
            ],
          ),
        ),
        _sectionHeader(context, context.l10n.settingsGroupData),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: StorageSettingsSection(onReloadSettings: onReloadSettings),
        ),
        _sectionHeader(context, context.l10n.settingsGroupAbout),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: AboutSettingsSection(packageInfo: packageInfo),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 24, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.sectionLabel.copyWith(
          color: AppColors.accentMuted,
        ),
      ),
    );
  }
}
