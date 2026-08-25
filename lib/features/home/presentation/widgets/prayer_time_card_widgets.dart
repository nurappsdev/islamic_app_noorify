part of 'prayer_time_card.dart';

class _CurrentPrayerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(5.r),
              child: CustomPaint(painter: _PrayerBadgeIllustrationPainter()),
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
                    appText.dhuhrPrayerTime,
                    style: homeSansStyle(fontSize: 14.sp, color: Colors.black),
                  ),
                ),
                SizedBox(height: 6.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '12:44 PM – 3:45 PM',
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

class _PrayerEdgeTime extends StatelessWidget {
  const _PrayerEdgeTime({
    required this.label,
    required this.time,
    required this.isSunrise,
    required this.secondaryLabel,
    required this.secondaryTime,
  });

  final String label;
  final String time;
  final bool isSunrise;
  final String secondaryLabel;
  final String secondaryTime;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(isSunrise ? 'prayer-edge-sunrise' : 'prayer-edge-sunset'),
      height: 64.h,
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
                    label,
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 13.sp, color: Colors.white),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 15.sp, color: Colors.white),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$secondaryLabel : $secondaryTime',
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 10.sp, color: Colors.white),
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
