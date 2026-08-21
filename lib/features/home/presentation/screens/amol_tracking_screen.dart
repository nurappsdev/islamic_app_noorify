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
                  const _FardhPrayerRow(),
                  SizedBox(height: 12.h),
                  for (final item in _items) ...[
                    _AmolRow(item: item),
                    SizedBox(height: 12.h),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 12.h),
              child: _DashboardButton(),
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
                      Expanded(child: _ProgressBar(progress: item.progress)),
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 7.h,
        child: Stack(
          children: [
            const ColoredBox(color: Color(0xFFDDE0D0)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const ColoredBox(color: AmolTrackingScreen._olive),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SalahStatus { locked, available, completed }

class _SalahItem {
  const _SalahItem({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.points,
    required this.status,
  });

  final String name;
  final IconData icon;
  final Color iconColor;
  final int points;
  final _SalahStatus status;

  _SalahItem copyWith({_SalahStatus? status}) => _SalahItem(
    name: name,
    icon: icon,
    iconColor: iconColor,
    points: points,
    status: status ?? this.status,
  );
}

class _FardhPrayerRow extends StatefulWidget {
  const _FardhPrayerRow();

  @override
  State<_FardhPrayerRow> createState() => _FardhPrayerRowState();
}

class _FardhPrayerRowState extends State<_FardhPrayerRow> {
  var _expanded = true;
  var _salah = const [
    _SalahItem(
      name: 'Fajr',
      icon: Icons.wb_twilight,
      iconColor: Color(0xFFFFC83D),
      points: 2,
      status: _SalahStatus.completed,
    ),
    _SalahItem(
      name: 'Duhr',
      icon: Icons.wb_sunny,
      iconColor: Color(0xFFFFC83D),
      points: 1,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Asr',
      icon: Icons.sunny,
      iconColor: Color(0xFFFFAA2C),
      points: 1,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Magrib',
      icon: Icons.wb_twilight_outlined,
      iconColor: Color(0xFFFF8E4A),
      points: 1,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Esa',
      icon: Icons.nights_stay,
      iconColor: Color(0xFFEACB2B),
      points: 2,
      status: _SalahStatus.locked,
    ),
  ];

  int get _totalPoints => _salah.fold(0, (sum, item) => sum + item.points);

  int get _completedPoints => _salah
      .where((item) => item.status == _SalahStatus.completed)
      .fold(0, (sum, item) => sum + item.points);

  void _toggle(int index) {
    final item = _salah[index];
    if (item.status == _SalahStatus.locked) return;
    setState(() {
      _salah = [
        for (var i = 0; i < _salah.length; i++)
          if (i == index)
            item.copyWith(
              status: item.status == _SalahStatus.completed
                  ? _SalahStatus.available
                  : _SalahStatus.completed,
            )
          else
            _salah[i],
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPoints;
    final completed = _completedPoints;
    final progress = total == 0 ? 0.0 : completed / total;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _expanded ? const Color(0xFFF7F7E7) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fardh Prayer',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(child: _ProgressBar(progress: progress)),
                            SizedBox(width: 10.w),
                            Text(
                              '$completed/$total',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.chevron_right,
                    size: 20.sp,
                    color: const Color(0xFF7E8C61),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: Column(
                children: [
                  for (var i = 0; i < _salah.length; i++) ...[
                    if (i != 0) SizedBox(height: 6.h),
                    _SalahRow(item: _salah[i], onTap: () => _toggle(i)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SalahRow extends StatelessWidget {
  const _SalahRow({required this.item, required this.onTap});

  final _SalahItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: item.status == _SalahStatus.locked ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 17.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(fontSize: 13.sp, color: Colors.black),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEBB5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '+${item.points}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F6B45),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            _ActionCircle(status: item.status),
          ],
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.status});

  final _SalahStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _SalahStatus.completed:
        return Container(
          width: 26.r,
          height: 26.r,
          decoration: const BoxDecoration(
            color: AmolTrackingScreen._olive,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 15.sp, color: Colors.white),
        );
      case _SalahStatus.available:
        return Container(
          width: 26.r,
          height: 26.r,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AmolTrackingScreen._olive, width: 1.4),
          ),
          child: Icon(
            Icons.check,
            size: 13.sp,
            color: AmolTrackingScreen._olive,
          ),
        );
      case _SalahStatus.locked:
        return Container(
          width: 26.r,
          height: 26.r,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDADDC6), width: 1.2),
          ),
          child: Icon(
            Icons.lock_outline,
            size: 13.sp,
            color: const Color(0xFFB7BBA0),
          ),
        );
    }
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
