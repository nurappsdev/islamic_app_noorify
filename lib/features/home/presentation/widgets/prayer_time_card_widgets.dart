part of 'prayer_time_card.dart';

class _CurrentPrayerBadge extends StatelessWidget {
  const _CurrentPrayerBadge({required this.times, required this.now});

  final DailyPrayerTimes? times;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla = _isBangla(context);
    String clock(PrayerClockTime t) =>
        localizeClockText(formatPrayerTime(t), bangla: bangla);
    final times = this.times;
    final period = times == null ? null : currentPrayerPeriod(now, times);
    final label = times == null
        ? '—'
        : (period?.displayName(appText) ?? appText.naflIshraq);
    final rangeText = times == null
        ? '—'
        : period != null
        ? '${clock(prayerStart(period, times))} – '
              '${clock(prayerEnd(period, times))}'
        : '${clock(times.sunrise)} – '
              '${clock(times.dhuhr)}';
    return Container(
      width: 190.w,
      height: 66.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EDB6),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFA2B253), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 39.r,
            height: 39.r,
            decoration: BoxDecoration(
              // The robe in the image is white, so it needs a coloured tile
              // to stand out.
              color: const Color(0xFF9E9E9E),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Image.asset(
                'assets/salatImg.png',
                fit: BoxFit.contain,
                // The source is ~1600px wide; decode it at icon size.
                cacheWidth: 160,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: homeSansStyle(fontSize: 14.sp, color: Colors.black),
                  ),
                ),
                SizedBox(height: 6.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rangeText,
                    style: homeSansStyle(fontSize: 13.sp, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one style for the calendar dates along the top of the card, so the
/// Hijri and Bengali dates always look alike. [fontSize] is only passed by
/// [_CardDateRow], when both have to shrink to fit.
TextStyle _calendarDateStyle({required Color color, double? fontSize}) {
  return homeSerifStyle(
    fontSize: fontSize ?? 10.sp,
    fontWeight: FontWeight.w400,
    color: color,
  ).copyWith(height: 1.2);
}

/// The two calendar dates along the top of the card: [start] at the left edge
/// and [end] at the right, set in [_calendarDateStyle].
///
/// When the pair is too wide for the card (the English Hijri date is long),
/// both shrink by the same factor rather than each fitting itself, so they
/// keep the same size and neither looks more prominent.
class _CardDateRow extends StatelessWidget {
  const _CardDateRow({
    required this.start,
    required this.end,
    required this.color,
  });

  final String start;
  final String end;
  final Color color;

  static const _minScale = .6;

  @override
  Widget build(BuildContext context) {
    final base = _calendarDateStyle(color: color);
    final scaler = MediaQuery.textScalerOf(context);
    final gap = 28.w;

    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: base),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = widthOf(start) + widthOf(end);
        final room = constraints.maxWidth - gap;
        // A little under the exact fit, so rounding never overflows the row.
        final scale = textWidth <= room || textWidth == 0
            ? 1.0
            : (room / textWidth * .98).clamp(_minScale, 1.0);
        final style = _calendarDateStyle(
          color: color,
          fontSize: base.fontSize! * scale,
        );
        Widget date(String text) => Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            date(start),
            SizedBox(width: gap),
            date(end),
          ],
        );
      },
    );
  }
}

class _PrayerEdgeTime extends StatelessWidget {
  const _PrayerEdgeTime({
    required this.label,
    required this.time,
    required this.isSunrise,
    required this.secondaryLabel,
    required this.secondaryTime,
    required this.showPrimary,
  });

  final String label;
  final String time;
  final bool isSunrise;
  final String secondaryLabel;
  final String secondaryTime;
  final bool showPrimary;

  @override
  Widget build(BuildContext context) {
    final displayLabel = showPrimary ? label : secondaryLabel;
    final displayTime = showPrimary ? time : secondaryTime;
    return SizedBox(
      key: ValueKey(isSunrise ? 'prayer-edge-sunrise' : 'prayer-edge-sunset'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.r,
            height: 38.r,
            child: CustomPaint(
              painter: _HorizonTimeIconPainter(isSunrise: isSunrise),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayLabel,
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 13.sp, color: Colors.white),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayTime,
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 15.sp, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
