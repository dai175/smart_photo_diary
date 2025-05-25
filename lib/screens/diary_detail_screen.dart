import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';

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
  late TextEditingController _contentController;
  List<AssetEntity> _photoAssets = [];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _loadDiaryEntry();
  }

  @override
  void dispose() {
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
      final entry = diaryService.getDiaryEntryById(widget.diaryId);

      if (entry == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '日記が見つかりませんでした';
        });
        return;
      }

      // 写真アセットを取得
      final assets = await entry.getPhotoAssets();

      setState(() {
        _diaryEntry = entry;
        _contentController.text = entry.content;
        _photoAssets = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '日記の読み込みに失敗しました: $e';
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
          const SnackBar(content: Text('日記を更新しました')),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('日記の削除'),
        content: const Text('この日記を削除してもよろしいですか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
          const SnackBar(content: Text('日記を削除しました')),
        );

        // 前の画面に戻る
        navigator.pop();
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
        backgroundColor: const Color(0xFF6C4AB6),
        foregroundColor: Colors.white,
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
          ? const Center(child: Text('日記が見つかりませんでした'))
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C4AB6),
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
                        const ThumbnailSize(400, 400),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            snapshot.data!,
                            width: 200,
                            height: 200,
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

          // 日記の内容（編集モードによって表示を切り替え）
          _isEditing
              ? TextField(
                  controller: _contentController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '日記の内容を入力してください',
                  ),
                )
              : Text(
                  _diaryEntry!.content,
                  style: const TextStyle(fontSize: 16),
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
