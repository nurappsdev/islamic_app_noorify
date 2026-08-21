import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';

class AmolTrackingScreen extends StatefulWidget {
  const AmolTrackingScreen({
    super.key,
    this.pointLabel = 'Point : 30/40',
    this.progressLabel = '86 %',
    this.progress = .86,
    this.initialExpandedCategory = 'Fardh Prayer',
    this.now,
  });

  final String pointLabel;
  final String progressLabel;
  final double progress;
  final String? initialExpandedCategory;
  final DateTime Function()? now;

  @override
  State<AmolTrackingScreen> createState() => _AmolTrackingScreenState();
}

class _AmolTrackingScreenState extends State<AmolTrackingScreen> {
  late String? _expandedCategory = widget.initialExpandedCategory;

  var _fardhItems = const [
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

  var _sunnahItems = const [
    _SalahItem(
      name: 'Fajr Sunnah',
      icon: Icons.wb_twilight,
      iconColor: Color(0xFFFFC83D),
      points: 1,
      status: _SalahStatus.completed,
    ),
    _SalahItem(
      name: 'Duhr Sunnah',
      icon: Icons.wb_sunny,
      iconColor: Color(0xFFFFC83D),
      points: 1,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Asr Sunnah',
      icon: Icons.sunny,
      iconColor: Color(0xFFFFAA2C),
      points: 1,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Magrib Sunnah',
      icon: Icons.wb_twilight_outlined,
      iconColor: Color(0xFFFF8E4A),
      points: 1,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Esa Sunnah',
      icon: Icons.nights_stay,
      iconColor: Color(0xFFEACB2B),
      points: 1,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Witr',
      icon: Icons.nightlight_round,
      iconColor: Color(0xFFEACB2B),
      points: 1,
      status: _SalahStatus.locked,
    ),
  ];

  var _naflItems = const [
    _SalahItem(
      name: 'Tahajjud',
      icon: Icons.nights_stay,
      iconColor: Color(0xFF7FA8C9),
      points: 1,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Ishraq',
      icon: Icons.wb_sunny,
      iconColor: Color(0xFFFFC83D),
      points: .5,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Chast',
      icon: Icons.wb_sunny,
      iconColor: Color(0xFFFFC83D),
      points: .5,
      status: _SalahStatus.locked,
    ),
    _SalahItem(
      name: 'Awabin',
      icon: Icons.wb_sunny,
      iconColor: Color(0xFFFFC83D),
      points: .5,
      status: _SalahStatus.locked,
    ),
  ];

  var _naflMoreItems = const [
    _SalahItem(
      name: 'Sadaqah',
      icon: Icons.volunteer_activism,
      iconColor: Color(0xFFE8916B),
      points: .5,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Karze Hasanah',
      icon: Icons.handshake,
      iconColor: Color(0xFF6FA8D8),
      points: .5,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Nafl Fasting',
      icon: Icons.self_improvement,
      iconColor: Color(0xFFC9A227),
      points: .5,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Physical Exercise',
      icon: Icons.fitness_center,
      iconColor: Color(0xFF4FB0C6),
      points: .5,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Given Good Ad Vice',
      icon: Icons.campaign,
      iconColor: Color(0xFF4FB0C6),
      points: .5,
      status: _SalahStatus.available,
    ),
    _SalahItem(
      name: 'Skill Development',
      icon: Icons.emoji_objects,
      iconColor: Color(0xFFFFC83D),
      points: .5,
      status: _SalahStatus.available,
    ),
  ];

  static const _quranEntry = _InfoEntry(
    icon: Icons.auto_awesome,
    iconColor: Color(0xFFFF8A50),
    name: 'Quran Tilawat',
    points: 11,
  );
  static const _hadithEntry = _InfoEntry(
    icon: Icons.auto_awesome,
    iconColor: Color(0xFFFF8A50),
    name: 'Hadith Reading',
    points: 8,
  );
  static const _quizEntry = _InfoEntry(
    icon: Icons.quiz,
    iconColor: Color(0xFFFFC83D),
    name: 'Giving Quiz',
    points: 2.5,
  );

  void _toggleCategory(String title) {
    setState(() {
      _expandedCategory = _expandedCategory == title ? null : title;
    });
  }

  void _toggleFardhItem(int index) {
    setState(() => _fardhItems = _toggledSalah(_fardhItems, index));
  }

  void _toggleSunnahItem(int index) {
    setState(() => _sunnahItems = _toggledSalah(_sunnahItems, index));
  }

  void _toggleNaflItem(int index) {
    setState(() => _naflItems = _toggledSalah(_naflItems, index));
  }

  void _toggleNaflMoreItem(int index) {
    setState(() => _naflMoreItems = _toggledSalah(_naflMoreItems, index));
  }

  static List<_SalahItem> _toggledSalah(List<_SalahItem> items, int index) {
    final item = items[index];
    if (item.status == _SalahStatus.locked) return items;
    return [
      for (var i = 0; i < items.length; i++)
        if (i == index)
          item.copyWith(
            status: item.status == _SalahStatus.completed
                ? _SalahStatus.available
                : _SalahStatus.completed,
          )
        else
          items[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final today = (widget.now ?? DateTime.now)();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AmolHeader(title: 'Amol Tracking'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
                children: [
                  AmolSummaryCard(
                    pointLabel: widget.pointLabel,
                    progressLabel: widget.progressLabel,
                    progress: widget.progress,
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    formatAmolDate(today),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _ExpandableAmolRow(
                    title: 'Fardh Prayer',
                    items: _fardhItems,
                    expanded: _expandedCategory == 'Fardh Prayer',
                    onToggleExpanded: () => _toggleCategory('Fardh Prayer'),
                    onToggleItem: _toggleFardhItem,
                  ),
                  SizedBox(height: 12.h),
                  _ExpandableAmolRow(
                    title: 'Sunnah and Witr',
                    items: _sunnahItems,
                    expanded: _expandedCategory == 'Sunnah and Witr',
                    onToggleExpanded: () =>
                        _toggleCategory('Sunnah and Witr'),
                    onToggleItem: _toggleSunnahItem,
                  ),
                  SizedBox(height: 12.h),
                  _ExpandableAmolRow(
                    title: 'Nafl Salat',
                    items: _naflItems,
                    expanded: _expandedCategory == 'Nafl Salat',
                    onToggleExpanded: () => _toggleCategory('Nafl Salat'),
                    onToggleItem: _toggleNaflItem,
                  ),
                  SizedBox(height: 12.h),
                  _InfoExpandableRow(
                    title: 'Quran',
                    fraction: '0/11',
                    entry: _quranEntry,
                    expanded: _expandedCategory == 'Quran',
                    onToggleExpanded: () => _toggleCategory('Quran'),
                  ),
                  SizedBox(height: 12.h),
                  _InfoExpandableRow(
                    title: 'Hadith',
                    fraction: '0/8',
                    entry: _hadithEntry,
                    expanded: _expandedCategory == 'Hadith',
                    onToggleExpanded: () => _toggleCategory('Hadith'),
                  ),
                  SizedBox(height: 12.h),
                  _InfoExpandableRow(
                    title: 'Quiz',
                    fraction: '0/2.5',
                    entry: _quizEntry,
                    expanded: _expandedCategory == 'Quiz',
                    onToggleExpanded: () => _toggleCategory('Quiz'),
                  ),
                  SizedBox(height: 12.h),
                  _GroupedExpandableRow(
                    title: 'Nafl & more',
                    items: _naflMoreItems,
                    expanded: _expandedCategory == 'Nafl & more',
                    onToggleExpanded: () => _toggleCategory('Nafl & more'),
                    onToggleItem: _toggleNaflMoreItem,
                  ),
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
              child: const ColoredBox(color: amolOlive),
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
  final num points;
  final _SalahStatus status;

  _SalahItem copyWith({_SalahStatus? status}) => _SalahItem(
    name: name,
    icon: icon,
    iconColor: iconColor,
    points: points,
    status: status ?? this.status,
  );
}

class _AccordionHeader extends StatelessWidget {
  const _AccordionHeader({
    required this.title,
    required this.progress,
    required this.fractionLabel,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final double progress;
  final String fractionLabel;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                        fractionLabel,
                        style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
              size: 20.sp,
              color: const Color(0xFF7E8C61),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFFF7F7E7) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: expanded
          ? child
          : CustomPaint(
              painter: _DashedCardBorderPainter(radius: 16.r),
              child: child,
            ),
    );
  }
}

String _formatPoints(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _ExpandableAmolRow extends StatelessWidget {
  const _ExpandableAmolRow({
    required this.title,
    required this.items,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggleItem,
  });

  final String title;
  final List<_SalahItem> items;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onToggleItem;

  @override
  Widget build(BuildContext context) {
    final num total = items.fold(0, (sum, item) => sum + item.points);
    final num completed = items
        .where((item) => item.status == _SalahStatus.completed)
        .fold(0, (sum, item) => sum + item.points);
    final progress = total == 0 ? 0.0 : completed / total;
    return _AccordionCard(
      expanded: expanded,
      child: Column(
        children: [
          _AccordionHeader(
            title: title,
            progress: progress,
            fractionLabel: '${_formatPoints(completed)}/${_formatPoints(total)}',
            expanded: expanded,
            onTap: onToggleExpanded,
          ),
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i != 0) SizedBox(height: 6.h),
                    _SalahRow(item: items[i], onTap: () => onToggleItem(i)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoEntry {
  const _InfoEntry({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.points,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final num points;
}

class _InfoExpandableRow extends StatelessWidget {
  const _InfoExpandableRow({
    required this.title,
    required this.fraction,
    required this.entry,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final String title;
  final String fraction;
  final _InfoEntry entry;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return _AccordionCard(
      expanded: expanded,
      child: Column(
        children: [
          _AccordionHeader(
            title: title,
            progress: 0,
            fractionLabel: fraction,
            expanded: expanded,
            onTap: onToggleExpanded,
          ),
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: _InfoEntryRow(entry: entry),
            ),
        ],
      ),
    );
  }
}

class _InfoEntryRow extends StatelessWidget {
  const _InfoEntryRow({required this.entry});

  final _InfoEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(entry.icon, color: entry.iconColor, size: 16.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            entry.name,
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
            '+${_formatPoints(entry.points)}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5F6B45),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupedExpandableRow extends StatelessWidget {
  const _GroupedExpandableRow({
    required this.title,
    required this.items,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggleItem,
  });

  final String title;
  final List<_SalahItem> items;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onToggleItem;

  @override
  Widget build(BuildContext context) {
    final num total = items.fold(0, (sum, item) => sum + item.points);
    final num completed = items
        .where((item) => item.status == _SalahStatus.completed)
        .fold(0, (sum, item) => sum + item.points);
    final progress = total == 0 ? 0.0 : completed / total;
    final mid = (items.length / 2).ceil();
    final firstGroup = items.sublist(0, mid);
    final secondGroup = items.sublist(mid);

    Widget group(List<_SalahItem> groupItems, int offset) => Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          for (var i = 0; i < groupItems.length; i++) ...[
            if (i != 0) SizedBox(height: 6.h),
            _SalahRow(
              item: groupItems[i],
              onTap: () => onToggleItem(offset + i),
            ),
          ],
        ],
      ),
    );

    return _AccordionCard(
      expanded: expanded,
      child: Column(
        children: [
          _AccordionHeader(
            title: title,
            progress: progress,
            fractionLabel: '${_formatPoints(completed)}/${_formatPoints(total)}',
            expanded: expanded,
            onTap: onToggleExpanded,
          ),
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: Column(
                children: [
                  group(firstGroup, 0),
                  SizedBox(height: 10.h),
                  group(secondGroup, mid),
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
                '+${_formatPoints(item.points)}',
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
            color: amolOlive,
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
            border: Border.all(color: amolOlive, width: 1.4),
          ),
          child: Icon(
            Icons.check,
            size: 13.sp,
            color: amolOlive,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AmolDashboardScreen(),
          ),
        ),
        child: Container(
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
        ),
      ),
    );
  }
}
