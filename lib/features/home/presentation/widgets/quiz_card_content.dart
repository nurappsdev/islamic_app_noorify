import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _textGreen = Color(0xFF9DAA62);
const _pointGreen = Color(0xFF8FA05A);

/// Content layer for the Quiz card. Draws no background of its own - place it
/// inside [HomeGradientShape]. Shares its header and title/counter block with
/// [AmalTrackerCardContent].
class QuizCardContent extends StatelessWidget {
  const QuizCardContent({
    super.key,
    this.percentage = 0,
    this.counter = '0/7',
    this.title = 'Quiz',
    this.percentageLabel,
    this.labels,
    this.onOpenTracker,
  });

  /// 0-100.
  final num percentage;

  /// Points earned / max points, e.g. `0/7`.
  final String counter;
  final String title;
  final String? percentageLabel;

  /// One overlapping glass tile per label, left to right.
  final List<String>? labels;
  final VoidCallback? onOpenTracker;

  @override
  Widget build(BuildContext context) {
    final labels =
        this.labels ??
        [
          for (var index = 1; index <= 2; index++)
            '${AppText.of(context).categoryQuiz} '
                '${context.localizedDigits('$index')}',
        ];
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
                      selectedSection: AmalSection.quiz,
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
                // Reference: each diamond is ~41% of the width, and the two
                // sit on one level with their centres ~33% of the width apart
                // (so neighbouring corners overlap a little).
                final extent = math.min(w * 0.41, h);
                final side = extent / QuizGlassCard.extentFactor;
                final count = labels.length;
                final span = w * 0.33 * (count - 1);
                final firstCentre = (w - span) / 2;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Later cards paint on top of earlier ones.
                    for (var i = 0; i < count; i++)
                      Positioned(
                        left: firstCentre + i * w * 0.33 - extent / 2,
                        top: (h - extent) / 2,
                        child: QuizGlassCard(
                          title: labels[i],
                          points: 1,
                          side: side,
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

/// A floating frosted-glass card in the shape of a rounded diamond (a rounded
/// square turned 45 degrees), with an upright points badge and [title].
///
/// One [Path] is used for the shadow, the backdrop blur clip, the fill and the
/// border, so they always line up. As in the design the glass is a light
/// frosted lift on the card background; it is set apart by a bright edge that
/// fades toward the bottom-right and a soft shadow outside the shape.
class QuizGlassCard extends StatelessWidget {
  const QuizGlassCard({
    super.key,
    required this.title,
    required this.side,
    this.points = 1,
    this.completed = false,
  });

  /// Height/width of the turned shape relative to [side].
  static const extentFactor = 1.182;

  final String title;
  final int points;

  /// Completed cards show a solid green badge instead of the white one.
  final bool completed;

  /// Side of the un-rotated rounded square.
  final double side;

  @override
  Widget build(BuildContext context) {
    final extent = side * extentFactor;
    final shape = _DiamondShape(side: side);
    final badge = extent * 0.24;
    return SizedBox(
      width: extent,
      height: extent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: shape,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _DiamondPainter(shape))),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: badge,
                height: badge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed ? _textGreen : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '+${context.localizedDigits('$points')}',
                  style: TextStyle(
                    fontSize: badge * 0.36,
                    color: completed ? Colors.white : _pointGreen,
                  ),
                ),
              ),
              SizedBox(height: extent * 0.03),
              SizedBox(
                width: extent * 0.62,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: extent * 0.145,
                      height: 1.1,
                      color: _textGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The rounded diamond outline, centred in a square as big as the widget.
class _DiamondShape extends CustomClipper<Path> {
  const _DiamondShape({required this.side});

  final double side;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: side, height: side),
      Radius.circular(side * 0.28),
    );
    final turn = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(math.pi / 4)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    return (Path()..addRRect(rrect)).transform(turn.storage);
  }

  @override
  bool shouldReclip(_DiamondShape old) => old.side != side;
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter(this.shape);

  final _DiamondShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getClip(size);
    final bounds = path.getBounds();
    final unit = size.height;

    // Shadow: outside the shape only (so it doesn't darken the glass), pushed
    // toward the bottom-right like the reference. Where the second card sits
    // on the first, its shadow falls across the first card's corner.
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(-unit, -unit, unit * 3, unit * 3)),
        path,
      ),
    );
    canvas.drawPath(
      path.shift(Offset(unit * 0.012, unit * 0.028)),
      Paint()
        ..color = const Color(0xFF3F4A22).withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.022),
    );
    canvas.restore();

    // Frosted fill: a light lift on the card background, a touch brighter at
    // the top-left where the light catches it.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.34),
            const Color(0xFFE6F0C8).withValues(alpha: 0.22),
          ],
        ).createShader(bounds),
    );

    // Glass edge: bright white at the top-left, fading to a faint line at the
    // bottom-right.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, unit * 0.008)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 1),
            Colors.white.withValues(alpha: 0.35),
          ],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => old.shape.side != shape.side;
}
