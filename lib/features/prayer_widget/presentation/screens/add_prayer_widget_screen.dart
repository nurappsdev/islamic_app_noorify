import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_location_service.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/date_labels.dart';
import 'package:tuhfatul_muslim/features/home/domain/current_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_location.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/features/prayer_widget/data/services/prayer_widget_service.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// The in-app entry point for adding the native Home Screen prayer widget —
/// reached from Settings. Shows a live, truthful preview of the three widget
/// sizes — the same time-of-day art, date row, current-prayer badge and
/// sunrise/sunset row the native widget renders, built from the exact same
/// [PrayerTimeCard] data/formatting — and the platform-appropriate way to
/// place it: a direct "Add to Home Screen" request where the OS supports it,
/// manual instructions otherwise.
class AddPrayerWidgetScreen extends StatefulWidget {
  const AddPrayerWidgetScreen({super.key});

  @override
  State<AddPrayerWidgetScreen> createState() => _AddPrayerWidgetScreenState();
}

class _AddPrayerWidgetScreenState extends State<AddPrayerWidgetScreen> {
  DailyPrayerTimes? _times;
  bool? _pinSupported;

  @override
  void initState() {
    super.initState();
    unawaited(PrayerWidgetService.syncPrayerWidget());
    unawaited(_loadPreviewTimes());
    if (Platform.isAndroid) {
      PrayerWidgetService.isPinSupported().then((supported) {
        if (mounted) setState(() => _pinSupported = supported);
      });
    } else {
      _pinSupported = false;
    }
  }

  Future<void> _loadPreviewTimes() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final now = bangladeshNow();
      final cached = service.cachedPrayerTimes(now);
      if (cached != null && mounted) setState(() => _times = cached);
      final fresh = await service.loadPrayerTimes(now);
      if (fresh != null && mounted) setState(() => _times = fresh);
    } catch (_) {
      // The preview simply falls back to placeholders; this screen never
      // blocks on the network.
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  Text(
                    appText.addPrayerWidgetSubtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.inkColor(const Color(0xFF6B7560)),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _WidgetPreview(
                    label: appText.widgetSizeMedium,
                    times: _times,
                    builder: (times, now, bangla) =>
                        _MediumPreview(times: times, now: now, appText: appText, bangla: bangla),
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _WidgetPreview(
                          label: appText.widgetSizeSmall,
                          times: _times,
                          builder: (times, now, bangla) => _SmallPreview(
                            times: times,
                            now: now,
                            appText: appText,
                            bangla: bangla,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        flex: 2,
                        child: _WidgetPreview(
                          label: appText.widgetSizeLarge,
                          times: _times,
                          builder: (times, now, bangla) => _LargePreview(
                            times: times,
                            now: now,
                            appText: appText,
                            bangla: bangla,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),
                  _ActionCard(appText: appText, pinSupported: _pinSupported),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: 44.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: appText.back,
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDFDE68),
                  foregroundColor: const Color(0xFF303629),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
            Text(
              appText.addPrayerWidgetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.primary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.label,
    required this.times,
    required this.builder,
  });

  final String label;
  final DailyPrayerTimes? times;
  final Widget Function(DailyPrayerTimes? times, DateTime now, bool bangla)
  builder;

  @override
  Widget build(BuildContext context) {
    final now = bangladeshNow();
    final bangla = context.appLanguage == AppLanguage.bangla;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.inkColor(const Color(0xFF6B7560)),
          ),
        ),
        SizedBox(height: 8.h),
        builder(times, now, bangla),
      ],
    );
  }
}

/// The full-bleed time-of-day photo every preview size renders over — the
/// same art [PrayerTimeCard] shows for this time of day
/// ([prayerThemeAsset]), with the same rounded corners and hairline border.
class _WidgetSurface extends StatelessWidget {
  const _WidgetSurface({
    required this.height,
    required this.now,
    required this.fajr,
    required this.child,
  });

  final double height;
  final DateTime now;
  final PrayerClockTime fajr;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD9DEA8)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(prayerThemeAsset(now: now, fajr: fajr), fit: BoxFit.cover),
          // A soft white veil so the black text below stays legible over
          // any photo, the same way the native widget does it.
          Container(color: Colors.white.withValues(alpha: .72)),
          Padding(padding: EdgeInsets.all(10.r), child: child),
        ],
      ),
    );
  }
}

