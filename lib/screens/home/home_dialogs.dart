part of '../home_screen.dart';

// ---------------------------------------------------------------------------
// _HomeScreenState ダイアログ系メソッド (mixin)
// ---------------------------------------------------------------------------

mixin _HomeDialogsMixin on State<HomeScreen> {
  _HomeScreenState get _self => this as _HomeScreenState;

  void _showSelectionLimitModal() {
    _showSimpleDialog(
      context.l10n.photoSelectionLimitMessage(AppConstants.maxPhotosSelection),
    );
  }

  void _showUsedPhotoModal() {
    _showSimpleDialog(context.l10n.photoUsedPhotoMessage);
  }

  void _showSimpleDialog(String message) {
    DialogUtils.showSimpleDialog(context, message);
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          icon: Icons.photo_library_outlined,
          iconColor: AppColors.warning,
          title: context.l10n.homePermissionDialogTitle,
          message: context.l10n.homePermissionDialogMessage,
          actions: [
            CustomDialogAction(
              text: context.l10n.commonCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomDialogAction(
              text: context.l10n.commonOpenSettings,
              isPrimary: true,
              icon: Icons.settings_rounded,
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLimitedAccessDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          icon: Icons.photo_library_outlined,
          iconColor: AppColors.info,
          title: context.l10n.homeLimitedAccessTitle,
          message: context.l10n.homeLimitedAccessMessage,
          actions: [
            CustomDialogAction(
              text: context.l10n.commonLater,
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomDialogAction(
              text: context.l10n.photoSelectAction,
              isPrimary: true,
              icon: Icons.add_photo_alternate_rounded,
              onPressed: () async {
                Navigator.of(context).pop();
                final photoService = ServiceRegistration.get<IPhotoService>();
                await photoService.presentLimitedLibraryPicker();
                _self._loadTodayPhotos();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCameraPermissionDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        icon: Icons.camera_alt_outlined,
        iconColor: Theme.of(context).colorScheme.primary,
        title: context.l10n.cameraPermissionDialogTitle,
        message: context.l10n.cameraPermissionDialogMessage,
        actions: [
          CustomDialogAction(
            text: context.l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomDialogAction(
            text: context.l10n.commonOpenSettings,
            isPrimary: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
          ),
        ],
      ),
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
