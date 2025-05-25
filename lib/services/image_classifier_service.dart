import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

/// TensorFlow Liteを使用して画像分類を行うサービスクラス
class ImageClassifierService {
  static const String _modelPath =
      'assets/models/mobilenet_v2_1.0_224_quant.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';

  // 入力画像サイズ
  static const int _inputSize = 224;

  // モデルとラベルのキャッシュ
  Interpreter? _interpreter;
  List<String>? _labels;

  /// モデルとラベルをロード
  Future<void> loadModel() async {
    try {
      // モデルのロード
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: interpreterOptions,
      );

      // ラベルのロード
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n');

      debugPrint('モデルとラベルのロードが完了しました');
      debugPrint('入力テンソル: ${_interpreter!.getInputTensors().first.shape}');
      debugPrint('出力テンソル: ${_interpreter!.getOutputTensors().first.shape}');
      debugPrint('ラベル数: ${_labels!.length}');
    } catch (e) {
      debugPrint('モデルロードエラー: $e');
      rethrow;
    }
  }

  /// AssetEntityから画像を分類し、ラベルを取得
  Future<List<String>> classifyAsset(
    AssetEntity asset, {
    int maxResults = 5,
  }) async {
    try {
      // AssetEntityからサムネイルを取得
      final Uint8List? thumbnail = await asset.thumbnailDataWithSize(
        const ThumbnailSize(_inputSize, _inputSize),
      );

      if (thumbnail == null) {
        debugPrint('サムネイルの取得に失敗しました');
        return [];
      }

      return classifyImage(thumbnail, maxResults: maxResults);
    } catch (e) {
      debugPrint('画像分類エラー: $e');
      return [];
    }
  }

  /// 画像データを分類し、ラベルを取得
  Future<List<String>> classifyImage(
    Uint8List imageData, {
    int maxResults = 5,
  }) async {
    try {
      // モデルが読み込まれていない場合は読み込む
      if (_interpreter == null || _labels == null) {
        await loadModel();
      }

      // 画像の前処理
      final processedImage = _preProcessImage(imageData);

      // 推論実行
      final outputShape = _interpreter!.getOutputTensors().first.shape;

      // 出力バッファの作成
      final outputBuffer = List<int>.filled(outputShape[0], 0);

      // 推論実行
      final inputs = [processedImage];
      final outputs = {0: outputBuffer};
      _interpreter!.runForMultipleInputs(inputs, outputs);

      // 結果の処理
      final resultList = outputBuffer;

      // 確率の高い順にインデックスを取得
      final List<MapEntry<int, int>> indexed = [];
      for (int i = 0; i < resultList.length; i++) {
        indexed.add(MapEntry(i, resultList[i]));
      }

      // 確率の高い順にソート
      indexed.sort((a, b) => b.value.compareTo(a.value));

      // 上位のラベルを取得
      final List<String> topLabels = [];
      for (int i = 0; i < maxResults && i < indexed.length; i++) {
        final labelIndex = indexed[i].key;
        if (labelIndex < _labels!.length) {
          topLabels.add(_labels![labelIndex]);
        }
      }

      return topLabels;
    } catch (e) {
      debugPrint('画像分類エラー: $e');
      return [];
    }
  }

  /// 画像の前処理
  Uint8List _preProcessImage(Uint8List imageData) {
    // imageライブラリを使用して画像をデコード
    final originalImage = img.decodeImage(imageData);
    if (originalImage == null) {
      throw Exception('画像のデコードに失敗しました');
    }

    // リサイズ
    final resizedImage = img.copyResize(
      originalImage,
      width: _inputSize,
      height: _inputSize,
    );

    // 量子化モデル用に画像データを準備
    final buffer = Uint8List(_inputSize * _inputSize * 3);
    int pixelIndex = 0;

    // image 4.x パッケージでは、getPixelはimg.Pixelオブジェクトを返す
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        // 最新のimageパッケージでは、getPixelはimg.Pixelオブジェクトを返す
        final pixel = resizedImage.getPixel(x, y);

        // img.Pixelから直接RGB成分を取得
        buffer[pixelIndex++] = pixel.r.toInt();
        buffer[pixelIndex++] = pixel.g.toInt();
        buffer[pixelIndex++] = pixel.b.toInt();
      }
    }

    return buffer;
  }

  /// リソースの解放
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
