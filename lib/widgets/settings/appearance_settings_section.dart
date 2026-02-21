import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/settings_service_interface.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../utils/dialog_utils.dart';
import 'settings_row.dart';

/// Locale choice model used by the language selector.
class LocaleChoice {
  final Locale? locale;
  final String title;

  const LocaleChoice({required this.locale, required this.title});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocaleChoice &&
        locale == other.locale &&
        title == other.title;
  }

  @override
  int get hashCode => Object.hash(locale, title);
}

/// Appearance settings section for theme and language selection.
class AppearanceSettingsSection extends StatelessWidget {
  final ISettingsService settingsService;
  final ILoggingService logger;
  final Locale? selectedLocale;
  final Function(ThemeMode)? onThemeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final VoidCallback onStateChanged;

  const AppearanceSettingsSection({
    super.key,
    required this.settingsService,
    required this.logger,
    required this.selectedLocale,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildThemeSelector(context),
        _buildDivider(),
        _buildLanguageSelector(context),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.outline.withValues(alpha: 0.1),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return SettingsRow(
      icon: AppIcons.settingsTheme,

      title: context.l10n.settingsThemeSectionTitle,
      subtitle: _getThemeModeLabel(context, settingsService.themeMode),
      onTap: () => _showThemeDialog(context),
      semanticLabel: context.l10n.settingsSectionSemanticLabel(
        context.l10n.settingsThemeSectionTitle,
        _getThemeModeLabel(context, settingsService.themeMode),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final options = _buildLocaleChoices(context);
    final currentChoice = options.firstWhere(
      (choice) => choice.locale == selectedLocale,
      orElse: () => options.first,
    );

    return SettingsRow(
      icon: AppIcons.settingsLanguage,

      title: context.l10n.settingsLanguageSectionTitle,
      subtitle: currentChoice.title,
      onTap: () => _showLanguageDialog(context),
      semanticLabel: context.l10n.settingsSectionSemanticLabel(
        context.l10n.settingsLanguageSectionTitle,
        currentChoice.title,
      ),
    );
  }

  String _getThemeModeLabel(BuildContext context, ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return context.l10n.settingsThemeLight;
      case ThemeMode.dark:
        return context.l10n.settingsThemeDark;
      case ThemeMode.system:
        return context.l10n.settingsThemeSystem;
    }
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final selectedTheme = await DialogUtils.showRadioSelectionDialog<ThemeMode>(
      context,
      context.l10n.settingsThemeDialogTitle,
      ThemeMode.values,
      settingsService.themeMode,
      (mode) => _getThemeModeLabel(context, mode),
    );

    if (selectedTheme != null) {
      settingsService.setThemeMode(selectedTheme);
      onThemeChanged?.call(selectedTheme);
      onStateChanged();
    }
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final options = _buildLocaleChoices(context);
    final currentChoice = options.firstWhere(
      (choice) => choice.locale == selectedLocale,
      orElse: () => options.first,
    );

    final result = await DialogUtils.showRadioSelectionDialog<LocaleChoice>(
      context,
      context.l10n.settingsLanguageDialogTitle,
      options,
      currentChoice,
      (choice) => choice.title,
    );

    if (result == null || !context.mounted) return;

    await _handleLocaleSelection(context, result.locale);
  }

  Future<void> _handleLocaleSelection(
    BuildContext context,
    Locale? locale,
  ) async {
    if (selectedLocale == locale) return;

    onLocaleChanged(locale);

    final result = await settingsService.setLocale(locale);
    if (result.isFailure) {
      logger.error(
        'Failed to update language preference',
        error: result.error,
        context: 'AppearanceSettingsSection',
      );

      if (context.mounted) {
        onLocaleChanged(settingsService.locale);
        DialogUtils.showSimpleDialog(
          context,
          context.l10n.settingsLanguageUpdateError,
        );
      }
    }
  }

  List<LocaleChoice> _buildLocaleChoices(BuildContext context) {
    return [
      LocaleChoice(locale: null, title: context.l10n.settingsLanguageSystem),
      LocaleChoice(
        locale: const Locale('en', 'US'),
        title: context.l10n.settingsLanguageEnglish,
      ),
      LocaleChoice(
        locale: const Locale('ja', 'JP'),
        title: context.l10n.settingsLanguageJapanese,
      ),
    ];
  }
}
