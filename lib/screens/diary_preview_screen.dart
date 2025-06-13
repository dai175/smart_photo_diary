import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/image_classifier_service.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/settings_service.dart';
import '../core/service_registration.dart';
import '../constants/app_constants.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';

/// 生成された日記のプレビュー画面
class DiaryPreviewScreen extends StatefulWidget {
  /// 選択された写真アセット
  final List<AssetEntity> selectedAssets;

  const DiaryPreviewScreen({super.key, required this.selectedAssets});

  @override
  State<DiaryPreviewScreen> createState() => _DiaryPreviewScreenState();
}

class _DiaryPreviewScreenState extends State<DiaryPreviewScreen> {
  late final ImageClassifierService _imageClassifier;
  late final AiServiceInterface _aiService;
  late final PhotoServiceInterface _photoService;

  bool _isLoading = true;
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    
    // サービスロケータからサービスを取得
    _imageClassifier = ServiceRegistration.get<ImageClassifierService>();
    _aiService = ServiceRegistration.get<AiServiceInterface>();
    _photoService = ServiceRegistration.get<PhotoServiceInterface>();
    
    _loadModelAndGenerateDiary();
  }

  @override
  void dispose() {
    _imageClassifier.dispose();
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

    try {
      // 設定サービスから生成モードを取得
      final settingsService = await SettingsService.getInstance();
      final generationMode = settingsService.generationMode;

      debugPrint('使用する生成モード: ${generationMode.name}');

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

      debugPrint('写真の撮影日時: $photoDateTime');

      DiaryGenerationResult result;

      if (generationMode == DiaryGenerationMode.vision) {
        // Vision API方式：画像を直接Geminiに送信
        debugPrint('Vision API方式で日記生成中...');
        
        if (widget.selectedAssets.length == 1) {
          // 単一写真の場合：従来通り
          final firstAsset = widget.selectedAssets.first;
          final imageData = await _photoService.getOriginalFile(firstAsset);
          
          if (imageData == null) {
            throw Exception('写真データの取得に失敗しました');
          }

          result = await _aiService.generateDiaryFromImage(
            imageData: imageData,
            date: photoDateTime,
          );
        } else {
          // 複数写真の場合：新しい順次処理方式を使用
          debugPrint('複数写真の順次分析を開始...');
          
          // 全ての写真データを収集
          final List<({Uint8List imageData, DateTime time})> imagesWithTimes = [];
          
          for (final asset in widget.selectedAssets) {
            final imageData = await _photoService.getOriginalFile(asset);
            if (imageData != null) {
              imagesWithTimes.add((imageData: imageData, time: asset.createDateTime));
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

          result = await _aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: imagesWithTimes,
            onProgress: (current, total) {
              debugPrint('画像分析進捗: $current/$total');
              setState(() {
                _currentPhotoIndex = current;
                _totalPhotos = total;
              });
            },
          );
          
          // 進捗表示を終了
          setState(() {
            _isAnalyzingPhotos = false;
          });
        }
      } else {
        // ラベル抽出方式：従来の方法
        debugPrint('ラベル抽出方式で日記生成中...');
        
        // モデルのロード
        await _imageClassifier.loadModel();

        // 各写真からラベルを抽出し、時刻とペアにする
        final List<PhotoTimeLabel> photoTimeLabels = [];
        final List<String> allLabels = [];
        
        for (final asset in widget.selectedAssets) {
          final labels = await _imageClassifier.classifyAsset(asset);
          allLabels.addAll(labels);
          
          // 写真ごとの時刻とラベルのペアを作成
          if (labels.isNotEmpty) {
            photoTimeLabels.add(PhotoTimeLabel(
              time: asset.createDateTime,
              labels: labels,
            ));
          }
        }

        // 重複を削除（全体のラベル）
        final uniqueLabels = allLabels.toSet().toList();

        debugPrint('検出されたラベル: $uniqueLabels');
        debugPrint('写真ごとの時刻とラベル: ${photoTimeLabels.map((p) => '${p.time}: ${p.labels}').join(', ')}');

        if (uniqueLabels.isEmpty) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '写真から特徴を検出できませんでした';
          });
          return;
        }

        // 日記を生成（写真ごとの時刻とラベル情報を使用）
        result = await _aiService.generateDiaryFromLabels(
          labels: uniqueLabels,
          date: photoDateTime,
          photoTimes: photoTimes,
          photoTimeLabels: photoTimeLabels,
        );
      }

      setState(() {
        _titleController.text = result.title;
        _contentController.text = result.content;
        _isLoading = false;
        // 写真の撮影日時を保存
        _photoDateTime = photoDateTime;
      });
    } catch (e) {
      debugPrint('日記生成エラー: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '日記の生成中にエラーが発生しました: $e';
      });
    }
  }

  /// 日記を保存する
  Future<void> _saveDiary() async {
    // BuildContextを保存
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('日記保存開始...');
      debugPrint('タイトル: ${_titleController.text}');
      debugPrint('本文: ${_contentController.text}');
      debugPrint('写真数: ${widget.selectedAssets.length}');

      // DiaryServiceのインスタンスを取得
      final diaryService = await ServiceRegistration.getAsync<DiaryServiceInterface>();

      // 日記を保存
      await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: _titleController.text,
        content: _contentController.text,
        photos: widget.selectedAssets,
      );

      debugPrint('日記保存成功');

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
      debugPrint('日記保存失敗: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '日記の保存に失敗しました: $e';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日記プレビュー'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        actions: [
          // 保存ボタン
          if (!_isLoading && !_hasError)
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
                      Column(
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
                            DateFormat('yyyy年MM月dd日').format(_photoDateTime),
                            style: AppTypography.withColor(
                              AppTypography.titleLarge,
                              AppColors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
                              color: AppColors.primary,
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
                                  right: index < widget.selectedAssets.length - 1 ? AppSpacing.sm : 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: AppSpacing.photoRadius,
                                    boxShadow: AppSpacing.cardShadow,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: AppSpacing.photoRadius,
                                    child: FutureBuilder<Uint8List?>(
                                      future: widget.selectedAssets[index]
                                          .thumbnailDataWithSize(
                                            ThumbnailSize(
                                              (AppConstants.previewImageSize * 1.2).toInt(),
                                              (AppConstants.previewImageSize * 1.2).toInt(),
                                            ),
                                          ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.data != null) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                          );
                                        }
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: AppSpacing.photoRadius,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
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

              // ローディング表示
              if (_isLoading)
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
                              color: AppColors.primaryContainer.withValues(alpha: 0.3),
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                widthFactor: _totalPhotos > 0 ? _currentPhotoIndex / _totalPhotos : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              // エラー表示
              else if (_hasError)
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
                            textAlign: TextAlign.center,
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
              // 日記編集フィールド
              else
                SizedBox(
                  height: 400,
                  child: SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: AppColors.primary,
                                size: AppSpacing.iconMd,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '日記の内容',
                                style: AppTypography.titleLarge,
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Flexible(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.outline.withValues(alpha: 0.2),
                                ),
                                borderRadius: AppSpacing.inputRadius,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: TextField(
                                controller: _contentController,
                                maxLines: 8,
                                minLines: 8,
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
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // 底部パディング（キーボード用の余白）
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !_isLoading && !_hasError
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
    );
  }
}
