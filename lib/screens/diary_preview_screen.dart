import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
import '../constants/app_constants.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/custom_dialog.dart' show PresetDialogs;
import '../ui/animations/list_animations.dart';
import '../core/errors/app_exceptions.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../models/plans/basic_plan.dart';
import '../models/writing_prompt.dart';
import '../core/errors/error_handler.dart';
import '../utils/prompt_category_utils.dart';
import '../utils/upgrade_dialog_utils.dart';
import 'diary_detail_screen.dart';

/// 生成された日記のプレビュー画面
class DiaryPreviewScreen extends StatefulWidget {
  /// 選択された写真アセット
  final List<AssetEntity> selectedAssets;

  /// 選択されたプロンプト（オプション）
  final WritingPrompt? selectedPrompt;

  const DiaryPreviewScreen({
    super.key,
    required this.selectedAssets,
    this.selectedPrompt,
  });

  @override
  State<DiaryPreviewScreen> createState() => _DiaryPreviewScreenState();
}

class _DiaryPreviewScreenState extends State<DiaryPreviewScreen> {
  late final LoggingService _logger;
  late final IAiService _aiService;
  late final IPhotoService _photoService;

  bool _isInitializing = true; // プロンプトサービス初期化中
  bool _isLoading = false; // 日記生成中
  bool _isSaving = false; // 自動保存中
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _photoDateTime = DateTime.now(); // 写真の撮影日時

  // 複数写真処理の進捗表示用
  int _currentPhotoIndex = 0;
  int _totalPhotos = 0;
  bool _isAnalyzingPhotos = false;

  // 日記の編集用コントローラー
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // プロンプト機能関連
  WritingPrompt? _selectedPrompt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    // サービスロケータからサービスを取得
    _logger = serviceLocator.get<LoggingService>();
    _aiService = ServiceRegistration.get<IAiService>();
    _photoService = ServiceRegistration.get<IPhotoService>();

    // 渡されたプロンプトがある場合は設定
    _selectedPrompt = widget.selectedPrompt;

