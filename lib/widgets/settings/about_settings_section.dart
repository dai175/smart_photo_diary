import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../utils/url_launcher_utils.dart';
import 'settings_row.dart';

class AboutSettingsSection extends StatelessWidget {
  final PackageInfo? packageInfo;

  const AboutSettingsSection({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsRow(
          showDivider: true,
          icon: AppIcons.settingsInfo,
          title: context.l10n.settingsVersionTitle,
          subtitle: packageInfo != null
              ? '${packageInfo!.version} (${packageInfo!.buildNumber})'
              : context.l10n.commonLoading,
        ),
        SettingsRow(
          showDivider: true,
          icon: Icons.privacy_tip_outlined,
          title: context.l10n.commonPrivacyPolicy,
          subtitle: context.l10n.settingsPrivacyPolicySubtitle,
          onTap: () => UrlLauncherUtils.launchPrivacyPolicy(context: context),
        ),
        SettingsRow(
          icon: Icons.article_outlined,
          title: context.l10n.settingsLicenseTitle,
          subtitle: context.l10n.settingsLicenseSubtitle,
          onTap: () => showLicensePage(
            context: context,
            applicationName: context.l10n.appTitle,
            applicationVersion:
                packageInfo?.version ?? context.l10n.commonLoading,
            applicationLegalese:
                '© ${DateTime.now().year} ${context.l10n.appTitle}',
          ),
        ),
      ],
    );
  }
}
