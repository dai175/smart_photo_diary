import 'dart:ui';
import '../interfaces/ai_service_interface.dart';
import '../interfaces/logging_service_interface.dart';
import 'diary_locale_utils.dart';

/// AIレスポンステキストを日記の title/content に分割する責務
class DiaryResponseParser {
  static final _titleRegexJa = RegExp(
    r'【タイトル】\s*(.+?)(?=【本文】|$)',
    dotAll: true,
  );
  static final _contentRegexJa = RegExp(r'【本文】\s*(.+?)$', dotAll: true);
  static final _titleRegexEn = RegExp(
    r'\[Title\]\s*(.+?)(?=\[Body\]|$)',
    dotAll: true,
    caseSensitive: false,
  );
  static final _contentRegexEn = RegExp(
    r'\[Body\]\s*(.+?)$',
    dotAll: true,
    caseSensitive: false,
  );

  final ILoggingService _logger;

  DiaryResponseParser({required ILoggingService logger}) : _logger = logger;

  DiaryGenerationResult parse(String generatedText, Locale locale) {
    final defaultTitle = DiaryLocaleUtils.isJapanese(locale)
        ? '今日の日記'
        : "Today's Journal";
    try {
      String? title = _titleRegexJa.firstMatch(generatedText)?.group(1)?.trim();
      String? content = _contentRegexJa
          .firstMatch(generatedText)
          ?.group(1)
          ?.trim();

      if (title == null ||
          title.isEmpty ||
          content == null ||
          content.isEmpty) {
        title =
            _titleRegexEn.firstMatch(generatedText)?.group(1)?.trim() ?? title;
        content =
            _contentRegexEn.firstMatch(generatedText)?.group(1)?.trim() ??
            content;
      }

      if (title == null ||
          title.isEmpty ||
          content == null ||
          content.isEmpty) {
        final lines = generatedText
            .split('\n')
            .where((line) => line.trim().isNotEmpty);
        if (lines.isNotEmpty) {
          title = lines.first.trim();
          content = lines.skip(1).join('\n').trim();
        }
      }

      return DiaryGenerationResult(
        title: (title == null || title.isEmpty) ? defaultTitle : title,
        content: (content == null || content.isEmpty)
            ? generatedText.trim()
            : content,
      );
    } catch (e) {
      _logger.error(
        'Error during diary parsing',
        context: 'DiaryResponseParser.parse',
        error: e,
      );
      return DiaryGenerationResult(
        title: defaultTitle,
        content: generatedText.trim(),
      );
    }
  }
}
