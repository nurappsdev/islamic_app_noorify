import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/update/app_update_service.dart';
import 'package:tuhfatul_muslim/core/update/app_update_texts.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// One prompt at a time: the launch check and the "download finished" signal
/// can both ask for the dialog, and an open one already moves itself on to
/// the right step.
///
/// Set as the dialog is asked for, and cleared by whichever comes first - the
/// card going away or the route's own future - so a navigator torn down from
/// under an open dialog cannot leave the flag stuck on.
bool _isDialogVisible = false;

/// Whether the update dialog is on screen.
bool get isAppUpdateDialogVisible => _isDialogVisible;

/// Shows the Google Play update prompt.
///
/// It starts on the "Update Now / Later" step, or - with [readyToInstall] -
/// straight on the restart step for an update that was downloaded earlier.
/// "Later" holds the prompt back for three days; "Update Now" starts the
/// background download and the card follows it to the restart. Does nothing
/// when a prompt is already showing.
Future<void> showAppUpdateDialog(
  BuildContext context, {
  bool readyToInstall = false,
}) async {
  if (_isDialogVisible) return;
  _isDialogVisible = true;
  final language = context.read<LanguageBloc>().state.language;
  try {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppUpdateTexts.later.resolve(language),
      barrierColor: Colors.black.withValues(alpha: .55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, animation, _, _) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .85, end: 1).animate(curved),
            child: _AppUpdateCard(
              language: language,
              readyToInstall: readyToInstall,
            ),
          ),
        );
      },
    );
  } finally {
    _isDialogVisible = false;
  }
}

/// The step the card is on.
enum _UpdateStep { available, downloading, ready }

class _AppUpdateCard extends StatefulWidget {
  const _AppUpdateCard({required this.language, required this.readyToInstall});

  final AppLanguage language;
  final bool readyToInstall;

  @override
  State<_AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<_AppUpdateCard> {
  final AppUpdateService _service = AppUpdateService.instance;

  late _UpdateStep _step = widget.readyToInstall
      ? _UpdateStep.ready
      : _UpdateStep.available;

  /// Shown under the message when Play could not download or install. A user
  /// who turns Play's own consent sheet down is not told anything: they just
  /// get the offer back.
  bool _failed = false;

  /// Keeps "Update Now" from starting a second download while Play's consent
  /// sheet is still up.
  bool _isStarting = false;

  /// Set while Play installs: on success the app restarts, so the button
  /// keeps its spinner until it does.
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _service.status.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _service.status.removeListener(_onStatusChanged);
    _isDialogVisible = false;
    super.dispose();
  }

  void _onStatusChanged() {
    if (!mounted) return;
    switch (_service.status.value) {
      case InstallStatus.downloaded:
        setState(() {
          _step = _UpdateStep.ready;
          _failed = false;
        });
      case InstallStatus.pending:
      case InstallStatus.downloading:
        setState(() {
          _step = _UpdateStep.downloading;
          _failed = false;
        });
      case InstallStatus.failed:
      case InstallStatus.canceled:
        // Back to the offer, so the user can try again from the same card.
        setState(() {
          _step = _UpdateStep.available;
          _failed = _service.status.value == InstallStatus.failed;
        });
      case InstallStatus.unknown:
      case InstallStatus.installing:
      case InstallStatus.installed:
        break;
    }
  }

  Future<void> _onUpdateNow() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
      _failed = false;
    });
    // Play's future resolves only once the download is done; the steps in
    // between arrive through the service's status instead.
    final result = await _service.startDownload();
    if (!mounted) return;
    setState(() {
      _isStarting = false;
      _failed = result == AppUpdateResult.inAppUpdateFailed;
    });
  }

  Future<void> _onLater() async {
    await _service.remindLater();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onInstall() async {
    if (_isInstalling) return;
    setState(() {
      _isInstalling = true;
      _failed = false;
    });
    final installed = await _service.install();
    if (!mounted) return;
    // On success the app is restarting into the new build; only a refusal
    // leaves anything to say.
    setState(() {
      _isInstalling = false;
      _failed = !installed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ink = context.inkColor(AppColor.lightTextStrong);
    final (title, message) = switch (_step) {
      _UpdateStep.available => (AppUpdateTexts.title, AppUpdateTexts.message),
      _UpdateStep.downloading => (
        AppUpdateTexts.downloadingTitle,
        AppUpdateTexts.downloadingMessage,
      ),
      _UpdateStep.ready => (
        AppUpdateTexts.readyTitle,
        AppUpdateTexts.readyMessage,
      ),
    };

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330.w),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: EdgeInsets.only(top: 38.h, left: 24.w, right: 24.w),
                padding: EdgeInsets.fromLTRB(22.w, 54.h, 22.w, 22.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: .35),
                      blurRadius: 32.r,
                      offset: Offset(0, 14.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.resolve(widget.language),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.authLogo,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      message.resolve(widget.language),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    if (_step == _UpdateStep.downloading) ...[
                      SizedBox(height: 20.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: LinearProgressIndicator(
                          minHeight: 6.h,
                          backgroundColor: context.surfaceColor(
                            AppColor.lightProgressTrack,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColor.authLogo,
                          ),
                        ),
                      ),
                    ],
                    if (_failed) ...[
                      SizedBox(height: 14.h),
                      Text(
                        AppUpdateTexts.downloadFailed.resolve(widget.language),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColor.forgotPassword,
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    _buildActions(),
                  ],
                ),
              ),
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC5D077), AppColor.authLogo],
                  ),
                  border: Border.all(
                    color: context.surfaceColor(Colors.white),
                    width: 5.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.authLogo.withValues(alpha: .45),
                      blurRadius: 18.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Icon(
                  switch (_step) {
                    _UpdateStep.available => Icons.system_update_rounded,
                    _UpdateStep.downloading => Icons.cloud_download_rounded,
                    _UpdateStep.ready => Icons.restart_alt_rounded,
                  },
                  color: Colors.white,
                  size: 36.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    switch (_step) {
      // The download runs on its own: the only thing left to offer is getting
      // out of the way until it is done.
      case _UpdateStep.downloading:
        return _OutlinedAction(
          label: AppUpdateTexts.keepBrowsing.resolve(widget.language),
          onPressed: () => Navigator.pop(context),
        );
      case _UpdateStep.available:
        return Row(
          children: [
            Expanded(
              child: _OutlinedAction(
                label: AppUpdateTexts.later.resolve(widget.language),
                onPressed: _onLater,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _FilledAction(
                label: AppUpdateTexts.updateNow.resolve(widget.language),
                icon: Icons.download_rounded,
                busy: _isStarting,
                onPressed: _isStarting ? null : _onUpdateNow,
              ),
            ),
          ],
        );
      case _UpdateStep.ready:
        return Row(
          children: [
            Expanded(
              child: _OutlinedAction(
                label: AppUpdateTexts.later.resolve(widget.language),
                onPressed: _isInstalling
                    ? null
                    : () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _FilledAction(
                label: AppUpdateTexts.restartAndInstall.resolve(
                  widget.language,
                ),
                icon: Icons.restart_alt_rounded,
                busy: _isInstalling,
                onPressed: _isInstalling ? null : _onInstall,
              ),
            ),
          ],
        );
    }
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(48.h),
        foregroundColor: AppColor.authLogo,
        side: const BorderSide(color: AppColor.primary, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FilledAction extends StatelessWidget {
  const _FilledAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFFB7C36B), AppColor.authLogo],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.authLogo.withValues(alpha: .4),
            blurRadius: 12.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: busy
            ? SizedBox(
                width: 18.sp,
                height: 18.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18.sp),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(48.h),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}
