# TestFlightビルド・配布完全ガイド

## 概要

Smart Photo DiaryアプリをTestFlightでテスト配布するための完全な手順書です。開発からテスター配布まで、段階的に説明します。

## 🚀 前提条件

### 必要なアカウント・ツール
- **Apple Developer Program**への登録（年額$99）
- **App Store Connect**アクセス権限
- **Xcode**（最新版推奨）
- **Transporter**アプリ（Mac App Store）
- **開発者証明書**と**プロビジョニングプロファイル**

### 環境設定確認
```bash
# Flutter環境確認
fvm flutter doctor

# プロジェクトの依存関係確認
fvm flutter pub get

# コード解析（エラー0件であることを確認）
fvm flutter analyze
```

## 📱 方法1: 自動ビルド + Transporter（推奨）

### Step 1: IPAファイル自動生成

```bash
# TestFlight用IPAファイル生成
./scripts/testflight_build.sh
```

**実行結果例**：
```
🚀 TestFlight用ビルド開始...
📱 iOS リリースビルド実行中...
✅ IPAファイル生成完了
📍 配布可能ファイル: build/ios/ipa/Smart Photo Diary.ipa
```

### Step 2: Transporterでアップロード

#### 2.1 Transporterアプリのインストール
```
1. Mac App Store を開く
2. 「Transporter」で検索
3. Apple公式のTransporterをダウンロード・インストール
```

#### 2.2 TestFlightアップロード
```
1. Transporter を起動
2. Apple ID でサインイン（開発者アカウント）
3. メイン画面の「+」ボタンをクリック
4. 「Smart Photo Diary.ipa」ファイルを選択
   ファイル場所: build/ios/ipa/Smart Photo Diary.ipa
5. 「Deliver」ボタンをクリック
6. アップロード完了まで待機（数分〜数十分）
```

## 🛠 方法2: Xcodeワークフロー（従来方式）

### Step 1: Xcode用準備

```bash
# APIキー付きでXcode準備
./scripts/prepare_xcode.sh
```

### Step 2: Xcodeでアーカイブ

```
1. Xcode で ios/Runner.xcworkspace を開く
2. デバイス選択で「Any iOS Device (arm64)」を選択
3. Product → Archive を実行
4. アーカイブ完了まで待機（数分）
```

### Step 3: App Store Connect配布

```
1. アーカイブ完了後、Organizer が自動で開く
2. 最新のアーカイブを選択
3. 「Distribute App」ボタンをクリック
4. 配布方法選択:
   - 「App Store Connect」を選択
   - 「Upload」を選択
5. 証明書・プロファイル確認画面で「Next」
6. 「Upload」ボタンでアップロード開始
```

## 📋 App Store Connect設定

### TestFlight設定手順

#### 1. App Store Connectにアクセス
```
1. https://appstoreconnect.apple.com にアクセス
2. 開発者アカウントでサインイン
3. 「マイApp」→「Smart Photo Diary」を選択
```

#### 2. TestFlightタブ設定
```
1. 「TestFlight」タブをクリック
2. アップロード完了したビルドが表示されるまで待機
3. ビルド処理状況:
   - アップロード中: 黄色のプログレスバー
   - 処理中: 「処理中」ステータス表示
   - 完了: 「テスト準備完了」ステータス
```

#### 3. テスター招待設定

**内部テスター設定**:
```
1. TestFlight → 内部テスト
2. 「内部テスターを管理」をクリック
3. チームメンバーを追加
4. テスト対象ビルドを選択
5. 「保存」をクリック
```

**外部テスター設定**:
```
1. TestFlight → 外部テスト
2. 「新しいグループを作成」または既存グループ選択
3. テスターのメールアドレスを追加
4. テスト対象ビルドを選択
5. 「テストの詳細」を入力:
   - テストの内容
   - フィードバック依頼事項
6. Apple審査待ち（外部テストの場合）
```

## 🔧 トラブルシューティング

### よくある問題と解決方法

#### 1. ビルドエラー

**エラー: 証明書が見つからない**
```
解決方法:
1. Xcode → Preferences → Accounts
2. Apple ID 追加・更新
3. 証明書の自動管理を有効化
4. または手動で証明書をダウンロード
```

