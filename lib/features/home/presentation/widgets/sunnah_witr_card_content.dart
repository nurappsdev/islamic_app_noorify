import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _pillGreen = Color(0xFFDAE5B8);
const _textGreen = Color(0xFF8FA05A);
const _darkGreen = Color(0xFFA1AD59);

/// One prayer's Sunnah state on the ring. Plain data so it can come straight
/// from the tracker API.
class SunnahPrayerData {
  const SunnahPrayerData({
    required this.prayerName,
    required this.points,
    this.label,
    this.sunnahCompleted = false,
  });

  /// Matches the pill labels: `Fajr`, `Duhr`, `Asr`, `Magrib`, `Esa`.
  final String prayerName;
  final String? label;
  final num points;

  /// Tracked today; the pill is drawn dark green.
  final bool sunnahCompleted;
}

/// Content layer for the Sunnah and Witr card. Draws no background of its own
/// - place it inside [HomeGradientShape]. Shares its header and title/counter
/// block with [AmalTrackerCardContent].
class SunnahWitrCardContent extends StatelessWidget {
  const SunnahWitrCardContent({
    super.key,
    this.percentage = 0,
    this.counter = '0/6',
    this.title = 'Sunnah and Witr',
    this.percentageLabel,
    this.prayers = const [],
    this.onOpenTracker,
    this.onPrayerTap,
  });

  /// 0-100.
  final num percentage;

  /// Points earned / max points, e.g. `0/6`.
  final String counter;
  final String title;
  final String? percentageLabel;

  /// Per-prayer points and tracked state, matched to the pills by
  /// [SunnahPrayerData.prayerName]. Prayers missing here show the design's
  /// default points, not tracked.
  final List<SunnahPrayerData> prayers;
  final VoidCallback? onOpenTracker;

  /// A tap on one prayer's pill, with the pill's name (`Fajr`, `Duhr`, ...).
  final ValueChanged<String>? onPrayerTap;

  // Clockwise from the upper right, as in the design.
  static const _pills = [
    ('Fajr', 1, (left: 0.56, centerY: 0.30, width: 0.427), true),
    ('Duhr', 1, (left: 0.56, centerY: 0.76, width: 0.34), true),
    ('Asr', 1, (left: 0.177, centerY: 0.88, width: 0.30), false),
    ('Magrib', 1, (left: 0.012, centerY: 0.53, width: 0.33), false),
    ('Esa', 2, (left: 0.142, centerY: 0.16, width: 0.327), false),
  ];

  SunnahPrayerData? _dataFor(String name) {
    for (final p in prayers) {
      if (p.prayerName == name) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 18.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: percentage,
            percentageLabel: percentageLabel,
            onTap:
                onOpenTracker ??
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AmolTrackingScreen(
                      selectedSection: AmalSection.sunnahWitr,
                    ),
                  ),
                ),
          ),
          SizedBox(height: 26.h),
          PrayerSummaryWidget(title: title, counter: counter),
          SizedBox(height: 8.h),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final h = box.maxHeight;
                final pillH = math.min(h * 0.27, 44.h);
                final ringOuter = h * 0.78;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: w * 0.455 - ringOuter / 2,
                      top: h * 0.46 - ringOuter / 2,
                      width: ringOuter,
                      height: ringOuter,
                      child: CustomPaint(
                        painter: _SegmentRingPainter(strokeWidth: h * 0.14),
                      ),
                    ),
                    for (final (name, defaultPoints, a, circleFirst) in _pills)
                      Positioned(
                        left: w * a.left,
                        top: h * a.centerY - pillH / 2,
                        width: w * a.width,
                        height: pillH,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onPrayerTap == null
                              ? null
                              : () => onPrayerTap!(name),
                          child: _SunnahPill(
                            name:
                                _dataFor(name)?.label?.trim().isNotEmpty == true
                                ? _dataFor(name)!.label!.trim()
                                : _localizedPrayerName(
                                    AppText.of(context),
                                    name,
                                  ),
                            points: _dataFor(name)?.points ?? defaultPoints,
                            circleFirst: circleFirst,
                            active: _dataFor(name)?.sunnahCompleted ?? false,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SunnahPill extends StatelessWidget {
  const _SunnahPill({
    required this.name,
    required this.points,
    required this.circleFirst,
    required this.active,
  });

  final String name;
  final num points;
  final bool circleFirst;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final circle = Container(
          width: h * 0.82,
          height: h * 0.82,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Text(
            '+${context.localizedDigits('${points == points.roundToDouble() ? points.toInt() : points}')}',
            style: TextStyle(fontSize: h * 0.36, color: _textGreen),
          ),
        );
        final label = Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: TextStyle(
                fontSize: h * 0.4,
                color: active ? Colors.white : _textGreen,
              ),
            ),
          ),
        );
        return Container(
          padding: EdgeInsets.symmetric(horizontal: h * 0.09),
          decoration: BoxDecoration(
            color: active ? _darkGreen : _pillGreen,
            borderRadius: BorderRadius.circular(h),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 5.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Row(
            children: circleFirst
                ? [circle, SizedBox(width: h * 0.1), label]
                : [SizedBox(width: h * 0.1), label, circle],
          ),
        );
      },
    );
  }
}

String _localizedPrayerName(AppText appText, String key) => switch (key) {
  'Fajr' => appText.prayerFajr,
  'Duhr' => appText.prayerDhuhr,
  'Asr' => appText.prayerAsr,
  'Magrib' => appText.prayerMaghribAndIftar,
  'Esa' => appText.prayerIsha,
  _ => key,
};

/// Five dark arcs with small gaps, drawn behind the pills.
class _SegmentRingPainter extends CustomPainter {
  const _SegmentRingPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = _darkGreen;
    const count = 5;
    const gap = 10 * math.pi / 180;
    const sweep = 2 * math.pi / count - gap;
    // First arc starts just past the top-right gap.
    var start = -math.pi / 2 - 0.45 + gap / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_SegmentRingPainter old) => old.strokeWidth != strokeWidth;
}
