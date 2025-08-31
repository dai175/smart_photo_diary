import 'package:characters/characters.dart';
import '../constants/app_constants.dart';

/// X（旧Twitter）向けの共有テキストを構築するビルダー。
/// 仕様:
/// - 構成: タイトル → 空行 → 本文 → 空行 → アプリ名
/// - 全体280文字以内。超える場合は本文を優先してトリム、必要ならタイトルもトリム。
/// - トリムが発生した要素にのみ末尾に「...」を付与。
class XShareTextBuilder {
  static const int _limit = 280;

  /// 共有テキストを生成する。
  /// [title] タイトル（省略可）
  /// [body] 本文
  /// [appName] 末尾に表示するアプリ名（既定: AppConstants.appTitle）
  static String build({
    String? title,
    required String body,
    String appName = AppConstants.appTitle,
  }) {
    String safeTitle = (title ?? '').trim();
    String safeBody = body.trim();

    String compose() {
      final segments = <String>[];
      if (safeTitle.isNotEmpty) segments.add(safeTitle);
      if (safeTitle.isNotEmpty && safeBody.isNotEmpty) segments.add('');
      if (safeBody.isNotEmpty) segments.add(safeBody);
      if ((safeTitle.isNotEmpty || safeBody.isNotEmpty)) segments.add('');
      segments.add(appName);
      return segments.join('\n');
    }

    String text = compose();
    if (_graphemeLength(text) <= _limit) return text;

    // 超過分を算出して、本文だけで収まるなら本文を優先して削る。
    // 本文だけでは収まらない場合はタイトルを削る（本文は保持）。
    int over = _graphemeLength(text) - _limit;
    final bodyLen = _graphemeLength(safeBody);
    if (safeBody.isNotEmpty && over < bodyLen) {
      safeBody = _truncateByDelta(safeBody, over);
    } else if (safeTitle.isNotEmpty) {
      safeTitle = _truncateByDelta(safeTitle, over);
    } else if (safeBody.isNotEmpty) {
      // タイトルが空で本文のみの場合は本文を削る
      safeBody = _truncateByDelta(safeBody, over);
    }

    text = compose();
    if (_graphemeLength(text) <= _limit) return text;

    // まだ超える場合は、残りをタイトル→本文の順でさらに削る
    over = _graphemeLength(text) - _limit;
    if (safeTitle.isNotEmpty) {
      safeTitle = _truncateByDelta(safeTitle, over);
    } else if (safeBody.isNotEmpty) {
      safeBody = _truncateByDelta(safeBody, over);
    }

    return compose();
  }

  static int _graphemeLength(String s) => s.characters.length;

  // 旧ロジックで使っていた補助は不要になったため削除

  /// 現在長からdelta分だけ短くする（末尾に...）
  static String _truncateByDelta(String input, int delta) {
    final len = _graphemeLength(input);
    final target = (len - delta).clamp(0, len);
    return _truncateWithEllipsis(input, target);
  }

  /// グラフェム単位でmaxLen以内に切り詰め。切り詰め時は末尾に...
  static String _truncateWithEllipsis(String input, int maxLen) {
    final chars = input.characters;
    final len = chars.length;
    if (len <= maxLen) return input;
    // 末尾に"..."を付ける分を確保
    final ellipsis = '...';
    final int safe = (maxLen - ellipsis.characters.length)
        .clamp(0, maxLen)
        .toInt();
    final truncated = chars.take(safe).toString();
    return '$truncated$ellipsis';
  }
}
