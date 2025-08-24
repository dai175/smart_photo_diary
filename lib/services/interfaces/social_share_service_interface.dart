import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../core/result/result.dart';

/// Instagram共有機能のサービスインターフェース
abstract class ISocialShareService {
  /// 日記をSNSに共有する
  ///
  /// [diary] 共有する日記エントリー
  /// [format] 共有フォーマット (Stories or Feed)
  /// [photos] 共有に使用する写真 (オプション)
  ///
  /// Returns: 共有処理の結果
  Future<Result<void>> shareToSocialMedia({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  });

  /// 共有用の画像を生成する
  ///
  /// [diary] 日記エントリー
  /// [format] 画像フォーマット
  /// [photos] 使用する写真
  ///
  /// Returns: 生成された画像ファイル
  Future<Result<File>> generateShareImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  });

  /// 共有可能なフォーマットの一覧を取得
  List<ShareFormat> getSupportedFormats();

  /// 指定されたフォーマットがサポートされているかチェック
  bool isFormatSupported(ShareFormat format);

  /// デバイスに適したフォーマットを取得
  ShareFormat getRecommendedFormat(ShareFormat baseFormat, {bool useHD = true});
}

/// 共有フォーマットの定義
enum ShareFormat {
  /// Instagram Stories用 (9:16)
  instagramStories(
    aspectRatio: 0.5625,
    width: 1080,
    height: 1920,
    displayName: 'Instagram Stories',
    scale: 2.0,
  ),

  /// Instagram Stories用 高解像度 (9:16)
  instagramStoriesHD(
    aspectRatio: 0.5625,
    width: 1350,
    height: 2400,
    displayName: 'Instagram Stories (HD)',
    scale: 2.5,
  );

  const ShareFormat({
    required this.aspectRatio,
    required this.width,
    required this.height,
    required this.displayName,
    required this.scale,
  });

  /// アスペクト比
  final double aspectRatio;

  /// 画像幅
  final int width;

  /// 画像高さ
  final int height;

  /// 表示名
  final String displayName;

  /// デバイス解像度スケール
  final double scale;

  /// Stories用かどうか
  bool get isStories =>
      this == ShareFormat.instagramStories ||
      this == ShareFormat.instagramStoriesHD;

  /// HD版かどうか
  bool get isHD => this == ShareFormat.instagramStoriesHD;

  /// スケールされた幅
  int get scaledWidth => (width * scale).round();

  /// スケールされた高さ
  int get scaledHeight => (height * scale).round();
}
