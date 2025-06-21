// 感情深掘り型プロンプトカテゴリの設計仕様
//
// 感情中心のライティングプロンプトシステムの品質を保証します。
// すべてのプロンプトは感情探求と内面深化を目的としています。

import '../models/writing_prompt.dart';

/// 感情深掘り型プロンプトカテゴリ仕様
class EmotionPromptCategorySpecs {
  /// 基本感情（Emotion）カテゴリ仕様
  ///
  /// 【対象】: Basic・Premium共通
  /// 【特徴】: 写真から感じる基本的な感情の探求
  /// 【狙い】: 感情の言語化と自己理解の基盤作り
  static const EmotionCategorySpec emotionCategory = EmotionCategorySpec();

  /// 感情深掘り（Emotion Depth）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 感情の背景や変化プロセスの詳細探求
  /// 【狙い】: 深い自己洞察と感情パターンの理解
  static const EmotionDepthCategorySpec emotionDepthCategory =
      EmotionDepthCategorySpec();

  /// 感情五感（Sensory Emotion）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 五感の記憶が呼び起こす感情体験の記録
  /// 【狙い】: 多感覚的な感情記憶の保存と再体験
  static const SensoryEmotionCategorySpec sensoryEmotionCategory =
      SensoryEmotionCategorySpec();

  /// 感情成長（Emotion Growth）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 感情体験を通じた個人的成長の記録
  /// 【狙い】: 感情的成熟と自己発達の追跡
  static const EmotionGrowthCategorySpec emotionGrowthCategory =
      EmotionGrowthCategorySpec();

  /// 感情つながり（Emotion Connection）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 人とのつながりや絆から生まれる感情の探求
  /// 【狙い】: 関係性における感情体験の深化
  static const EmotionConnectionCategorySpec emotionConnectionCategory =
      EmotionConnectionCategorySpec();

  /// 感情発見（Emotion Discovery）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 新たな感情や予想外の反応の発見と理解
  /// 【狙い】: 感情の多様性認識と自己発見の促進
  static const EmotionDiscoveryCategorySpec emotionDiscoveryCategory =
      EmotionDiscoveryCategorySpec();

  /// 感情幻想（Emotion Fantasy）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 懐かしさや憧れなど、想像的感情の探求
  /// 【狙い】: 内面世界の豊かさと創造的感情の育成
  static const EmotionFantasyCategorySpec emotionFantasyCategory =
      EmotionFantasyCategorySpec();

  /// 感情癒し（Emotion Healing）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 癒しや安らぎをもたらす感情体験の記録
  /// 【狙い】: 感情的回復力と心の平安の育成
  static const EmotionHealingCategorySpec emotionHealingCategory =
      EmotionHealingCategorySpec();

  /// 感情エネルギー（Emotion Energy）カテゴリ仕様
  ///
  /// 【対象】: Premium限定
  /// 【特徴】: 活力や情熱を生み出す感情体験の探求
  /// 【狙い】: 生命力と動機の源泉としての感情理解
  static const EmotionEnergyCategorySpec emotionEnergyCategory =
      EmotionEnergyCategorySpec();
}

/// 基本感情（Emotion）カテゴリの詳細仕様
class EmotionCategorySpec {
  const EmotionCategorySpec();

  /// カテゴリの基本情報
  PromptCategory get category => PromptCategory.emotion;
  String get name => '感情';
  String get description => '写真から感じる基本的な感情を探求し、自己理解を深める';

  /// 対象ユーザーとプラン配分
  bool get isBasicAvailable => true;
  int get basicPromptCount => 5; // Basic用プロンプト数
  int get premiumPromptCount => 0; // 基本感情カテゴリはBasicのみ

  /// プロンプトの設計方針
  List<String> get designPrinciples => [
    '写真から感じる素直な感情に焦点を当てる',
    'シンプルで親しみやすい感情表現を促進',
    '感情の言語化を支援する',
    '自分らしさや心の動きを大切にする',
    '感謝や温かさなどポジティブ感情も含む',
  ];

  /// 期待される効果
  List<String> get expectedBenefits => [
    '感情の言語化スキル向上',
    '自己理解の深化',
    'ポジティブな感情体験の認識',
    '写真と感情の結びつき強化',
    '日記習慣の継続促進',
  ];

  /// Basic用プロンプトのテーマ
  List<String> get basicThemes => [
    '最初に感じた気持ち',
    '心が動いた理由',
    '温かい感情',
    '感謝の気持ち',
    '自分らしさ',
  ];

