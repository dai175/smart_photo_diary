import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/writing_prompt.dart';
import '../screens/diary_preview_screen.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/past_photo_grid_widget.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/page_transitions.dart';
import '../utils/prompt_category_utils.dart';

/// 過去の写真選択画面（タブ付き）
class PastPhotosSelectionScreen extends StatefulWidget {
  final WritingPrompt? selectedPrompt;

  const PastPhotosSelectionScreen({super.key, this.selectedPrompt});

  @override
  State<PastPhotosSelectionScreen> createState() =>
      _PastPhotosSelectionScreenState();
}

class _PastPhotosSelectionScreenState extends State<PastPhotosSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PhotoSelectionController _todayPhotoController;
  late final PhotoSelectionController _pastPhotoController;

  PhotoSelectionController get activeController =>
      _tabController.index == 0 ? _todayPhotoController : _pastPhotoController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _todayPhotoController = PhotoSelectionController();
    _pastPhotoController = PhotoSelectionController();

    _tabController.addListener(() {
      setState(() {});
    });

    _loadTodayPhotos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _todayPhotoController.dispose();
    _pastPhotoController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayPhotos() async {
    if (!mounted) return;

    _todayPhotoController.setLoading(true);

    try {
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      _todayPhotoController.setPermission(hasPermission);

      if (!hasPermission) {
        _todayPhotoController.setLoading(false);
        return;
      }

      final photos = await photoService.getTodayPhotos();

      if (!mounted) return;

      _todayPhotoController.setPhotoAssets(photos);
      _todayPhotoController.setLoading(false);
    } catch (e) {
      debugPrint('写真読み込みエラー: $e');
      if (mounted) {
        _todayPhotoController.setPhotoAssets([]);
        _todayPhotoController.setLoading(false);
      }
    }
  }

  Future<void> _loadPastPhotos() async {
    if (!mounted) return;

    _pastPhotoController.setLoading(true);

    try {
      // TODO: 過去の写真を読み込む処理を実装
      // PhotoServiceの拡張メソッドを使用
      await Future.delayed(const Duration(milliseconds: 500)); // 仮の処理

      if (!mounted) return;

      _pastPhotoController.setPhotoAssets([]); // 暫定的に空リスト
      _pastPhotoController.setLoading(false);
    } catch (e) {
      debugPrint('過去の写真読み込みエラー: $e');
      if (mounted) {
        _pastPhotoController.setPhotoAssets([]);
        _pastPhotoController.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を選択'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today_rounded), text: '今日'),
            Tab(icon: Icon(Icons.history_rounded), text: '過去の写真'),
          ],
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.7),
          onTap: (index) {
            if (index == 1 && _pastPhotoController.photoAssets.isEmpty) {
              _loadPastPhotos();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 選択されたプロンプトの表示（ある場合）
          if (widget.selectedPrompt != null) _buildSelectedPrompt(),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTodayPhotosTab(), _buildPastPhotosTab()],
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
        color: PromptCategoryUtils.getCategoryColor(
          prompt.category,
        ).withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: PromptCategoryUtils.getCategoryColor(
            prompt.category,
          ).withValues(alpha: 0.3),
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

  Widget _buildTodayPhotosTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon: Icons.photo_camera_rounded, title: '今日の写真'),
          const SizedBox(height: AppSpacing.lg),
          PhotoGridWidget(
            controller: _todayPhotoController,
            onSelectionLimitReached: _showSelectionLimitModal,
            onUsedPhotoSelected: _showUsedPhotoModal,
            onRequestPermission: _loadTodayPhotos,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPastPhotosTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon: Icons.history_rounded, title: '過去の写真'),
          const SizedBox(height: AppSpacing.lg),

          // 過去の写真グリッド
          PastPhotoGridWidget(
            controller: _pastPhotoController,
            onSelectionLimitReached: _showSelectionLimitModal,
            onUsedPhotoSelected: _showUsedPhotoModal,
            onAccessDenied: _showAccessDeniedModal,
            onRequestPermission: _loadPastPhotos,
            photoGroups: const [], // TODO: 実際の写真グループデータを渡す
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.titleLarge),
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
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _todayPhotoController,
            _pastPhotoController,
          ]),
          builder: (context, child) {
            final selectedCount = activeController.selectedCount;

            return AnimatedButton(
              onPressed: selectedCount > 0 ? _navigateToDiaryPreview : null,
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              backgroundColor: selectedCount > 0
                  ? AppColors.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              foregroundColor: selectedCount > 0
                  ? Colors.white
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
              shadowColor: selectedCount > 0
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : null,
              elevation: selectedCount > 0 ? AppSpacing.elevationSm : 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedCount > 0
                        ? Icons.auto_awesome_rounded
                        : Icons.photo_camera_outlined,
                    size: AppSpacing.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    selectedCount > 0
                        ? '${selectedCount}枚の写真で日記を作成'
                        : '写真を選んでください',
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
        selectedAssets: activeController.selectedPhotos,
        selectedPrompt: widget.selectedPrompt,
      ).customRoute(),
    ).then((_) {
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

  void _showAccessDeniedModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PresetDialogs.confirmation(
        title: 'プレミアムプラン限定',
        message:
            'この写真にアクセスするには\nプレミアムプランが必要です。\n\nプレミアムプランなら1年前までの\n写真から日記を作成できます。',
        confirmText: 'プレミアムを見る',
        cancelText: '閉じる',
        onConfirm: () {
          Navigator.of(context).pop();
          // TODO: プレミアムプラン購入画面に遷移
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
