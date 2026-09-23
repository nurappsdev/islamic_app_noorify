import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/qiblah_compass/domain/qiblah_bearing.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/widgets/qiblah_compass_dial.dart';

enum _CompassAccess {
  checking,
  ready,
  serviceDisabled,
  permissionDenied,
  unsupported,
}

/// Full-screen live Qiblah compass, opened from [HomeProgressSection]'s
/// "View Full Screen" button (design `img_41.png`). [qiblahAngle] is the
/// bearing (degrees clockwise from true north) `GET /home/dashboard`
/// already resolved for the user; this screen adds the live device heading
/// on top of it via `flutter_compass` and reads back how far to turn.
class QiblahCompassScreen extends StatefulWidget {
  const QiblahCompassScreen({super.key, required this.qiblahAngle});

  final double qiblahAngle;

  @override
  State<QiblahCompassScreen> createState() => _QiblahCompassScreenState();
}

class _QiblahCompassScreenState extends State<QiblahCompassScreen>
    with WidgetsBindingObserver {
  _CompassAccess _access = _CompassAccess.checking;
  StreamSubscription<CompassEvent>? _subscription;
  double? _heading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Location services/permission are commonly changed from the OS
    // settings screen this widget can send the user to below.
    final awaitingSettings =
        _access == _CompassAccess.serviceDisabled ||
        _access == _CompassAccess.permissionDenied;
    if (state == AppLifecycleState.resumed && awaitingSettings) {
      _init();
    }
  }

  Future<void> _init() async {
    if (FlutterCompass.events == null) {
      if (mounted) setState(() => _access = _CompassAccess.unsupported);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _access = _CompassAccess.serviceDisabled);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _access = _CompassAccess.permissionDenied);
      return;
    }

    await _subscription?.cancel();
    _subscription = FlutterCompass.events!.listen((event) {
      if (!mounted || event.heading == null) return;
      setState(() {
        _heading = event.heading;
        _access = _CompassAccess.ready;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 56.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: HomeCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          appText.kiblahCompassTitle,
          style: homeSansStyle(
            context: context,
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              _CompassBody(
                access: _access,
                qiblahAngle: widget.qiblahAngle,
                heading: _heading,
                onRetry: _init,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassBody extends StatelessWidget {
  const _CompassBody({
    required this.access,
    required this.qiblahAngle,
    required this.heading,
    required this.onRetry,
  });

  final _CompassAccess access;
  final double qiblahAngle;
  final double? heading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    if (access == _CompassAccess.checking) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: AppColor.primary),
      );
    }
    if (access == _CompassAccess.serviceDisabled) {
      return _AccessMessage(
        message: appText.compassLocationServicesDisabled,
        actionLabel: appText.compassEnableLocation,
        onAction: () => Geolocator.openLocationSettings(),
      );
    }
    if (access == _CompassAccess.permissionDenied) {
      return _AccessMessage(
        message: appText.compassPermissionDenied,
        actionLabel: appText.compassOpenSettings,
        onAction: () => Geolocator.openAppSettings(),
      );
    }
    if (access == _CompassAccess.unsupported) {
      return _AccessMessage(message: appText.compassUnsupported);
    }

    // `heading` is always non-null once `access` reaches `ready` (both are
    // set together on the first compass event).
    final relativeAngle = relativeQiblahBearing(qiblahAngle, heading!);
    final direction = relativeAngle < 0
        ? appText.compassDirectionLeft
        : appText.compassDirectionRight;
    final chipText =
        '${appText.kiblahLabel} ${relativeAngle.round()}° $direction';

    return Column(
      children: [
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: context.lineColor(AppColor.primary)),
          ),
          child: Text(
            chipText,
            style: homeSansStyle(context: context, fontSize: 13.sp),
          ),
        ),
        SizedBox(height: 36.h),
        QiblahCompassDial(
          qiblahAngle: qiblahAngle,
          heading: heading!,
          size: 300.w,
        ),
      ],
    );
  }
}

class _AccessMessage extends StatelessWidget {
  const _AccessMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80.h, left: 24.w, right: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: 48.sp,
            color: context.appPalette.textPrimary.withValues(alpha: 0.4),
          ),
          SizedBox(height: 14.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: homeSansStyle(context: context, fontSize: 14.sp),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 18.h),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
