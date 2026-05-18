import 'package:flutter/material.dart';

import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';

/// 日記エントリが存在する日付のカレンダーセル
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xxs),
      decoration: const BoxDecoration(
        color: AppColors.calEntryBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}
