# プラン管理のクラス化移行計画

## 概要

### 現状の課題

現在、Smart Photo Diaryのサブスクリプションプラン管理は`SubscriptionPlan` enumで実装されていますが、以下の課題があります：

1. **拡張性の制限**: enumの制約により、プラン情報の動的な拡張が困難
2. **保守性の問題**: 新プラン追加時に複数箇所のコード修正が必要
3. **ビジネスロジックの分散**: プラン固有のロジックがenum内のswitch文で管理されている
4. **テストの困難さ**: enumのモック作成が難しく、単体テストが複雑化

### 移行の目的とメリット

プラン管理をクラスベースに移行することで：

- ✅ **拡張性向上**: 新プランの追加が単一クラスの追加で完結
- ✅ **保守性向上**: プラン固有のロジックをカプセル化
- ✅ **テスタビリティ向上**: インターフェースによるモック作成が容易
- ✅ **型安全性維持**: 抽象クラスによる型制約でコンパイル時エラー検出

## 技術設計

### クラス構成

```
lib/models/plans/
├── plan.dart                    # 抽象基底クラス
├── basic_plan.dart              # Basicプラン実装
├── premium_monthly_plan.dart    # Premium月額プラン実装
├── premium_yearly_plan.dart     # Premium年額プラン実装
├── plan_factory.dart            # プランファクトリー
└── plan_repository.dart         # プランリポジトリ（将来の拡張用）
```

### 抽象基底クラス設計

```dart
// lib/models/plans/plan.dart
abstract class Plan {
  final String id;
  final String displayName;
  final String description;
  final int price;
  final int monthlyAiGenerationLimit;
  final List<String> features;
  final String productId;

  const Plan({
    required this.id,
    required this.displayName,
    required this.description,
    required this.price,
    required this.monthlyAiGenerationLimit,
    required this.features,
    required this.productId,
  });

  // 抽象メソッド（各プランで実装必須）
  bool get isPremium;
  bool get hasWritingPrompts;
  bool get hasAdvancedFilters;
  bool get hasAdvancedAnalytics;
  bool get hasPrioritySupport;

  // 共通メソッド
  bool get isPaid => price > 0;
  bool get isFree => price == 0;
  double get dailyAverageGenerations => monthlyAiGenerationLimit / 30.0;
  
  // 価格フォーマット
  String get formattedPrice {
    if (price == 0) return '無料';
    return '¥${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    )}';
  }
}
```

### 具体的なプランクラス実装例

```dart
// lib/models/plans/basic_plan.dart
import 'plan.dart';
import '../../constants/subscription_constants.dart';

class BasicPlan extends Plan {
  BasicPlan()
      : super(
          id: SubscriptionConstants.basicPlanId,
          displayName: SubscriptionConstants.basicDisplayName,
          description: SubscriptionConstants.basicDescription,
          price: SubscriptionConstants.basicYearlyPrice,
          monthlyAiGenerationLimit: SubscriptionConstants.basicMonthlyAiLimit,
          features: SubscriptionConstants.basicFeatures,
          productId: '', // 無料プランは商品IDなし
        );

  @override
  bool get isPremium => false;

  @override
  bool get hasWritingPrompts => false;

  @override
  bool get hasAdvancedFilters => false;

  @override
  bool get hasAdvancedAnalytics => false;

  @override
  bool get hasPrioritySupport => false;
}
```

### プランファクトリー実装

```dart
// lib/models/plans/plan_factory.dart
import 'plan.dart';
import 'basic_plan.dart';
import 'premium_monthly_plan.dart';
import 'premium_yearly_plan.dart';

class PlanFactory {
  static final Map<String, Plan> _plans = {
    'basic': BasicPlan(),
    'premium_monthly': PremiumMonthlyPlan(),
    'premium_yearly': PremiumYearlyPlan(),
  };

  /// プランIDから対応するPlanインスタンスを取得
  static Plan createPlan(String planId) {
    final plan = _plans[planId.toLowerCase()];
    if (plan == null) {
      throw ArgumentError('Unknown plan ID: $planId');
    }
    return plan;
  }

  /// 全プランのリストを取得
  static List<Plan> getAllPlans() {
    return _plans.values.toList();
  }

  /// 有料プランのみ取得
  static List<Plan> getPaidPlans() {
    return _plans.values.where((plan) => plan.isPaid).toList();
  }

  /// プレミアムプランのみ取得
  static List<Plan> getPremiumPlans() {
    return _plans.values.where((plan) => plan.isPremium).toList();
  }
}
```

