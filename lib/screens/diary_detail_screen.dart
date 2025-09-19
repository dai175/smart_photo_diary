import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/social_share_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/dialog_utils.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../core/service_locator.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;

  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();

  /// カスタムページ遷移を提供
  Route<T> customRoute<T>() {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => this,
      transitionDuration: AppConstants.defaultAnimationDuration,
      reverseTransitionDuration: AppConstants.shortAnimationDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  DiaryEntry? _diaryEntry;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _hasError = false;
  String _errorMessage = '';
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<AssetEntity> _photoAssets = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    // ローカライズへの依存をinitState完了後に解決するため初回ロードはフレーム後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDiaryEntry();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 日記エントリーを読み込む
  Future<void> _loadDiaryEntry() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // DiaryServiceのインスタンスを取得
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      // 日記エントリーを取得
      final entry = await diaryService.getDiaryEntry(widget.diaryId);

      if (!mounted) return;

      if (entry == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = context.l10n.diaryNotFoundMessage;
        });
        return;
      }

      // 写真アセットを取得
      final assets = await entry.getPhotoAssets();

      setState(() {
        _diaryEntry = entry;
        _titleController.text = entry.title;
        _contentController.text = entry.content;
        _photoAssets = assets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '${l10n.diaryLoadErrorMessage}: $e';
      });
    }
  }

  /// 日記を更新する
  Future<void> _updateDiary() async {
    // BuildContextを保存
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_diaryEntry == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // DiaryServiceのインスタンスを取得
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      // 日記を更新
      final updatedEntry = _diaryEntry!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        updatedAt: DateTime.now(),
      );
      await diaryService.updateDiaryEntry(updatedEntry);

      // 日記エントリーを再読み込み
      await _loadDiaryEntry();

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        // 更新成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(context.l10n.diaryUpdateSuccessMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '日記の更新に失敗しました: $e';
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('エラー: $_errorMessage')),
        );
      }
    }
  }

  /// 日記を削除する
  Future<void> _deleteDiary() async {
    // BuildContextを保存
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_diaryEntry == null) return;

    // 確認ダイアログを表示
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      '日記の削除',
      'この日記を削除してもよろしいですか？\nこの操作は元に戻せません。',
      confirmText: '削除',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // DiaryServiceのインスタンスを取得
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      // 日記を削除
      await diaryService.deleteDiaryEntry(_diaryEntry!.id);

      if (mounted) {
        // 削除成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(context.l10n.diaryDeleteSuccessMessage)),
        );

        // 前の画面に戻る（削除成功を示すフラグを返す）
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '日記の削除に失敗しました: $e';
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('エラー: $_errorMessage')),
        );
      }
    }
  }

  /// 共有ダイアログを表示
  Future<void> _showShareDialog() async {
    if (_diaryEntry == null) return;

    final result = await showDialog<ShareFormat>(
      context: context,
      builder: (context) => CustomDialog(
        title: '共有',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('どの形式で共有しますか？', style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            // X（旧Twitter）へ直接共有
            _buildShareOption(
              format: ShareFormat.square,
              title: '写真と日記テキスト',
              subtitle: 'X（旧Twitter）向け',
              icon: Icons.share_rounded,
              onTap: () async {
                Navigator.of(context).pop();
                await _shareToX();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // 縦長オプション
            _buildShareOption(
              format: ShareFormat.portrait,
              title: '写真と日記を画像に',
              subtitle: 'Instagram向け（縦長）',
              icon: Icons.crop_portrait_rounded,
              onTap: () {
                Navigator.of(context).pop(ShareFormat.portrait);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // 正方形オプション
            _buildShareOption(
              format: ShareFormat.square,
              title: '写真と日記を画像に',
              subtitle: 'Instagram向け（正方形）',
              icon: Icons.crop_din_rounded,
              onTap: () {
                Navigator.of(context).pop(ShareFormat.square);
              },
            ),
          ],
        ),
        actions: [
          CustomDialogAction(
            text: 'キャンセル',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    if (result != null) {
      await _shareToInstagram(result);
    }
  }

  Rect _resolveShareOrigin() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final topLeft = renderBox.localToGlobal(Offset.zero);
      return topLeft & renderBox.size;
    }
    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  /// 共有オプションのウィジェットを構築
  Widget _buildShareOption({
    required ShareFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MicroInteractions.bounceOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: AppSpacing.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  /// X（旧Twitter）へ共有
  Future<void> _shareToX() async {
    final diary = _diaryEntry;
    if (diary == null) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final shareOrigin = _resolveShareOrigin();

    try {
      // ローディングダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CustomDialog(
            title: '共有準備中',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text('準備しています...', style: AppTypography.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator(strokeWidth: 3)),
              ],
            ),
            actions: const [],
          );
        },
      );

      final share = serviceLocator.get<ISocialShareService>();
      final result = await share.shareToX(
        diary: diary,
        shareOrigin: shareOrigin,
      );

      // ローディングダイアログを閉じる
      if (mounted) navigator.pop();

      result.fold(
        (_) {
          // 成功時は特に何もしない（システム共有シートで完結）
        },
        (error) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('共有に失敗しました: ${error.message}')),
          );
        },
      );
    } catch (e) {
      // ローディングダイアログを閉じる
      if (mounted) navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('予期しないエラーが発生しました: $e')),
      );
    }
  }

  /// Instagramに共有
  Future<void> _shareToInstagram(ShareFormat format) async {
    if (_diaryEntry == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final shareOrigin = _resolveShareOrigin();

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: '共有準備中',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '共有用画像を生成しています...',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // SocialShareServiceを取得
      final socialShareService = serviceLocator.get<ISocialShareService>();

      // Instagram共有を実行
      final result = await socialShareService.shareToSocialMedia(
        diary: _diaryEntry!,
        format: format,
        photos: _photoAssets,
        shareOrigin: shareOrigin,
      );

      // ローディングダイアログを閉じる
      if (mounted) Navigator.of(context).pop();

      result.fold(
        (_) {
          // 共有成功時は特に何もしない（システム共有シートで完結）
        },
        (error) {
          // エラーメッセージ
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('共有に失敗しました: ${error.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    } catch (e) {
      // ローディングダイアログを閉じる
      if (mounted) Navigator.of(context).pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('予期しないエラーが発生しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? '日記を編集' : '日記の詳細'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        elevation: 2,
        actions: [
          // 共有ボタン
          if (!_isLoading && !_hasError && _diaryEntry != null && !_isEditing)
            IconButton(
              onPressed: () {
                MicroInteractions.hapticTap();
                _showShareDialog();
              },
              icon: Icon(
                Icons.share_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              tooltip: '共有',
            ),
          // 編集モード切替ボタン
          if (!_isLoading && !_hasError && _diaryEntry != null)
            IconButton(
              onPressed: () {
                MicroInteractions.hapticTap();
                if (_isEditing) {
                  _updateDiary();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              icon: Icon(
                _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              tooltip: _isEditing ? '保存' : '編集',
            ),
          // 削除ボタン
          if (!_isLoading && !_hasError && _diaryEntry != null)
            IconButton(
              onPressed: () {
                MicroInteractions.hapticTap(
                  intensity: VibrationIntensity.medium,
                );
                _deleteDiary();
              },
              icon: Icon(
                Icons.delete_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              tooltip: '削除',
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('日記を読み込み中...', style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '日記の内容と写真を取得しています',
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
          : _hasError
          ? Center(
              child: FadeInWidget(
                child: CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('エラーが発生しました', style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _errorMessage,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        onPressed: () => Navigator.pop(context),
                        text: '戻る',
                        icon: Icons.arrow_back_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _diaryEntry == null
          ? Center(
              child: FadeInWidget(
                child: CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('日記が見つかりません', style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.diaryNotFoundMessage,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        onPressed: () => Navigator.pop(context),
                        text: '戻る',
                        icon: Icons.arrow_back_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _buildDiaryDetail(),
      bottomNavigationBar:
          _isEditing && !_isLoading && !_hasError && _diaryEntry != null
          ? SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SecondaryButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _titleController.text = _diaryEntry!.title;
                            _contentController.text = _diaryEntry!.content;
                          });
                        },
                        text: 'キャンセル',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 1,
                      child: PrimaryButton(
                        onPressed: _updateDiary,
                        text: '保存',
                        icon: Icons.save_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDiaryDetail() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付ヘッダーカード
          FadeInWidget(
            child: Container(
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: AppSpacing.cardRadius,
                boxShadow: AppSpacing.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '日記の日付',
                          style: AppTypography.withColor(
                            AppTypography.labelMedium,
                            Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy年MM月dd日').format(_diaryEntry!.date),
                          style: AppTypography.withColor(
                            AppTypography.titleLarge,
                            Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((_diaryEntry!.tags?.isNotEmpty ?? false)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: AppSpacing.chipRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: AppSpacing.iconXs,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${(_diaryEntry!.tags?.length ?? 0)}個のタグ',
                            style: AppTypography.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 写真セクション
          if (_photoAssets.isNotEmpty) ...[
            SlideInWidget(
              delay: const Duration(milliseconds: 100),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: AppSpacing.iconMd,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '写真 (${_photoAssets.length}枚)',
                          style: AppTypography.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photoAssets.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == _photoAssets.length - 1
                                  ? 0
                                  : AppSpacing.md,
                            ),
                            child: _buildPhotoItem(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // コンテンツセクション
          SlideInWidget(
            delay: Duration(milliseconds: _photoAssets.isNotEmpty ? 200 : 100),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit_rounded : Icons.article_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppSpacing.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _isEditing ? '日記を編集' : '日記の内容',
                        style: AppTypography.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // タイトルセクション
                  _isEditing
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            borderRadius: AppSpacing.inputRadius,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: AppTypography.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'タイトル',
                              border: InputBorder.none,
                              hintText: '日記のタイトルを入力',
                              contentPadding: AppSpacing.inputPadding,
                              labelStyle: AppTypography.labelMedium,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'タイトル',
                              style: AppTypography.labelMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _diaryEntry!.title.isNotEmpty
                                  ? _diaryEntry!.title
                                  : '無題',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: AppSpacing.lg),

                  // 本文セクション
                  _isEditing
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            borderRadius: AppSpacing.inputRadius,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            minLines: 8,
                            textAlignVertical: TextAlignVertical.top,
                            style: AppTypography.bodyLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: '本文',
                              border: InputBorder.none,
                              hintText: '日記の内容を入力してください',
                              contentPadding: AppSpacing.inputPadding,
                              labelStyle: AppTypography.labelMedium,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '本文',
                              style: AppTypography.labelMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _diaryEntry!.content,
                              style: AppTypography.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // メタデータセクション
          SlideInWidget(
            delay: Duration(milliseconds: _photoAssets.isNotEmpty ? 300 : 200),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: AppSpacing.iconSm,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '詳細情報',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildMetadataRow(
                    '作成日時',
                    DateFormat(
                      'yyyy年MM月dd日 HH:mm',
                    ).format(_diaryEntry!.createdAt),
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMetadataRow(
                    '更新日時',
                    DateFormat(
                      'yyyy年MM月dd日 HH:mm',
                    ).format(_diaryEntry!.updatedAt),
                    Icons.update_rounded,
                  ),
                  if ((_diaryEntry!.tags?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildTagsRow(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return FutureBuilder<Uint8List?>(
      future: _photoAssets[index].thumbnailDataWithSize(
        ThumbnailSize(
          (AppConstants.largeImageSize * 1.2).toInt(),
          (AppConstants.largeImageSize * 1.2).toInt(),
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 200,
            height: 200, // 正方形に変更
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        return MicroInteractions.bounceOnTap(
          onTap: () {
            MicroInteractions.hapticTap();
            _showPhotoDialog(snapshot.data!, index);
          },
          child: Container(
            width: 200,
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.photoRadius,
              child: RepaintBoundary(
                child: Image.memory(
                  snapshot.data!,
                  width: 200,
                  fit: BoxFit.contain, // cover → contain に変更
                  cacheWidth: (200 * MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppSpacing.iconXs,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.tag_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppSpacing.iconXs,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'タグ: ',
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: (_diaryEntry!.tags ?? [])
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: AppSpacing.chipRadius,
                    ),
                    child: Text(
                      tag,
                      style: AppTypography.withColor(
                        AppTypography.labelSmall,
                        Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showPhotoDialog(Uint8List imageData, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.cardRadiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppSpacing.cardRadiusLarge,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Image.memory(imageData, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: MicroInteractions.bounceOnTap(
                  onTap: () {
                    MicroInteractions.hapticTap();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
