import 'package:hive_ce/hive_ce.dart';

part 'prompt_category.g.dart';

@HiveType(typeId: 3)
enum PromptCategory {
  @HiveField(0)
  emotion('emotion'),

  @HiveField(1)
  emotionDepth('emotion_depth'),

  @HiveField(2)
  sensoryEmotion('sensory_emotion'),

  @HiveField(3)
  emotionGrowth('emotion_growth'),

  @HiveField(4)
  emotionConnection('emotion_connection'),

  @HiveField(5)
  emotionDiscovery('emotion_discovery'),

  @HiveField(6)
  emotionFantasy('emotion_fantasy'),

  @HiveField(7)
  emotionHealing('emotion_healing'),

  @HiveField(8)
  emotionEnergy('emotion_energy');

  const PromptCategory(this.id);

  final String id;

  static PromptCategory fromId(String id) {
    return PromptCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => PromptCategory.emotion,
    );
  }
}
