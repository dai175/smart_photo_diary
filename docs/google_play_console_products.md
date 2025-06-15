# Google Play Console 商品設定ガイド

## 概要

Smart Photo DiaryのAndroid版In-App Purchase商品設定のためのガイドです。Google Play Consoleで設定する商品情報を定義します。

## 商品一覧

### 1. Premium月額プラン

**商品ID**: `smart_photo_diary_premium_monthly`
**商品タイプ**: サブスクリプション (Subscription)
**価格**: ¥300/月
**サブスクリプションのベース プラン**: premium_monthly_base
**請求期間**: P1M（1か月）

**商品名（日本語）**: Smart Photo Diary Premium 月額プラン
**商品説明（日本語）**:
```
月100回のAI日記生成とプレミアム機能をご利用いただけます。

含まれる機能：
• 月100回までのAI日記生成
• ライティングプロンプト機能
• 高度なフィルタ・検索機能
• タグベース検索
• 日付範囲指定検索
• 時間帯フィルタ
• データエクスポート（複数形式）
• 優先カスタマーサポート
• 統計・分析ダッシュボード

いつでもキャンセル可能です。
```

**商品名（英語）**: Smart Photo Diary Premium Monthly
**商品説明（英語）**:
```
Access 100 AI diary generations per month and premium features.

Included features:
• Up to 100 AI diary generations per month
• Writing prompt assistance
• Advanced filtering and search
• Tag-based search
• Date range search
• Time filter
• Data export (multiple formats)
• Priority customer support
• Statistics and analytics dashboard

Cancel anytime.
```

### 2. Premium年額プラン

**商品ID**: `smart_photo_diary_premium_yearly`
**商品タイプ**: サブスクリプション (Subscription)
**価格**: ¥2,800/年
**サブスクリプションのベース プラン**: premium_yearly_base
**請求期間**: P1Y（1年）

**商品名（日本語）**: Smart Photo Diary Premium 年額プラン
**商品説明（日本語）**:
```
月100回のAI日記生成とプレミアム機能を年額でご利用いただけます。月額プランより22%お得です。

含まれる機能：
• 月100回までのAI日記生成
• ライティングプロンプト機能
• 高度なフィルタ・検索機能
• タグベース検索
• 日付範囲指定検索
• 時間帯フィルタ
• データエクスポート（複数形式）
• 優先カスタマーサポート
• 統計・分析ダッシュボード

年額プランは月額プランより¥800お得です。
いつでもキャンセル可能です。
```

**商品名（英語）**: Smart Photo Diary Premium Yearly
**商品説明（英語）**:
```
Access 100 AI diary generations per month and premium features with yearly billing. Save 22% compared to monthly plan.

Included features:
• Up to 100 AI diary generations per month
• Writing prompt assistance
• Advanced filtering and search
• Tag-based search
• Date range search
• Time filter
• Data export (multiple formats)
• Priority customer support
• Statistics and analytics dashboard

Yearly plan saves ¥800 compared to monthly billing.
Cancel anytime.
```

## サブスクリプショングループ設定

**サブスクリプション グループ**: Smart Photo Diary Premium
**基本プラン優先順位**:
1. Premium年額プラン（高い優先度）
2. Premium月額プラン（標準優先度）

## 無料トライアル設定

**対象商品**: Premium月額プラン、Premium年額プラン両方
**無料トライアル期間**: P7D（7日間）
**無料トライアル価格**: ¥0

**無料トライアルの説明**:
```
7日間無料でPremium機能をお試しいただけます。
トライアル期間中はいつでもキャンセル可能です。
キャンセルしない場合は自動的に有料プランに移行します。
```

## 地域・価格設定

### 日本
- **月額プラン**: ¥300 (JPY)
- **年額プラン**: ¥2,800 (JPY)

### アメリカ
- **月額プラン**: $2.99 (USD)
- **年額プラン**: $28.99 (USD)

### その他主要地域
- **ユーロ圏**: €2.99/月、€28.99/年
- **イギリス**: £2.99/月、£28.99/年
- **カナダ**: CAD$3.99/月、CAD$38.99/年
- **オーストラリア**: AUD$4.49/月、AUD$44.99/年

