# カメラ機能実装チェックリスト

## 概要
ホーム画面から直接写真を撮影する機能を追加する実装計画です。既存のアーキテクチャ（ServiceLocator、Result<T>パターン）と統合し、エラーハンドリングとログ出力を統一します。

## 実装フェーズ

### フェーズ1: 依存関係とパッケージの追加
- [x] `pubspec.yaml`に`image_picker: ^1.0.7`パッケージを追加
  - 既存の`photo_manager`と併用してカメラ機能を追加
  - `wechat_camera_picker`も代替選択肢として検討可能
- [x] iOS Info.plist にカメラ使用許可の記述追加 (`NSCameraUsageDescription`)
- [x] Android AndroidManifest.xml にカメラ権限追加 (`CAMERA`)
- [x] `fvm flutter pub get`で依存関係を更新

### フェーズ2: サービス層の拡張
- [x] `IPhotoServiceInterface`にカメラ撮影用メソッドを追加
  - [x] `Future<Result<AssetEntity?>> capturePhoto()`
  - [x] `Future<Result<bool>> requestCameraPermission()`
  - [x] `Future<Result<bool>> isCameraPermissionDenied()`
- [x] `PhotoService`に`image_picker`を使用したカメラ機能実装
  - [x] ImagePickerクラスのインスタンス化
  - [x] カメラ撮影メソッドの実装
  - [x] Result<T>パターンを使用したエラーハンドリング
  - [x] LoggingServiceを使用したログ出力
- [x] 権限管理の拡張
  - [x] カメラ権限のリクエスト処理
  - [x] 権限状態の判定ロジック

### フェーズ3: UI層の実装
- [x] `HomeContentWidget`にカメラ撮影ボタンを追加
  - [x] FloatingActionButton またはカメラアイコンボタン
  - [x] 既存の写真選択エリアとの統合
- [x] カメラ権限関連のダイアログ実装
  - [x] カメラ権限リクエストダイアログ
  - [x] 権限拒否時の説明ダイアログ
  - [x] 設定アプリへの誘導機能
- [ ] 撮影後の写真処理フロー
  - [ ] 撮影した写真を写真選択コントローラーに追加
  - [ ] UIの更新とフィードバック表示

### フェーズ4: エラーハンドリングと UX 改善
- [ ] カメラ使用不可時の適切なエラー表示
- [ ] ネットワーク不要な機能であることの確認
- [ ] 撮影キャンセル時の適切な処理
- [ ] ローディング状態の表示

### フェーズ5: テストの追加
- [ ] `PhotoService`のカメラ機能のユニットテスト
  - [ ] カメラ撮影成功時のテスト
  - [ ] 権限拒否時のエラーハンドリングテスト
  - [ ] キャンセル時のテスト
- [ ] `HomeContentWidget`のウィジェットテスト
  - [ ] カメラボタンの表示テスト
  - [ ] カメラボタンタップ時の動作テスト
- [ ] 統合テストの追加
  - [ ] カメラ機能全体のフローテスト

### フェーズ6: コード品質とドキュメント
- [ ] `fvm flutter analyze`でコード品質チェック
- [ ] `fvm dart format .`でコードフォーマット
- [ ] 新機能の動作確認
- [ ] 既存機能への影響がないことの確認

## 技術仕様詳細

### 使用パッケージ
- `image_picker: ^1.0.7`: カメラ撮影とギャラリー選択（推奨）
  - 標準的な選択肢で、iOSとAndroidで確実に動作
  - `XFile`形式で撮影結果を返す
- 既存の`photo_manager`: 撮影後の写真管理とAssetEntity変換に使用
- 既存の`permission_handler`: カメラ権限管理に使用
- **代替候補**: `wechat_camera_picker` - `photo_manager`と統合されたカメラ機能

### アーキテクチャ統合
- **ServiceLocator**: `IPhotoService`経由でのカメラ機能アクセス
- **Result<T>パターン**: 全ての非同期処理で型安全なエラーハンドリング
- **LoggingService**: 統一されたログ出力
- **既存のPhotoSelectionController**: 撮影写真の選択状態管理

### UI/UX設計
- **カメラボタン配置**: ホーム画面の写真選択エリア内に配置
- **権限フロー**: 初回使用時に権限リクエスト、拒否時は説明と設定誘導
- **フィードバック**: 撮影中のローディング、成功・失敗の適切な通知

### エラーケース対応
- カメラが利用できないデバイス
- カメラ権限の拒否
- 撮影のキャンセル
- ディスク容量不足
- その他のシステムエラー

## 完了条件
- [ ] 全てのテストが通過（100%成功率維持）
- [ ] `fvm flutter analyze`で警告・エラーなし
- [ ] 既存機能に影響がないことを確認
- [ ] カメラ機能が正常に動作することを確認
- [ ] ドキュメントとコメントが適切に更新されている

## 注意事項
- iPhone専用アプリのため、iOS固有の権限処理に注意
- 既存の写真管理フローとの整合性を保つ
- Result<T>パターンの一貫した使用
- LoggingServiceを使用した適切なログ出力
- セキュリティ：カメラで撮影した写真の適切な取り扱い