/// AI関連の定数
class AiConstants {
  // Gemini API設定
  static const String geminiModelName = 'gemini-2.5-flash';
  static const double defaultTemperature = 0.7;
  static const int defaultMaxOutputTokens = 1000;
  static const double defaultTopP = 0.8;
  static const int defaultTopK = 10;
  static const double tagGenerationTemperature = 0.3;

  // 時間帯判定
  static const int morningStartHour = 5;
  static const int afternoonStartHour = 12;
  static const int eveningStartHour = 18;
  static const int nightStartHour = 22;
}