/// Mirrors `PrayerLocationText._label` exactly, so the preview's centre
/// block shows the same "finding your location…"/"permission denied"/etc.
/// placeholder the home card shows instead of going blank.
String _locationLabel(AppText appText) {
  final state = PrayerLocationService.instance.state;
  final location = state.location?.districtCountryDisplayName ?? '';
  if (location.isNotEmpty) return location;
  return switch (state.status) {
    PrayerLocationStatus.idle ||
    PrayerLocationStatus.locating => appText.locationFinding,
    PrayerLocationStatus.serviceDisabled => appText.locationServiceDisabled,
    PrayerLocationStatus.permissionDenied ||
    PrayerLocationStatus.permissionDeniedForever =>
      appText.locationPermissionDenied,
    PrayerLocationStatus.unavailable => appText.locationUnavailable,
    PrayerLocationStatus.ready => appText.locationUnavailable,
  };
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.now, required this.times, required this.bangla, this.fontSize = 9});

  final DateTime now;
  final DailyPrayerTimes? times;
  final bool bangla;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize.sp,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            hijriDateLabel(now, bangla: bangla, maghrib: times?.maghrib),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            banglaDateLabel(now, english: !bangla),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// Gregorian-date chip, current time, verified location and a small
/// "track your Amol" nudge back into the app — all in black, over the white
/// veil [_WidgetSurface] draws.
class _CenterBlock extends StatelessWidget {
  const _CenterBlock({
    required this.now,
    required this.times,
    required this.appText,
    required this.bangla,
    required this.timeFontSize,
  });

  final DateTime now;
  final DailyPrayerTimes? times;
  final AppText appText;
  final bool bangla;
  final double timeFontSize;

  @override
  Widget build(BuildContext context) {
    final dateText = localizeDigits(
      '${now.day} ${appText.monthNames[now.month - 1]} ${now.year}',
      bangla: bangla,
    );
    final periodTime = localizedPeriodClock(
      PrayerClockTime(hour: now.hour, minute: now.minute),
      times: times,
      appText: appText,
      bangla: bangla,
    );
    final location = _locationLabel(appText);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFD9DEA8)),
          ),
          child: Text(dateText, style: TextStyle(fontSize: 9.sp, color: Colors.black)),
        ),
        SizedBox(height: 2.h),
        Text(
          periodTime,
          maxLines: 1,
          style: TextStyle(
            fontSize: timeFontSize.sp,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9.sp, color: const Color(0xFF3F4A38)),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/sejdaIcon.png', width: 12.r, height: 12.r),
            SizedBox(width: 4.w),
            Text(
              appText.widgetAmolTagline,
              style: TextStyle(
                fontSize: 9.sp,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF6F7F52),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// All five daily prayers in one row, the current one marked - what the
/// native widget shows instead of a single current-prayer badge.
class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.now,
    required this.times,
    required this.appText,
    required this.bangla,
    required this.compact,
  });

  final DateTime now;
  final DailyPrayerTimes? times;
  final AppText appText;
  final bool bangla;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final times = this.times;
    final period = times == null ? null : currentPrayerPeriod(now, times);
    final fontSize = compact ? 8.sp : 10.sp;
    String shortClock(PrayerClockTime t) {
      final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final minute = t.minute.toString().padLeft(2, '0');
      return localizeDigits('$hour:$minute', bangla: bangla);
    }

    Widget cell(PrayerPeriod p) {
      final active = period == p;
      final label = p.displayName(appText);
      final range = times == null
          ? '--:--'
          : '${shortClock(prayerStart(p, times))} - ${shortClock(prayerEnd(p, times))}';
      final textColor = active ? Colors.white : Colors.black;
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          padding: EdgeInsets.symmetric(vertical: compact ? 4.h : 6.h),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6F7F52) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, color: textColor),
              ),
              Text(
                range,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: fontSize - 1, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: PrayerPeriod.values.map(cell).toList(),
    );
  }
}

class _SunEdgeRow extends StatelessWidget {
  const _SunEdgeRow({required this.times, required this.appText, required this.bangla});

