import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../models/subscription_info.dart';
import '../utils/dialog_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/animated_button.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_icons.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const SettingsScreen({
    super.key,
    this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;
  PackageInfo? _packageInfo;
  StorageInfo? _storageInfo;
  SubscriptionInfo? _subscriptionInfo;
  bool _isLoading = true;
  bool _subscriptionExpanded = false;
  bool _storageExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _settingsService = await SettingsService.getInstance();
      _packageInfo = await PackageInfo.fromPlatform();
      _storageInfo = await StorageService.getInstance().getStorageInfo();
      
      // サブスクリプション情報を取得
      final subscriptionResult = await _settingsService.getSubscriptionInfo();
      if (subscriptionResult.isSuccess) {
        _subscriptionInfo = subscriptionResult.value;
      } else {
        debugPrint('サブスクリプション情報の取得エラー: ${subscriptionResult.error}');
      }
    } catch (e) {
      debugPrint('設定の読み込みエラー: $e');
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
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: Icon(
                AppIcons.settingsRefresh,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _loadSettings,
              tooltip: '設定を更新',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: FadeInWidget(
                child: CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '設定を読み込み中...',
                        style: AppTypography.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'アプリの設定情報を取得しています',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : MicroInteractions.pullToRefresh(
              onRefresh: _loadSettings,
              color: AppColors.primary,
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  CustomCard(
                    elevation: AppSpacing.elevationMd,
                    child: Column(
                      children: [
                        FadeInWidget(
                          child: _buildThemeSelector(),
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
                          delay: const Duration(milliseconds: 150),
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

  Widget _buildThemeSelector() {
    return Semantics(
      label: 'テーマ設定、現在: ${_getThemeModeLabel(_settingsService.themeMode)}',
      button: true,
      child: MicroInteractions.bounceOnTap(
        onTap: () {
          MicroInteractions.hapticTap();
          _showThemeDialog();
        },
        child: Container(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  AppIcons.settingsTheme,
                  color: AppColors.warning,
                  size: AppSpacing.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'テーマ',
                      style: AppTypography.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _getThemeModeLabel(_settingsService.themeMode),
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.actionForward,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ],
          ),
        ),
      ),
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                    'サブスクリプション',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '読み込み中...',
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
                        'サブスクリプション',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _subscriptionInfo!.displayData.planStatus != null
                            ? '現在のプラン: ${_subscriptionInfo!.displayData.planName} (${_subscriptionInfo!.displayData.planStatus})'
                            : '現在のプラン: ${_subscriptionInfo!.displayData.planName}',
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Column(
              children: [
                _buildSubscriptionItem(
                  'AI生成使用量',
                  _subscriptionInfo!.displayData.usageText,
                  _subscriptionInfo!.displayData.isNearLimit 
                      ? AppColors.warning 
                      : AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSubscriptionItem(
                  '残り回数',
                  _subscriptionInfo!.displayData.remainingText,
                  _subscriptionInfo!.usageStats.remainingCount > 0 
                      ? AppColors.success 
                      : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSubscriptionItem(
                  'リセット予定',
                  _subscriptionInfo!.displayData.resetDateText,
                  AppColors.info,
                ),
                if (_subscriptionInfo!.displayData.expiryText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildSubscriptionItem(
                    '有効期限',
                    _subscriptionInfo!.displayData.expiryText!,
                    _subscriptionInfo!.displayData.isExpiryNear 
                        ? AppColors.warning 
                        : AppColors.success,
                  ),
                ],
                // 警告メッセージの表示
                if (_subscriptionInfo!.displayData.warningMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildWarningMessage(_subscriptionInfo!.displayData.warningMessage!),
                ],
                // 推奨メッセージの表示
                if (_subscriptionInfo!.displayData.recommendationMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildRecommendationMessage(_subscriptionInfo!.displayData.recommendationMessage!),
                ],
                if (!_subscriptionInfo!.isPremium) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildUpgradeButton(),
                ],
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
      text: 'Premiumにアップグレード',
      icon: Icons.upgrade_rounded,
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
                    'ストレージ情報',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '読み込み中...',
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
              _storageExpanded = !_storageExpanded;
            });
          },
          child: Container(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Icon(
                    AppIcons.settingsStorage,
                    color: AppColors.info,
                    size: AppSpacing.iconSm,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '使用容量',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '合計: ${_storageInfo!.formattedTotalSize}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _storageExpanded ? 0.25 : 0.0,
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
        if (_storageExpanded) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Column(
              children: [
                _buildStorageItem('日記データ', _storageInfo!.formattedDiaryDataSize, AppColors.primary),
                const SizedBox(height: AppSpacing.md),
                _buildStorageItem('画像データ（推定）', _storageInfo!.formattedImageDataSize, AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildStorageItem(String label, String size, Color color) {
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
          size,
          style: AppTypography.labelLarge.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBackupAction() {
    return MicroInteractions.bounceOnTap(
      onTap: () {
        MicroInteractions.hapticTap();
        _exportData();
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                AppIcons.settingsExport,
                color: AppColors.success,
                size: AppSpacing.iconSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'バックアップ',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '日記データをファイルに保存',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.actionForward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizeAction() {
    return MicroInteractions.bounceOnTap(
      onTap: () {
        MicroInteractions.hapticTap();
        _optimizeDatabase();
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                AppIcons.settingsCleanup,
                color: AppColors.error,
                size: AppSpacing.iconSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '容量の整理',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '不要なデータを削除してアプリを軽くする',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.actionForward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(
              AppIcons.settingsInfo,
              color: AppColors.primary,
              size: AppSpacing.iconSm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'アプリバージョン',
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _packageInfo != null 
                      ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                      : '読み込み中...',
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

  Widget _buildLicenseInfo() {
    return MicroInteractions.bounceOnTap(
      onTap: () {
        MicroInteractions.hapticTap();
        showLicensePage(
          context: context,
          applicationName: 'Smart Photo Diary',
          applicationVersion: _packageInfo?.version ?? '1.0.0',
          applicationLegalese: '© 2024 Smart Photo Diary',
        );
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                Icons.article_outlined,
                color: AppColors.accent,
                size: AppSpacing.iconSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ライセンス',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'オープンソースライセンス',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.actionForward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'ライトテーマ';
      case ThemeMode.dark:
        return 'ダークテーマ';
      case ThemeMode.system:
        return 'システムに従う';
    }
  }



  void _showThemeDialog() async {
    final selectedTheme = await DialogUtils.showRadioSelectionDialog<ThemeMode>(
      context,
      'テーマ選択',
      ThemeMode.values,
      _settingsService.themeMode,
      _getThemeModeLabel,
    );
    
    if (selectedTheme != null) {
      _settingsService.setThemeMode(selectedTheme);
      widget.onThemeChanged?.call(selectedTheme);
      setState(() {});
    }
  }

  /// Phase 1.8.2.2: プラン変更・管理画面への遷移
  void _showUpgradeDialog() {
    DialogUtils.showSimpleDialog(
      context,
      'Premiumプランでは月間100回までAI日記生成が可能になり、高度なフィルタや統計機能もご利用いただけます。\n\n現在、アプリ内課金機能の準備中です。しばらくお待ちください。',
    );
  }


  Future<void> _exportData() async {
    try {
      _showLoadingDialog('エクスポート中...');
      
      final filePath = await StorageService.getInstance().exportData();
      
      if (mounted) {
        Navigator.pop(context); // ローディングダイアログを閉じる
        
        if (filePath != null) {
          _showSuccessDialog('エクスポート完了', 'バックアップファイルが正常に保存されました');
        } else {
          _showErrorDialog('エクスポートがキャンセルされたか、失敗しました');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('エラーが発生しました: $e');
      }
    }
  }

  Future<void> _optimizeDatabase() async {
    try {
      _showLoadingDialog('最適化中...');
      
      final success = await StorageService.getInstance().optimizeDatabase();
      
      if (mounted) {
        Navigator.pop(context); // ローディングダイアログを閉じる
        
        if (success) {
          await _loadSettings(); // ストレージ情報を再読み込み
          _showSuccessDialog('最適化完了', 'データベースの最適化が完了しました');
        } else {
          _showErrorDialog('最適化に失敗しました');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('エラーが発生しました: $e');
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


}