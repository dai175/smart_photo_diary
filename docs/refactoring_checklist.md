# Smart Photo Diary リファクタリングチェックリスト

このドキュメントは、Smart Photo Diaryプロジェクトのリファクタリング作業を体系的に実行するためのチェックリストです。

## 概要

- **作成日**: 2025-08-16
- **対象ブランチ**: `feature/cleanup`
- **推定作業時間**: 40-60時間
- **テストカバレッジ維持**: 100%必須

---

## 最優先 (緊急) 🔥

### 1. Result<T>パターンの全面移行

**概要**: エラーハンドリングの統一による安定性向上

**現状分析**:
- ✅ SettingsService: 実装済み
- ✅ SubscriptionService: 実装済み  
- ✅ AiService: 実装済み
- ✅ DiaryService: 実装完了
- ❌ PhotoService: 未実装
- ❌ StorageService: 部分実装

**作業項目**:

#### DiaryService移行
- [x] DiaryServiceInterfaceにResult<T>メソッド追加
- [x] getAllDiaries()をResult<List<DiaryEntry>>に変更
- [x] saveDiary()をResult<DiaryEntry>に変更
- [x] deleteDiary()をResult<void>に変更
- [x] updateDiary()をResult<DiaryEntry>に変更
- [x] searchDiaries()をResult<List<DiaryEntry>>に変更
- [x] 呼び出し元の更新（DiaryScreenController、統計画面等）
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/diary_service_*`

#### PhotoService移行
- [x] PhotoServiceInterfaceにResult<T>メソッド追加
- [x] getPhotos()をResult<List<AssetEntity>>に変更
- [x] requestPermission()をResult<PermissionState>に変更
- [x] loadMorePhotos()をResult<List<AssetEntity>>に変更
- [x] 写真関連Controllerの更新
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/photo_service_*`

#### StorageService移行
- [x] StorageServiceInterfaceの作成
- [x] exportData()をResult<String?>に変更
- [x] getStorageInfo()をResult<StorageInfo>に変更
- [x] optimizeDatabase()をResult<bool>に変更
- [x] 呼び出し元の更新（settings_screen.dart）
- [x] ServiceLocator登録の更新
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/storage_service_test.dart`

**完了条件**:
- [x] 全テストが緑（800+テスト100%成功維持） ✅ **達成済み**
- [x] `fvm flutter analyze`でエラーなし ✅ **達成済み**
- [ ] 例外ベースのエラーハンドリングが全て除去 🔄 **進行中（Result<T>移行完了）**
- [ ] 132箇所のthrow/Exception使用箇所を50箇所以下に削減 📊 **現状178箇所→目標継続**

---

### 2. Deprecated API(@Deprecated)の除去

**場所**: `lib/services/settings_service.dart:158`

**作業項目**:
- [x] `getPlanPeriodInfo()`メソッドの削除
- [x] 呼び出し元の調査: `grep -r "getPlanPeriodInfo(" lib/`
- [x] 全ての呼び出し元を`getPlanPeriodInfoV2()`に更新
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/settings_service_*`

**完了条件**:
- [x] @Deprecated アノテーションが完全除去 ✅ **達成済み**
- [x] 全テストが成功 ✅ **達成済み**
- [x] `fvm flutter analyze`でエラーなし ✅ **達成済み**

---

## 高優先度 ⚡

### 3. サービス初期化パターンの統一

**現状**:
- ✅ 全サービスがServiceLocator経由でアクセス可能
- ✅ 依存関係が明確化され、循環依存が排除
- ✅ 初期化順序が最適化

**作業項目**:

#### ServiceLocator統一パターンへの移行
- [x] `lib/core/service_registration.dart`の現状分析
- [x] 全サービスのServiceLocator登録パターン統一
- [x] DiaryServiceのgetInstance()パターンを段階的廃止
- [x] SettingsServiceの初期化パターン統一
- [x] 各サービスのファクトリメソッド標準化

#### 依存関係の明確化
- [x] サービス間依存関係のドキュメント化
- [x] 循環依存の排除
- [x] 初期化順序の最適化

**完了条件**:
- [x] 全サービスがServiceLocator経由でアクセス可能 ✅ **達成済み**
- [x] 初期化パターンが統一 ✅ **達成済み**
- [x] テストでのモック化が容易 ✅ **達成済み**
- [x] 全テストが成功 ✅ **達成済み**

---

### 4. TODOコメントの解決

**場所**:
- `lib/ui/components/animated_button.dart`
- `lib/services/settings_service.dart`

