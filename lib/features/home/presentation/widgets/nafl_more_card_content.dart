import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _pillGreen = Color(0xFFDAE5B8);
const _textGreen = Color(0xFF8FA05A);
const _activeGreen = Color(0xFFA1AD59);
const _ringFill = Color(0xFFD9E5B5);
const _ringEdge = Color(0xFFB9C98C);

/// One Nafl / "more" deed around the ring. Plain data so it can come straight
/// from the tracker API.
class NaflItemData {
  const NaflItemData({
    required this.name,
    required this.points,
    this.completed = false,
    this.itemKey,
  });

  /// The tracker's `itemKey` for this deed, when it comes from the tracker.
  final String? itemKey;

  final String name;
  final num points;

  /// Tracked today; drawn in the active (dark) style.
  final bool completed;
}

/// Content layer for the Nafl and more card. Draws no background of its own -
/// place it inside [HomeGradientShape]. Shares its header and title/counter
/// block with [AmalTrackerCardContent].
///
/// [items] are laid out two per row (left, right) along a ring, so any number
/// the API returns works - six gives the designed three rows.
class NaflMoreCardContent extends StatelessWidget {
  const NaflMoreCardContent({
    super.key,
    this.percentage = 0,
    this.counter = '0/7',
    this.title = 'Nafl and more',
    this.percentageLabel,
    this.items = const [],
    this.onOpenDashboard,
    this.onItemTap,
  });

  /// 0-100.
  final num percentage;

  /// Points earned / max points, e.g. `0/7`.
  final String counter;
  final String title;
  final String? percentageLabel;
  final List<NaflItemData> items;
  final VoidCallback? onOpenDashboard;

  /// A tap on one deed's pill.
  final ValueChanged<NaflItemData>? onItemTap;

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
                onOpenDashboard ??
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AmolDashboardScreen(),
                  ),
                ),
          ),
          SizedBox(height: 26.h),
          PrayerSummaryWidget(title: title, counter: counter),
          SizedBox(height: 8.h),
          Expanded(
            child: _NaflRing(items: items, onItemTap: onItemTap),
          ),
        ],
      ),
    );
  }
}

class _NaflRing extends StatelessWidget {
  const _NaflRing({required this.items, this.onItemTap});

  final List<NaflItemData> items;
  final ValueChanged<NaflItemData>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final rows = (items.length + 1) ~/ 2;
        final pillH = math.min(h * 0.28, 40.h);
        final pillW = w * 0.30;
        // Row centres run from the top pill to the bottom pill.
        double centerY(int r) =>
            rows == 1 ? h * 0.5 : pillH / 2 + r * (h - pillH) / (rows - 1);
        // Pills sit nearer the middle on the first/last rows and bulge out on
        // the rows between, following the ring.
        double offset(int r) {
          final t = rows == 1 ? 0.0 : r / (rows - 1);
          return w * (0.22 + 0.10 * math.sin(math.pi * t));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RingPainter(segments: items.length, pillH: pillH),
              ),
            ),
            for (var i = 0; i < items.length; i++)
              () {
                final row = i ~/ 2;
                final right = i.isOdd;
                final cx = w / 2 + (right ? offset(row) : -offset(row));
                // The last row flips its badge side, as in the design.
                final circleFirst = right != (rows > 1 && row == rows - 1);
                return Positioned(
                  left: cx - pillW / 2,
                  top: centerY(row) - pillH / 2,
                  width: pillW,
                  height: pillH,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onItemTap == null
                        ? null
                        : () => onItemTap!(items[i]),
                    child: _NaflPill(item: items[i], circleFirst: circleFirst),
                  ),
                );
              }(),
          ],
        );
      },
    );
  }
}

class _NaflPill extends StatelessWidget {
  const _NaflPill({required this.item, required this.circleFirst});

  final NaflItemData item;
  final bool circleFirst;

  static String _points(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : '$v';

  @override
  Widget build(BuildContext context) {
    final active = item.completed;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final circle = Container(
          width: h * 0.8,
          height: h * 0.8,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Text(
            context.localizedDigits(_points(item.points)),
            style: TextStyle(fontSize: h * 0.34, color: _textGreen),
          ),
        );
        final label = Expanded(
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: circleFirst ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: h * 0.34,
              color: active ? Colors.white : _textGreen,
            ),
          ),
        );
        return Container(
          padding: EdgeInsets.symmetric(horizontal: h * 0.1),
          decoration: BoxDecoration(
            color: active ? _activeGreen : _pillGreen,
            borderRadius: BorderRadius.circular(h),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: active ? 0.2 : 0.12),
                blurRadius: 5.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Row(
            children: circleFirst
                ? [circle, SizedBox(width: h * 0.12), label]
                : [label, SizedBox(width: h * 0.06), circle],
          ),
        );
      },
    );
  }
}

/// A thin, segmented ring behind the pills: soft green plates with a faint
/// outline, split by small gaps.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.segments, required this.pillH});

  final int segments;
  final double pillH;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments < 2) return;
    final band = size.height * 0.16;
    final rx = size.width * 0.26;
    final ry = size.height * 0.34;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.56),
      width: rx * 2,
      height: ry * 2,
    );
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = band
      ..color = _ringFill.withValues(alpha: 0.9);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _ringEdge;
    final gap = 0.12;
    final sweep = 2 * math.pi / segments - gap;
    var start = -math.pi / 2 + gap / 2;
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(oval, start, sweep, false, fill);
      canvas.drawArc(oval.inflate(band / 2), start, sweep, false, edge);
      canvas.drawArc(oval.deflate(band / 2), start, sweep, false, edge);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.segments != segments || old.pillH != pillH;
}
