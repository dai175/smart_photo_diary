import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/writing_prompt.dart';
import '../screens/diary_preview_screen.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../widgets/photo_grid_widget.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/page_transitions.dart';
import '../utils/prompt_category_utils.dart';

/// 写真選択画面
class PhotoSelectionScreen extends StatefulWidget {
  final WritingPrompt? selectedPrompt;

  const PhotoSelectionScreen({
    super.key,
    this.selectedPrompt,
  });

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  late final PhotoSelectionController _photoController;

  @override
  void initState() {
    super.initState();
    _photoController = PhotoSelectionController();
    _loadTodayPhotos();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayPhotos() async {
    if (!mounted) return;
    
    _photoController.setLoading(true);

    try {
      // 権限リクエスト
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();
      final hasPermission = await photoService.requestPermission();
      debugPrint('権限ステータス: $hasPermission');

      if (!mounted) return;

      _photoController.setPermission(hasPermission);

      if (!hasPermission) {
        _photoController.setLoading(false);
        return;
      }

      // 今日撮影された写真だけを取得
      final photos = await photoService.getTodayPhotos();
      debugPrint('取得した写真数: ${photos.length}');

      if (!mounted) return;

      _photoController.setPhotoAssets(photos);
      _photoController.setLoading(false);
    } catch (e) {
      debugPrint('写真読み込みエラー: $e');
      if (mounted) {
        _photoController.setPhotoAssets([]);
        _photoController.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を選択'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 選択されたプロンプトの表示（ある場合）
          if (widget.selectedPrompt != null) _buildSelectedPrompt(),
          
          // 写真グリッド
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          
          // 日記作成ボタン
          _buildCreateDiaryButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedPrompt() {
    final prompt = widget.selectedPrompt!;
    
    return Container(
      margin: AppSpacing.screenPadding,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: PromptCategoryUtils.getCategoryColor(prompt.category).withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: PromptCategoryUtils.getCategoryColor(prompt.category).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: PromptCategoryUtils.getCategoryColor(prompt.category),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  PromptCategoryUtils.getCategoryDisplayName(prompt.category),
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.edit_note_rounded,
                color: PromptCategoryUtils.getCategoryColor(prompt.category),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            prompt.text,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (prompt.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              prompt.description!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_camera_rounded,
              color: AppColors.primary,
              size: AppSpacing.iconMd,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '今日の写真',
              style: AppTypography.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PhotoGridWidget(
          controller: _photoController,
          onSelectionLimitReached: _showSelectionLimitModal,
          onUsedPhotoSelected: _showUsedPhotoModal,
          onRequestPermission: _loadTodayPhotos,
        ),
      ],
    );
  }

  Widget _buildCreateDiaryButton() {
    return Container(
      padding: AppSpacing.screenPadding,
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
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _photoController,
          builder: (context, child) {
            return AnimatedButton(
              onPressed: _photoController.selectedCount > 0
                  ? _navigateToDiaryPreview
                  : null,
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              backgroundColor: _photoController.selectedCount > 0 
                  ? AppColors.primary 
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              foregroundColor: _photoController.selectedCount > 0 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              shadowColor: _photoController.selectedCount > 0 
                  ? AppColors.primary.withValues(alpha: 0.3) 
                  : null,
              elevation: _photoController.selectedCount > 0 ? AppSpacing.elevationSm : 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _photoController.selectedCount > 0 
                        ? Icons.auto_awesome_rounded 
                        : Icons.photo_camera_outlined,
                    size: AppSpacing.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _photoController.selectedCount > 0
                        ? '${_photoController.selectedCount}枚の写真で日記を作成'
                        : '写真を選択してください',
                    style: AppTypography.labelLarge,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDiaryPreview() {
    Navigator.push(
      context,
      DiaryPreviewScreen(
        selectedAssets: _photoController.selectedPhotos,
        selectedPrompt: widget.selectedPrompt, // プロンプトを渡す
      ).customRoute(),
    ).then((_) {
      // プレビューから戻ったらホーム画面まで戻る
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _showSelectionLimitModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PresetDialogs.error(
        title: '選択枚数の上限',
        message: '一度に選択できる写真は3枚までです。\n他の写真を選択する場合は、先に選択を解除してください。',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showUsedPhotoModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PresetDialogs.error(
        title: '使用済み写真',
        message: 'この写真は既に他の日記で使用されています。\n同じ写真を複数の日記で使用することはできません。',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }
}