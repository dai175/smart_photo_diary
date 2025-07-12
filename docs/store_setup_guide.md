# Store Setup Guide

## Overview

This guide provides the In-App Purchase product configuration for Smart Photo Diary on both iOS (App Store Connect) and Android (Google Play Console).

## Product Configuration

### 1. Premium Monthly Plan

#### iOS (App Store Connect)
- **Product ID**: `smart_photo_diary_premium_monthly_plan`
- **Product Type**: Auto-Renewable Subscription
- **Price**: ¥300/month
- **Subscription Group**: Smart Photo Diary Premium
- **Duration**: 1 month

#### Android (Google Play Console)
- **Product ID**: `smart_photo_diary_premium_monthly_plan`
- **Product Type**: Subscription
- **Price**: ¥300/month
- **Base Plan**: premium_monthly_base
- **Billing Period**: P1M (1 month)

#### Product Names
- **Japanese**: Smart Photo Diary Premium 月額プラン
- **English**: Smart Photo Diary Premium Monthly

#### Product Description

**Japanese**:
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

**English**:
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

### 2. Premium Yearly Plan

#### iOS (App Store Connect)
- **Product ID**: `smart_photo_diary_premium_yearly_plan`
- **Product Type**: Auto-Renewable Subscription
- **Price**: ¥2,800/year
- **Subscription Group**: Smart Photo Diary Premium
- **Duration**: 1 year

#### Android (Google Play Console)
- **Product ID**: `smart_photo_diary_premium_yearly_plan`
- **Product Type**: Subscription
- **Price**: ¥2,800/year
- **Base Plan**: premium_yearly_base
- **Billing Period**: P1Y (1 year)

#### Product Names
- **Japanese**: Smart Photo Diary Premium 年額プラン
- **English**: Smart Photo Diary Premium Yearly

#### Product Description

**Japanese**:
```
年間1200回のAI日記生成とプレミアム機能をお得な年額プランで。

含まれる機能：
• 年間1200回のAI日記生成（月100回相当）
• ライティングプロンプト機能
• 高度なフィルタ・検索機能
• タグベース検索
• 日付範囲指定検索
• 時間帯フィルタ
• データエクスポート（複数形式）
• 優先カスタマーサポート
• 統計・分析ダッシュボード

月額プランより約22%お得。いつでもキャンセル可能です。
```

**English**:
```
Access 1200 AI diary generations per year and premium features with savings.

Included features:
• Up to 1200 AI diary generations per year (equivalent to 100/month)
• Writing prompt assistance
• Advanced filtering and search
• Tag-based search
• Date range search
• Time filter
• Data export (multiple formats)
• Priority customer support
• Statistics and analytics dashboard

Save ~22% compared to monthly plan. Cancel anytime.
```

## Regional Pricing

### Monthly Plan
- **Japan**: ¥300
- **United States**: $2.99
- **European Union**: €2.99
- **United Kingdom**: £2.99
- **Canada**: CAD $3.99
- **Australia**: AUD $4.49

### Yearly Plan
- **Japan**: ¥2,800
- **United States**: $28.99
- **European Union**: €28.99
- **United Kingdom**: £28.99
- **Canada**: CAD $38.99
- **Australia**: AUD $43.99

## Setup Instructions

### iOS (App Store Connect)

1. **Navigate to**: App Store Connect > Apps > Smart Photo Diary > Features > In-App Purchases
2. **Create Subscription Group**: "Smart Photo Diary Premium"
3. **Add Monthly Subscription**:
   - Product ID: `smart_photo_diary_premium_monthly_plan`
   - Reference Name: Premium Monthly Plan
   - Duration: 1 month
   - Price: ¥300 (Tier 3)
4. **Add Yearly Subscription**:
   - Product ID: `smart_photo_diary_premium_yearly_plan`
   - Reference Name: Premium Yearly Plan
   - Duration: 1 year
   - Price: ¥2,800 (Tier 23)
5. **Configure Localization**: Add Japanese and English descriptions
6. **Submit for Review**: Both products must be approved before going live

### Android (Google Play Console)

1. **Navigate to**: Google Play Console > Smart Photo Diary > Monetize > Products > Subscriptions
2. **Create Monthly Subscription**:
   - Product ID: `smart_photo_diary_premium_monthly_plan`
   - Base plan ID: `premium_monthly_base`
   - Billing period: Monthly (P1M)
   - Price: ¥300
3. **Create Yearly Subscription**:
   - Product ID: `smart_photo_diary_premium_yearly_plan`
   - Base plan ID: `premium_yearly_base`
   - Billing period: Yearly (P1Y)
   - Price: ¥2,800
4. **Configure Localization**: Add Japanese and English descriptions
5. **Activate Products**: Enable both subscriptions for production

## Testing

### iOS
- Use Sandbox environment with test Apple IDs
- Test subscription purchase, renewal, and cancellation flows
- Verify receipt validation

### Android
- Use License testing with test Google accounts
- Test subscription flows in internal testing track
- Verify Google Play Billing integration

## Important Notes

### iOS Specific
- Products must be submitted for App Review approval
- Subscription groups allow users to upgrade/downgrade between plans
- StoreKit 2 compatibility ensured with `in_app_purchase: 3.1.10`

### Android Specific
- Subscriptions must be activated in Google Play Console
- Base plans define the core subscription structure
- Grace periods and account hold settings can be configured

### Both Platforms
- Free trial periods are not currently implemented
- Auto-renewal is enabled by default
- Users can cancel subscriptions at any time through platform settings