  /// 推奨タグ
  List<String> get recommendedTags => [
    '感情',
    '気持ち',
    '心',
    '温かい',
    '感謝',
    'ありがたい',
    '自分らしさ',
    '素直',
    '第一印象',
    '直感',
  ];
}

/// 感情深掘り（Emotion Depth）カテゴリの詳細仕様
class EmotionDepthCategorySpec {
  const EmotionDepthCategorySpec();

  PromptCategory get category => PromptCategory.emotionDepth;
  String get name => '感情深掘り';
  String get description => '感情の背景や変化プロセスを詳細に探求し、深い自己洞察を促進する';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '感情の根本的原因の探求',
    '時間的変化の追跡',
    '深い内省の促進',
    '感情パターンの認識',
    '自己理解の深化',
  ];

  List<String> get expectedBenefits => [
    '感情的自己認識の向上',
    '感情調整能力の発達',
    '深い内省習慣の形成',
    '感情パターンの理解',
    '心理的成熟の促進',
  ];

  List<String> get premiumThemes => ['感情の背景・キッカケ', '感情の時間的変化'];

  List<String> get recommendedTags => [
    '感情深掘り',
    '背景',
    'キッカケ',
    '変化',
    '時間',
    '原因',
    '進化',
    '深層',
    '探求',
    '洞察',
  ];
}

/// 感情五感（Sensory Emotion）カテゴリの詳細仕様
class SensoryEmotionCategorySpec {
  const SensoryEmotionCategorySpec();

  PromptCategory get category => PromptCategory.sensoryEmotion;
  String get name => '感情五感';
  String get description => '五感の記憶が呼び起こす感情体験を記録し、多感覚的な感情記憶を保存する';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '五感と感情の結びつき探求',
    '感覚記憶の活用',
    '多感覚的体験の記録',
    '感情の立体的理解',
    '記憶の鮮明な保存',
  ];

  List<String> get expectedBenefits => [
    '感覚と感情の統合理解',
    '記憶の鮮明度向上',
    '体験の多層的記録',
    '感情体験の豊かさ向上',
    '感覚的感受性の発達',
  ];

  List<String> get premiumThemes => ['音・においの感情喚起', '場所の空気感・心への影響'];

  List<String> get recommendedTags => [
    '感情五感',
    '音',
    'におい',
    '空気感',
    '雰囲気',
    '感覚',
    '記憶',
    '喚起',
    '影響',
    '体験',
  ];
}

/// 感情成長（Emotion Growth）カテゴリの詳細仕様
class EmotionGrowthCategorySpec {
  const EmotionGrowthCategorySpec();

  PromptCategory get category => PromptCategory.emotionGrowth;
  String get name => '感情成長';
  String get description => '感情体験を通じた個人的成長を記録し、感情的成熟を促進する';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '成長体験の感情的側面を探求',
    '過去との比較による変化認識',
    '内面的発達の記録',
    '感情的成熟の追跡',
    '自己発見の促進',
  ];

  List<String> get expectedBenefits => [
    '感情的成熟の促進',
    '自己成長の認識向上',
    '内面的発達の記録',
    '変化への気づき強化',
    '成長実感の向上',
  ];

  List<String> get premiumThemes => ['成長・変化の実感', '過去との違い・進歩'];

  List<String> get recommendedTags => [
    '感情成長',
    '変化',
    '成長',
    '発見',
    '自己認識',
    '過去',
    '比較',
    '進歩',
    '発達',
    '成熟',
  ];
}

/// 感情つながり（Emotion Connection）カテゴリの詳細仕様
class EmotionConnectionCategorySpec {
  const EmotionConnectionCategorySpec();

  PromptCategory get category => PromptCategory.emotionConnection;
  String get name => '感情つながり';
  String get description => '人とのつながりや絆から生まれる感情を探求し、関係性を深化させる';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '関係性から生まれる感情の探求',
    '絆や愛情の記録',
    '安心感・所属感の認識',
    '人とのつながりの価値化',
    '社会的感情の育成',
  ];

  List<String> get expectedBenefits => [
    '人間関係の質向上',
    '愛情・絆の深い理解',
    '所属感の強化',
    '共感性の発達',
    '社会的幸福感の向上',
  ];

  List<String> get premiumThemes => ['人とのつながり・絆', '安心感・居心地の良さ'];

  List<String> get recommendedTags => [
    '感情つながり',
    '絆',
    '関係性',
    '愛情',
    'コミュニティ',
    '安心感',
    '居心地',
    '安全',
    '所属感',
    'つながり',
  ];
}

