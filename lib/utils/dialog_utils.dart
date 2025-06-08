import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// ダイアログ表示のユーティリティクラス
class DialogUtils {
  /// 簡単なメッセージダイアログを表示
  /// 
  /// [context]: BuildContext
  /// [message]: 表示するメッセージ
  static Future<void> showSimpleDialog(
    BuildContext context,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppConstants.okButton),
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
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.okButton),
            ),
          ],
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
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.okButton),
            ),
          ],
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: isDestructive ? const TextStyle(color: Colors.red) : null,
            ),
          ),
        ],
      ),
    );
  }

  /// ローディングダイアログを表示
  /// 
  /// [context]: BuildContext
  /// [message]: ローディング中に表示するメッセージ
  /// 戻り値: ダイアログを閉じるためのNavigator.pop用のFuture
  static Future<void> showLoadingDialog(
    BuildContext context,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppConstants.defaultPadding),
              Flexible(child: Text(message)),
            ],
          ),
        );
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
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return RadioListTile<T>(
                    title: Text(getLabel(option)),
                    value: option,
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                      });
                      Navigator.pop(context, value);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// リスト選択ダイアログを表示
  /// 
  /// [context]: BuildContext
  /// [title]: ダイアログのタイトル
  /// [items]: 表示するアイテムのリスト
  /// [itemBuilder]: アイテムを構築するビルダー関数
  static Future<void> showListSelectionDialog<T>(
    BuildContext context,
    String title,
    List<T> items,
    Widget Function(BuildContext, T, int) itemBuilder,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return itemBuilder(context, items[index], index);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }
}