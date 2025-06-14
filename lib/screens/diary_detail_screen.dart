import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../core/service_registration.dart';
import '../constants/app_constants.dart';
import '../utils/dialog_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/animated_button.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;

  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();

  /// カスタムページ遷移を提供
  Route<T> customRoute<T>() {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => this,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
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
    _loadDiaryEntry();
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
      final diaryService = await ServiceRegistration.getAsync<DiaryServiceInterface>();

      // 日記エントリーを取得
      final entry = await diaryService.getDiaryEntry(widget.diaryId);

      if (entry == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = AppConstants.diaryNotFoundMessage;
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
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '${AppConstants.diaryLoadErrorMessage}: $e';
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
      final diaryService = await ServiceRegistration.getAsync<DiaryServiceInterface>();

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
          const SnackBar(content: Text(AppConstants.diaryUpdateSuccessMessage)),
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
      final diaryService = await ServiceRegistration.getAsync<DiaryServiceInterface>();

      // 日記を削除
      await diaryService.deleteDiaryEntry(_diaryEntry!.id);

      if (mounted) {
        // 削除成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text(AppConstants.diaryDeleteSuccessMessage)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? '日記を編集' : '日記の詳細'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        actions: [
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
                MicroInteractions.hapticTap(intensity: VibrationIntensity.medium);
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
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '日記を読み込み中...',
                        style: AppTypography.titleLarge,
                      ),
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
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'エラーが発生しました',
                        style: AppTypography.titleLarge,
                      ),
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
                          color: AppColors.warning.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          color: AppColors.warning,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '日記が見つかりません',
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppConstants.diaryNotFoundMessage,
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
      bottomNavigationBar: _isEditing && !_isLoading && !_hasError && _diaryEntry != null
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
                      flex: 3,
                      child: SecondaryButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _titleController.text = _diaryEntry!.title;
                            _contentController.text = _diaryEntry!.content;
                          });
                        },
                        text: 'キャンセル',
                        icon: Icons.close_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 4,
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
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.cardRadius,
                boxShadow: AppSpacing.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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
                            AppColors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy年MM月dd日').format(_diaryEntry!.date),
                          style: AppTypography.withColor(
                            AppTypography.titleLarge,
                            AppColors.onPrimaryContainer,
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
                        color: AppColors.primary,
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
                          color: AppColors.primary,
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
                              right: index == _photoAssets.length - 1 ? 0 : AppSpacing.md,
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
                        color: AppColors.primary,
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
                              color: AppColors.outline.withValues(alpha: 0.2),
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _diaryEntry!.title.isNotEmpty ? _diaryEntry!.title : '無題',
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
                              color: AppColors.outline.withValues(alpha: 0.2),
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    DateFormat('yyyy年MM月dd日 HH:mm').format(_diaryEntry!.createdAt),
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMetadataRow(
                    '更新日時',
                    DateFormat('yyyy年MM月dd日 HH:mm').format(_diaryEntry!.updatedAt),
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
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
            decoration: BoxDecoration(
              borderRadius: AppSpacing.photoRadius,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.photoRadius,
              child: RepaintBoundary(
                child: Image.memory(
                  snapshot.data!,
                  width: 200,
                  height: 240,
                  fit: BoxFit.cover,
                  cacheHeight: (240 * MediaQuery.of(context).devicePixelRatio).round(),
                  cacheWidth: (200 * MediaQuery.of(context).devicePixelRatio).round(),
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
            children: (_diaryEntry!.tags ?? []).map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.chipRadius,
              ),
              child: Text(
                tag,
                style: AppTypography.withColor(
                  AppTypography.labelSmall,
                  AppColors.onPrimaryContainer,
                ),
              ),
            )).toList(),
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
        child: Stack(
          children: [
            Center(
              child: Container(
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
                  child: Image.memory(
                    imageData,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: MicroInteractions.bounceOnTap(
                onTap: () {
                  MicroInteractions.hapticTap();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
