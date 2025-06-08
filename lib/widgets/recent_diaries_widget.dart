import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/diary_entry.dart';

/// 最近の日記表示ウィジェット
class RecentDiariesWidget extends StatelessWidget {
  final List<DiaryEntry> recentDiaries;
  final bool isLoading;
  final Function(String) onDiaryTap;

  const RecentDiariesWidget({
    super.key,
    required this.recentDiaries,
    required this.isLoading,
    required this.onDiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppConstants.smallPadding),
        _buildContent(context),
      ],
    );
  }

  Widget _buildHeader() {
    return const Text(
      AppConstants.recentDiariesTitle,
      style: TextStyle(
        fontSize: AppConstants.cardTitleFontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (recentDiaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(AppConstants.noDiariesMessage),
        ),
      );
    }

    return Column(
      children: recentDiaries
          .map((diary) => _buildDiaryCard(context, diary))
          .toList(),
    );
  }

  Widget _buildDiaryCard(BuildContext context, DiaryEntry diary) {
    final title = diary.title.isNotEmpty ? diary.title : '無題';

    return GestureDetector(
      onTap: () => onDiaryTap(diary.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: ThemeConstants.defaultCardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateLabel(diary.date),
            const SizedBox(height: 6),
            _buildTitle(context, title),
            const SizedBox(height: 4),
            _buildDiaryContent(context, diary.content),
          ],
        ),
      ),
    );
  }

  Widget _buildDateLabel(DateTime date) {
    return Text(
      DateFormat('yyyy年MM月dd日').format(date),
      style: const TextStyle(
        color: Colors.purple,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: AppConstants.defaultPadding,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDiaryContent(BuildContext context, String content) {
    return Text(
      content,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: AppConstants.bodyFontSize,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}