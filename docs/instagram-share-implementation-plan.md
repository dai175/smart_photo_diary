# Instagram共有機能実装プラン

## 📋 プロジェクト概要

### 機能説明
Smart Photo DiaryのAIが生成した日記の文章を写真にオーバーレイし、Instagram（ストーリーズ・フィード投稿）やその他のSNSアプリに簡単に共有できる機能を実装します。

### 期待される成果
- [ ] ユーザーが日記を美しい画像として簡単にSNSに投稿できる
- [ ] アプリの認知度向上とユーザーエンゲージメント強化
- [ ] ブランド露出の増加（透かしやアプリ名表示）

### 技術スタック
- **share_plus**: Flutter公式のSNS共有プラグイン
- **image**: 画像処理・テキストオーバーレイ用
- **flutter/painting**: Canvas描画システム
- **既存アーキテクチャ**: ServiceLocator + Result<T>パターンを継承

---

## 🎯 実装チェックリスト

### Phase 1: 基盤準備
- [x] **1.1** pubspec.yamlに依存関係を追加
  - [x] `share_plus: ^11.1.0` (最新版を確認)
  - [x] `image: ^4.5.4` (最新版を確認)
- [x] **1.2** 依存関係のビルド確認
  - [x] `fvm flutter pub get` 実行
  - [x] `fvm dart run build_runner build` 実行
  - [x] アプリが正常にビルドできることを確認

### Phase 2: サービス層実装
- [x] **2.1** インターフェース作成
  - [x] `lib/services/interfaces/social_share_service_interface.dart`
  - [x] `ISocialShareService`インターフェース定義
  - [x] Result<T>パターンでのメソッド署名
- [x] **2.2** サービス実装
  - [x] `lib/services/social_share_service.dart`
  - [x] `SocialShareService`クラス実装
  - [x] LoggingService統合
  - [x] エラーハンドリング実装
- [x] **2.3** ServiceLocator登録
  - [x] `core/service_registration.dart`への追加
  - [x] DI設定の完了

### Phase 3: 画像生成機能
- [x] **3.1** 画像生成クラス作成
  - [x] `lib/services/diary_image_generator.dart`
  - [x] Canvas描画での合成機能
  - [x] 日本語テキストレンダリング対応
- [x] **3.2** レイアウト設計
  - [x] Instagram Stories用（9:16）
  - [x] Instagram Feed用（1:1）
  - [x] 複数写真対応（カルーセル風レイアウト）
  - [x] レスポンシブテキストサイズ調整
  - [x] HD解像度対応（デバイス解像度対応）
  - [x] 美的レイアウト改善
- [x] **3.3** ブランド要素の追加
  - [x] アプリ名/ロゴの透かし（プライマリカラーベース）
  - [x] 美しい日本語フォント適用（Noto Sans JP統一）
  - [x] 既存デザインシステムとの統一（AppColors/AppSpacing活用）
  - [x] カメラアイコン風の視覚的要素追加
  - [x] エレガントなグラデーション装飾

### Phase 4: UI統合
- [x] **4.1** DiaryDetailScreenに共有ボタン追加
  - [x] AppBarに配置（編集・削除ボタンとの調和）
  - [x] Material Design 3準拠（Icons.share_rounded使用）
  - [x] MicroInteractions統合（hapticTap対応）
  - [x] 編集モード時は非表示（UX配慮）
- [x] **4.2** 共有オプションダイアログ
  - [x] Stories/Feed選択UI（視覚的なオプション表示）
  - [x] カスタマイズされたオプションカード
  - [x] CustomDialog使用（既存UIコンポーネント活用）
  - [x] MicroInteractions.bounceOnTap統合
- [x] **4.3** 共有処理の実装
  - [x] ISocialShareService連携
  - [x] Result<T>パターンでのエラーハンドリング
  - [x] ローディングダイアログ表示（ユーザビリティ向上）
  - [x] 成功・失敗時のSnackBar表示

### Phase 5: エラーハンドリング & UX改善
- [ ] **5.1** エラー対応
  - [ ] 権限エラー（PermissionException使用）
  - [ ] ファイル生成エラー（AppException使用）
  - [ ] 共有キャンセル対応（Result.failure適切な処理）
- [ ] **5.2** パフォーマンス最適化
  - [ ] 大きな画像の最適化
  - [ ] メモリ使用量の監視
  - [ ] 一時ファイルの適切な削除

### Phase 6: テスト実装
- [ ] **6.1** ユニットテスト
  - [ ] `test/unit/services/social_share_service_test.dart`
  - [ ] `ISocialShareService`のモック作成
  - [ ] Result<T>パターンのテスト
- [ ] **6.2** 統合テスト
  - [ ] `test/integration/social_share_integration_test.dart`
  - [ ] 画像生成の統合テスト
  - [ ] ファイル共有のテスト
- [ ] **6.3** ウィジェットテスト
  - [ ] 共有ボタンのテスト
  - [ ] ダイアログ表示のテスト

### Phase 7: 品質保証
- [ ] **7.1** コード品質チェック
  - [ ] `fvm flutter analyze` - エラーゼロを確認
  - [ ] `fvm dart format .` - フォーマット適用
  - [ ] 100%テスト成功率の維持
