import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/qiblah_compass/domain/qiblah_bearing.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/widgets/qiblah_compass_dial.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/widgets/qiblah_compass_shimmer.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/widgets/qiblah_heading_listener.dart';

/// Full-screen live Qiblah compass, opened from [HomeProgressSection]'s
/// "View Full Screen" button (design `img_41.png`). [qiblahAngle] is the
/// bearing (degrees clockwise from true north) `GET /home/dashboard`
/// already resolved for the user; [QiblahHeadingListener] adds the live
/// device heading on top of it via `flutter_compass` so this screen can
/// read back how far to turn.
class QiblahCompassScreen extends StatelessWidget {
  const QiblahCompassScreen({super.key, required this.qiblahAngle});

  final double qiblahAngle;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth - 32.w;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: ConstrainedBox(
                // Centers the compass in the available viewport when it
                // fits, and falls back to scrolling instead of overflowing
                // on short screens or with large accessibility text sizes.
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 24.h).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QiblahHeadingListener(
                      builder: (context, access, heading, accuracy) =>
                          _CompassBody(
                            access: access,
                            qiblahAngle: qiblahAngle,
                            heading: heading,
                            accuracy: accuracy,
                            maxWidth: contentWidth,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    required this.accuracy,
    required this.maxWidth,
  });

  final QiblahAccess access;
  final double qiblahAngle;
  final double? heading;

  /// The sensor's estimated error in degrees (lower is better); `null`
  /// means unreliable/unknown, which is also worth a calibration nudge.
  final double? accuracy;

  /// Available width for the dial to size itself within, so it never
  /// overflows on narrow screens.
  final double maxWidth;

  double get _dialSize => 300.w < maxWidth ? 300.w : maxWidth;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    if (access == QiblahAccess.checking) {
      return QiblahCompassShimmer(dialSize: _dialSize);
    }
    if (access == QiblahAccess.serviceDisabled) {
      return _AccessMessage(
        message: appText.compassLocationServicesDisabled,
        actionLabel: appText.compassEnableLocation,
        onAction: () => Geolocator.openLocationSettings(),
      );
    }
    if (access == QiblahAccess.permissionDenied) {
      return _AccessMessage(
        message: appText.compassPermissionDenied,
        actionLabel: appText.compassOpenSettings,
        onAction: () => Geolocator.openAppSettings(),
      );
    }
    if (access == QiblahAccess.unsupported) {
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
      mainAxisSize: MainAxisSize.min,
      children: [
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
          size: _dialSize,
        ),
        if (accuracy == null || accuracy! >= 45) ...[
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              appText.compassCalibrationHint,
              textAlign: TextAlign.center,
              style: homeSansStyle(
                context: context,
                fontSize: 12.sp,
                color: context.appPalette.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
