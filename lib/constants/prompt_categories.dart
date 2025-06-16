// プロンプトカテゴリ別の詳細設計と仕様定義
// 
// 各カテゴリの特徴、対象ユーザー、プロンプト設計方針を定義し、
// Premium機能としてのライティングプロンプトの品質を保証します。

import '../models/writing_prompt.dart';

/// カテゴリ別プロンプト設計仕様
class PromptCategorySpecs {
  /// 日常（Daily）カテゴリ仕様
  /// 
  /// 【対象】: 全ユーザー（Basic/Premium共通の基盤カテゴリ）
  /// 【特徴】: 日々の些細な出来事や感情に焦点を当てた記録支援
  /// 【狙い】: 継続的な日記習慣の形成と日常の価値の再発見
  static const DailyCategorySpec dailyCategory = DailyCategorySpec();
  
  /// 旅行（Travel）カテゴリ仕様
  /// 
  /// 【対象】: Premium限定（体験の深掘りが重要）
  /// 【特徴】: 場所、体験、文化的発見に重点を置いた記録
  /// 【狙い】: 旅行記録の質向上と思い出の鮮明な保存
  static const TravelCategorySpec travelCategory = TravelCategorySpec();
  
  /// 仕事（Work）カテゴリ仕様
  /// 
  /// 【対象】: Premium限定（キャリア発展支援）
  /// 【特徴】: 成長、学習、課題解決に焦点を当てた振り返り
  /// 【狙い】: 専門的成長の記録とキャリア開発支援
  static const WorkCategorySpec workCategory = WorkCategorySpec();
  
  /// 感謝（Gratitude）カテゴリ仕様
  /// 
  /// 【対象】: Basic一部・Premium完全（ウェルビーイング向上）
  /// 【特徴】: ポジティブ心理学に基づいた感謝の記録
  /// 【狙い】: 心理的健康の向上と幸福感の増進
  static const GratitudeCategorySpec gratitudeCategory = GratitudeCategorySpec();
  
  /// 振り返り（Reflection）カテゴリ仕様
  /// 
  /// 【対象】: Premium限定（深い内省が必要）
  /// 【特徴】: 自己分析、価値観の探求、人生の方向性の検討
  /// 【狙い】: 個人的成長と自己理解の深化
  static const ReflectionCategorySpec reflectionCategory = ReflectionCategorySpec();
  
  /// 創作（Creative）カテゴリ仕様
  /// 
  /// 【対象】: Premium限定（高度な創作支援）
  /// 【特徴】: 想像力、創造性、表現力を刺激するプロンプト
  /// 【狙い】: 創作能力の向上と表現の多様化
  static const CreativeCategorySpec creativeCategory = CreativeCategorySpec();
  
  /// 健康・ウェルネス（Wellness）カテゴリ仕様
  /// 
  /// 【対象】: Premium限定（包括的健康管理）
  /// 【特徴】: 身体的・精神的・社会的健康の統合的記録
  /// 【狙い】: ホリスティックな健康意識の向上
  static const WellnessCategorySpec wellnessCategory = WellnessCategorySpec();
  
  /// 人間関係（Relationships）カテゴリ仕様
  /// 
  /// 【対象】: Premium限定（対人関係スキル向上）
  /// 【特徴】: コミュニケーション、共感、社会的つながりの記録
  /// 【狙い】: 対人関係能力の向上と社会的幸福感の増進
  static const RelationshipsCategorySpec relationshipsCategory = RelationshipsCategorySpec();
}

/// 日常（Daily）カテゴリの詳細仕様
class DailyCategorySpec {
  const DailyCategorySpec();
  
  /// カテゴリの基本情報
  PromptCategory get category => PromptCategory.daily;
  String get name => '日常';
  String get description => '日々の出来事や感情を記録し、日常の価値を再発見する';
  
  /// 対象ユーザーとプラン配分
  bool get isBasicAvailable => true;
  int get basicPromptCount => 3; // Basic用プロンプト数
  int get premiumPromptCount => 8; // Premium追加プロンプト数
  
  /// プロンプトの設計方針
  List<String> get designPrinciples => [
    '日常の小さな瞬間に焦点を当てる',
    'シンプルで親しみやすい表現を使用',
    '継続しやすい軽い負荷のプロンプト',
    '感情と出来事の両方を記録',
    '現在志向（今日・今の気持ち）',
  ];
  
  /// 期待される効果
  List<String> get expectedBenefits => [
    '日記習慣の継続促進',
    '日常生活への意識向上',
    'ポジティブな視点の育成',
    '感情の言語化スキル向上',
    '自己観察能力の発達',
  ];
  
