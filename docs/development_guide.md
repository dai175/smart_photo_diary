# 開発ガイド

## 環境構築

### 必要なツール
- Flutter SDK（最新安定版）
- Dart SDK（Flutterに同梱）
- Android Studio または Xcode（エミュレータ/実機デバッグ用）
- FVM（推奨）: Flutter Version Management

### セットアップ手順

```bash
# リポジトリをクローン
git clone https://github.com/your-username/smart_photo_diary.git
cd smart_photo_diary

# FVMを利用している場合（推奨）
fvm flutter pub get

# コード生成（Hiveアダプター）
fvm dart run build_runner build

# アプリを起動
fvm flutter run
```

### 環境変数設定

```bash
# .envファイルを作成（ルートディレクトリ）
# Google Gemini APIキーを設定（日記生成用）
GEMINI_API_KEY=your_api_key_here
```

## 開発コマンド

### 基本コマンド
```bash
# 依存関係の取得
fvm flutter pub get

# コード生成（Hiveモデル）
fvm dart run build_runner build

# 強制再生成（競合解決）
fvm dart run build_runner build --delete-conflicting-outputs

# アプリ実行
fvm flutter run

# ホットリロード対応（開発中）
# r キー: ホットリロード
# R キー: ホットリスタート
```

### テスト実行
```bash
# 全テスト実行（133テスト、100%成功率）
fvm flutter test

# ユニットテストのみ
fvm flutter test test/unit/

# ウィジェットテストのみ
fvm flutter test test/widget/

# 統合テストのみ
fvm flutter test test/integration/

# 特定のテストファイル
fvm flutter test test/unit/services/diary_service_mock_test.dart

# カバレッジ付きテスト
fvm flutter test --coverage

# 詳細出力
fvm flutter test --reporter expanded

# JSON出力（CI用）
fvm flutter test --reporter json
```

### ビルド・リリース
```bash
# デバッグビルド
fvm flutter build apk --debug

# リリースビルド
fvm flutter build apk --release
fvm flutter build appbundle

# プラットフォーム別ビルド
fvm flutter build macos
fvm flutter build windows
fvm flutter build linux
fvm flutter build ipa  # iOS (Macのみ)

# APKインストール
adb install build/app/outputs/flutter-apk/app-release.apk

# アプリ起動
adb shell am start -n com.example.smart_photo_diary/.MainActivity
```

### コード品質
```bash
# 静的解析（設定済み: 0 issues維持）
fvm flutter analyze

# コード整形
fvm dart format .

# 依存関係確認
fvm flutter pub outdated
```

## コーディング規約

### 命名規則
- **クラス名・ウィジェット**: PascalCase（例: `PhotoPicker`）
- **変数・関数**: camelCase（例: `getUserPhotos`）
- **定数**: UPPER_SNAKE_CASE（例: `MAX_PHOTOS`）
- **ファイル名**: snake_case（例: `photo_picker.dart`）

### コメント規則
- **ドキュメントコメント**: `///` を使用
- **ビジネスロジック**: 日本語コメント推奨
- **複雑なアルゴリズム**: 日本語での詳細説明

### コード品質要件
- Flutter analyze: 0 issues必須
- テスト成功率: 100%維持
- 型安全なDartコード
- const コンストラクタの積極利用

## アーキテクチャガイドライン

### サービス層設計
```dart
// インターフェース定義
abstract class ServiceInterface {
  Future<Result<T>> operation();
}

// 実装クラス
class ServiceImpl implements ServiceInterface {
  // 依存性注入による疎結合
}
```

### エラーハンドリング
```dart
// Result<T>パターンの使用
Future<Result<DiaryEntry>> saveDiary(DiaryEntry entry) async {
  try {
    // 処理実装
    return Result.success(savedEntry);
  } catch (e) {
    return Result.failure(ServiceException('保存に失敗しました'));
  }
}

// UIでの使用
result.fold(
  onSuccess: (entry) => showSuccess('保存完了'),
  onFailure: (error) => showError(error.message),
);
```

### 新機能開発パターン
1. **Result<T>パターン必須**: 新機能はすべてResult<T>を使用
2. **インターフェース設計**: テスタビリティ重視
3. **依存性注入**: ServiceLocator経由でのサービス取得
4. **テストファースト**: 実装前にテスト作成

## テスト戦略

### テスト分類
```bash
# Unit Tests: 純粋ロジック（モック使用）
test/unit/services/           # サービス層テスト
test/unit/models/            # データモデルテスト
test/unit/core/              # コア機能テスト

# Widget Tests: UIコンポーネント
test/widget/                 # ウィジェット単体テスト

# Integration Tests: E2Eフロー
test/integration/            # 統合テスト
```

### テストベストプラクティス
- **モックファースト**: 外部依存は必ずモック
- **インターフェーステスト**: 実装ではなくインターフェースをテスト
- **分離原則**: 各テストは独立して実行可能
- **Result<T>テスト**: 成功・失敗両パターンをテスト

## Git ワークフロー

### ブランチ戦略
- `main`: 安定版ブランチ
- `feature/xxx`: 機能開発ブランチ
- `fix/xxx`: バグ修正ブランチ

### コミットメッセージ
フォーマット: `type(scope): メッセージ`

```bash
# 例
feat(ai): Google Gemini API統合
fix(ui): ダークテーマでの文字視認性改善
refactor(service): 依存性注入パターン適用
test(diary): 日記生成フローテスト追加
docs: アーキテクチャドキュメント更新
```

### プルリクエスト手順
1. 機能ブランチ作成 (`git checkout -b feature/xxx`)
2. 実装とテスト作成
3. コード品質チェック (`fvm flutter analyze`)
4. テスト実行 (`fvm flutter test`)
5. プッシュとPR作成
6. コードレビュー
7. マージ

## 開発環境特記事項

### 日本語対応
- **ロケール設定**: MaterialApp で `ja_JP` 設定済み
- **フォント最適化**: 中華フォント回避設定
- **ローカライゼーション**: flutter_localizations 統合

### パフォーマンス監視
- **画像最適化**: デバイスピクセル比対応
- **RepaintBoundary**: 適切な配置
- **メモリ効率**: 画像キャッシュ最適化

### デバッグツール
- **フォントデバッグ**: `/debug/font_debug_screen.dart`
- **ログ出力**: LoggingService による構造化ログ
- **エラー追跡**: ErrorDisplayService

## トラブルシューティング

### よくある問題
1. **コード生成エラー**: `fvm dart run build_runner clean` 後に再実行
2. **権限エラー**: AndroidManifest.xml の権限設定確認
3. **フォント問題**: 日本語ロケール設定確認
4. **テスト失敗**: モックの初期化確認

### デバッグコマンド
```bash
# 依存関係の問題
fvm flutter clean
fvm flutter pub get

# ビルド問題
fvm flutter build apk --verbose

# テスト詳細
fvm flutter test --reporter expanded
```

## リリース準備

### チェックリスト
- [ ] テスト成功率100%確認
- [ ] Flutter analyze: 0 issues確認
- [ ] バージョン番号更新（pubspec.yaml）
- [ ] CHANGELOG.md 更新
- [ ] リリースビルド確認

### デプロイ
```bash
# バージョンタグ
git tag v1.0.0
git push origin v1.0.0

# リリースビルド
fvm flutter build apk --release
fvm flutter build appbundle  # Google Play用
```

この開発ガイドに従うことで、高品質で保守性の高いコードを効率的に開発できます。