  final DailyPrayerTimes? times;
  final AppText appText;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final times = this.times;
    final area = PrayerLocationService.instance.state.location?.shortDisplayName ?? '';
    String edgeLabel(String label) => area.isEmpty ? label : '$label, $area';
    String clock(PrayerClockTime t) =>
        localizedPeriodClock(t, times: times, appText: appText, bangla: bangla);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              edgeLabel(appText.sunrise),
              style: TextStyle(fontSize: 10.sp, color: const Color(0xFF3F4A38)),
            ),
            Text(
              times == null ? '--:--' : clock(times.sunrise),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              edgeLabel(appText.sunset),
              style: TextStyle(fontSize: 10.sp, color: const Color(0xFF3F4A38)),
            ),
            Text(
              times == null ? '--:--' : clock(times.sunset),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallPreview extends StatelessWidget {
  const _SmallPreview({
    required this.times,
    required this.now,
    required this.appText,
    required this.bangla,
  });

  final DailyPrayerTimes? times;
  final DateTime now;
  final AppText appText;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final period = times == null ? null : currentPrayerPeriod(now, times!);
    final periodName = times == null
        ? '—'
        : (period?.displayName(appText) ?? appText.naflIshraq);
    final label = times == null ? periodName : '$periodName ${appText.namazWord}';
    final time = localizedPeriodClock(
      PrayerClockTime(hour: now.hour, minute: now.minute),
      times: times,
      appText: appText,
      bangla: bangla,
    );
    return _WidgetSurface(
      height: 92.h,
      now: now,
      fajr: times?.fajr ?? const PrayerClockTime(hour: 5, minute: 0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            Text(time, maxLines: 1, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/sejdaIcon.png', width: 11.r, height: 11.r),
                SizedBox(width: 3.w),
                Text(
                  appText.widgetAmolTagline,
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF6F7F52),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediumPreview extends StatelessWidget {
  const _MediumPreview({
    required this.times,
    required this.now,
    required this.appText,
    required this.bangla,
  });

  final DailyPrayerTimes? times;
  final DateTime now;
  final AppText appText;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    return _WidgetSurface(
      height: 190.h,
      now: now,
      fajr: times?.fajr ?? const PrayerClockTime(hour: 5, minute: 0),
      child: Column(
        children: [
          _DateRow(now: now, times: times, bangla: bangla),
          const Spacer(),
          _CenterBlock(now: now, times: times, appText: appText, bangla: bangla, timeFontSize: 15),
          const Spacer(),
          _PrayerRow(now: now, times: times, appText: appText, bangla: bangla, compact: true),
        ],
      ),
    );
  }
}

class _LargePreview extends StatelessWidget {
  const _LargePreview({
    required this.times,
    required this.now,
    required this.appText,
    required this.bangla,
  });

  final DailyPrayerTimes? times;
  final DateTime now;
  final AppText appText;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    return _WidgetSurface(
      height: 190.h,
      now: now,
      fajr: times?.fajr ?? const PrayerClockTime(hour: 5, minute: 0),
      child: Column(
        children: [
          _DateRow(now: now, times: times, bangla: bangla, fontSize: 10),
          const Spacer(),
          _CenterBlock(now: now, times: times, appText: appText, bangla: bangla, timeFontSize: 18),
          const Spacer(),
          _PrayerRow(now: now, times: times, appText: appText, bangla: bangla, compact: false),
          SizedBox(height: 8.h),
          _SunEdgeRow(times: times, appText: appText, bangla: bangla),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({required this.appText, required this.pinSupported});

  final AppText appText;
  final bool? pinSupported;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _requesting = false;

  Future<void> _requestPin() async {
    setState(() => _requesting = true);
    try {
      await PrayerWidgetService.requestPin();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = widget.appText;
    final showButton = Platform.isAndroid && widget.pinSupported == true;
    final instructions = Platform.isIOS
        ? appText.addPrayerWidgetIosInstructions
        : appText.addPrayerWidgetAndroidInstructions;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFE4EDB6)),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFA2B253), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showButton) ...[
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _requesting ? null : _requestPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F7F52),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _requesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        appText.addPrayerWidgetButton,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
          Text(
            instructions,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF445238),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
