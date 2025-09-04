import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/writing_prompt.dart';
import '../widgets/prompt_selection_modal.dart';
import '../screens/diary_preview_screen.dart';
import '../services/logging_service.dart';
import '../core/service_registration.dart';

/// 日記作成処理を管理するサービス
/// スマートFABから日記作成機能を呼び出すための統一インターフェース
class DiaryCreationService {
  static const DiaryCreationService _instance =
      DiaryCreationService._internal();

  factory DiaryCreationService() => _instance;

  const DiaryCreationService._internal();

  /// 写真選択から日記作成までの統合フローを開始
  Future<void> startDiaryCreation({
    required BuildContext context,
    required List<AssetEntity> selectedPhotos,
  }) async {
    try {
      final logger = ServiceRegistration.get<LoggingService>();

      logger.info(
        '日記作成開始（スマートFABから）',
        context: 'DiaryCreationService.startDiaryCreation',
        data: '選択写真数: ${selectedPhotos.length}',
      );

      if (selectedPhotos.isEmpty) {
        logger.warning(
          '日記作成: 写真が選択されていません',
          context: 'DiaryCreationService.startDiaryCreation',
        );
        return;
      }

      // プロンプト選択モーダルを表示
      await _showPromptSelectionModal(context, selectedPhotos);
    } catch (e) {
      final logger = ServiceRegistration.get<LoggingService>();
      logger.error(
        '日記作成処理中にエラーが発生',
        context: 'DiaryCreationService.startDiaryCreation',
        error: e,
      );
    }
  }

  /// プロンプト選択モーダルを表示
  Future<void> _showPromptSelectionModal(
    BuildContext context,
    List<AssetEntity> selectedPhotos,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PromptSelectionModal(
        onPromptSelected: (prompt) {
          Navigator.of(context).pop();
          _navigateToDiaryPreview(context, selectedPhotos, prompt);
        },
        onSkip: () {
          Navigator.of(context).pop();
          _navigateToDiaryPreview(context, selectedPhotos, null);
        },
      ),
    );
  }

  /// 日記プレビュー画面に遷移
  void _navigateToDiaryPreview(
    BuildContext context,
    List<AssetEntity> selectedPhotos,
    WritingPrompt? selectedPrompt,
  ) {
    final logger = ServiceRegistration.get<LoggingService>();

    logger.info(
      '日記プレビュー画面に遷移',
      context: 'DiaryCreationService._navigateToDiaryPreview',
      data:
          'プロンプト: ${selectedPrompt?.text ?? "なし"}, 写真数: ${selectedPhotos.length}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: selectedPhotos,
          selectedPrompt: selectedPrompt,
        ),
      ),
    );
  }
}
