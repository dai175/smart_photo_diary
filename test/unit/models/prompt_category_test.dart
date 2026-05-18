import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/prompt_category.dart';

void main() {
  group('PromptCategory', () {
    test('all values have correct IDs', () {
      expect(PromptCategory.emotion.id, 'emotion');
      expect(PromptCategory.emotionDepth.id, 'emotion_depth');
      expect(PromptCategory.sensoryEmotion.id, 'sensory_emotion');
      expect(PromptCategory.emotionGrowth.id, 'emotion_growth');
      expect(PromptCategory.emotionConnection.id, 'emotion_connection');
      expect(PromptCategory.emotionDiscovery.id, 'emotion_discovery');
      expect(PromptCategory.emotionFantasy.id, 'emotion_fantasy');
      expect(PromptCategory.emotionHealing.id, 'emotion_healing');
      expect(PromptCategory.emotionEnergy.id, 'emotion_energy');
    });

    test('has exactly 9 values', () {
      expect(PromptCategory.values.length, 9);
    });

    test('fromId returns correct category for all known IDs', () {
      expect(PromptCategory.fromId('emotion'), PromptCategory.emotion);
      expect(
        PromptCategory.fromId('emotion_depth'),
        PromptCategory.emotionDepth,
      );
      expect(
        PromptCategory.fromId('sensory_emotion'),
        PromptCategory.sensoryEmotion,
      );
      expect(
        PromptCategory.fromId('emotion_growth'),
        PromptCategory.emotionGrowth,
      );
      expect(
        PromptCategory.fromId('emotion_connection'),
        PromptCategory.emotionConnection,
      );
      expect(
        PromptCategory.fromId('emotion_discovery'),
        PromptCategory.emotionDiscovery,
      );
      expect(
        PromptCategory.fromId('emotion_fantasy'),
        PromptCategory.emotionFantasy,
      );
      expect(
        PromptCategory.fromId('emotion_healing'),
        PromptCategory.emotionHealing,
      );
      expect(
        PromptCategory.fromId('emotion_energy'),
        PromptCategory.emotionEnergy,
      );
    });

    test('fromId falls back to emotion for unknown ID', () {
      expect(PromptCategory.fromId('unknown'), PromptCategory.emotion);
      expect(PromptCategory.fromId(''), PromptCategory.emotion);
      expect(PromptCategory.fromId('EMOTION'), PromptCategory.emotion);
    });

    test('all categories have unique IDs', () {
      final ids = PromptCategory.values.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