/// 感情発見（Emotion Discovery）カテゴリの詳細仕様
class EmotionDiscoveryCategorySpec {
  const EmotionDiscoveryCategorySpec();

  PromptCategory get category => PromptCategory.emotionDiscovery;
  String get name => '感情発見';
  String get description => '新たな感情や予想外の反応を発見し、感情の多様性を認識する';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '未知の感情の発見',
    '予想外の反応の探求',
    '感情の多様性認識',
    '自己理解の拡張',
    '内面の新発見促進',
  ];

  List<String> get expectedBenefits => [
    '感情語彙の拡張',
    '自己理解の深化',
    '感情的柔軟性の向上',
    '内面の豊かさ認識',
    '自己受容の促進',
  ];

  List<String> get premiumThemes => ['新しく気づいた感情', '意外だった反応・気持ち'];

  List<String> get recommendedTags => [
    '感情発見',
    '新発見',
    '気づき',
    '自己理解',
    '内省',
    '意外',
    '反応',
    '予想外',
    '驚き',
    '発見',
  ];
}

/// 感情幻想（Emotion Fantasy）カテゴリの詳細仕様
class EmotionFantasyCategorySpec {
  const EmotionFantasyCategorySpec();

  PromptCategory get category => PromptCategory.emotionFantasy;
  String get name => '感情幻想';
  String get description => '懐かしさや憧れなど想像的感情を探求し、内面世界を豊かにする';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 1;

  List<String> get designPrinciples => [
    '想像的感情の探求',
    'ノスタルジアの記録',
    '憧れ・憧憬の表現',
    '内面世界の拡張',
    '創造的感情の育成',
  ];

  List<String> get expectedBenefits => [
    '感情の豊かさ向上',
    '創造性の発達',
    'ノスタルジアの健全な活用',
    '内面世界の深化',
    '感情的想像力の育成',
  ];

  List<String> get premiumThemes => ['懐かしさ・憧れの感情'];

  List<String> get recommendedTags => [
    '感情幻想',
    '懐かしさ',
    '憧れ',
    'ノスタルジア',
    '憧憬',
    '想像',
    '幻想',
    '夢',
    '理想',
    '憧憬',
  ];
}

/// 感情癒し（Emotion Healing）カテゴリの詳細仕様
class EmotionHealingCategorySpec {
  const EmotionHealingCategorySpec();

  PromptCategory get category => PromptCategory.emotionHealing;
  String get name => '感情癒し';
  String get description => '癒しや安らぎをもたらす感情体験を記録し、感情的回復力を育成する';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '癒し体験の記録',
    '平安・安らぎの探求',
    '感情的回復の促進',
    '心の安定化支援',
    '穏やかさの価値化',
  ];

  List<String> get expectedBenefits => [
    '感情的回復力の向上',
    'ストレス軽減',
    '心の平安の育成',
    '安らぎの認識強化',
    '感情調整能力の向上',
  ];

  List<String> get premiumThemes => ['心が癒された理由・感覚', '平和・安らぎの感情'];

  List<String> get recommendedTags => [
    '感情癒し',
    '癒し',
    '理由',
    '感覚',
    '回復',
    '平和',
    '安らぎ',
    '静寂',
    '穏やか',
    '安心',
  ];
}

/// 感情エネルギー（Emotion Energy）カテゴリの詳細仕様
class EmotionEnergyCategorySpec {
  const EmotionEnergyCategorySpec();

  PromptCategory get category => PromptCategory.emotionEnergy;
  String get name => '感情エネルギー';
  String get description => '活力や情熱を生み出す感情体験を探求し、生命力の源泉を理解する';

  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 2;

  List<String> get designPrinciples => [
    '活力源の感情探求',
    '情熱・エネルギーの記録',
    '動機となる感情の発見',
    '生命力の源泉理解',
    '感情的インパクトの測定',
  ];

  List<String> get expectedBenefits => [
    '活力・動機の向上',
    '情熱の再発見',
    'エネルギー源の認識',
    '感情的推進力の理解',
    '生活意欲の向上',
  ];

  List<String> get premiumThemes => ['エネルギー・活力の源', '最も強い感情・インパクト'];

  List<String> get recommendedTags => [
    '感情エネルギー',
    '活力',
    'エネルギー',
    '源',
    '力',
    '強い感情',
    '動かされた',
    'インパクト',
    '印象',
    '情熱',
  ];
}
