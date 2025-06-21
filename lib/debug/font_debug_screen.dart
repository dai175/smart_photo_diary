import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// フォントデバッグ用の画面
class FontDebugScreen extends StatefulWidget {
  const FontDebugScreen({super.key});

  @override
  State<FontDebugScreen> createState() => _FontDebugScreenState();
}

class _FontDebugScreenState extends State<FontDebugScreen> {
  List<String> systemFonts = [];

  @override
  void initState() {
    super.initState();
    _loadSystemFonts();
  }

  Future<void> _loadSystemFonts() async {
    try {
      // システムフォント一覧を取得
      final fontList = await rootBundle.loadString('FontManifest.json');
      debugPrint('System fonts: $fontList');
    } catch (e) {
      debugPrint('Error loading fonts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォントデバッグ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFontTest(
              'Theme.headlineSmall',
              Theme.of(context).textTheme.headlineSmall,
            ),
            _buildFontTest(
              'Theme.titleLarge',
              Theme.of(context).textTheme.titleLarge,
            ),
            _buildFontTest(
              'Theme.bodyLarge',
              Theme.of(context).textTheme.bodyLarge,
            ),
            _buildFontTest(
              'Theme.labelLarge',
              Theme.of(context).textTheme.labelLarge,
            ),

            const Divider(height: 40),

            _buildManualFontTest('Sans-serif', 'sans-serif'),
            _buildManualFontTest('Android Default', null),
            _buildManualFontTest('Roboto', 'Roboto'),
            _buildManualFontTest('Default (null)', null),

            const Divider(height: 40),

            const Text(
              'テストテキスト（サイズ別）:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildSizeTest('最適化', 12),
            _buildSizeTest('最適化', 16),
            _buildSizeTest('最適化', 20),
            _buildSizeTest('最適化', 24),
            _buildSizeTest('最適化', 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFontTest(String label, TextStyle? style) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '最適化テスト - fontFamily: ${style?.fontFamily ?? "null"}, fontSize: ${style?.fontSize ?? "null"}',
            style: style,
          ),
          Text(
            'Font info: ${style?.fontFamily} / ${style?.fontSize}sp',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildManualFontTest(String label, String? fontFamily) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '最適化テスト - Manual font: $fontFamily',
            style: TextStyle(fontFamily: fontFamily, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeTest(String text, double size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${size}sp:', style: const TextStyle(fontSize: 10)),
          ),
          Text(
            text,
            style: TextStyle(
              // fontFamily: 'NotoSansCJK', // Androidデフォルトフォントを使用
              fontSize: size,
            ),
          ),
          const SizedBox(width: 20),
          Text(text, style: TextStyle(fontSize: size)),
        ],
      ),
    );
  }
}