**価格設定の根拠**:
- 競合他社との価格競争力
- AI APIコストとの収益性バランス
- 地域別購買力を考慮した設定

## プライバシー・セキュリティ設定

**データセーフティ**:
- データの収集: なし
- データの共有: なし
- 暗号化: あり（ローカルデータベース）
- ユーザーデータの削除要求: 対応（ローカルデータのため即座に削除可能）

**アプリのカテゴリ**: ライフスタイル
**コンテンツ レーティング**: 全年齢対象

## テスト設定

### ライセンステスト
**テストアカウント**:
- テスト用Googleアカウントを設定
- 購入テスト、復元テスト、キャンセルテストを実施

### 内部テスト配布
**テスト範囲**:
- 内部テスター（開発チーム）
- クローズドテスト（選定ユーザー）

## 実装チェックリスト

### Google Play Console設定
- [ ] アプリ署名キーの設定
- [ ] サブスクリプション商品作成
  - [ ] Premium月額プラン (smart_photo_diary_premium_monthly)
  - [ ] Premium年額プラン (smart_photo_diary_premium_yearly)
- [ ] 商品説明文設定（日本語・英語）
- [ ] 価格設定（各地域）
- [ ] 無料トライアル設定（7日間）
- [ ] ベースプラン設定
- [ ] サブスクリプション グループ設定

### 契約・収益化
- [ ] Google Play Console開発者アカウント確認
- [ ] 支払いプロファイル設定
- [ ] 税務情報設定
- [ ] 収益レポート設定

### アプリ情報
- [ ] データセーフティフォーム完了
- [ ] コンテンツレーティング取得
- [ ] ターゲット層設定
- [ ] ストアリスティング最適化

### テスト準備
- [ ] 内部テスト版アップロード
- [ ] ライセンステスト設定
- [ ] テストアカウント準備
- [ ] 購入フローテスト実施

## Play Billing Library統合

### 必要なdependencies
```gradle
dependencies {
    implementation 'com.android.billingclient:billing:5.0.0'
    // Flutter plugin
    implementation 'io.flutter.plugins.in_app_purchase'
}
```

### Androidマニフェスト設定
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### ProGuard設定
```
-keep class com.android.vending.billing.**
```

## セキュリティ設定

### サーバーサイド検証
**推奨**: Google Play Developer APIを使用した購入検証
**実装**: 将来のサーバー統合時に検討

### 現在の実装（ローカル検証）
- クライアントサイドでの基本的な購入検証
- トランザクションIDの保存と管理
- 不正購入の基本的な検出

## サポート・トラブルシューティング

### よくある問題

**商品が表示されない**:
- Google Play Consoleでの商品公開状態を確認
- アプリの署名キーが正しいことを確認
- テストアカウントの設定を確認

**購入に失敗する**:
- インターネット接続を確認
- Google Playサービスの状態を確認
- 支払い方法の設定を確認

**復元に失敗する**:
- 同じGoogleアカウントでログインしているか確認
- purchaseTokenの管理を確認

### エラーコード対応
- **BILLING_UNAVAILABLE**: Google Playサービス利用不可
- **ITEM_UNAVAILABLE**: 商品が利用不可
- **USER_CANCELED**: ユーザーによるキャンセル
- **SERVICE_UNAVAILABLE**: 一時的なサービス停止

## コンプライアンス

### Google Play ポリシー準拠
- [ ] デベロッパー プログラム ポリシー確認
- [ ] 支払いポリシー準拠
- [ ] ユーザーデータポリシー準拠
- [ ] コンテンツポリシー準拠

### サブスクリプション要件
- [ ] キャンセル・返金ポリシーの明示
- [ ] 自動更新の明確な説明
- [ ] 価格と請求期間の明示
- [ ] 無料トライアルの条件説明

## 参考ドキュメント

- [Google Play Console ヘルプ](https://support.google.com/googleplay/android-developer/)
- [Play Billing Library](https://developer.android.com/google/play/billing)
- [サブスクリプション設定ガイド](https://developer.android.com/google/play/billing/subscriptions)
- [Google Play ポリシーセンター](https://play.google.com/about/developer-content-policy/)