**エラー: プロビジョニングプロファイルが無効**
```
解決方法:
1. Apple Developer Portal でプロファイル確認
2. Bundle ID が正しいか確認: com.focuswave.dev.smartPhotoDiary
3. 証明書の有効期限確認
4. 新しいプロファイルを生成
```

#### 2. アップロードエラー

**エラー: Transporterでアップロード失敗**
```
解決方法:
1. インターネット接続確認
2. Apple ID の認証情報確認
3. App用パスワード生成・使用
4. ファイルサイズ・形式確認
```

**エラー: バンドルIDが一致しない**
```
解決方法:
1. App Store Connect でアプリ設定確認
2. Xcode プロジェクト設定確認
3. Bundle ID: com.focuswave.dev.smartPhotoDiary で統一
```

#### 3. TestFlight処理エラー

**ビルドが「処理中」で止まる**
```
解決方法:
1. 24-48時間待機（通常の処理時間）
2. App Store Connect ステータス確認
3. Apple Developer Support 問い合わせ
```

**テスターに通知が届かない**
```
解決方法:
1. テスターのメールアドレス確認
2. スパムフォルダ確認
3. テスター招待の再送信
4. TestFlightアプリのインストール確認
```

## 📊 ビルド成功チェックリスト

### アップロード前確認事項
- [ ] Flutterプロジェクトのエラー0件（`flutter analyze`）
- [ ] 全テスト成功（`flutter test`）
- [ ] APIキーが正しく設定されている
- [ ] Bundle IDが正しい（com.focuswave.dev.smartPhotoDiary）
- [ ] 証明書・プロファイルが有効
- [ ] バージョン番号が適切に設定されている

### アップロード後確認事項
- [ ] App Store Connect でビルド表示確認
- [ ] ビルド処理完了確認
- [ ] TestFlightでのテスト設定完了
- [ ] 内部テスターへの配布設定
- [ ] テスター招待メール送信確認

## 🚀 自動化スクリプト詳細

### 利用可能なスクリプト

#### `testflight_build.sh`
```bash
# 完全自動IPAビルド
./scripts/testflight_build.sh

# 機能:
# - API キー自動設定
# - リリースビルド実行
# - IPA ファイル生成
# - 後続手順の案内表示
```

#### `prepare_xcode.sh`
```bash
# Xcode Archive準備
./scripts/prepare_xcode.sh

# 機能:
# - API キー設定
# - Xcode用準備ビルド
# - Archive手順の案内表示
```

#### `upload_testflight.sh`
```bash
# TestFlightアップロード支援
./scripts/upload_testflight.sh

# 機能:
# - IPA ファイル存在確認
# - Apple ID 認証情報入力
# - altool コマンドでアップロード
# - エラー時の解決策提示
```

## 📋 定期的なテスト配布ワークフロー

### 週次リリースの例

```bash
# 1. 開発完了後の品質チェック
fvm flutter test
fvm flutter analyze

# 2. TestFlight用ビルド
./scripts/testflight_build.sh

# 3. Transporterでアップロード
# （手動でTransporterアプリ使用）

# 4. App Store Connect でテスター配布
# （ウェブ管理画面で設定）
```

### リリース管理のベストプラクティス

1. **バージョン管理**:
   - セマンティックバージョニング使用
   - ビルド番号の自動増加
   - リリースノートの記録

2. **テスター管理**:
   - 内部テスター: 開発チーム
   - 外部テスター: ベータユーザー
   - フィードバック収集の仕組み

3. **品質保証**:
   - 自動テストの100%成功
   - 手動テストシナリオの実行
   - パフォーマンステスト

## 🔗 参考リンク

- [Apple Developer Documentation - TestFlight](https://developer.apple.com/testflight/)
- [App Store Connect ヘルプ - TestFlight](https://help.apple.com/app-store-connect/#/devdc42b26b8)
- [Transporter ユーザーガイド](https://help.apple.com/app-store-connect/#/dev2cd126805)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

## 📞 サポート

問題が発生した場合:

1. **技術的問題**: Apple Developer Support
2. **App Store Connect**: App Store Connect サポート
3. **Flutter関連**: Flutter コミュニティ・ドキュメント

---

**最終更新**: 2025年7月12日  
**対象バージョン**: Smart Photo Diary v1.0.0  
**Flutter版**: 3.32.0