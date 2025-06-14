import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/dialog_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';

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
  bool _isLoading = true;

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
                Icons.refresh_rounded,
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
                        style: AppTypography.titleLarge,
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
                          delay: const Duration(milliseconds: 100),
                          child: _buildStorageInfo(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 150),
                          child: _buildBackupAction(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 200),
                          child: _buildOptimizeAction(),
                        ),
                        _buildDivider(),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 250),
                          child: _buildVersionInfo(),
                        ),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 300),
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
                  Icons.brightness_6_rounded,
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
                      style: AppTypography.titleMedium,
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
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ],
          ),
        ),
      ),
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
                color: AppColors.surfaceVariant,
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
                    style: AppTypography.titleMedium,
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

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            Icons.storage_rounded,
            color: AppColors.info,
            size: AppSpacing.iconSm,
          ),
        ),
        title: Text(
          '使用容量',
          style: AppTypography.titleMedium,
        ),
        subtitle: Text(
          '合計: ${_storageInfo!.formattedTotalSize}',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
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
      ),
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
            style: AppTypography.bodyMedium,
          ),
        ),
        Text(
          size,
          style: AppTypography.withColor(
            AppTypography.labelLarge,
            color,
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
                Icons.file_download_outlined,
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
                    style: AppTypography.titleMedium,
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
              Icons.chevron_right_rounded,
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
                Icons.cleaning_services_rounded,
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
                    style: AppTypography.titleMedium,
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
              Icons.chevron_right_rounded,
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
              Icons.info_outline_rounded,
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
                  style: AppTypography.titleMedium,
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
                    style: AppTypography.titleMedium,
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
              Icons.chevron_right_rounded,
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