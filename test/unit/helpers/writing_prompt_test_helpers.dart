import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

/// テスト用の no-op ILoggingService 実装
class NoOpLogger implements ILoggingService {
  @override
  void info(String message, {String? context, dynamic data}) {}
  @override
  void warning(String message, {String? context, dynamic data}) {}
  @override
  void error(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {}
  @override
  void debug(String message, {String? context, dynamic data}) {}
  @override
  Stopwatch startTimer(String operation, {String? context}) =>
      Stopwatch()..start();
  @override
  void endTimer(Stopwatch stopwatch, String operation, {String? context}) {}
}

/// テスト用 WritingPrompt ファクトリ
WritingPrompt makeWritingPrompt({
  required String id,
  required PromptCategory category,
  bool isPremiumOnly = false,
  bool isActive = true,
  int priority = 50,
  String? text,
  List<String> tags = const [],
}) => WritingPrompt(
  id: id,
  text: text ?? 'Prompt $id',
  category: category,
  isPremiumOnly: isPremiumOnly,
  isActive: isActive,
  priority: priority,
  tags: tags,
);
