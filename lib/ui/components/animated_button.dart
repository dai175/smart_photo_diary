/// Smart Photo Diary 統一ボタンシステム
///
/// ## 利用可能なボタンタイプ
///
/// ### プライマリーボタン
/// - `PrimaryButton`: メインアクション用（保存、送信など）
/// - `DangerButton`: 危険な操作用（削除、リセットなど）
///
/// ### セカンダリーボタン
/// - `SecondaryButton`: サブアクション用（境界線あり）
/// - `AccentButton`: アクセント色の強調ボタン
/// - `SurfaceButton`: サーフェス色の控えめなボタン
///
/// ### その他のボタン
/// - `TextOnlyButton`: テキストのみボタン（軽量アクション用）
/// - `IconTextButton`: アイコン+テキストボタン
/// - `SmallButton`: 小さいサイズのボタン
/// - `CircularIconButton`: 丸型アイコンボタン
library;

export 'buttons/animated_button_base.dart';
export 'buttons/primary_button.dart';
export 'buttons/secondary_button.dart';
export 'buttons/accent_button.dart';
export 'buttons/small_button.dart';
export 'buttons/circular_icon_button.dart';
export 'buttons/surface_button.dart';
export 'buttons/danger_button.dart';
export 'buttons/text_only_button.dart';
export 'buttons/icon_text_button.dart';
