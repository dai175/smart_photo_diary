import 'package:flutter/material.dart';
import '../component_constants.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BottomSheetConstants.handleWidth,
      height: BottomSheetConstants.handleHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(BottomSheetConstants.handleRadius),
      ),
    );
  }
}
