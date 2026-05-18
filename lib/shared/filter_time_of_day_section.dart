import 'package:flutter/material.dart';
import '../models/diary_filter.dart';
import '../ui/design_system/app_spacing.dart';
import '../localization/localization_extensions.dart';
import 'filter_selection_chip.dart';

class FilterTimeOfDaySection extends StatelessWidget {
  const FilterTimeOfDaySection({
    super.key,
    required this.selectedPeriods,
    required this.onPeriodToggled,
  });

  final Set<TimeOfDayPeriod> selectedPeriods;
  final ValueChanged<TimeOfDayPeriod> onPeriodToggled;

  List<MapEntry<TimeOfDayPeriod, String>> _entries(BuildContext context) {
    final l10n = context.l10n;
    return [
      MapEntry(TimeOfDayPeriod.morning, '🌅 ${l10n.filterTimeSlotMorning}'),
      MapEntry(TimeOfDayPeriod.noon, '☀️ ${l10n.filterTimeSlotNoon}'),
      MapEntry(TimeOfDayPeriod.evening, '🌆 ${l10n.filterTimeSlotEvening}'),
      MapEntry(TimeOfDayPeriod.night, '🌙 ${l10n.filterTimeSlotNight}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _entries(context).map((entry) {
        return FilterSelectionChip(
          key: ValueKey(entry.key),
          label: entry.value,
          isSelected: selectedPeriods.contains(entry.key),
          onTap: () => onPeriodToggled(entry.key),
        );
      }).toList(),
    );
  }
}
