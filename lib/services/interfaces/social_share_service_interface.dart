import 'dart:io';
import 'dart:ui';

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
  /// Returns:
  /// - Success: 共有処理が正常に完了
  /// - Failure: [SocialShareException] 画像生成失敗、共有先アプリ未インストール、またはシステムエラー時
  Future<Result<void>> shareToSocialMedia({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  });

  /// X（旧Twitter）に共有する（画像とテキストを別々に渡す）
  /// - 画像: 元の写真 最大3枚
  /// - テキスト: タイトル+本文+アプリ名（XShareTextBuilderで整形）
  ///
  /// Returns:
  /// - Success: X共有処理が正常に完了
  /// - Failure: [SocialShareException] 写真読み込み失敗、共有先アプリ未インストール、またはシステムエラー時
  Future<Result<void>> shareToX({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  });

  /// 共有用の画像を生成する
  ///
  /// [diary] 日記エントリー
  /// [format] 画像フォーマット
  /// [photos] 使用する写真
  ///
  /// Returns:
  /// - Success: 生成された画像ファイル
  /// - Failure: [SocialShareException] 写真読み込み失敗、画像レンダリングエラー、またはファイル書き込みエラー時
  Future<Result<File>> generateShareImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  });

  /// 共有可能なフォーマットの一覧を取得
  ///
  /// 戻り値: サポートされている全 [ShareFormat] のリスト。
  List<ShareFormat> getSupportedFormats();

  /// 指定されたフォーマットがサポートされているかチェック
  ///
  /// 戻り値: サポートされていれば true、そうでなければ false。
  bool isFormatSupported(ShareFormat format);

  /// デバイスに適したフォーマットを取得
  ///
  /// [baseFormat] ベースとなるフォーマット
  /// [useHD] HD版を優先するかどうか
  /// 戻り値: デバイスに最適な [ShareFormat]。
  ShareFormat getRecommendedFormat(ShareFormat baseFormat, {bool useHD = true});
}

/// 共有フォーマットの定義
enum ShareFormat {
  /// 縦長フォーマット (9:16)
  portrait(
    aspectRatio: 0.5625,
    width: 1080,
    height: 1920,
    displayName: '縦長',
    scale: 2.0,
  ),

  /// 縦長フォーマット 高解像度 (9:16)
  portraitHD(
    aspectRatio: 0.5625,
    width: 1350,
    height: 2400,
    displayName: '縦長 (HD)',
    scale: 2.5,
  ),

  /// 正方形フォーマット (1:1)
  square(
    aspectRatio: 1.0,
    width: 1080,
    height: 1080,
    displayName: '正方形',
    scale: 2.0,
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

  /// 縦長フォーマットかどうか
  bool get isPortrait =>
      this == ShareFormat.portrait || this == ShareFormat.portraitHD;

  /// 正方形フォーマットかどうか
  bool get isSquare => this == ShareFormat.square;

  /// HD版かどうか
  bool get isHD => this == ShareFormat.portraitHD;

  /// スケールされた幅
  int get scaledWidth => (width * scale).round();

  /// スケールされた高さ
  int get scaledHeight => (height * scale).round();
}