    _initializePromptServices();
  }

  /// 初期化完了後の処理
  Future<void> _initializePromptServices() async {
    // 少し待ってから初期化完了とする
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isInitializing = false; // 初期化完了
      });

      // プロンプトの有無に関わらず自動的に日記生成を開始
      _loadModelAndGenerateDiary();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// モデルをロードして日記を生成
  Future<void> _loadModelAndGenerateDiary() async {
    if (widget.selectedAssets.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '選択された写真がありません';
      });
      return;
    }

    // 日記生成開始時にローディング状態を設定
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 写真の撮影日時を取得
      List<DateTime> photoTimes = [];

      // 全ての写真の撮影時刻を収集
      for (final asset in widget.selectedAssets) {
        photoTimes.add(asset.createDateTime);
      }

      // 写真が複数ある場合は時間範囲を考慮、単一の場合はその時刻を使用
      DateTime photoDateTime;
      if (photoTimes.length == 1) {
        photoDateTime = photoTimes.first;
      } else {
        // 複数写真の場合は中央値の時刻を使用
        photoTimes.sort();
        final middleIndex = photoTimes.length ~/ 2;
        photoDateTime = photoTimes[middleIndex];
      }

      DiaryGenerationResult result;

      // Vision API方式：画像を直接Geminiに送信
      if (widget.selectedAssets.length == 1) {
        // 単一写真の場合：従来通り
        final firstAsset = widget.selectedAssets.first;
        final imageData = await _photoService.getOriginalFile(firstAsset);

        if (imageData == null) {
          throw Exception('写真データの取得に失敗しました');
        }

        final resultFromAi = await _aiService.generateDiaryFromImage(
          imageData: imageData,
          date: photoDateTime,
          prompt: _selectedPrompt?.text,
        );

        if (resultFromAi.isFailure) {
          // Phase 1.7.2.1: 使用量制限エラーの専用UI表示
          if (resultFromAi.error is AiProcessingException &&
              resultFromAi.error.message.contains('月間制限に達しました')) {
            await _showUsageLimitDialog(resultFromAi.error.message);
            return;
          }
          throw Exception(resultFromAi.error.message);
        }

        result = resultFromAi.value;
      } else {
        // 複数写真の場合：新しい順次処理方式を使用
        _logger.info('複数写真の順次分析を開始', context: 'DiaryPreviewScreen');

        // 全ての写真データを収集
        final List<({Uint8List imageData, DateTime time})> imagesWithTimes = [];

        for (final asset in widget.selectedAssets) {
          final imageData = await _photoService.getOriginalFile(asset);
          if (imageData != null) {
            imagesWithTimes.add((
              imageData: imageData,
              time: asset.createDateTime,
            ));
          }
        }

        if (imagesWithTimes.isEmpty) {
          throw Exception('写真データの取得に失敗しました');
        }

        // 進捗表示を開始
        setState(() {
          _isAnalyzingPhotos = true;
          _totalPhotos = imagesWithTimes.length;
          _currentPhotoIndex = 0;
        });

        final resultFromAi = await _aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          prompt: _selectedPrompt?.text,
          onProgress: (current, total) {
            _logger.info(
              '画像分析進捗: $current/$total',
              context: 'DiaryPreviewScreen',
            );
            setState(() {
              _currentPhotoIndex = current;
              _totalPhotos = total;
            });
          },
        );

        if (resultFromAi.isFailure) {
          // Phase 1.7.2.1: 使用量制限エラーの専用UI表示
          if (resultFromAi.error is AiProcessingException &&
              resultFromAi.error.message.contains('月間制限に達しました')) {
            await _showUsageLimitDialog(resultFromAi.error.message);
            return;
          }
          throw Exception(resultFromAi.error.message);
        }

        result = resultFromAi.value;

        // 進捗表示を終了
        setState(() {
          _isAnalyzingPhotos = false;
        });
      }

      setState(() {
        _titleController.text = result.title;
        _contentController.text = result.content;
        _isLoading = false;
        _isSaving = true; // 自動保存開始
        // 写真の撮影日時を保存
        _photoDateTime = photoDateTime;
      });

      // プロンプトが使用された場合のみ使用履歴を記録
      if (_selectedPrompt != null) {
        try {
          final promptService =
              await ServiceRegistration.getAsync<IPromptService>();
          await promptService.recordPromptUsage(promptId: _selectedPrompt!.id);
        } catch (e) {
          _logger.error(
            'プロンプト使用履歴記録エラー',
            error: e,
            context: 'DiaryPreviewScreen',
          );
        }
      }

      // 自動保存を実行
      await _autoSaveDiary();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '日記の生成中にエラーが発生しました。\n時間を空けてもう一度お試しください。';
      });
    }
  }

  /// 自動保存を実行し、日記詳細画面に遷移する
  Future<void> _autoSaveDiary() async {
    // BuildContextを保存
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      _logger.info('自動保存開始', context: 'DiaryPreviewScreen');
      _logger.info(
        'タイトル: ${_titleController.text}',
        context: 'DiaryPreviewScreen',
      );
      _logger.info(
        '本文: ${_contentController.text}',
        context: 'DiaryPreviewScreen',
      );
      _logger.info(
        '写真数: ${widget.selectedAssets.length}',
        context: 'DiaryPreviewScreen',
      );

      // DiaryServiceのインスタンスを取得
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      // 日記を保存
      final savedDiary = await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: _titleController.text,
        content: _contentController.text,
        photos: widget.selectedAssets,
      );

      _logger.info('自動保存成功', context: 'DiaryPreviewScreen');

      // ウィジェットがまだマウントされている場合のみ遷移
      if (mounted) {
        // 日記詳細画面に遷移（保存完了メッセージ付き）
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(diaryId: savedDiary.id),
          ),
        );

        // 保存成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('日記を保存しました')),
        );
      }
    } catch (e, stackTrace) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '自動保存');
      loggingService.error(
        '日記の自動保存に失敗しました',
        context: 'DiaryPreviewScreen._autoSaveDiary',
        error: appError,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasError = true;
          _errorMessage = '日記の保存に失敗しました。\n時間を空けてもう一度お試しください。';
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('エラー: $_errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// 日記を保存する（手動保存用、後方互換性のため残す）
  Future<void> _saveDiary() async {
    // BuildContextを保存
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      _logger.info('日記保存開始', context: 'DiaryPreviewScreen');
      _logger.info(
        'タイトル: ${_titleController.text}',
        context: 'DiaryPreviewScreen',
      );
      _logger.info(
        '本文: ${_contentController.text}',
        context: 'DiaryPreviewScreen',
      );
      _logger.info(
        '写真数: ${widget.selectedAssets.length}',
        context: 'DiaryPreviewScreen',
      );

      // DiaryServiceのインスタンスを取得
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      // 日記を保存
      await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: _titleController.text,
        content: _contentController.text,
        photos: widget.selectedAssets,
      );

      _logger.info('日記保存成功', context: 'DiaryPreviewScreen');

      // ウィジェットがまだマウントされている場合のみ状態を更新
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 保存成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('日記を保存しました')),
        );

        // 前の画面に戻る
        navigator.pop();
      }
    } catch (e, stackTrace) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '日記保存');
      loggingService.error(
        '日記の保存に失敗しました',
        context: 'DiaryPreviewScreen._saveDiaryEntry',
        error: appError,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '日記の保存に失敗しました。\n時間を空けてもう一度お試しください。';
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('エラー: $_errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Phase 1.7.2.1: 使用量制限エラー専用ダイアログ表示
  Future<void> _showUsageLimitDialog(String errorMessage) async {
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // プラン情報を取得
      final planResult = await subscriptionService.getCurrentPlanClass();
      final resetDateResult = await subscriptionService.getNextResetDate();

      final plan = planResult.isSuccess ? planResult.value : BasicPlan();
      final limit = plan.monthlyAiGenerationLimit;
      final nextResetDate = resetDateResult.isSuccess
          ? resetDateResult.value
          : DateTime.now().add(const Duration(days: 30));

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => PresetDialogs.usageLimitReached(
            context: context,
            planName: plan.displayName,
            limit: limit,
            nextResetDate: nextResetDate,
            onUpgrade: () {
              Navigator.of(context).pop();
              _navigateToUpgrade();
            },
            onDismiss: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 前の画面に戻る
            },
          ),
        );
      }
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      loggingService.warning(
        '使用量制限ダイアログ表示エラー',
        context: 'DiaryPreviewScreen._showUsageLimitDialog',
        data: e.toString(),
      );
      // フォールバック: 基本的なエラーダイアログ
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => PresetDialogs.error(
            context: context,
            title: 'AI生成の制限に達しました',
            message: 'AI生成の月間制限に達したため、来月まで新しい日記を生成できません。',
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(); // 前の画面に戻る
        }
      }
    }
  }

  /// Phase 1.7.2.4: プラン変更誘導機能
  void _navigateToUpgrade() async {
    // アップグレードダイアログを表示
    await UpgradeDialogUtils.showUpgradeDialog(context);

    // ダイアログを閉じた後、日記生成画面も閉じてホーム画面に戻る
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// プロンプトをクリア（再生成時に使用）
  void _clearPrompt() {
    setState(() {
      _selectedPrompt = null;
    });
  }

  /// 選択されたプロンプトの表示
  Widget _buildSelectedPromptDisplay() {
    if (_selectedPrompt == null) return const SizedBox.shrink();

    return FadeInWidget(
      delay: const Duration(milliseconds: 50),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: PromptCategoryUtils.getCategoryColor(
                    _selectedPrompt!.category,
                  ),
                  size: AppSpacing.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('使用中のプロンプト', style: AppTypography.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PromptCategoryUtils.getCategoryColor(
                      _selectedPrompt!.category,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    PromptCategoryUtils.getCategoryDisplayName(
                      _selectedPrompt!.category,
                    ),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _selectedPrompt!.text,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_selectedPrompt!.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _selectedPrompt!.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 日記破棄の確認ダイアログを表示
  Future<bool> _showDiscardConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PresetDialogs.confirmation(
        context: context,
        title: '日記を破棄しますか？',
        message: 'AI生成回数は既に消費されています。',
        confirmText: '破棄して戻る',
        cancelText: 'キャンセル',
        isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // 日記が生成済みかチェック（タイトルが空でない場合）
        if (!_isLoading && !_hasError && _titleController.text.isNotEmpty) {
          // 確認ダイアログを表示
          final shouldPop = await _showDiscardConfirmationDialog();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // 生成前・ローディング中・エラー時は確認なしで戻る
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('日記プレビュー'),
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
          actions: [
            // 再生成ボタン（プロンプトをスキップ）
            if (!_isInitializing &&
                !_isLoading &&
                !_hasError &&
                _selectedPrompt != null)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.xs),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    _clearPrompt();
                    _loadModelAndGenerateDiary();
                  },
                  tooltip: 'プロンプトなしで再生成',
                ),
              ),
            // 手動保存ボタン（自動保存有効時は表示しない）
            if (!_isInitializing && !_isLoading && !_isSaving && !_hasError)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: IconButton(
                  icon: Icon(
                    Icons.save_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _saveDiary,
                  tooltip: '日記を保存',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日付表示カード
                FadeInWidget(
                  child: Container(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '日記の日付',
                              style: AppTypography.withColor(
                                AppTypography.labelMedium,
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(_photoDateTime),
                              style: AppTypography.withColor(
                                AppTypography.titleLarge,
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // プロンプトが選択されている場合のみ表示
                if (!_isInitializing && _selectedPrompt != null)
                  _buildSelectedPromptDisplay(),
                if (!_isInitializing && _selectedPrompt != null)
                  const SizedBox(height: AppSpacing.lg),

                // 選択された写真のプレビュー
                if (widget.selectedAssets.isNotEmpty)
                  FadeInWidget(
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
                                '選択された写真 (${widget.selectedAssets.length}枚)',
                                style: AppTypography.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.selectedAssets.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right:
                                        index < widget.selectedAssets.length - 1
                                        ? AppSpacing.sm
                                        : 0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: AppSpacing.photoRadius,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: AppSpacing.photoRadius,
                                      child: FutureBuilder<Uint8List?>(
                                        future: widget.selectedAssets[index]
                                            .thumbnailDataWithSize(
                                              ThumbnailSize(
                                                (AppConstants.previewImageSize *
                                                        1.2)
                                                    .toInt(),
                                                (AppConstants.previewImageSize *
                                                        1.2)
                                                    .toInt(),
                                              ),
                                            ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.done &&
                                              snapshot.data != null) {
                                            return Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                borderRadius:
                                                    AppSpacing.photoRadius,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    AppSpacing.photoRadius,
                                                child: Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.contain,
                                                  width: 120,
                                                  height: 120,
                                                ),
                                              ),
                                            );
                                          }
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceVariant,
                                              borderRadius:
                                                  AppSpacing.photoRadius,
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ローディング表示（初期化中、日記生成中、または自動保存中）
                if (_isInitializing || _isLoading || _isSaving)
                  FadeInWidget(
                    child: CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: AppSpacing.cardPadding,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            if (_isAnalyzingPhotos && _totalPhotos > 1) ...[
                              Text(
                                '写真を分析中...',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '$_currentPhotoIndex/$_totalPhotos枚完了',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                width: double.infinity,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _totalPhotos > 0
                                      ? _currentPhotoIndex / _totalPhotos
                                      : 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (_isInitializing) ...[
                              Text(
                                'プロンプトサービスを初期化中...',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'プロンプト機能の準備をしています',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else if (_isSaving) ...[
                              Text(
                                '日記を保存中...',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '生成された日記を保存しています',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              Text(
                                '写真から日記を生成中...',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'AIがあなたの写真を分析しています',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_selectedPrompt != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PromptCategoryUtils.getCategoryColor(
                                      _selectedPrompt!.category,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.md,
                                    ),
                                    border: Border.all(
                                      color:
                                          PromptCategoryUtils.getCategoryColor(
                                            _selectedPrompt!.category,
                                          ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 16,
                                        color:
                                            PromptCategoryUtils.getCategoryColor(
                                              _selectedPrompt!.category,
                                            ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: Text(
                                          _selectedPrompt!.text.length > 30
                                              ? '${_selectedPrompt!.text.substring(0, 30)}...'
                                              : _selectedPrompt!.text,
                                          style: AppTypography.bodySmall.copyWith(
                                            color:
                                                PromptCategoryUtils.getCategoryColor(
                                                  _selectedPrompt!.category,
                                                ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                // エラー表示（初期化完了後のみ）
                else if (!_isInitializing && _hasError)
                  SizedBox(
                    height: 400,
                    child: FadeInWidget(
                      child: CustomCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              style: AppTypography.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.left,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
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
                // 日記編集フィールド（初期化完了後、日記生成完了後、自動保存前）
                else if (!_isInitializing &&
                    !_isLoading &&
                    !_isSaving &&
                    !_hasError)
                  SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: AppSpacing.iconMd,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '日記の内容',
                                  style: AppTypography.titleLarge,
                                ),
                              ),
                              if (_selectedPrompt != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PromptCategoryUtils.getCategoryColor(
                                      _selectedPrompt!.category,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.xs,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 12,
                                        color:
                                            PromptCategoryUtils.getCategoryColor(
                                              _selectedPrompt!.category,
                                            ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'プロンプト使用',
                                        style: AppTypography.labelSmall.copyWith(
                                          color:
                                              PromptCategoryUtils.getCategoryColor(
                                                _selectedPrompt!.category,
                                              ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
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
                              minLines: 12,
                              textAlignVertical: TextAlignVertical.top,
                              style: AppTypography.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: '本文',
                                hintText: '日記の内容を編集できます',
                                border: InputBorder.none,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                // 底部パディング（保存ボタン分の余白）
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        bottomNavigationBar: !_isLoading && !_isSaving && !_hasError
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
                  child: SlideInWidget(
                    delay: const Duration(milliseconds: 400),
                    begin: const Offset(0, 1),
                    child: PrimaryButton(
                      onPressed: _saveDiary,
                      text: '日記を保存',
                      icon: Icons.save_rounded,
                      width: double.infinity,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
