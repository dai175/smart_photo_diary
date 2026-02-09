import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart'; // StorageInfoクラス用
import '../services/interfaces/storage_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
import '../models/subscription_info_v2.dart';
import '../models/import_result.dart';
import '../utils/dialog_utils.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../utils/url_launcher_utils.dart';
import '../utils/dynamic_pricing_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_icons.dart';
import '../constants/app_constants.dart';
import '../constants/subscription_constants.dart';
import '../localization/localization_extensions.dart';
import '../controllers/scroll_signal.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final ScrollSignal? scrollSignal;

  const SettingsScreen({super.key, this.onThemeChanged, this.scrollSignal});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final LoggingService _logger;
  late SettingsService _settingsService;
  late final ScrollController _scrollController;
  PackageInfo? _packageInfo;
  StorageInfo? _storageInfo;
  SubscriptionInfoV2? _subscriptionInfo;
  bool _isLoading = true;
  bool _subscriptionExpanded = false;
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<LoggingService>();
    _scrollController = ScrollController();
    widget.scrollSignal?.addListener(_onScrollToTop);
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.scrollSignal?.removeListener(_onScrollToTop);
    super.dispose();
  }

  void _onScrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: AppConstants.defaultAnimationDuration,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _settingsService = await ServiceRegistration.getAsync<SettingsService>();
      _packageInfo = await PackageInfo.fromPlatform();
      final storageService = ServiceRegistration.get<IStorageService>();
      final storageResult = await storageService.getStorageInfoResult();
      if (storageResult.isSuccess) {
        _storageInfo = storageResult.value;
      } else {
        _logger.error(
          'Failed to fetch storage info',
          error: storageResult.error,
          context: 'SettingsScreen',
        );
      }

      _selectedLocale = _settingsService.locale;

      // サブスクリプション情報を取得（V2版）
      final subscriptionResult = await _settingsService.getSubscriptionInfoV2();
      if (subscriptionResult.isSuccess) {
        _subscriptionInfo = subscriptionResult.value;
      } else {
        _logger.error(
          'Failed to fetch subscription info',
          error: subscriptionResult.error,
          context: 'SettingsScreen',
        );
      }
    } catch (e) {
      _logger.error(
        'Failed to load settings',
        error: e,
        context: 'SettingsScreen',
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.settingsAppBarTitle),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        elevation: 2,
      ),
      body: MicroInteractions.pullToRefresh(
        onRefresh: _loadSettings,
        color: AppColors.primary,
        child: ListView(
          controller: _scrollController,
          padding: AppSpacing.screenPadding,
          children: _isLoading
              ? [
                  SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                        AppConstants.loadingCenterHeightRatio,
                  ),
                  Center(
                    child: FadeInWidget(
                      child: CustomCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: AppSpacing.cardPadding,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: AppConstants.opacityXLow,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              context.l10n.settingsLoadingTitle,
                              style: AppTypography.titleLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              context.l10n.settingsLoadingSubtitle,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              : [
                  CustomCard(
                    elevation: AppSpacing.elevationMd,
                    child: Column(
                      children: [
                        FadeInWidget(child: _buildThemeSelector()),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 40),
                          child: _buildLanguageSelector(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 50),
                          child: _buildSubscriptionStatus(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 100),
                          child: _buildStorageInfo(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 125),
                          child: _buildBackupAction(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 140),
                          child: _buildRestoreAction(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 155),
                          child: _buildOptimizeAction(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 175),
                          child: _buildVersionInfo(),
                        ),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 200),
                          child: _buildLicenseInfo(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.outline.withValues(alpha: 0.1),
    );
  }

  Widget _buildLanguageSelector() {
    final options = _buildLocaleChoices(context);
    final currentChoice = options.firstWhere(
      (choice) => choice.locale == _selectedLocale,
      orElse: () => options.first,
    );

    return _buildSettingsRow(
      icon: AppIcons.settingsLanguage,
      iconColor: AppColors.info,
      title: context.l10n.settingsLanguageSectionTitle,
      subtitle: currentChoice.title,
      onTap: _showLanguageDialog,
      semanticLabel: context.l10n.settingsSectionSemanticLabel(
        context.l10n.settingsLanguageSectionTitle,
        currentChoice.title,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return _buildSettingsRow(
      icon: AppIcons.settingsTheme,
      iconColor: AppColors.warning,
      title: context.l10n.settingsThemeSectionTitle,
      subtitle: _getThemeModeLabel(context, _settingsService.themeMode),
      onTap: _showThemeDialog,
      semanticLabel: context.l10n.settingsSectionSemanticLabel(
        context.l10n.settingsThemeSectionTitle,
        _getThemeModeLabel(context, _settingsService.themeMode),
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final options = _buildLocaleChoices(context);
    final currentChoice = options.firstWhere(
      (choice) => choice.locale == _selectedLocale,
      orElse: () => options.first,
    );

    final result = await DialogUtils.showRadioSelectionDialog<_LocaleChoice>(
      context,
      context.l10n.settingsLanguageDialogTitle,
      options,
      currentChoice,
      (choice) => choice.title,
    );

    if (!mounted || result == null) {
      return;
    }

    await _handleLocaleSelection(result.locale);
  }

  Future<void> _handleLocaleSelection(Locale? locale) async {
    if (_selectedLocale == locale) {
      return;
    }

    setState(() {
      _selectedLocale = locale;
    });

    final result = await _settingsService.setLocale(locale);
    if (result.isFailure) {
      _logger.error(
        'Failed to update language preference',
        error: result.error,
        context: 'SettingsScreen',
      );

      if (mounted) {
        setState(() {
          _selectedLocale = _settingsService.locale;
        });
        DialogUtils.showSimpleDialog(
          context,
          context.l10n.settingsLanguageUpdateError,
        );
      }
    }
  }

  List<_LocaleChoice> _buildLocaleChoices(BuildContext context) {
    return [
      _LocaleChoice(locale: null, title: context.l10n.settingsLanguageSystem),
      _LocaleChoice(
        locale: const Locale('ja', 'JP'),
        title: context.l10n.settingsLanguageJapanese,
      ),
      _LocaleChoice(
        locale: const Locale('en', 'US'),
        title: context.l10n.settingsLanguageEnglish,
      ),
    ];
  }

  /// 多言語化されたSubscriptionDisplayDataを取得
  SubscriptionDisplayDataV2 _getLocalizedDisplayData() {
    return _subscriptionInfo!.getLocalizedDisplayData(
      locale: context.l10n.localeName,
      usageFormatter: (used, limit) =>
          context.l10n.usageStatusUsageValue(used, limit),
      remainingFormatter: (remaining) =>
          context.l10n.usageStatusRemainingValue(remaining),
      limitReachedFormatter: () =>
          context.l10n.subscriptionUsageWarningLimitReached,
      warningRemainingFormatter: (remaining) =>
          context.l10n.subscriptionUsageWarningRemaining(remaining),
      upgradeRecommendationLimitFormatter: (limit) =>
          context.l10n.subscriptionUpgradeRecommendationLimit(limit),
      upgradeRecommendationGeneralFormatter: () =>
          context.l10n.subscriptionUpgradeRecommendationGeneral,
    );
  }

  /// Phase 1.8.2.1: サブスクリプション状態表示
  Widget _buildSubscriptionStatus() {
    if (_subscriptionInfo == null) {
      return Container(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                Icons.card_membership_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: AppSpacing.iconSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsSubscriptionSectionTitle,
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

    return Column(
      children: [
        MicroInteractions.bounceOnTap(
          onTap: () {
            setState(() {
              _subscriptionExpanded = !_subscriptionExpanded;
            });
          },
          child: Container(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _subscriptionInfo!.isPremium
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Icon(
                    _subscriptionInfo!.isPremium
                        ? Icons.star_rounded
                        : Icons.card_membership_rounded,
                    color: _subscriptionInfo!.isPremium
                        ? AppColors.success
                        : AppColors.primary,
                    size: AppSpacing.iconSm,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.settingsSubscriptionSectionTitle,
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _getLocalizedDisplayData().planStatus != null
                            ? context.l10n.settingsCurrentPlanWithStatus(
                                _getLocalizedDisplayData().planName,
                                _getLocalizedDisplayData().planStatus!,
                              )
                            : context.l10n.settingsCurrentPlan(
                                _getLocalizedDisplayData().planName,
                              ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _subscriptionExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    AppIcons.actionForward,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: AppSpacing.iconSm,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_subscriptionExpanded) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Column(
              children: [
                _buildSubscriptionItem(
                  context.l10n.settingsSubscriptionUsageLabel,
                  _getLocalizedDisplayData().usageText,
                  _getLocalizedDisplayData().isNearLimit
                      ? AppColors.warning
                      : AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSubscriptionItem(
                  context.l10n.settingsSubscriptionRemainingLabel,
                  _getLocalizedDisplayData().remainingText,
                  _subscriptionInfo!.usageStats.remainingCount > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSubscriptionItem(
                  context.l10n.settingsSubscriptionResetLabel,
                  _getLocalizedDisplayData().resetDateText,
                  AppColors.info,
                ),
                if (_getLocalizedDisplayData().expiryText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildSubscriptionItem(
                    context.l10n.settingsSubscriptionExpiryLabel,
                    _getLocalizedDisplayData().expiryText!,
                    _getLocalizedDisplayData().isExpiryNear
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ],
                // 警告メッセージの表示
                if (_getLocalizedDisplayData().warningMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildWarningMessage(
                    _getLocalizedDisplayData().warningMessage!,
                  ),
                ],
                // 推奨メッセージの表示
                if (_getLocalizedDisplayData().recommendationMessage !=
                    null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildRecommendationMessage(
                    _getLocalizedDisplayData().recommendationMessage!,
                  ),
                ],
                if (!_subscriptionInfo!.isPremium) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildUpgradeButton(),
                ],
                // Apple審査要件：サブスクリプション法的情報
                const SizedBox(height: AppSpacing.lg),
                _buildSubscriptionLegalInfo(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildSubscriptionItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.info,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return PrimaryButton(
      onPressed: () {
        MicroInteractions.hapticTap();
        _showUpgradeDialog();
      },
      text: context.l10n.settingsUpgradeToPremium,
      icon: Icons.auto_awesome_rounded,
      width: double.infinity,
    );
  }

  Widget _buildStorageInfo() {
    if (_storageInfo == null) {
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

    return _buildSettingsRow(
      icon: AppIcons.settingsStorage,
      iconColor: AppColors.info,
      title: context.l10n.settingsStorageAppDataTitle,
      subtitle: context.l10n.settingsStorageUsageValue(
        _storageInfo!.formattedTotalSize,
      ),
    );
  }

  Widget _buildBackupAction() {
    return _buildSettingsRow(
      icon: AppIcons.settingsExport,
      iconColor: AppColors.success,
      title: context.l10n.settingsBackupTitle,
      subtitle: context.l10n.settingsBackupSubtitle,
      onTap: _exportData,
    );
  }

  Widget _buildRestoreAction() {
    return _buildSettingsRow(
      icon: AppIcons.settingsImport,
      iconColor: AppColors.primary,
      title: context.l10n.settingsRestoreTitle,
      subtitle: context.l10n.settingsRestoreSubtitle,
      onTap: _restoreData,
    );
  }

  Widget _buildOptimizeAction() {
    return _buildSettingsRow(
      icon: AppIcons.settingsCleanup,
      iconColor: AppColors.error,
      title: context.l10n.settingsCleanupTitle,
      subtitle: context.l10n.settingsCleanupSubtitle,
      onTap: _optimizeDatabase,
    );
  }

  Widget _buildVersionInfo() {
    return _buildSettingsRow(
      icon: AppIcons.settingsInfo,
      iconColor: AppColors.primary,
      title: context.l10n.settingsVersionTitle,
      subtitle: _packageInfo != null
          ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
          : context.l10n.commonLoading,
    );
  }

  Widget _buildLicenseInfo() {
    return _buildSettingsRow(
      icon: Icons.article_outlined,
      iconColor: Theme.of(context).colorScheme.secondary,
      title: context.l10n.settingsLicenseTitle,
      subtitle: context.l10n.settingsLicenseSubtitle,
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'Smart Photo Diary',
        applicationVersion: _packageInfo?.version ?? '1.0.0',
        applicationLegalese: '© 2024 Smart Photo Diary',
      ),
    );
  }

  /// 設定行の共通ウィジェット
  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    String? semanticLabel,
  }) {
    final row = Container(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: iconColor, size: AppSpacing.iconSm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // ignore: use_null_aware_elements, build_runner analyzer does not yet support this syntax
          if (trailing != null) trailing,
          if (trailing == null && onTap != null)
            Icon(
              AppIcons.actionForward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
        ],
      ),
    );

    Widget result = onTap != null
        ? MicroInteractions.bounceOnTap(
            onTap: () {
              MicroInteractions.hapticTap();
              onTap();
            },
            child: row,
          )
        : row;

    if (semanticLabel != null) {
      result = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: result,
      );
    }

    return result;
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

  void _showThemeDialog() async {
    final selectedTheme = await DialogUtils.showRadioSelectionDialog<ThemeMode>(
      context,
      context.l10n.settingsThemeDialogTitle,
      ThemeMode.values,
      _settingsService.themeMode,
      (mode) => _getThemeModeLabel(context, mode),
    );

    if (selectedTheme != null) {
      _settingsService.setThemeMode(selectedTheme);
      widget.onThemeChanged?.call(selectedTheme);
      setState(() {});
    }
  }

  /// Phase 1.8.2.2: プラン変更・管理画面への遷移
  void _showUpgradeDialog() async {
    // 共通のアップグレードダイアログを表示
    await UpgradeDialogUtils.showUpgradeDialog(context);
    // UI更新
    setState(() {});
  }

  Future<void> _exportData() async {
    try {
      _showLoadingDialog(context.l10n.settingsBackupInProgress);

      final storageService = ServiceRegistration.get<IStorageService>();
      final exportResult = await storageService.exportDataResult();

      if (mounted) {
        Navigator.pop(context); // ローディングダイアログを閉じる

        if (exportResult.isSuccess) {
          final filePath = exportResult.value;
          if (filePath != null) {
            _showSuccessDialog(
              context.l10n.settingsBackupSuccessTitle,
              context.l10n.settingsBackupSuccessMessage,
            );
          } else {
            _showErrorDialog(context.l10n.settingsBackupCancelledMessage);
          }
        } else {
          _showErrorDialog(
            context.l10n.settingsBackupErrorWithDetails(
              exportResult.error.message,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(
          context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    try {
      _showLoadingDialog(context.l10n.settingsRestoreInProgress);

      final storageService = ServiceRegistration.get<IStorageService>();
      final result = await storageService.importData();

      if (mounted) {
        Navigator.pop(context); // ローディングダイアログを閉じる

        result.fold(
          (importResult) {
            _showImportResultDialog(importResult);
          },
          (error) {
            _showErrorDialog(
              context.l10n.commonErrorWithMessage(error.message),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(
          context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
        );
      }
    }
  }

  Future<void> _optimizeDatabase() async {
    try {
      _showLoadingDialog(context.l10n.settingsOptimizeInProgress);

      final storageService = ServiceRegistration.get<IStorageService>();
      final optimizeResult = await storageService.optimizeDatabaseResult();

      if (mounted) {
        Navigator.pop(context); // ローディングダイアログを閉じる

        if (optimizeResult.isSuccess && optimizeResult.value) {
          await _loadSettings(); // ストレージ情報を再読み込み
          _showSuccessDialog(
            context.l10n.settingsOptimizeSuccessTitle,
            context.l10n.settingsOptimizeSuccessMessage,
          );
        } else {
          final errorMessage = optimizeResult.isFailure
              ? context.l10n.settingsOptimizeErrorWithDetails(
                  optimizeResult.error.message,
                )
              : context.l10n.settingsOptimizeFailedMessage;
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(
          context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    DialogUtils.showLoadingDialog(context, message);
  }

  void _showSuccessDialog(String title, String message) {
    DialogUtils.showSuccessDialog(context, title, message);
  }

  void _showErrorDialog(String message) {
    DialogUtils.showErrorDialog(context, message);
  }

  void _showImportResultDialog(ImportResult result) {
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

              // 統計情報
              if (result.totalEntries > 0) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Column(
                    children: [
                      _buildResultItem(
                        context.l10n.settingsRestoreTotalEntriesLabel,
                        context.l10n.settingsRestoreEntriesCount(
                          result.totalEntries,
                        ),
                      ),
                      _buildResultItem(
                        context.l10n.settingsRestoreSuccessLabel,
                        context.l10n.settingsRestoreEntriesCount(
                          result.successfulImports,
                        ),
                      ),
                      if (result.skippedEntries > 0)
                        _buildResultItem(
                          context.l10n.settingsRestoreSkippedLabel,
                          context.l10n.settingsRestoreEntriesCount(
                            result.skippedEntries,
                          ),
                        ),
                      if (result.failedImports > 0)
                        _buildResultItem(
                          context.l10n.settingsRestoreFailedLabel,
                          context.l10n.settingsRestoreEntriesCount(
                            result.failedImports,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 警告セクション
              if (result.hasWarnings) ...[
                Container(
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
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // エラーセクション
              if (result.hasErrors) ...[
                Container(
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
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xxs,
                              ),
                              child: Text(
                                '• $error',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildResultItem(String label, String value) {
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

  /// Apple審査要件：サブスクリプション法的情報セクション
  Widget _buildSubscriptionLegalInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サブスクリプション詳細情報
          Text(
            context.l10n.settingsSubscriptionInfoTitle,
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Premium Monthly詳細
          _buildDynamicSubscriptionPlanDetail(
            context.l10n.settingsPremiumMonthlyTitle,
            SubscriptionConstants.premiumMonthlyPlanId,
            (price) => context.l10n.pricingPerMonthShort(price),
            context.l10n.settingsPremiumPlanFeatures,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Premium Yearly詳細
          _buildDynamicSubscriptionPlanDetail(
            context.l10n.settingsPremiumYearlyTitle,
            SubscriptionConstants.premiumYearlyPlanId,
            (price) => context.l10n.pricingPerYearShort(price),
            context.l10n.settingsPremiumPlanFeatures,
          ),

          const SizedBox(height: AppSpacing.md),

          // 自動更新に関する注意事項
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppSpacing.iconXs,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      context.l10n.settingsSubscriptionAutoRenewTitle,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.settingsSubscriptionAutoRenewDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 法的文書へのリンク
          Row(
            children: [
              Expanded(
                child: _buildLegalLinkButton(
                  context.l10n.commonPrivacyPolicy,
                  Icons.privacy_tip_outlined,
                  () => UrlLauncherUtils.launchPrivacyPolicy(context: context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildLegalLinkButton(
                  context.l10n.commonTermsOfUse,
                  Icons.article_outlined,
                  () => UrlLauncherUtils.launchTermsOfUse(context: context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 動的価格対応のサブスクリプションプラン詳細表示
  Widget _buildDynamicSubscriptionPlanDetail(
    String title,
    String planId,
    String Function(String) formatter,
    String features,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // 動的価格表示
                  DynamicPriceText(
                    planId: planId,
                    locale: context.l10n.localeName,
                    formatter: formatter,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    loadingWidget: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                features,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 法的文書リンクボタン
  Widget _buildLegalLinkButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.iconXs, color: AppColors.primary),
      label: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
      ),
    );
  }
}

class _LocaleChoice {
  final Locale? locale;
  final String title;

  const _LocaleChoice({required this.locale, required this.title});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _LocaleChoice &&
        locale == other.locale &&
        title == other.title;
  }

  @override
  int get hashCode => Object.hash(locale, title);
}
