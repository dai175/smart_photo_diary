# Phase 1 基盤準備 - 分析結果レポート

## 実施日時
- 開始: 2025年1月15日
- 完了: 2025年1月15日
- 所要時間: 約30分

## 📋 分析結果サマリー

### ✅ 完了したタスク
- [x] 既存コードの詳細分析を完了する
- [x] home_screen.dartのTabController使用箇所を特定する
- [x] home_content_widget.dartのタブ関連ロジックを特定する
- [x] PhotoSelectionControllerの使用状況を確認する
- [x] 新しいタイムライン用データ構造を設計する
- [x] 日付グルーピング仕様を詳細化する
- [x] 写真取得ロジックの統一仕様を作成する
- [x] FAB統合仕様の詳細設計を完了する
- [x] 既存テストケースの実行・確認をする
- [x] テスト用のモックデータを準備する

### 📊 テスト環境確認
- **テスト実行結果**: 800+ テストケースが100%成功
- **品質保証**: 既存機能への影響なし確認済み

## 🔍 既存コード分析結果

### 1. TabController使用箇所（home_screen.dart）
```dart
// 削除対象の箇所
Line 39:  late final TabController _tabController;           // 宣言
Line 57:  _tabController = TabController(length: 2, vsync: this);  // 初期化
Line 68:  _tabController.dispose();                          // dispose
Line 275: tabController: _tabController,                     // Widget渡し
Line 340: animation: _tabController,                         // AnimatedBuilder
Line 342: _tabController.index == 0                          // 条件分岐
```

### 2. タブ関連ロジック（home_content_widget.dart）
```dart
// 削除対象の主要箇所
Line 33:   final TabController tabController;               // プロパティ
Line 76:   widget.tabController.addListener(_handleTabChange);  // リスナー
Line 189-220: TabBar実装                                    // タブUI
Line 227-231: TabBarView実装                                // タブコンテンツ
Line 363:   widget.tabController,                           // アニメーション制御
Line 366-368: アクティブコントローラー決定ロジック
```

### 3. PhotoSelectionController分析
```dart
// 活用可能な機能
- 日付制限機能: _enableDateRestriction（過去写真で使用中）
- 選択状態管理: toggleSelect、clearSelection
- 使用済み写真管理: setUsedPhotoIds、isPhotoUsed
- 視覚的フィードバック: canSelectPhoto（opacity制御用）
```

**現在の使用パターン**:
- `_photoController`: 今日の写真用（日付制限なし）
- `_pastPhotoController`: 過去の写真用（日付制限あり）

**統合後の設計**: 単一コントローラーで日付制限を常時有効化

## 🏗️ 設計仕様

### 1. タイムライン用データ構造
```dart
class TimelinePhotoGroup {
  final String displayName;       // "今日", "昨日", "2025年1月"
  final DateTime groupDate;       // グループを代表する日付
  final TimelineGroupType type;   // 今日/昨日/月単位
  final List<AssetEntity> photos; // そのグループの写真リスト
}

enum TimelineGroupType {
  today,      // 今日
  yesterday,  // 昨日  
  monthly,    // 月単位
}
```

### 2. タイムライン管理サービス
```dart
class TimelineGroupingService {
  List<TimelinePhotoGroup> groupPhotosForTimeline(List<AssetEntity> photos);
  String getTimelineHeader(DateTime date, TimelineGroupType type);
  bool shouldShowDimmed(AssetEntity photo, DateTime? selectedDate);
}
```

### 3. 日付グルーピングルール
```dart
// 今日: その日撮影された写真
if (isSameDate(photo.createDateTime, today)) {
  displayName = "今日";
  type = TimelineGroupType.today;
}
// 昨日: 昨日撮影された写真  
else if (isSameDate(photo.createDateTime, yesterday)) {
  displayName = "昨日";
  type = TimelineGroupType.yesterday;
}
// それ以前: 月単位でグルーピング
else {
  displayName = "${photo.createDateTime.year}年${photo.createDateTime.month}月";
  type = TimelineGroupType.monthly;
}
```

