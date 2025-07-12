# In-App Purchase 設定・テストガイド

Smart Photo DiaryアプリのIn-App Purchase機能の設定からテストまでの完全ガイドです。

## 目次

1. [概要](#概要)
2. [App Store Connect設定](#app-store-connect設定)
3. [In-App Purchase商品作成](#in-app-purchase商品作成)
4. [アプリ側実装確認](#アプリ側実装確認)
5. [TestFlightでのテスト](#testflightでのテスト)
6. [トラブルシューティング](#トラブルシューティング)

## 概要

### Smart Photo Diary の収益化戦略

**フリーミアムモデル**
- **Basic プラン**: 無料（月10回のAI生成）
- **Premium プラン**: 有料（月100回のAI生成 + ライティングプロンプト）

**価格設定**
- **月額**: ¥300
- **年額**: ¥2,800（22%割引）

### 必要な設定項目

1. **Apple Developer Program**: 有効な開発者アカウント
2. **App Store Connect**: 契約・税務・銀行情報
3. **In-App Purchase商品**: 月額・年額プラン
4. **アプリコード**: Product ID設定
5. **TestFlight**: Sandbox環境でのテスト

## App Store Connect設定

### Step 1: 基本契約の完了

#### Agreements, Tax, and Banking
1. [App Store Connect](https://appstoreconnect.apple.com/) にログイン
2. **Business** タブをクリック
3. **Agreements** セクションを確認

**必須項目:**
- ✅ **Paid Apps Agreement**: `Active` 状態
- ✅ **Tax Forms**: 完了済み
- ✅ **Banking Information**: 設定・承認済み

#### 契約状態の確認
```
Free Apps Agreement: Active ✅
Paid Apps Agreement: Active ✅ (最重要)
```

### Step 2: 税務情報の設定

#### Tax Forms設定
1. **Tax Forms** セクションをクリック
2. **Add Tax Form** → **United States** を選択
3. **W-8BEN Form** を完了：
   - 氏名: `Daisuke Oba`
   - 居住国: `Japan`
   - 住所: 日本の住所
   - 署名・日付

#### 設定完了の確認
```
U.S. Form W-8BEN: Active ✅
U.S. Certificate of Foreign Status: Active ✅
```

### Step 3: 銀行情報の設定

#### Banking Information
1. **Bank Accounts** セクションをクリック
2. **Add Bank Account** をクリック
3. 日本の銀行口座情報を入力：
   - 銀行名: `Saitama Resona Bank`
   - 口座情報
   - 受取人情報

#### 処理完了まで
- **処理時間**: 24時間以内
- **Status**: `Processing` → `Active`

## In-App Purchase商品作成

### Step 1: アプリの基本設定

#### App情報確認
1. **Apps** → **Smart Photo Diary** をクリック
2. **App Information** タブで基本情報確認
3. **Bundle ID**: `com.focuswave.dev.smartPhotoDiary`

### Step 2: In-App Purchase商品の作成

#### 商品作成手順
1. **In-App Purchases** タブをクリック
2. **Create** ボタンをクリック
3. **Type**: `Non-Consumable` を選択

#### 月額プラン設定
```
Reference Name: Premium Monthly Plan
Product ID: smart_photo_diary_monthly
```

#### 年額プラン設定
```
Reference Name: Premium Yearly Plan  
Product ID: smart_photo_diary_yearly
```

### Step 3: 商品詳細の設定

#### 基本情報
- **Family Sharing**: 有効
- **Availability**: 175 Countries or Regions
- **Tax Category**: Match to parent app

#### 価格設定
**月額プラン:**
```
Base Country: Japan (JPY)
Price: ¥300
```

**年額プラン:**
```
Base Country: Japan (JPY)  
Price: ¥2,800
```

#### App Store Localization
**Japanese:**
```
Display Name: プレミアムプラン（月額）
Description: 月100回のAI日記生成と全20種類のライティングプロンプトへのアクセス
```

### Step 4: Review Information

#### 必須設定項目
- **Screenshot**: アプリの課金画面
- **Review Notes**: 日本語での説明文
```
月100回のAI日記生成と全20種類の日記パターンを提供する年間プランです。
月額プランより約23%お得です。
```

## アプリ側実装確認

### Product ID設定

#### constants/subscription_constants.dart
```dart
/// Premium プラン月額の商品ID
static const String premiumMonthlyProductId = 'smart_photo_diary_monthly';

/// Premium プラン年額の商品ID  
static const String premiumYearlyProductId = 'smart_photo_diary_yearly';
```

#### config/in_app_purchase_config.dart
```dart
/// 商品IDからプランを取得
static SubscriptionPlan getSubscriptionPlan(String productId) {
  switch (productId) {
    case 'smart_photo_diary_monthly':
      return SubscriptionPlan.premiumMonthly;
    case 'smart_photo_diary_yearly':
      return SubscriptionPlan.premiumYearly;
    default:
      throw ArgumentError('Unknown product ID: $productId');
  }
}
```

### Bundle ID統一確認

#### iOS設定
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleIdentifier</key>
<string>com.focuswave.dev.smartPhotoDiary</string>
```

#### Xcode Project設定
```
PRODUCT_BUNDLE_IDENTIFIER = com.focuswave.dev.smartPhotoDiary
```

### In-App Purchase実装確認

#### services/subscription_service.dart
- ✅ `in_app_purchase` プラグイン統合
- ✅ Product ID取得機能
- ✅ 購入処理実装
- ✅ 購入復元機能

## TestFlightでのテスト

### Step 1: Sandbox環境設定

#### テスト環境の特徴
- **TestFlight**: 自動的にSandbox環境で動作
- **実課金なし**: 全ての購入はテスト購入
- **サブスクリプション**: 24時間間隔で更新

#### Sandbox Tester設定
1. **App Store Connect** → **Users and Access** → **Sandbox Testers**
2. テスト用Apple IDを使用
3. **重要**: 本番Apple IDは使用しない

### Step 2: In-App Purchase有効化

#### App Version設定
1. **App Information** → **iOS App Version 1.0.0**
2. **In-App Purchases and Subscriptions** セクション（予定）
3. 作成したIn-App Purchaseを選択・有効化

**注意:** この設定が「準備中」問題解決の鍵となります

### Step 3: TestFlightでのテスト実行

#### テスト手順
1. **TestFlightアプリ**で最新ビルドをインストール
2. **プレミアムプラン**ボタンをタップ
3. **期待される結果**:
   - ❌ 「現在、アプリ内課金機能の準備中です」
   - ✅ 実際の購入画面が表示

#### 購入フローテスト
1. **月額プラン (¥300)** をタップ
2. **Touch ID/Face ID** で認証
3. **購入完了**の確認
4. **プレミアム機能**へのアクセス確認

### Step 4: 購入復元テスト

#### 復元機能確認
1. アプリを削除・再インストール
2. **購入復元**ボタンをタップ
3. 以前の購入が復元されることを確認

## トラブルシューティング

### 「準備中」問題

#### 原因と解決方法

**1. Paid Apps Agreement未完了**
```
原因: 契約が Active 状態になっていない
解決: Business → Agreements で契約を完了
```

**2. Tax Forms未完了**
```
原因: W-8BEN Form が未提出
解決: Tax Forms セクションで書類提出
```

**3. Banking Information未設定**
```
原因: 銀行口座情報が未設定
解決: Bank Accounts で口座情報設定
```

**4. Product ID不一致**
```
原因: アプリコードとApp Store Connect設定が不一致
解決: Product ID を統一
```

**5. App Version設定未完了**
```
原因: App VersionでIn-App Purchase未選択
解決: iOS App Version 1.0.0 で商品を有効化
```

### 購入エラー

#### ネットワークエラー
```
エラー: Unable to connect to App Store
原因: ネットワーク接続問題
解決: Wi-Fi/LTE接続確認
```

#### 商品情報取得エラー
```
エラー: Product information not available
原因: Product ID設定ミス
解決: アプリコードとApp Store Connect設定を確認
```

### Sandbox環境問題

#### 購入履歴リセット
```
問題: TestFlightでは購入履歴がリセットできない
対策: 新しいSandbox Testerアカウントを使用
```

#### レシート検証エラー
```
問題: Receipt validation failed
原因: Sandbox環境でのレシート形式違い
対策: Sandbox環境用の検証ロジック使用
```

## 監視・分析

### 購入データ分析

#### App Store Connect Analytics
- **Revenue**: 収益推移
- **Subscriptions**: サブスクリプション数
- **Conversion Rate**: 購入転換率

#### アプリ内分析
- **Premium機能使用率**: ライティングプロンプト利用状況
- **AI生成回数**: プラン別使用パターン
- **ユーザー行動**: アップグレード動機分析

### A/Bテスト候補

#### 価格設定
- 月額: ¥300 vs ¥400
- 年額割引率: 22% vs 30%

#### UI/UX改善
- プレミアム訴求文言
- 購入ボタンデザイン
- 機能比較表示

## ベストプラクティス

### セキュリティ
- [ ] Receipt検証実装
- [ ] 不正購入検知
- [ ] サーバーサイド検証（将来実装）

### ユーザーエクスペリエンス
- [ ] 明確な価格表示
- [ ] 解約手順の案内
- [ ] カスタマーサポート整備

### コンプライアンス
- [ ] 自動更新の明示
- [ ] 利用規約・プライバシーポリシー
- [ ] 地域別法令対応

## 参考リンク

### Apple公式ドキュメント
- [In-App Purchase Programming Guide](https://developer.apple.com/in-app-purchase/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [StoreKit Framework](https://developer.apple.com/documentation/storekit)

### Flutter関連
- [in_app_purchase Plugin](https://pub.dev/packages/in_app_purchase)
- [Flutter In-App Purchase Tutorial](https://docs.flutter.dev/cookbook/plugins/in-app-purchases)

---

**最終更新**: 2025年7月12日  
**バージョン**: 1.0.0  
**担当**: Claude Code Assistant