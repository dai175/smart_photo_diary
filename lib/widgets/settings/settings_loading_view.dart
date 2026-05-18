import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/loading_state_card.dart';

class SettingsLoadingView extends StatelessWidget {
  const SettingsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height:
              MediaQuery.sizeOf(context).height *
              AppConstants.loadingCenterHeightRatio,
        ),
        Center(
          child: LoadingStateCard(
            title: context.l10n.settingsLoadingTitle,
            subtitle: context.l10n.settingsLoadingSubtitle,
          ),
        ),
      ],
    );
  }
}