### 4. 写真取得ロジック統一仕様
```dart
class UnifiedPhotoService {
  Future<List<AssetEntity>> getTimelinePhotos() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // プランに応じた過去日数を取得
    final plan = await _getCurrentPlan();
    final daysBack = plan?.pastPhotoAccessDays ?? 365;
    final startDate = todayStart.subtract(Duration(days: daysBack));
    
    // 今日を含む全期間の写真を取得
    final endDate = todayStart.add(Duration(days: 1));
    
    return await photoService.getPhotosInDateRange(
      startDate: startDate,
      endDate: endDate,
      limit: 1000, // タイムライン表示用の上限
    );
  }
}
```

### 5. スマートFAB設計
```dart
class SmartFABController extends ChangeNotifier {
  final PhotoSelectionController _photoController;
  
  SmartFABState get currentState {
    return _photoController.selectedCount > 0 
        ? SmartFABState.createDiary 
        : SmartFABState.camera;
  }
  
  IconData get icon => currentState == SmartFABState.camera 
      ? Icons.photo_camera_rounded 
      : Icons.auto_awesome_rounded;
      
  String get tooltip => currentState == SmartFABState.camera
      ? '写真を撮影'
      : '${_photoController.selectedCount}枚で日記を作成';
}
```

### 6. 視覚的フィードバック仕様
- **写真未選択時**: 全ての写真が通常表示で選択可能
- **写真選択時**: 選択した日付以外の写真は薄い表示（`opacity: 0.3`）で選択不可を明示
- **同一日付制限**: 既存の`PhotoSelectionController.canSelectPhoto()`で判定

## 🔧 技術的実装方針

### 活用する既存コンポーネント
- **OptimizedPhotoGridWidget**: 遅延読み込みとキャッシュ機能を継承
- **PhotoSelectionController**: 日付制限機能をそのまま活用
- **既存のFAB撮影処理**: `_capturePhoto`メソッドを移植

### 新規実装が必要な要素
- **CustomScrollView + Sliver構造**: タイムライン表示
- **SliverPersistentHeader**: スティッキー日付ヘッダー  
- **TimelineGroupingService**: 写真の日付グルーピング
- **SmartFABController**: 状態に応じたFAB制御

## 📋 Phase 2 実装準備

### 削除対象（Phase 4で実施）
```dart
// home_screen.dart
- late final TabController _tabController;
- _tabController = TabController(length: 2, vsync: this);
- _tabController.dispose();
- FAB表示の条件分岐（_tabController.index == 0）

// home_content_widget.dart  
- TabBar実装（Line 189-220）
- TabBarView実装（Line 227-231）
- タブリスナー処理（_handleTabChange）
- 最近の日記セクション（_buildRecentDiariesSection）
- カレンダー関連機能
```

### 実装優先順位
1. **Phase 2**: TimelinePhotoWidget基本実装
2. **Phase 3**: SmartFAB統合  
3. **Phase 4**: 既存機能削除
4. **Phase 5**: 統合・テスト

## 🎯 成功要因

### 低リスク要因
1. **既存コンポーネント活用**: `OptimizedPhotoGridWidget`等を再利用
2. **段階的実装**: Phase分けによる安全な移行
3. **機能削減中心**: 新機能追加ではなく簡素化
4. **100%テスト成功維持**: 品質保証体制が整備済み

### リスク対策
1. **写真探索困難**: 月単位グルーピングで緩和
2. **操作混乱**: tooltipとアニメーションでガイド  
3. **パフォーマンス**: 既存の遅延読み込みで対応

## 📈 次のステップ

Phase 2の基本統合実装に向けて、以下の準備が完了：

- [x] 設計仕様確定
- [x] 既存コード影響箇所特定
- [x] テスト環境確認  
- [x] 実装方針策定

**Phase 2開始準備完了** - チェックリストに従って`TimelinePhotoWidget`の実装から開始可能です。