- [ ] **7.2** 実機テスト
  - [ ] iPhone実機でのInstagram連携確認
  - [ ] 各アスペクト比での表示確認
  - [ ] 様々な日記内容での表示確認

---

## 🛠 技術仕様詳細

### API設計

```dart
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../models/diary_entry.dart';
import '../core/result/result.dart';

// ISocialShareService インターフェース
abstract class ISocialShareService {
  Future<Result<void>> shareToSocialMedia({
    required DiaryEntry diary,
    required ShareFormat format, // Stories or Feed
    List<AssetEntity>? photos,
  });
  
  Future<Result<File>> generateShareImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  });
}

// ShareFormat enum
enum ShareFormat {
  instagramStories(aspectRatio: 0.5625), // 9:16
  instagramFeed(aspectRatio: 1.0);       // 1:1
  
  const ShareFormat({required this.aspectRatio});
  final double aspectRatio;
}
```

### 画像生成仕様

```dart
import 'dart:ui' as ui;
import 'package:photo_manager/photo_manager.dart';
import '../models/diary_entry.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';

class DiaryImageGenerator {
  static const double _storyWidth = 1080;
  static const double _storyHeight = 1920;
  static const double _feedSize = 1080;
  
  LoggingService get _logger => serviceLocator.get<LoggingService>();
  
  Future<ui.Image> generateDiaryImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      final canvas = _createCanvas(format);
      
      // 1. 背景写真の描画
      await _drawPhotos(canvas, photos, format);
      
      // 2. オーバーレイ背景の描画
      _drawOverlayBackground(canvas, format);
      
      // 3. テキスト要素の描画
      _drawTitle(canvas, diary.title, format);
      _drawContent(canvas, diary.content, format);
      _drawDate(canvas, diary.date, format);
      
      // 4. ブランド要素の描画
      _drawAppBranding(canvas, format);
      
      return canvas.toImage();
    } catch (e) {
      _logger.error(
        '画像生成エラー',
        context: 'DiaryImageGenerator.generateDiaryImage',
        error: e,
      );
      rethrow;
    }
  }
}
```

### ファイル構成

```
lib/services/
├── interfaces/
│   └── social_share_service_interface.dart
├── social_share_service.dart
└── diary_image_generator.dart

lib/models/
└── share_format.dart

lib/ui/components/
└── share_dialog.dart

lib/constants/
└── social_share_constants.dart
```

---

## 🧪 テスト戦略

### テスト項目

#### ユニットテスト
- [ ] SocialShareServiceの各メソッド
- [ ] DiaryImageGeneratorの画像生成
- [ ] エラーケースのハンドリング
- [ ] Result<T>パターンの適切な使用

#### 統合テスト
- [ ] 実際のDiaryEntryでの画像生成
- [ ] share_plusプラグインとの連携
- [ ] 一時ファイルの作成・削除

#### 手動テスト
- [ ] iPhone実機でのInstagram連携
- [ ] Stories・Feed投稿の表示確認
- [ ] 各種日記内容での表示品質

---

## ⚡ パフォーマンス考慮事項

### メモリ管理
- 大きな画像処理時のメモリ使用量監視（PerformanceMonitor使用）
- Canvas作成時の適切なdispose処理
- 一時ファイルの確実な削除（path_providerの一時ディレクトリ活用）

### UI応答性
- 画像生成中のローディング表示
- 非同期処理での適切な状態管理
- ユーザーキャンセル時の処理中断

---

## 📱 UX設計

### 共有フロー
1. **日記詳細画面**で共有ボタンタップ（MicroInteractions.hapticTap）
2. **フォーマット選択ダイアログ**表示（Stories/Feed）
3. **画像生成プレビュー**表示（LoadingShimmer使用）
4. **SNSアプリ選択**（share_plus）
5. **投稿完了**（成功時SnackBar表示）

### エラー対応
- 権限不足時の適切なガイド表示（DialogUtils.showConfirmationDialog使用）
- ネットワークエラー時の再試行機能
- 生成失敗時のフォールバック表示（ErrorDisplay使用）

---

## 🔄 実装ステップの詳細

### Step 1: 基盤準備（1時間）
```bash
# 依存関係追加
fvm flutter pub add share_plus image

# ビルド確認
fvm flutter pub get
fvm dart run build_runner build
fvm flutter analyze
```

### Step 2: サービス層（1.5時間）
インターフェース定義 → 実装 → ServiceLocator登録

### Step 3: 画像生成（2時間）
Canvas描画ロジック → 日本語テキスト対応 → レイアウト調整

### Step 4: UI統合（1時間）
共有ボタン追加 → ダイアログ実装 → UX調整

### Step 5: テスト（1時間）
ユニットテスト → 統合テスト → 実機確認

---

## ✅ 完了チェック

最終的に以下が全て完了していることを確認：

- [ ] **機能要件**: Instagram Stories/Feed両方に対応
- [ ] **品質要件**: テスト100%成功、analyze エラーゼロ
- [ ] **UX要件**: 直感的な操作フロー、適切なエラー表示
- [ ] **パフォーマンス**: メモリリーク無し、応答性良好
- [ ] **アーキテクチャ**: 既存パターン準拠、保守性確保

---

**推定実装時間: 6.5時間**
**難易度: 中級**
**リスク: 低**（既存パターン活用、実績あるプラグイン使用）