  /// Basic用プロンプトのテーマ
  List<String> get basicThemes => [
    '今日の出来事',
    '気持ちや感情',
    '小さな発見',
  ];
  
  /// Premium用追加プロンプトのテーマ
  List<String> get premiumThemes => [
    '深い感情の探求',
    '価値観の確認',
    '習慣の振り返り',
    '関係性の記録',
    '成長の実感',
  ];
  
  /// 推奨タグ
  List<String> get recommendedTags => [
    '日常', '気持ち', '発見', '小さな幸せ', '今日',
    '感情', '出来事', '変化', '気づき', '瞬間',
  ];
}

/// 旅行（Travel）カテゴリの詳細仕様
class TravelCategorySpec {
  const TravelCategorySpec();
  
  PromptCategory get category => PromptCategory.travel;
  String get name => '旅行';
  String get description => '旅行体験を深く記録し、文化的発見と思い出を鮮明に保存する';
  
  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 6;
  
  List<String> get designPrinciples => [
    '場所の特徴と個人的体験の結合',
    '文化的発見と学びに重点',
    '五感を活用した記録促進',
    '旅行前後の変化を捉える',
    '思い出の詳細な保存',
  ];
  
  List<String> get expectedBenefits => [
    '旅行体験の質向上',
    '文化的理解の深化',
    '思い出の鮮明な記録',
    '旅行前後の成長記録',
    '次回旅行の参考資料作成',
  ];
  
  List<String> get premiumThemes => [
    '場所との出会い',
    '文化的発見',
    '予期しない体験',
    '地元の人々との交流',
    '旅行からの学び',
    '思い出の詳細記録',
  ];
  
  List<String> get recommendedTags => [
    '旅行', '発見', '文化', '体験', '学び',
    '思い出', '場所', '人々', '感動', '変化',
  ];
}

/// 仕事（Work）カテゴリの詳細仕様
class WorkCategorySpec {
  const WorkCategorySpec();
  
  PromptCategory get category => PromptCategory.work;
  String get name => '仕事';
  String get description => '仕事での成長と学びを記録し、キャリア発展を支援する';
  
  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 7;
  
  List<String> get designPrinciples => [
    '成長と学習に焦点を当てる',
    '具体的な成果と課題を記録',
    'プロフェッショナルな視点を維持',
    '将来への応用を考慮',
    'スキルと知識の蓄積',
  ];
  
  List<String> get expectedBenefits => [
    'キャリア発展の記録',
    'スキル向上の自覚',
    '課題解決能力の向上',
    '成果の可視化',
    '将来計画の立案支援',
  ];
  
  List<String> get premiumThemes => [
    '今日の成果',
    '学んだスキル',
    '解決した課題',
    'チームワーク',
    '将来への応用',
    'プロフェッショナルな成長',
    '価値創造',
  ];
  
  List<String> get recommendedTags => [
    '仕事', '成長', 'スキル', '課題', '成果',
    '学び', 'チーム', '解決', '価値', '将来',
  ];
}

/// 感謝（Gratitude）カテゴリの詳細仕様
class GratitudeCategorySpec {
  const GratitudeCategorySpec();
  
  PromptCategory get category => PromptCategory.gratitude;
  String get name => '感謝';
  String get description => 'ポジティブ心理学に基づいた感謝の記録で心理的健康を向上させる';
  
  bool get isBasicAvailable => true; // 一部Basic対応
  int get basicPromptCount => 2; // Basic用基本的な感謝プロンプト
  int get premiumPromptCount => 6; // Premium用高度な感謝プロンプト
  
  List<String> get designPrinciples => [
    'ポジティブ感情の強化',
    '具体的な感謝対象の特定',
    '小さな幸せへの注目',
    '他者への感謝の表現',
    '感謝の習慣化促進',
  ];
  
  List<String> get expectedBenefits => [
    '心理的ウェルビーイングの向上',
    'ポジティブ思考の強化',
    '人間関係の改善',
    'ストレス軽減',
    '幸福感の増進',
  ];
  
  List<String> get basicThemes => [
    '今日の感謝',
    '身近な人への感謝',
  ];
  
  List<String> get premiumThemes => [
    '深い感謝の探求',
    '困難な状況からの学び',
    '成長への感謝',
    '環境への感謝',
    '自分自身への感謝',
    '未来への希望',
  ];
  
  List<String> get recommendedTags => [
    '感謝', '幸せ', '大切', '支え', 'ありがとう',
    '恵み', '喜び', '温かさ', '絆', '愛',
  ];
}

/// 振り返り（Reflection）カテゴリの詳細仕様
class ReflectionCategorySpec {
  const ReflectionCategorySpec();
  
