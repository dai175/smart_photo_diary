import 'dart:ui';
import '../../models/diary_length.dart';
import 'diary_locale_utils.dart';

/// プロンプト種別分析とAI生成パラメータ最適化を担当
class DiaryPromptAnalyzer {
  DiaryPromptAnalyzer._();

  // ── Max token constants per prompt type ──

  // Standard max tokens: {ja, en}
  static const int emotionTokensJaStandard = 300;
  static const int emotionTokensEnStandard = 360;
  static const int growthTokensJaStandard = 320;
  static const int growthTokensEnStandard = 380;
  static const int connectionTokensJaStandard = 310;
  static const int connectionTokensEnStandard = 370;
  static const int healingTokensJaStandard = 290;
  static const int healingTokensEnStandard = 360;

  // Short max tokens: {ja, en}
  static const int emotionTokensJaShort = 115;
  static const int emotionTokensEnShort = 145;
  static const int growthTokensJaShort = 125;
  static const int growthTokensEnShort = 155;
  static const int connectionTokensJaShort = 120;
  static const int connectionTokensEnShort = 150;
  static const int healingTokensJaShort = 110;
  static const int healingTokensEnShort = 140;

  // Additional tokens for multi-image generation
  static const int multiImageExtraTokensJaStandard = 50;
  static const int multiImageExtraTokensEnStandard = 60;
  static const int multiImageExtraTokensJaShort = 15;
  static const int multiImageExtraTokensEnShort = 20;

  /// プロンプト種別を分析
  static String analyzePromptType(String? prompt) {
    if (prompt == null || prompt.trim().isEmpty) {
      return 'emotion';
    }

    final lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.contains('感情') ||
        lowerPrompt.contains('気持ち') ||
        lowerPrompt.contains('感じ') ||
        lowerPrompt.contains('心') ||
        lowerPrompt.contains('emotion') ||
        lowerPrompt.contains('feeling') ||
        lowerPrompt.contains('feelings') ||
        lowerPrompt.contains('heart')) {
      return 'emotion';
    }

    if (lowerPrompt.contains('成長') ||
        lowerPrompt.contains('変化') ||
        lowerPrompt.contains('発見') ||
        lowerPrompt.contains('気づき') ||
        lowerPrompt.contains('growth') ||
        lowerPrompt.contains('change') ||
        lowerPrompt.contains('learning') ||
        lowerPrompt.contains('discovery')) {
      return 'growth';
    }

    if (lowerPrompt.contains('つながり') ||
        lowerPrompt.contains('人') ||
        lowerPrompt.contains('関係') ||
        lowerPrompt.contains('connection') ||
        lowerPrompt.contains('relationship') ||
        lowerPrompt.contains('together') ||
        lowerPrompt.contains('community')) {
      return 'connection';
    }

    if (lowerPrompt.contains('癒し') ||
        lowerPrompt.contains('平和') ||
        lowerPrompt.contains('安らぎ') ||
        lowerPrompt.contains('healing') ||
        lowerPrompt.contains('calm') ||
        lowerPrompt.contains('peace') ||
        lowerPrompt.contains('restful')) {
      return 'healing';
    }

    return 'emotion';
  }

  /// プロンプト種別に応じた最適化パラメータを取得
  static ({int maxTokens, String emphasis}) getOptimizationParams(
    String promptType,
    Locale locale, {
    DiaryLength diaryLength = DiaryLength.standard,
  }) {
    final isJapanese = DiaryLocaleUtils.isJapanese(locale);
    final isShort = diaryLength == DiaryLength.short;
    switch (promptType) {
      case 'growth':
        return (
          maxTokens: isJapanese
              ? (isShort ? growthTokensJaShort : growthTokensJaStandard)
              : (isShort ? growthTokensEnShort : growthTokensEnStandard),
          emphasis: isJapanese
              ? '成長と変化に焦点を当てて'
              : 'highlights personal growth and change',
        );
      case 'connection':
        return (
          maxTokens: isJapanese
              ? (isShort ? connectionTokensJaShort : connectionTokensJaStandard)
              : (isShort
                    ? connectionTokensEnShort
                    : connectionTokensEnStandard),
          emphasis: isJapanese
              ? '人とのつながりや関係性を重視して'
              : 'emphasises meaningful relationships and connection',
        );
      case 'healing':
        return (
          maxTokens: isJapanese
              ? (isShort ? healingTokensJaShort : healingTokensJaStandard)
              : (isShort ? healingTokensEnShort : healingTokensEnStandard),
          emphasis: isJapanese
              ? '穏やかで心安らぐ文体で'
              : 'feels calm, gentle, and restorative',
        );
      case 'emotion':
      default:
        return (
          maxTokens: isJapanese
              ? (isShort ? emotionTokensJaShort : emotionTokensJaStandard)
              : (isShort ? emotionTokensEnShort : emotionTokensEnStandard),
          emphasis: isJapanese
              ? '感情の深みを大切にして'
              : 'captures emotional depth and nuance',
        );
    }
  }
}
