import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../constants/app_constants.dart';
import '../utils/dialog_utils.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;

  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
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
      final diaryService = await DiaryService.getInstance();

      // 日記エントリーを取得
      final entry = await diaryService.getDiaryEntryById(widget.diaryId);

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
      final diaryService = await DiaryService.getInstance();

      // 日記を更新
      await diaryService.updateDiaryEntry(
        id: _diaryEntry!.id,
        title: _titleController.text,
        content: _contentController.text,
      );

      // 日記エントリーを再読み込み
      await _loadDiaryEntry();

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        // 更新成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(AppConstants.diaryUpdateSuccessMessage)),
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
      final diaryService = await DiaryService.getInstance();

      // 日記を削除
      await diaryService.deleteDiaryEntry(_diaryEntry!.id);

      if (mounted) {
        // 削除成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(AppConstants.diaryDeleteSuccessMessage)),
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
      appBar: AppBar(
        title: const Text('日記の詳細'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // 編集モード切替ボタン
          if (!_isLoading && !_hasError && _diaryEntry != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  // 編集モードを終了して保存
                  _updateDiary();
                } else {
                  // 編集モードに切り替え
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
          // 削除ボタン
          if (!_isLoading && !_hasError && _diaryEntry != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteDiary),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(child: Text('エラー: $_errorMessage'))
          : _diaryEntry == null
          ? Center(child: Text(AppConstants.diaryNotFoundMessage))
          : _buildDiaryDetail(),
    );
  }

  Widget _buildDiaryDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付表示
          Text(
            DateFormat('yyyy年MM月dd日').format(_diaryEntry!.date),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // 写真があれば表示
          if (_photoAssets.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photoAssets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == _photoAssets.length - 1 ? 0 : 8,
                    ),
                    child: FutureBuilder<Uint8List?>(
                      future: _photoAssets[index].thumbnailDataWithSize(
                        ThumbnailSize(
                          AppConstants.largeImageSize.toInt(),
                          AppConstants.largeImageSize.toInt(),
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(
                            width: AppConstants.detailImageSize,
                            height: AppConstants.detailImageSize,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            snapshot.data!,
                            width: AppConstants.detailImageSize,
                            height: AppConstants.detailImageSize,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 日記のタイトルと内容（編集モードによって表示を切り替え）
          _isEditing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'タイトル',
                        hintText: '日記のタイトルを入力してください',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '本文',
                        hintText: '日記の内容を入力してください',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _diaryEntry!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _diaryEntry!.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

          const SizedBox(height: 16),

          // メタデータ表示
          Text(
            '作成日時: ${DateFormat('yyyy/MM/dd HH:mm').format(_diaryEntry!.createdAt)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            '更新日時: ${DateFormat('yyyy/MM/dd HH:mm').format(_diaryEntry!.updatedAt)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
