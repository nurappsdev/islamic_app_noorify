import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _darkGreen = Color(0xFFA1AD59);
const _ringTrack = Color(0xFFDAE5B8);

/// Content layer for the Quran card. Draws no background of its own - place
/// it inside [HomeGradientShape]. Shares its title/counter block with
/// [AmalTrackerCardContent].
class QuranCardContent extends StatelessWidget {
  const QuranCardContent({
    super.key,
    this.counter = '0/11',
    this.progress = 0,
    this.readingTimeLabel = '',
    this.title = 'Quran',
    this.percentageLabel,
    this.onOpenQuran,
  });

  /// Points earned / max points, e.g. `7/11`.
  final String counter;

  /// 0-1; how much of the ring is filled.
  final double progress;

  /// Time read today, e.g. `1 hr 37 min`. Empty shows nothing under the title.
  final String readingTimeLabel;
  final String title;
  final String? percentageLabel;
  final VoidCallback? onOpenQuran;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 22.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: progress.clamp(0.0, 1.0) * 100,
            percentageLabel: percentageLabel,
            onTap:
                onOpenQuran ??
                () => Navigator.of(context).pushNamed(RouteNames.quran),
          ),
          SizedBox(height: 18.h),
          PrayerSummaryWidget(title: title, counter: counter),
          const Spacer(),
          _QuranRing(
            progress: progress,
            readingTimeLabel: readingTimeLabel,
            title: title,
          ),
        ],
      ),
    );
  }
}

class _QuranRing extends StatelessWidget {
  const _QuranRing({
    required this.progress,
    required this.readingTimeLabel,
    required this.title,
  });

  final double progress;
  final String readingTimeLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final size = 164.r;
    final stroke = 18.r;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                strokeWidth: stroke,
              ),
            ),
          ),
          // Text lives inside the ring's inner circle, padded clear of the
          // stroke, and is independent of the painter.
          Padding(
            padding: EdgeInsets.all(stroke + 14.r),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: _darkGreen),
                  ),
                  if (readingTimeLabel.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      context.localizedDigits(readingTimeLabel),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.sp, color: _darkGreen),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round-capped ring that fills clockwise from 12 o'clock, with a soft drop
/// shadow so it sits on the card like the reference design.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = _ringTrack;
    canvas.drawShadow(
      Path()..addOval(arcRect),
      Colors.black.withValues(alpha: 0.35),
      6,
      false,
    );
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    if (progress <= 0) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _darkGreen;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