## 移行計画

### フェーズ1: 基盤実装（推定: 2-3時間）

- [x] プランクラス構造の作成
  - [x] `lib/models/plans/`ディレクトリ作成
  - [x] 抽象基底クラス`Plan`の実装
  - [x] `BasicPlan`クラスの実装
  - [x] `PremiumMonthlyPlan`クラスの実装
  - [x] `PremiumYearlyPlan`クラスの実装
  - [x] `PlanFactory`クラスの実装

### フェーズ2: サービス層の移行（推定: 3-4時間）

- [x] `SubscriptionService`の更新
  - [x] `getPlan()`メソッドを新クラスベースに変更
  - [x] `getCurrentPlan()`メソッドの更新
  - [x] プラン関連のビジネスロジックの移行
  - [x] 既存enumとの互換性レイヤー実装

- [x] `SettingsService`の更新
  - [x] プラン情報取得ロジックの更新
  - [x] UI表示用メソッドの調整

### フェーズ3: モデル層の更新（推定: 2時間）

- [x] `SubscriptionInfo`クラスの更新
  - [x] `Plan`クラスを使用するよう変更
  - [x] ファクトリメソッドの更新

- [x] `SubscriptionStatus`との統合
  - [x] プランIDからPlanインスタンスへの変換ロジック

### フェーズ4: テストの更新（推定: 3-4時間）

- [x] 単体テストの作成・更新
  - [x] `plan_test.dart`の作成
  - [x] `plan_factory_test.dart`の作成
  - [x] 各プランクラスのテスト作成

- [x] 既存テストの更新
  - [x] `MockSubscriptionService`の更新（新インターフェースメソッドの実装）

### フェーズ5: UI層の更新（推定: 2-3時間）

- [x] プラン表示箇所の特定と更新
  - [x] `SettingsScreen`の更新
  - [x] `UpgradeDialog`の更新
  - [x] その他のプラン表示箇所

### フェーズ6: クリーンアップ（推定: 1-2時間）

- [ ] 既存enumの削除
  - [ ] `SubscriptionPlan` enumの削除
  - [ ] 関連する不要なコードの削除

- [ ] ドキュメント更新
  - [ ] CLAUDE.mdの更新
  - [ ] コードコメントの更新

## 影響範囲

### 直接影響を受けるファイル

1. **サービス層**
   - `lib/services/subscription_service.dart`
   - `lib/services/settings_service.dart`
   - `lib/services/prompt_service.dart`
   - `lib/services/ai_service.dart`

2. **モデル層**
   - `lib/models/subscription_plan.dart` (削除予定)
   - `lib/models/subscription_info.dart`
   - `lib/models/subscription_status.dart`

3. **UI層**
   - `lib/screens/settings_screen.dart`
   - `lib/utils/upgrade_dialog_utils.dart`
   - `lib/widgets/home_content_widget.dart`

4. **設定層**
   - `lib/config/in_app_purchase_config.dart`
   - `lib/constants/subscription_constants.dart`

### テストファイル

- `test/unit/models/subscription_plan_test.dart`
- `test/unit/services/subscription_service_test.dart`
- `test/unit/services/settings_service_subscription_test.dart`
- その他関連テスト

## 進捗管理

### 全体進捗チェックリスト

- [x] **設計レビュー完了**
- [x] **実装開始**
- [x] **フェーズ1完了**: 基盤実装
- [x] **フェーズ2完了**: サービス層移行
- [x] **フェーズ3完了**: モデル層更新
- [x] **フェーズ4完了**: テスト更新
- [x] **フェーズ5完了**: UI層更新
- [ ] **フェーズ6完了**: クリーンアップ
- [ ] **最終テスト実行**
- [ ] **コードレビュー**
- [ ] **マージ準備完了**

### 完了条件

各フェーズの完了条件：

