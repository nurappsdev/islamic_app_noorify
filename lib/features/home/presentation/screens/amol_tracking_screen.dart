import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/presentation/widgets/amol_progress_ring.dart';

class AmolTrackingScreen extends StatelessWidget {
  const AmolTrackingScreen({
    super.key,
    this.pointLabel = 'Point : 30/40',
    this.progressLabel = '86 %',
    this.progress = .86,
    this.now,
  });

  final String pointLabel;
  final String progressLabel;
  final double progress;
  final DateTime Function()? now;

  static const _olive = Color(0xFF8D9B70);
  static const _cardGreen = Color(0xFFE3ECAE);

  static const _items = [
    _AmolItem(title: 'Fardh Prayer', fraction: '0/7', progress: .58),
    _AmolItem(title: 'Sunnah and Witr', fraction: '0/6', progress: .5),
    _AmolItem(title: 'Nafl Salat', fraction: '0/2.5', progress: .52),
    _AmolItem(title: 'Quran', fraction: '0/11', progress: .55),
    _AmolItem(title: 'Hadith', fraction: '0/8', progress: .48),
    _AmolItem(title: 'Quiz', fraction: '0/2.5', progress: .45),
    _AmolItem(title: 'Nafl & more', fraction: '0/3', progress: .55),
  ];

  @override
  Widget build(BuildContext context) {
    final today = (now ?? DateTime.now)();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
                children: [
                  _SummaryCard(
                    pointLabel: pointLabel,
                    progressLabel: progressLabel,
                    progress: progress,
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    _formatDate(today),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  for (final item in _items) ...[
                    _AmolRow(item: item),
                    SizedBox(height: 12.h),
                  ],
                  SizedBox(height: 4.h),
                  _DashboardButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _formatDate(DateTime date) {
    final weekday = _weekdayNames[date.weekday - 1];
    final month = _monthNames[date.month - 1];
    return '$weekday ${date.day} $month, ${date.year}';
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF7F5CE),
                foregroundColor: const Color(0xFF526044),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Text(
            'Amol Tracking',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: AmolTrackingScreen._olive,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.pointLabel,
    required this.progressLabel,
    required this.progress,
  });

  final String pointLabel;
  final String progressLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AmolTrackingScreen._cardGreen,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8E8),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Image.asset(
              'assets/noorifyLogo.png',
              fit: BoxFit.contain,
              color: const Color(0xFF879461),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todays Amol track',
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
                ),
                SizedBox(height: 5.h),
                Text(
                  pointLabel,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black87),
                ),
              ],
            ),
          ),
          AmolProgressRing(
            label: progressLabel,
            progress: progress,
            dimension: 74.r,
            holeDimension: 50.r,
            holeColor: AmolTrackingScreen._cardGreen,
            labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AmolRow extends StatelessWidget {
  const _AmolRow({required this.item});

  final _AmolItem item;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCardBorderPainter(radius: 16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: SizedBox(
                            height: 7.h,
                            child: Stack(
                              children: [
                                const ColoredBox(color: Color(0xFFDDE0D0)),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: item.progress.clamp(0.0, 1.0),
                                  child: const ColoredBox(
                                    color: AmolTrackingScreen._olive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        item.fraction,
                        style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              width: 30.r,
              height: 30.r,
              decoration: const BoxDecoration(
                color: Color(0xFFDDEBB5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: const Color(0xFF7E8C61),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCardBorderPainter extends CustomPainter {
  const _DashedCardBorderPainter({required this.radius});

  final double radius;
  static const _color = Color(0xFFC7D69C);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outline = Path()..addRRect(rrect);
    final dashed = Path();
    const dashWidth = 5.0;
    const dashGap = 4.0;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = _color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedCardBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _DashboardButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      decoration: BoxDecoration(
        color: const Color(0xFFA3B06B),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View in dashboard',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 26.r,
            height: 26.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              size: 15.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmolItem {
  const _AmolItem({
    required this.title,
    required this.fraction,
    required this.progress,
  });

  final String title;
  final String fraction;
  final double progress;
}
