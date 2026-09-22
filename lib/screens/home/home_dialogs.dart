part of '../home_screen.dart';

// ---------------------------------------------------------------------------
// _HomeScreenState ダイアログ系メソッド (mixin)
// ---------------------------------------------------------------------------

mixin _HomeDialogsMixin on State<HomeScreen> {
  _HomeScreenState get _self => this as _HomeScreenState;

  void _showLockedPhotoModal() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => CustomDialog(
        icon: Icons.lock_open_rounded,
        iconColor: Theme.of(dialogContext).colorScheme.primary,
        title: dialogContext.l10n.lockedPhotoDialogTitle,
        message: dialogContext.l10n.lockedPhotoDialogMessage,
        onClose: () => Navigator.of(dialogContext).pop(),
        actions: [
          CustomDialogAction(
            text: dialogContext.l10n.settingsUpgradeToPremium,
            isPrimary: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await UpgradeDialogUtils.showUpgradeDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSelectionLimitModal() {
    _showSimpleDialog(
      context.l10n.photoSelectionLimitMessage(AppConstants.maxPhotosSelection),
    );
  }

  void _showUsedPhotoModal() {
    _showSimpleDialog(context.l10n.photoUsedPhotoMessage);
  }

  void _showDifferentDateModal() {
    _showSimpleDialog(context.l10n.photoDifferentDateMessage);
  }

  void _showSimpleDialog(String message) {
    DialogUtils.showSimpleDialog(context, message);
  }

  Future<void> _showLimitedAccessDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          icon: Icons.photo_library_outlined,
          iconColor: AppColors.secondary,
          title: context.l10n.homeLimitedAccessTitle,
          message: context.l10n.homeLimitedAccessMessage,
          onClose: () => Navigator.of(context).pop(),
          actions: [
            CustomDialogAction(
              text: context.l10n.photoSelectAction,
              isPrimary: true,
              onPressed: () async {
                Navigator.of(context).pop();
                // Result is intentionally not checked here — fire and forget
                await _self._photoService.presentLimitedLibraryPicker();
                _self._dataLoader.loadTodayPhotos();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCaptureSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.cameraCaptureSuccess),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
