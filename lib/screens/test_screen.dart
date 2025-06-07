import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/image_classifier_service.dart';
import '../services/ai_service.dart';
import 'package:intl/intl.dart';

/// 画像分析とAI日記生成のテスト用画面
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final ImageClassifierService _imageClassifier = ImageClassifierService();
  final AiService _aiService = AiService();

  File? _selectedImage;
  List<String> _detectedLabels = [];
  String _generatedDiary = '';
  bool _isProcessing = false;
  bool _isGeneratingDiary = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _imageClassifier.loadModel();
      debugPrint('モデルのロードが完了しました');
    } catch (e) {
      debugPrint('モデルロードエラー: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _detectedLabels = [];
        _generatedDiary = '';
      });

      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 画像ファイルをバイトデータに変換
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();

      // 画像を分析してラベルを取得
      final labels = await _imageClassifier.classifyImage(imageBytes);

      debugPrint('検出されたラベル: $labels');

      setState(() {
        _detectedLabels = labels;
        _isProcessing = false;
      });

      // ラベルが検出されたら日記を生成
      if (labels.isNotEmpty) {
        _generateDiary(labels);
      }
    } catch (e) {
      debugPrint('画像分析エラー: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _generateDiary(List<String> labels) async {
    setState(() {
      _isGeneratingDiary = true;
    });

    try {
      // 現在の日時を使用
      final now = DateTime.now();

      // 日記を生成
      final result = await _aiService.generateDiaryFromLabels(
        labels: labels,
        date: now,
        location: '自宅', // テスト用に固定値
      );

      final diary = '【${result.title}】\n${result.content}';
      debugPrint('生成された日記: $diary');

      setState(() {
        _generatedDiary = diary;
        _isGeneratingDiary = false;
      });
    } catch (e) {
      debugPrint('日記生成エラー: $e');
      setState(() {
        _isGeneratingDiary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像分析テスト'),
        backgroundColor: Colors.purple.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('画像を選択'),
            ),
            const SizedBox(height: 20),

            // 選択された画像の表示
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 処理中の表示
            if (_isProcessing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('画像を分析中...'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 検出されたラベルの表示（デバッグ用）
            if (_detectedLabels.isNotEmpty) ...[
              const Text(
                '検出されたラベル（デバッグ用）:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _detectedLabels.map((label) {
                  return Chip(
                    label: Text(label),
                    backgroundColor: Colors.purple.shade50,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // 日記生成中の表示
            if (_isGeneratingDiary) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('日記を生成中...'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 生成された日記の表示
            if (_generatedDiary.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_generatedDiary),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _imageClassifier.dispose();
    super.dispose();
  }
}
