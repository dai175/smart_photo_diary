import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/dialog_utils.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(Color)? onAccentColorChanged;

  const SettingsScreen({
    super.key,
    this.onThemeChanged,
    this.onAccentColorChanged,
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
        title: const Text(
          '設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAppearanceSection(),
                  const SizedBox(height: 24),
                  _buildDataManagementSection(),
                  const SizedBox(height: 24),
                  _buildAppInfoSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAppearanceSection() {
    debugPrint('外観設定セクションを構築中...');
    return _buildSection(
      title: 'テーマ・見た目',
      icon: Icons.palette,
      children: [
        _buildThemeSelector(),
        const Divider(height: 1),
        _buildAccentColorSelector(),
        const Divider(height: 1),
        _buildGenerationModeSelector(),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return _buildSection(
      title: 'データ・容量',
      icon: Icons.storage,
      children: [
        _buildStorageInfo(),
        const Divider(height: 1),
        _buildDataActions(),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return _buildSection(
      title: 'アプリ情報',
      icon: Icons.info,
      children: [
        _buildVersionInfo(),
        const Divider(height: 1),
        _buildLicenseInfo(),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('テーマ'),
      subtitle: Text(_getThemeModeLabel(_settingsService.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showThemeDialog();
      },
    );
  }

  Widget _buildAccentColorSelector() {
    return ListTile(
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: _settingsService.accentColor,
      ),
      title: const Text('アプリのカラー'),
      subtitle: Text(_getColorName(_settingsService.accentColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showColorDialog();
      },
    );
  }

  Widget _buildGenerationModeSelector() {
    try {
      return ListTile(
        leading: const Icon(Icons.auto_fix_high),
        title: const Text('プライバシー設定'),
        subtitle: Text(_getGenerationModeLabel(_settingsService.generationMode)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showGenerationModeDialog();
        },
      );
    } catch (e) {
      debugPrint('日記生成モード設定の読み込みエラー: $e');
      return ListTile(
        leading: const Icon(Icons.auto_fix_high),
        title: const Text('プライバシー設定'),
        subtitle: const Text('設定の読み込み中...'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showGenerationModeDialog();
        },
      );
    }
  }

  Widget _buildStorageInfo() {
    if (_storageInfo == null) {
      return const ListTile(
        leading: Icon(Icons.storage),
        title: Text('ストレージ情報'),
        subtitle: Text('読み込み中...'),
      );
    }

    return ExpansionTile(
      leading: const Icon(Icons.storage),
      title: const Text('使用容量'),
      subtitle: Text('合計: ${_storageInfo!.formattedTotalSize}'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildStorageItem('日記データ', _storageInfo!.formattedDiaryDataSize, Colors.blue),
              const SizedBox(height: 8),
              _buildStorageItem('画像データ（推定）', _storageInfo!.formattedImageDataSize, Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageItem(String label, String size, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          size,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDataActions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('バックアップ'),
          subtitle: const Text('日記データをファイルに保存'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _exportData,
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: const Text('容量の整理'),
          subtitle: const Text('不要なデータを削除してアプリを軽くする'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _optimizeDatabase,
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    if (_packageInfo == null) {
      return const ListTile(
        leading: Icon(Icons.info),
        title: Text('アプリのバージョン'),
        subtitle: Text('読み込み中...'),
      );
    }

    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('アプリバージョン'),
      subtitle: Text('${_packageInfo!.version} (${_packageInfo!.buildNumber})'),
    );
  }

  Widget _buildLicenseInfo() {
    return ListTile(
      leading: const Icon(Icons.article),
      title: const Text('ライセンス'),
      subtitle: const Text('オープンソースライセンス'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showLicensePage(
          context: context,
          applicationName: 'Smart Photo Diary',
          applicationVersion: _packageInfo?.version ?? '1.0.0',
          applicationLegalese: '© 2024 Smart Photo Diary',
        );
      },
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

  String _getColorName(Color color) {
    final index = SettingsService.availableColors.indexOf(color);
    if (index >= 0 && index < SettingsService.colorNames.length) {
      return SettingsService.colorNames[index];
    }
    return 'カスタム';
  }

  String _getGenerationModeLabel(DiaryGenerationMode mode) {
    final index = SettingsService.availableModes.indexOf(mode);
    if (index >= 0 && index < SettingsService.modeNames.length) {
      return SettingsService.modeNames[index];
    }
    return 'ラベル抽出方式';
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

  void _showColorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カラーを選ぶ'),
          content: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: SettingsService.availableColors.map((color) {
              final isSelected = color == _settingsService.accentColor;
              
              return GestureDetector(
                onTap: () {
                  _settingsService.setAccentColor(color);
                  widget.onAccentColorChanged?.call(color);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData() async {
    try {
      _showLoadingDialog('エクスポート中...');
      
      final filePath = await StorageService.getInstance().exportData();
      
      if (mounted) {
        Navigator.pop(context); // ローディングダイアログを閉じる
        
        if (filePath != null) {
          _showSuccessDialog('エクスポート完了', 'データが以下の場所に保存されました:\n$filePath');
        } else {
          _showErrorDialog('エクスポートに失敗しました');
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

  void _showGenerationModeDialog() {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('プライバシー設定'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: SettingsService.availableModes.map((mode) {
                final index = SettingsService.availableModes.indexOf(mode);
                return RadioListTile<DiaryGenerationMode>(
                  title: Text(SettingsService.modeNames[index]),
                  subtitle: Text(SettingsService.modeDescriptions[index]),
                  value: mode,
                  groupValue: _settingsService.generationMode,
                  onChanged: (value) {
                    if (value != null) {
                      _settingsService.setGenerationMode(value);
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('日記生成モードダイアログ表示エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定の読み込みに失敗しました: $e')),
      );
    }
  }
}