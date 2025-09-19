import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/design_system/app_spacing.dart';

const double _radioDialogMaxWidth = 360;
const double _radioTileOpacity = 0.12;

/// ダイアログ表示のユーティリティクラス
class DialogUtils {
  /// 簡単なメッセージダイアログを表示
  ///
  /// [context]: BuildContext
  /// [message]: 表示するメッセージ
  static Future<void> showSimpleDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          message: message,
          actions: [
            CustomDialogAction(
              text: AppConstants.okButton,
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  /// 成功メッセージダイアログを表示
  ///
  /// [context]: BuildContext
  /// [title]: ダイアログのタイトル
  /// [message]: 表示するメッセージ
  static Future<void> showSuccessDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return PresetDialogs.success(
          title: title,
          message: message,
          onConfirm: () => Navigator.pop(context),
        );
      },
    );
  }

  /// エラーメッセージダイアログを表示
  ///
  /// [context]: BuildContext
  /// [message]: 表示するエラーメッセージ
  /// [title]: ダイアログのタイトル（デフォルト: 'エラー'）
  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    String title = 'エラー',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return PresetDialogs.error(
          title: title,
          message: message,
          onConfirm: () => Navigator.pop(context),
        );
      },
    );
  }

  /// 確認ダイアログを表示
  ///
  /// [context]: BuildContext
  /// [title]: ダイアログのタイトル
  /// [message]: 確認メッセージ
  /// [confirmText]: 確認ボタンのテキスト（デフォルト: 'OK'）
  /// [cancelText]: キャンセルボタンのテキスト（デフォルト: 'キャンセル'）
  /// [isDestructive]: 確認アクションが破壊的操作かどうか（テキストを赤色にする）
  /// 戻り値: ユーザーが確認した場合true、キャンセルした場合false
  static Future<bool?> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'OK',
    String cancelText = 'キャンセル',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PresetDialogs.confirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }

  /// ローディングダイアログを表示
  ///
  /// [context]: BuildContext
  /// [message]: ローディング中に表示するメッセージ
  /// 戻り値: ダイアログを閉じるためのNavigator.pop用のFuture
  static Future<void> showLoadingDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PresetDialogs.loading(message: message);
      },
    );
  }

  /// ラジオボタン選択ダイアログを表示
  ///
  /// [context]: BuildContext
  /// [title]: ダイアログのタイトル
  /// [options]: 選択肢のリスト
  /// [currentValue]: 現在選択されている値
  /// [onChanged]: 選択が変更された時のコールバック
  /// [getLabel]: 選択肢のラベルを取得する関数
  static Future<T?> showRadioSelectionDialog<T>(
    BuildContext context,
    String title,
    List<T> options,
    T? currentValue,
    String Function(T) getLabel,
  ) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        T? selectedValue = currentValue;
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return CustomDialog(
              title: title,
              maxWidth: _radioDialogMaxWidth,
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(options.length, (index) {
                  final option = options[index];
                  final isSelected = option == selectedValue;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == options.length - 1 ? 0 : AppSpacing.xs,
                    ),
                    child: RadioListTile<T>(
                      title: Text(
                        getLabel(option),
                        style: theme.textTheme.bodyLarge,
                      ),
                      value: option,
                      groupValue: selectedValue,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadiusSm,
                        ),
                      ),
                      tileColor: theme.colorScheme.surfaceVariant.withValues(
                        alpha: _radioTileOpacity,
                      ),
                      selectedTileColor: theme.colorScheme.primary.withValues(
                        alpha: _radioTileOpacity,
                      ),
                      selected: isSelected,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value;
                        });
                        Navigator.pop(context, value);
                      },
                    ),
                  );
                }),
              ),
              actions: [
                CustomDialogAction(
                  text: 'キャンセル',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
