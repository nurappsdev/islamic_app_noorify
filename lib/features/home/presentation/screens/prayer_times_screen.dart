import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/core/localization/localized_time_formatter.dart';
import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/current_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/nafl_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/features/alarm/presentation/screens/set_all_alarm_screen.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/prayer_times_bloc.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/prayer_arc_sun_painter.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/prayer_location_widgets.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key, this.prayerTimeService, this.now});

  final PrayerTimeService? prayerTimeService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return PrayerLocationScope(
      child: BlocProvider(
        create: (_) {
          final bloc = PrayerTimesBloc(
            prayerTimeService: prayerTimeService,
            now: now,
          )..add(const LoadPrayerTimes());
          if (now == null) bloc.add(const StartClock());
          return bloc;
        },
        child: const _PrayerTimesView(),
      ),
    );
  }
}

class _PrayerTimesView extends StatelessWidget {
  const _PrayerTimesView();

  static const _olive = Color(0xFF8D9B70);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrayerTimesBloc>().state;
    final active = state.times == null
        ? null
        : currentPrayerPeriod(state.now, state.times!);
    return Scaffold(
      backgroundColor: context.pageColor(_olive),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              // Room for the countdown and its progress bar under the
              // current-prayer chip, above the sunrise/sunset labels.
              height: 336.h,
              child: _PrayerSummaryHeader(
                now: state.now,
                times: state.times,
                active: active,
                olive: _olive,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(15.w, 20.h, 15.w, 18.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(Color(0xFFFCFDF8)),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(27.r),
                  ),
                ),
                child: _PrayerList(
                  now: state.now,
                  times: state.times,
                  active: active,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerSummaryHeader extends StatelessWidget {
  const _PrayerSummaryHeader({
    required this.now,
    required this.times,
    required this.active,
    required this.olive,
  });

  final DateTime now;
  final DailyPrayerTimes? times;
  final PrayerPeriod? active;
  final Color olive;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla = context.appLanguage == AppLanguage.bangla;
    String clockText(PrayerClockTime? t) => t == null
        ? LocalizedTimeFormatter.placeholder
        : localizedPeriodClock(
            t,
            times: times,
            appText: appText,
            bangla: bangla,
          );
    // The chip is narrow, so its own range is digits only — the waqt name
    // above it already says which part of the day it is.
    String clockDigits(PrayerClockTime? t) => t == null
        ? LocalizedTimeFormatter.placeholder
        : localizedClockDigits(t, bangla: bangla);
    final dates = context.localizedDates;
    final summaryPeriod = active ?? PrayerPeriod.dhuhr;
    final summaryStart = clockDigits(
      times == null ? null : prayerStart(summaryPeriod, times!),
    );
    final summaryEnd = clockDigits(
      times == null ? null : prayerEnd(summaryPeriod, times!),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.surfaceColor(olive)),
        Positioned(
          top: 110.h,
          left: 70.w,
          right: 70.w,
          height: 120.h,
          child: Image.asset('assets/images/backImg2.png', fit: BoxFit.fill),
        ),
        Positioned(
          top: 9.h,
          left: 14.w,
          child: IconButton(
            tooltip: appText.back,
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: context.surfaceColor(Color(0xFFF7F5CE)),
              foregroundColor: context.inkColor(Color(0xFF526044)),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        Positioned(
          top: 9.h,
          right: 14.w,
          child: IconButton(
            tooltip: appText.setAllAlarm,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SetAllAlarmScreen(times: times),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: context.surfaceColor(Color(0xFFF7F5CE)),
              foregroundColor: context.inkColor(Color(0xFF526044)),
            ),
            icon: const Icon(Icons.alarm_add_outlined),
          ),
        ),
        Positioned(
          top: 18.h,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Text(
              appText.prayerTimesTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15.sp),
            ),
          ),
        ),
        Positioned(
          top: 65.h,
          left: 30.w,
          right: 30.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dates.hijri(now, maghrib: times?.maghrib),
                    style: _italicStyle(10.sp),
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    dates.banglaCalendar(now),
                    style: _italicStyle(10.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 90.h,
          left: 33.w,
          right: 33.w,
          child: SizedBox(
            height: 142.h,
            child: PrayerDayProgress(
              progress: times == null
                  ? 0
                  : isNightPhase(now, times!)
                  ? nightProgress(now, times!)
                  : dayProgress(now, times!),
              isNight: times != null && isNightPhase(now, times!),
            ),
          ),
        ),
        Positioned(
          top: 121.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                // English keeps the short month (`28 Sep 2026`); Bangla writes
                // the month out in full.
                dates.gregorian(now, shortMonth: true),
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
              Text(
                clockText(PrayerClockTime(hour: now.hour, minute: now.minute)),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              PrayerLocationText(
                style: TextStyle(color: Colors.white70, fontSize: 9.sp),
              ),
            ],
          ),
        ),
        Positioned(
          top: 183.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: context.surfaceColor(Color(0xFFE8EFB8)),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: const Color(0xFFA7B55E)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Just the waqt — `পরবর্তী:` in front of it while none is
                  // running — then its range, the countdown and the bar.
                  Text(
                    active == null
                        ? '${appText.nextPrefix} ${summaryPeriod.displayName(appText)}'
                        : summaryPeriod.displayName(appText),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.localizedDigits('$summaryStart – $summaryEnd'),
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  if (times != null) ...[
                    SizedBox(height: 7.h),
                    // Dhuhr running 11:44 -> 3:34 reads as `শেষ হতে বাকি
                    // ২ ঘণ্টা ১৫ মিনিট`, with the bar showing how much of
                    // that window has already gone by. In the gap between
                    // sunrise and Dhuhr, where no fard prayer is running, it
                    // counts down to Dhuhr's start instead.
                    _PrayerWindowCountdown(
                      isEnding: active != null,
                      // Sunrise, Zawal and sunset: the bar turns red while
                      // prayer is prohibited.
                      isProhibited: isProhibitedPrayerTime(now, times!),
                      minutesLeft: minutesUntilClock(
                        now,
                        active == null
                            ? times!.dhuhr
                            : prayerEnd(summaryPeriod, times!),
                      ),
                      progress: windowProgress(
                        now,
                        PrayerTimeWindow(
                          start: active == null
                              ? times!.sunrise
                              : prayerStart(summaryPeriod, times!),
                          end: active == null
                              ? times!.dhuhr
                              : prayerEnd(summaryPeriod, times!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 61.w,
          right: 61.w,
          bottom: 12.h,
          child: PrayerLocationBuilder(
            builder: (context, locationState) {
              final area = locationState.location?.shortDisplayName ?? '';
              String edgeLabel(String label) =>
                  area.isEmpty ? label : '$label, $area';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _EdgeLabel(
                      title: edgeLabel(appText.sunrise),
                      value: clockText(times?.sunrise),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: _EdgeLabel(
                      title: edgeLabel(appText.sunset),
                      value: clockText(times?.sunset),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static TextStyle _italicStyle(double size) => TextStyle(
    color: Colors.white,
    fontSize: size,
    fontStyle: FontStyle.italic,
  );
}

class _EdgeLabel extends StatelessWidget {
  const _EdgeLabel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 9.sp),
      ),
      SizedBox(height: 4.h),
      Text(
        value,
        style: TextStyle(color: Colors.white, fontSize: 11.sp),
      ),
    ],
  );
}

/// `শেষ হতে বাকি ২ ঘণ্টা ১৫ মিনিট` with a bar underneath showing how far
/// through the window the clock has come — or `শুরু হতে বাকি …` when it is
/// counting down to a window that has not opened yet.
class _PrayerWindowCountdown extends StatelessWidget {
  const _PrayerWindowCountdown({
    required this.isEnding,
    required this.isProhibited,
    required this.minutesLeft,
    required this.progress,
  });

  /// `true` while the window is running (count down to its end), `false` when
  /// counting down to the next window's start.
  final bool isEnding;

  /// `true` while one of the prohibited windows is running, which turns the
  /// bar light red.
  final bool isProhibited;
  final int minutesLeft;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final label = isEnding
        ? appText.prayerEndsInLabel
        : appText.prayerStartsInLabel;
    final ink = context.inkColor(const Color(0xFF4C5A33));
    return SizedBox(
      // The widest line in the chip, so this is what sets the card's width.
      width: 136.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 11.sp, color: ink),
                SizedBox(width: 3.w),
                Text(
                  key: const ValueKey('prayer-window-countdown'),
                  '$label ${context.localizedTimes.minutesDuration(minutesLeft)}',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          _WindowProgressBar(progress: progress, isProhibited: isProhibited),
        ],
      ),
    );
  }
}

class _WindowProgressBar extends StatelessWidget {
  const _WindowProgressBar({
    required this.progress,
    required this.isProhibited,
  });

  final double progress;

  /// Olive normally; a light red while prayer is prohibited.
  final bool isProhibited;

  static const _olive = [Color(0xFF6F7F52), Color(0xFF4C5A33)];
  static const _red = [Color(0xFFF08A84), Color(0xFFDC5A54)];

  @override
  Widget build(BuildContext context) => ClipRRect(
    key: const ValueKey('prayer-window-progress'),
    borderRadius: BorderRadius.circular(4.r),
    child: Container(
      height: 5.h,
      color: isProhibited
          ? context.appPalette.dangerTint
          : context.surfaceColor(const Color(0xFFCBD897)),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isProhibited ? _red : _olive),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PrayerList extends StatelessWidget {
  const _PrayerList({
    required this.now,
    required this.times,
    required this.active,
  });

  final DateTime now;
  final DailyPrayerTimes? times;
  final PrayerPeriod? active;

  @override
  Widget build(BuildContext context) {
    final rows = PrayerPeriod.values;
    // The five fard rows and the four Nafl windows together are taller than
    // the panel on a phone, so the panel scrolls rather than squeezing them.
    return SingleChildScrollView(
      child: Column(
        children: [
          // Each row takes the height its own content needs: the panel
          // scrolls, so there is no height to divide between them, and a
          // fixed one would clip the text on a short screen.
          for (var index = 0; index < rows.length; index++) ...[
            _PrayerRow(
              period: rows[index],
              times: times,
              active: active == rows[index],
            ),
            if (index != rows.length - 1) SizedBox(height: 9.h),
          ],
          SizedBox(height: 18.h),
          _NaflSection(now: now, times: times),
        ],
      ),
    );
  }
}

/// Tahajjud, Ishraq, Chasht (Duha) and Awwabin — the Nafl windows of the day,
/// under a heading of their own below the fard prayers.
class _NaflSection extends StatelessWidget {
  const _NaflSection({required this.now, required this.times});

  final DateTime now;
  final DailyPrayerTimes? times;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final periods = NaflPeriod.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 16.sp,
              color: context.inkColor(const Color(0xFF7E8C61)),
            ),
            SizedBox(width: 6.w),
            Text(
              appText.naflPrayersTitle,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: context.inkColor(const Color(0xFF2F3A22)),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Divider(
                height: 1,
                color: context.lineColor(const Color(0xFFDCE9B8)),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        for (var index = 0; index < periods.length; index += 2) ...[
          IntrinsicHeight(
            // The scroll view has no height to stretch the tiles to, so they
            // take the taller one's own height and stay a matching pair.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _NaflTile(
                    period: periods[index],
                    now: now,
                    times: times,
                  ),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: index + 1 < periods.length
                      ? _NaflTile(
                          period: periods[index + 1],
                          now: now,
                          times: times,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (index + 2 < periods.length) SizedBox(height: 9.h),
        ],
      ],
    );
  }
}

class _NaflTile extends StatelessWidget {
  const _NaflTile({
    required this.period,
    required this.now,
    required this.times,
  });

  final NaflPeriod period;
  final DateTime now;
  final DailyPrayerTimes? times;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla = context.appLanguage == AppLanguage.bangla;
    final times = this.times;
    final window = times == null ? null : naflWindow(period, times);
    final active = window != null && isWithinWindow(now, window);
    final range = window == null
        ? '${LocalizedTimeFormatter.placeholder} – '
              '${LocalizedTimeFormatter.placeholder}'
        : '${localizedPeriodClock(window.start, times: times, appText: appText, bangla: bangla)}'
              ' – ${localizedClockDigits(window.end, bangla: bangla)}';
    final ink = context.inkColor(const Color(0xFF2F3A22));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(
          active ? const Color(0xFFEDF4D5) : Colors.white,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.lineColor(
            active ? const Color(0xFF9DAB6F) : const Color(0xFFDCE9B8),
          ),
          width: active ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              color: context.surfaceColor(const Color(0xFFFFF8D7)),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(
              _icon,
              color: context.inkColor(_iconColor),
              size: 17.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        period.displayName(appText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
                    if (active) ...[
                      SizedBox(width: 5.w),
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6F7F52),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.localizedDigits(range),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(const Color(0xFF5E6B43)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (period) {
    NaflPeriod.tahajjud => Icons.bedtime_outlined,
    NaflPeriod.ishraq => Icons.wb_twilight,
    NaflPeriod.chasht => Icons.light_mode_outlined,
    NaflPeriod.awwabin => Icons.brightness_4_outlined,
  };

  Color get _iconColor => switch (period) {
    NaflPeriod.tahajjud => const Color(0xFF7FA8C9),
    NaflPeriod.ishraq => const Color(0xFFFFC83D),
    NaflPeriod.chasht => const Color(0xFFFFAA2C),
    NaflPeriod.awwabin => const Color(0xFFFF8E4A),
  };
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.period,
    required this.times,
    required this.active,
  });

  final PrayerPeriod period;
  final DailyPrayerTimes? times;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla = context.appLanguage == AppLanguage.bangla;
    String clockText(PrayerClockTime t) =>
        localizedPeriodClock(t, times: times, appText: appText, bangla: bangla);
    final start = times == null
        ? LocalizedTimeFormatter.placeholder
        : clockText(prayerStart(period, times!));
    final end = times == null
        ? LocalizedTimeFormatter.placeholder
        : clockText(prayerEnd(period, times!));
    final titleColor = active
        ? Colors.white
        : context.inkColor(const Color(0xFF2F3A22));
    return Row(
      children: [
        Container(
          width: 20.r,
          height: 20.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(
              active ? const Color(0xFF829061) : const Color(0xFFDDEBB5),
            ),
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF829061).withValues(alpha: .45),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: AnimatedContainer(
            key: active ? const ValueKey('active-prayer-row') : null,
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFF9DAB6F), Color(0xFF6F7F52)],
                    )
                  : null,
              color: active ? null : context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: context.lineColor(
                  active ? const Color(0xFF6F7F52) : const Color(0xFFDCE9B8),
                ),
                width: active ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: active
                      ? const Color(0xFF6F7F52).withValues(alpha: .4)
                      : const Color(0x10000000),
                  blurRadius: active ? 14 : 5,
                  offset: Offset(0, active ? 6 : 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: .92)
                        : context.surfaceColor(const Color(0xFFFFF8D7)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _icon,
                    color: context.inkColor(_iconColor),
                    size: 25.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              period.displayName(appText),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                          ),
                          if (active) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE27A),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                appText.prayerNowLabel,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF4A4210),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 5.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white.withValues(alpha: .22)
                                : context.surfaceColor(const Color(0xFFEEF4D6)),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14.sp,
                                color: active
                                    ? Colors.white
                                    : context.inkColor(const Color(0xFF7E8C61)),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                context.localizedDigits('$start – $end'),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData get _icon => switch (period) {
    PrayerPeriod.fajr => Icons.wb_twilight,
    PrayerPeriod.dhuhr => Icons.wb_sunny,
    PrayerPeriod.asr => Icons.sunny,
    PrayerPeriod.maghrib => Icons.wb_twilight_outlined,
    PrayerPeriod.isha => Icons.nights_stay,
  };

  Color get _iconColor => switch (period) {
    PrayerPeriod.fajr => const Color(0xFFFFC83D),
    PrayerPeriod.dhuhr => const Color(0xFFFFC83D),
    PrayerPeriod.asr => const Color(0xFFFFAA2C),
    PrayerPeriod.maghrib => const Color(0xFFFF8E4A),
    PrayerPeriod.isha => const Color(0xFFEACB2B),
  };
}
