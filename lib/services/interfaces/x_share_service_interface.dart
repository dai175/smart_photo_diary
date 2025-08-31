import 'package:photo_manager/photo_manager.dart';
import '../../core/result/result.dart';
import '../../models/diary_entry.dart';

/// X（旧Twitter）共有用サービスのインターフェース
abstract class IXShareService {
  /// 日記をX向けに共有する（システム共有シート経由）
  /// - 画像: 最大3枚（元画像）
  /// - テキスト: タイトル/本文/アプリ名（`XShareTextBuilder`で生成）
  Future<Result<void>> shareToX({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
  });
}
