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
}

/// 共有フォーマットの定義
enum ShareFormat {
  /// Instagram Stories用 (9:16)
  instagramStories(
    aspectRatio: 0.5625,
    width: 1080,
    height: 1920,
    displayName: 'Instagram Stories',
  ),

  /// Instagram Feed用 (1:1)
  instagramFeed(
    aspectRatio: 1.0,
    width: 1080,
    height: 1080,
    displayName: 'Instagram Feed',
  );

  const ShareFormat({
    required this.aspectRatio,
    required this.width,
    required this.height,
    required this.displayName,
  });

  /// アスペクト比
  final double aspectRatio;

  /// 画像幅
  final int width;

  /// 画像高さ
  final int height;

  /// 表示名
  final String displayName;

  /// Stories用かどうか
  bool get isStories => this == ShareFormat.instagramStories;

  /// Feed用かどうか
  bool get isFeed => this == ShareFormat.instagramFeed;
}
