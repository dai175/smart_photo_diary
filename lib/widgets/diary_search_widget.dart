import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DiarySearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchStart;
  final VoidCallback onSearchStop;
  final VoidCallback onSearchClear;
  final bool isSearching;

  const DiarySearchWidget({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchStart,
    required this.onSearchStop,
    required this.onSearchClear,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: isSearching
          ? TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: 'タイトルや本文を検索...',
                hintStyle: TextStyle(
                  color: colorScheme.onPrimary.withValues(
                    alpha: AppConstants.opacityMedium,
                  ),
                ),
                border: InputBorder.none,
              ),
              onChanged: onSearchChanged,
            )
          : const Text('日記一覧'),
      backgroundColor: colorScheme.primary,
      leading: isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onSearchStop,
            )
          : null,
      actions: isSearching
          ? [
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onSearchClear,
                ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: onSearchStart,
              ),
            ],
      foregroundColor: colorScheme.onPrimary,
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      elevation: 0,
    );
  }
}