**作業項目**:
- [ ] `grep -r "TODO\|FIXME\|HACK" lib/`で全TODO箇所を特定
- [ ] 各TODOの内容分析と優先度付け
- [ ] 実装可能なTODOの解決
- [ ] 不要なTODOの削除
- [ ] 長期TODOのissue化

**完了条件**:
- [ ] TODOコメントが5個以下に削減
- [ ] 残存TODOが適切にドキュメント化
- [ ] 全テストが成功

---

## 中優先度 📝

### 5. インターフェース命名規則の統一

**現状混在**:
- `ISubscriptionService` (Iプレフィックス)
- `PhotoServiceInterface` (Interfaceサフィックス)
- `AiServiceInterface` (Interfaceサフィックス)

**作業項目**:

#### 命名規則の決定
- [ ] プロジェクト標準命名規則の決定（推奨: Interfaceサフィックス）
- [ ] アーキテクチャドキュメントの更新

#### インターフェースリネーム
- [ ] `ISubscriptionService` → `SubscriptionServiceInterface`
- [ ] `IPromptService` → `PromptServiceInterface`
- [ ] 全ての実装クラスの更新
- [ ] インポート文の更新
- [ ] 関連テストの更新

**完了条件**:
- [ ] 命名規則が完全統一
- [ ] 全テストが成功
- [ ] `fvm flutter analyze`でエラーなし

---

### 6. 状態管理パターンの最適化

**現状**: 6つのControllerで24箇所のsetState/notifyListeners

**作業項目**:

#### 現状分析
- [ ] 各Controllerの責務分析
- [ ] 状態管理の重複箇所特定
- [ ] パフォーマンスボトルネック調査

#### 最適化実装
- [ ] 重複状態の統合
- [ ] リアクティブ性の向上
- [ ] Riverpod/Provider移行の検討（オプション）
- [ ] 状態更新の最適化

**完了条件**:
- [ ] setState/notifyListeners使用箇所が20個以下
- [ ] パフォーマンス改善が確認される
- [ ] 全テストが成功

---

## 低優先度（長期課題） 📋

### 7. 写真ウィジェットの統合

**対象ウィジェット**:
- OptimizedPhotoGridWidget
- PhotoGridWidget  
- PastPhotoCalendarWidget

**作業項目**:
- [ ] 各ウィジェットの機能分析
- [ ] 共通部分の抽出
- [ ] 統合ウィジェット設計
- [ ] 段階的統合実装
- [ ] パフォーマンステスト

**完了条件**:
- [ ] 重複コードが50%以上削減
- [ ] 機能性が維持される
- [ ] パフォーマンスが改善

---

### 8. UIコンポーネント設計システム強化

**作業項目**:
- [ ] 現在の設計システム分析
- [ ] コンポーネントライブラリの拡張
- [ ] デザイントークンの標準化
- [ ] ドキュメント化

**完了条件**:
- [ ] 設計システムが完全ドキュメント化
- [ ] 新規コンポーネントの追加が容易

---

## 作業実行ガイドライン

### 前提条件
- [ ] 現在のブランチ: `feature/cleanup`
- [ ] 全テスト成功確認: `fvm flutter test`
- [ ] 静的解析クリア: `fvm flutter analyze`
- [ ] フォーマット適用: `fvm dart format .`

### 各段階での必須チェック
- [ ] テスト実行: `fvm flutter test`
- [ ] 静的解析: `fvm flutter analyze`  
- [ ] フォーマット: `fvm dart format .`
- [ ] 機能動作確認
- [ ] パフォーマンステスト

### 完了条件
- [ ] 全800+テストが成功（100%維持）
- [ ] 静的解析エラーゼロ
- [ ] コードフォーマット準拠
- [ ] 機能回帰なし
- [ ] パフォーマンス改善または維持

---

## 進捗追跡

### 週次目標
- **Week 1**: Result<T>移行（DiaryService） ✅ **完了**
- **Week 2**: Result<T>移行（PhotoService、StorageService） ✅ **完了**
- **Week 3**: ServiceLocator統一、Deprecated API除去 ✅ **完了**
- **Week 4**: TODO解決、命名規則統一
- **Week 5**: 状態管理最適化
- **Week 6-8**: 低優先度項目（オプション）

### 完了チェック
- [ ] 全最優先項目完了
- [ ] 全高優先度項目完了
- [ ] 中優先度項目50%以上完了
- [ ] ドキュメント更新
- [ ] チームレビュー完了
- [ ] リリース準備完了

---

**最終更新**: 2025-08-16 (Week 3: ServiceLocator統一完了)  
**レビュー者**: [担当者名]  
**承認日**: [承認日]