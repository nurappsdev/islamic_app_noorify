import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/brand_colors.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart'
    hide localizeDigits;
import 'package:tuhfatul_muslim/features/alarm/presentation/screens/all_alarm_screen.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/date_labels.dart';
import 'package:tuhfatul_muslim/features/home/domain/current_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/shared/widgets/profile_avatar_circle.dart';

const _maxBadgeCount = 99;

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final palette = context.appPalette;
    final dashboard = context.watch<HomeDashboardBloc>().state.dashboard;
    final dashboardName = context.localized(
      dashboard?.userSummary.localizedFullName,
    );
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
          child: ProfileAvatarCircle(
            dimension: 38.r,
            backgroundColor: context.surfaceColor(palette.avatar),
            placeholderIconColor: AppColor.primary,
          ),
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: profileNameNotifier,
                  builder: (context, name, _) {
                    return Text(
                      (name == null || name.isEmpty)
                          ? (dashboardName.isEmpty
                                ? appText.competitorName
                                : dashboardName)
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: homeSansStyle(
                        context: context,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                SizedBox(height: 2.h),
                const _HeaderRotatingSubtitle(),
              ],
            ),
          ),
        ),
        SizedBox.square(
          dimension: 32.r,
          child: IconButton(
            tooltip: appText.alarm,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AllAlarmScreen()),
            ),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.alarm, color: AppColor.primary, size: 20.sp),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: unreadNotificationCountNotifier,
          builder: (context, unreadCount, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox.square(
                  dimension: 36.r,
                  child: IconButton(
                    tooltip: appText.notifications,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.notifications),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColor.primary,
                    ),
                    icon: Icon(Icons.notifications_none, size: 20.sp),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 2.h,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      constraints: BoxConstraints(
                        minWidth: 16.r,
                        minHeight: 16.r,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6969),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: context.lineColor(palette.background),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > _maxBadgeCount
                            ? '$_maxBadgeCount+'
                            : '$unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// What a rotation slot shows.
enum _RotationKind { reminder, gregorian, hijri, bangla }

/// The header subtitle beneath the user's name:
///
/// 1. The Salam greeting, for 5 seconds.
/// 2. Then, every 2 seconds, cycles through: a "have you completed X
///    prayer?" reminder (only while today's current fard prayer is active
///    and not yet tracked) followed by the date in Gregorian, Hijri and
///    Bangla form, each paired with the current prayer's time range.
///
/// Reads prayer times ([AladhanPrayerTimeService]) and today's tracking
/// state ([AmolDailyStore]) the same way the rest of Home does; writes
/// neither, so it can't affect tracking.
class _HeaderRotatingSubtitle extends StatefulWidget {
  const _HeaderRotatingSubtitle();

  @override
  State<_HeaderRotatingSubtitle> createState() =>
      _HeaderRotatingSubtitleState();
}

class _HeaderRotatingSubtitleState extends State<_HeaderRotatingSubtitle> {
  static const _greetingDuration = Duration(seconds: 5);
  static const _rotationInterval = Duration(seconds: 2);

  /// [PrayerPeriod] is declared fajr/dhuhr/asr/maghrib/isha, in that order -
  /// matches the `fardh_prayer` pillar's item keys index for index.
  static const _fardhItemKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  Timer? _timer;
  DailyPrayerTimes? _times;
  bool _showingGreeting = true;
  int _rotationIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTimes();
    AmolDailyStore.instance
      ..addListener(_onTrackingChanged)
      ..ensureLoaded();
    _timer = Timer(_greetingDuration, _endGreeting);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AmolDailyStore.instance.removeListener(_onTrackingChanged);
    super.dispose();
  }

  Future<void> _loadTimes() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final now = bangladeshNow();
      final cached = service.cachedPrayerTimes(now);
      if (mounted && cached != null) setState(() => _times = cached);
      final fresh = await service.loadPrayerTimes(now);
      if (mounted && fresh != null) setState(() => _times = fresh);
    } catch (_) {
      // Rotation falls back to date-only items until times are available.
    }
  }

  void _onTrackingChanged() {
    if (mounted) setState(() {});
  }

  void _endGreeting() {
    if (!mounted) return;
    setState(() => _showingGreeting = false);
    _timer = Timer.periodic(_rotationInterval, (_) {
      if (mounted) setState(() => _rotationIndex++);
    });
  }

  bool _isTracked(PrayerPeriod period) {
    final items = AmolDailyStore.instance.pillar('fardh_prayer')?.items;
    if (items == null) return false;
    final key = _fardhItemKeys[period.index];
    for (final item in items) {
      if (item.itemKey == key) return item.isCompleted;
    }
    return false;
  }

  /// Reminder first (only while the current prayer is active and untracked),
  /// then the three calendar formats, always in this fixed order so the
  /// rotation doesn't reshuffle as the underlying data changes.
  List<_RotationKind> _rotationKinds(DateTime now) {
    final times = _times;
    final period = times == null ? null : currentPrayerPeriod(now, times);
    return [
      if (period != null && !_isTracked(period)) _RotationKind.reminder,
      _RotationKind.gregorian,
      _RotationKind.hijri,
      _RotationKind.bangla,
    ];
  }

  /// e.g. `"Asr : 3:45 PM - 5:12 PM"`, or the Ishraq window between sunrise
  /// and Dhuhr when no fard prayer is currently active - same fallback
  /// [PrayerTimeCard]'s current-prayer badge uses.
  String _prayerRangeLabel(DateTime now, AppText appText, bool bangla) {
    final times = _times;
    if (times == null) return '—';
    String clock(PrayerClockTime t) =>
        localizeClockText(formatPrayerTime(t), bangla: bangla);
    final period = currentPrayerPeriod(now, times);
    final label = period?.displayName(appText) ?? appText.naflIshraq;
    final range = period != null
        ? '${clock(prayerStart(period, times))} - ${clock(prayerEnd(period, times))}'
        : '${clock(times.sunrise)} - ${clock(times.dhuhr)}';
    return '$label : $range';
  }

  String _label(
    _RotationKind kind,
    DateTime now,
    AppText appText,
    bool bangla,
  ) {
    switch (kind) {
      case _RotationKind.reminder:
        final period = currentPrayerPeriod(now, _times!)!;
        return '${appText.prayerReminderPrefix} '
            '${period.displayName(appText)} '
            '${appText.prayerReminderSuffix}';
      case _RotationKind.gregorian:
        final date = localizeDigits(
          '${now.day} ${appText.monthNames[now.month - 1]} ${now.year}',
          bangla: bangla,
        );
        return '$date    ${_prayerRangeLabel(now, appText, bangla)}';
      case _RotationKind.hijri:
        final date = hijriDateLabel(
          now,
          bangla: bangla,
          maghrib: _times?.maghrib,
        );
        return '$date    ${_prayerRangeLabel(now, appText, bangla)}';
      case _RotationKind.bangla:
        final date = banglaDateLabel(now, english: !bangla);
        return '$date    ${_prayerRangeLabel(now, appText, bangla)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final now = bangladeshNow();

    final String text;
    final bool isReminder;
    if (_showingGreeting) {
      final dashboardGreeting = context.localized(
        context
            .watch<HomeDashboardBloc>()
            .state
            .dashboard
            ?.userSummary
            .localizedGreetingText,
      );
      text = dashboardGreeting.isEmpty ? appText.greeting : dashboardGreeting;
      isReminder = false;
    } else {
      final kinds = _rotationKinds(now);
      final kind = kinds[_rotationIndex % kinds.length];
      text = _label(kind, now, appText, bangla);
      isReminder = kind == _RotationKind.reminder;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: homeSansStyle(
          context: context,
          fontSize: 8.sp,
          color: isReminder ? BrandColors.warning : null,
          fontWeight: isReminder ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}