1. **コード実装完了**: 全ての必要なコード変更が完了
2. **テスト成功**: 関連する全てのテストが成功（100%成功率維持）
3. **Lint成功**: `fvm flutter analyze`でエラーなし
4. **フォーマット完了**: `fvm dart format .`実行済み
5. **動作確認**: アプリが正常に動作することを確認

## リスクと対策

### 想定されるリスク

1. **後方互換性の破壊**
   - 対策: 移行期間中は既存enumとの互換性レイヤーを維持

2. **テストカバレッジの低下**
   - 対策: 新クラスに対する包括的なテストを先に作成

3. **パフォーマンスへの影響**
   - 対策: プランインスタンスのキャッシュ実装

### ロールバック計画

問題が発生した場合：
1. Gitで移行前のコミットに戻す
2. 互換性レイヤーを使用して段階的に戻す
3. 問題箇所を特定して部分的な移行に切り替える

## 次のステップ

1. このドキュメントのレビューと承認
2. フェーズ1の実装開始
3. 各フェーズ完了時の進捗報告
4. 最終的な動作確認とマージ

---

最終更新日: 2025-07-26
作成者: Claude Code

## 実装履歴

### フェーズ1完了 (2025-07-26)
- ✅ プランクラス構造の作成完了
- ✅ 抽象基底クラス`Plan`の実装
- ✅ 各プランクラス（Basic, Premium月額, Premium年額）の実装
- ✅ `PlanFactory`によるプラン管理機能の実装
- ✅ コードフォーマット適用済み

実装ファイル:
- `lib/models/plans/plan.dart`
- `lib/models/plans/basic_plan.dart`
- `lib/models/plans/premium_monthly_plan.dart`
- `lib/models/plans/premium_yearly_plan.dart`
- `lib/models/plans/plan_factory.dart`

### フェーズ2完了 (2025-07-26)
- ✅ `SubscriptionService`の更新完了
  - `getPlanClass()` メソッド追加
  - `getCurrentPlanClass()` メソッド追加
  - `purchasePlanClass()` メソッド追加
  - `changePlanClass()` メソッド追加
- ✅ `ISubscriptionService`インターフェースの更新
- ✅ `SettingsService`の更新完了
  - `getCurrentPlanClass()` メソッド追加
  - `getUsageStatisticsWithPlanClass()` メソッド追加
- ✅ コードフォーマットとlintチェック完了

更新ファイル:
- `lib/services/subscription_service.dart`
- `lib/services/interfaces/subscription_service_interface.dart`
- `lib/services/settings_service.dart`

### フェーズ3完了 (2025-07-26)
- ✅ `SubscriptionInfoV2`クラスの作成
  - 新Planクラスを使用した実装
  - 既存SubscriptionInfoとの相互変換機能
- ✅ ヘルパークラスの実装
  - `UsageStatisticsV2` - Planクラス対応
  - `PlanPeriodInfoV2` - Planクラス対応
- ✅ `SubscriptionStatus`拡張メソッドの実装
  - `plan`プロパティでPlanインスタンス取得
  - 便利なユーティリティメソッド追加
- ✅ コードフォーマットとlintエラー解消

作成ファイル:
- `lib/models/subscription_info_v2.dart`
- `lib/models/subscription_info_extensions.dart`
- `lib/models/subscription_status_extensions.dart`

### フェーズ4完了 (2025-07-26)
- ✅ 単体テストの作成完了
  - `plan_test.dart` - Plan抽象クラスの包括的テスト
  - `plan_factory_test.dart` - PlanFactoryの全機能テスト
  - `basic_plan_test.dart` - BasicPlanの単体テスト
  - `premium_monthly_plan_test.dart` - PremiumMonthlyPlanの単体テスト
  - `premium_yearly_plan_test.dart` - PremiumYearlyPlanの単体テスト
- ✅ 既存テストの更新
  - `MockSubscriptionService`に新インターフェースメソッド追加
- ✅ テスト実行確認 - 115件のテストが成功

作成・更新ファイル:
- `test/unit/models/plans/plan_test.dart`
- `test/unit/models/plans/plan_factory_test.dart`
- `test/unit/models/plans/basic_plan_test.dart`
- `test/unit/models/plans/premium_monthly_plan_test.dart`
- `test/unit/models/plans/premium_yearly_plan_test.dart`
- `test/mocks/mock_subscription_service.dart`