  PromptCategory get category => PromptCategory.reflection;
  String get name => '振り返り';
  String get description => '深い内省を通じて自己理解を深め、個人的成長を促進する';
  
  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 8;
  
  List<String> get designPrinciples => [
    '深い自己分析の促進',
    '価値観の明確化',
    '行動パターンの認識',
    '将来への方向性の検討',
    '内的動機の探求',
  ];
  
  List<String> get expectedBenefits => [
    '自己理解の深化',
    '価値観の明確化',
    '人生の方向性の発見',
    '内的成長の促進',
    '意思決定能力の向上',
  ];
  
  List<String> get premiumThemes => [
    '価値観の探求',
    '人生の目標',
    '行動パターンの分析',
    '重要な決断',
    '成長の実感',
    '学びの統合',
    '将来への展望',
    '内なる声への傾聴',
  ];
  
  List<String> get recommendedTags => [
    '振り返り', '成長', '価値観', '目標', '学び',
    '変化', '決断', '発見', '理解', '方向性',
  ];
}

/// 創作（Creative）カテゴリの詳細仕様
class CreativeCategorySpec {
  const CreativeCategorySpec();
  
  PromptCategory get category => PromptCategory.creative;
  String get name => '創作';
  String get description => '創造性と表現力を刺激し、多様な創作活動を支援する';
  
  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 6;
  
  List<String> get designPrinciples => [
    '想像力の刺激',
    '創造的表現の促進',
    '固定概念の打破',
    '多様な視点の提供',
    '表現の自由度の確保',
  ];
  
  List<String> get expectedBenefits => [
    '創造性の向上',
    '表現力の多様化',
    '想像力の拡張',
    '創作技術の向上',
    '芸術的感性の発達',
  ];
  
  List<String> get premiumThemes => [
    '想像の世界',
    '創造的表現',
    '物語の創作',
    '感性の記録',
    '芸術的発見',
    '表現の実験',
  ];
  
  List<String> get recommendedTags => [
    '創作', '想像', '表現', '芸術', '感性',
    '物語', '創造', '発想', '実験', '自由',
  ];
}

/// 健康・ウェルネス（Wellness）カテゴリの詳細仕様
class WellnessCategorySpec {
  const WellnessCategorySpec();
  
  PromptCategory get category => PromptCategory.wellness;
  String get name => '健康・ウェルネス';
  String get description => '身体的・精神的・社会的健康を統合的に記録し、ホリスティックな健康意識を向上させる';
  
  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 6;
  
  List<String> get designPrinciples => [
    'ホリスティックな健康観',
    '身体と心の統合的記録',
    '予防的健康管理',
    '生活習慣の意識化',
    'ウェルビーイングの向上',
  ];
  
  List<String> get expectedBenefits => [
    '健康意識の向上',
    'ライフスタイルの改善',
    'ストレス管理能力の向上',
    '身体的健康の維持',
    '精神的安定の促進',
  ];
  
  List<String> get premiumThemes => [
    '身体の状態',
    '心の健康',
    '生活習慣',
    'ストレス管理',
    '運動と活動',
    '栄養と食事',
  ];
  
  List<String> get recommendedTags => [
    '健康', 'ウェルネス', '身体', '心', '習慣',
    '運動', '食事', 'ストレス', '睡眠', 'バランス',
  ];
}

/// 人間関係（Relationships）カテゴリの詳細仕様
class RelationshipsCategorySpec {
  const RelationshipsCategorySpec();
  
  PromptCategory get category => PromptCategory.relationships;
  String get name => '人間関係';
  String get description => 'コミュニケーションと社会的つながりを記録し、対人関係能力を向上させる';
  
  bool get isBasicAvailable => false; // Premium限定
  int get basicPromptCount => 0;
  int get premiumPromptCount => 7;
  
  List<String> get designPrinciples => [
    '対人関係の質的向上',
    'コミュニケーション能力の発達',
    '共感性の育成',
    '社会的つながりの強化',
    '関係性の深化促進',
  ];
  
  List<String> get expectedBenefits => [
    '対人関係スキルの向上',
    'コミュニケーション能力の発達',
    '社会的幸福感の増進',
    '共感性の向上',
    '人間関係の質的改善',
  ];
  
  List<String> get premiumThemes => [
    '大切な人との時間',
    'コミュニケーション',
    '共感と理解',
    '支え合い',
    '関係性の成長',
    '新しい出会い',
    '人間関係の学び',
  ];
  
  List<String> get recommendedTags => [
    '人間関係', 'コミュニケーション', '共感', '理解', '支え',
    '絆', '友情', '愛情', '信頼', '成長',
  ];
}