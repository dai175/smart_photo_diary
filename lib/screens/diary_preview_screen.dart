import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/image_classifier_service.dart';
import '../services/ai_service.dart';
import '../services/diary_service.dart';
import '../services/settings_service.dart';
import '../services/photo_service.dart';
import '../constants/app_constants.dart';

/// 生成された日記のプレビュー画面
class DiaryPreviewScreen extends StatefulWidget {
  /// 選択された写真アセット
  final List<AssetEntity> selectedAssets;

  const DiaryPreviewScreen({super.key, required this.selectedAssets});

  @override
  State<DiaryPreviewScreen> createState() => _DiaryPreviewScreenState();
}

class _DiaryPreviewScreenState extends State<DiaryPreviewScreen> {
  final ImageClassifierService _imageClassifier = ImageClassifierService();
  final AiService _aiService = AiService();

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
          final imageData = await PhotoService.getOriginalFile(firstAsset);
          
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
            final imageData = await PhotoService.getOriginalFile(asset);
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
      final diaryService = await DiaryService.getInstance();

      // 日記を保存
      await diaryService.saveDiaryEntry(
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
        backgroundColor: Colors.purple.shade100,
        actions: [
          // 保存ボタン
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveDiary,
              tooltip: '日記を保存',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日付表示
            Text(
              DateFormat('yyyy年MM月dd日').format(_photoDateTime),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),

            // 選択された写真のプレビュー
            if (widget.selectedAssets.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.selectedAssets.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List?>(
                          future: widget.selectedAssets[index]
                              .thumbnailDataWithSize(
                                ThumbnailSize(
                                  AppConstants.previewImageSize.toInt(),
                                  AppConstants.previewImageSize.toInt(),
                                ),
                              ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              );
                            }
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // ローディング表示
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      if (_isAnalyzingPhotos && _totalPhotos > 1) ...[
                        Text('写真を分析中... $_currentPhotoIndex/$_totalPhotos枚'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _totalPhotos > 0 ? _currentPhotoIndex / _totalPhotos : 0,
                        ),
                      ] else
                        const Text('写真から日記を生成中...'),
                    ],
                  ),
                ),
              )
            // エラー表示
            else if (_hasError)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('戻る'),
                      ),
                    ],
                  ),
                ),
              )
            // 日記編集フィールド
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '日記の内容',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
                        border: OutlineInputBorder(),
                        hintText: '日記のタイトルを入力',
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: '本文',
                          hintText: '日記の内容を編集できます',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: !_isLoading && !_hasError
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ElevatedButton(
                  onPressed: _saveDiary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('日記を保存'),
                ),
              ),
            )
          : null,
    );
  }
}
