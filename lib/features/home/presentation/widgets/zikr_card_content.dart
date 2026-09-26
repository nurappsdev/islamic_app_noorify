import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _pillGreen = Color(0xFFDAE5B8);
const _textGreen = Color(0xFF8FA05A);
const _lineGreen = Color(0xFFA1AD59);

/// Content layer for the Zikr card. Draws no background of its own - place it
/// inside [HomeGradientShape]. Shares its header and title/counter block with
/// [AmalTrackerCardContent].
class ZikrCardContent extends StatelessWidget {
  const ZikrCardContent({
    super.key,
    this.percentage = 0,
    this.counter = '0/7',
    this.onOpenZikr,
  });

  /// 0-100.
  final num percentage;

  /// Points earned / max points, e.g. `0/7`.
  final String counter;
  final VoidCallback? onOpenZikr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 18.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: percentage,
            onTap:
                onOpenZikr ??
                () => Navigator.of(context).pushNamed(RouteNames.zikr),
          ),
          SizedBox(height: 26.h),
          PrayerSummaryWidget(title: 'Zikr', counter: counter),
          SizedBox(height: 4.h),
          const Expanded(child: _ZikrStairs()),
        ],
      ),
    );
  }
}

/// Five "Zikr n +1" pills climbing left to right, joined by a curved line and
/// set against dashed guide lines. Positions are fractions of the area so it
/// scales with the card.
class _ZikrStairs extends StatelessWidget {
  const _ZikrStairs();

  // Left edge (of width) and vertical centre (of height) per pill.
  static const _lefts = [0.04, 0.22, 0.41, 0.56, 0.70];
  static const _guides = [0.18, 0.34, 0.50, 0.66, 0.82];
  static const _pillWidth = 0.27;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final pillW = w * _pillWidth;
        final gap = 4.8.h;
        final count = _lefts.length;
        // Pills stack bottom-up with a fixed gap; shrink them only if five
        // plus the gaps won't fit.
        final pillH = [
          h * 0.22,
          46.0.h,
          (h - gap * (count - 1)) / count,
        ].reduce((a, b) => a < b ? a : b);
        final centersY = [
          for (var i = 0; i < count; i++) h - pillH / 2 - i * (pillH + gap),
        ];
        // The line meets each pill at its +1 circle.
        final anchors = [
          for (var i = 0; i < count; i++)
            Offset(w * _lefts[i] + pillW - pillH * 0.5, centersY[i]),
        ];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StairsPainter(
                  anchors: anchors,
                  guides: [for (final g in _guides) w * g],
                  strokeWidth: 4.r,
                ),
              ),
            ),
            for (var i = 0; i < _lefts.length; i++)
              Positioned(
                left: w * _lefts[i],
                top: centersY[i] - pillH / 2,
                width: pillW,
                height: pillH,
                child: _ZikrPill(label: 'Zikr ${i + 1}'),
              ),
          ],
        );
      },
    );
  }
}

class _ZikrPill extends StatelessWidget {
  const _ZikrPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        return Container(
          padding: EdgeInsets.only(left: h * 0.42, right: h * 0.08),
          decoration: BoxDecoration(
            color: _pillGreen,
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
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(fontSize: h * 0.42, color: _textGreen),
                  ),
                ),
              ),
              Container(
                width: h * 0.84,
                height: h * 0.84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 3.r,
                      offset: Offset(0, 1.h),
                    ),
                  ],
                ),
                child: Text(
                  '+1',
                  style: TextStyle(fontSize: h * 0.38, color: _textGreen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StairsPainter extends CustomPainter {
  const _StairsPainter({
    required this.anchors,
    required this.guides,
    required this.strokeWidth,
  });

  final List<Offset> anchors;
  final List<double> guides;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = _lineGreen.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (final x in guides) {
      for (var y = 0.0; y < size.height; y += 8) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 4), dash);
      }
    }

    if (anchors.length < 2) return;
    final path = Path()..moveTo(anchors.first.dx, anchors.first.dy);
    for (var i = 1; i < anchors.length - 1; i++) {
      final mid = (anchors[i] + anchors[i + 1]) / 2;
      path.quadraticBezierTo(anchors[i].dx, anchors[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(anchors.last.dx, anchors.last.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = _lineGreen.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_StairsPainter old) =>
      old.anchors != anchors ||
      old.guides != guides ||
      old.strokeWidth != strokeWidth;
}
