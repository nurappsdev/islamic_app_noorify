import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_gradient_header.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// Tap-to-count screen for a zikr sequence (designs `devImg/img_17.png` and
/// `devImg/img_18.png`).
///
/// Walks through [ZikrCounterArgs.items] one zikr at a time. The header count is
/// the running total; the dotted ring tracks the current zikr, the bottom bar
/// tracks the whole sequence. Count is in memory only.
class ZikrCounterScreen extends StatefulWidget {
  const ZikrCounterScreen({super.key, required this.args});

  final ZikrCounterArgs args;

  @override
  State<ZikrCounterScreen> createState() => _ZikrCounterScreenState();
}

class _ZikrCounterScreenState extends State<ZikrCounterScreen> {
  int _count = 0;

  List<ZikrItem> get _items => widget.args.items;
  int get _totalTarget => widget.args.totalTarget;

  /// Index of the zikr currently being counted, and how many of it are done.
  ({ZikrItem item, int done}) get _current {
    var remaining = _count;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (remaining < item.target || i == _items.length - 1) {
        return (item: item, done: remaining.clamp(0, item.target));
      }
      remaining -= item.target;
    }
    return (item: _items.last, done: _items.last.target);
  }

  bool get _finished => _totalTarget > 0 && _count >= _totalTarget;

  void _tap() {
    if (_finished) return;
    HapticFeedback.selectionClick();
    setState(() => _count++);
    final current = _current;
    if (current.done == current.item.target || _finished) {
      HapticFeedback.mediumImpact();
    }
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() => _count = 0);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final current = _current;
    final ringProgress = current.item.target > 0
        ? (current.done / current.item.target).clamp(0.0, 1.0)
        : 0.0;
    final barProgress = _totalTarget > 0
        ? (_count / _totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.only(bottom: 30.h),
        children: [
          ZikrGradientHeader(title: widget.args.title, total: _count),
          Transform.translate(
            offset: Offset(0, -22.h),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.45),
                    end: Offset.zero,
                  ).animate(animation);
                  return ClipRect(
                    child: SlideTransition(
                      position: slide,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
                child: _CurrentZikrCard(
                  key: ValueKey(current.item.name),
                  item: current.item,
                ),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Center(
            child: _TapButton(
              progress: ringProgress.toDouble(),
              label: _finished ? appText.zikrCompleted : appText.zikrTapToCount,
              onTap: _tap,
            ),
          ),
          SizedBox(height: 40.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              appText.zikrCompletingProgress,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3C4A28),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: _ProgressBar(progress: barProgress.toDouble()),
          ),
          SizedBox(height: 26.h),
          Center(
            child: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4C5A34),
              ),
              label: Text(
                appText.zikrCounterReset,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentZikrCard extends StatelessWidget {
  const _CurrentZikrCard({super.key, required this.item});

  final ZikrItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40.w),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8C4),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.arabic.isNotEmpty ? item.arabic : item.name,
              textAlign: TextAlign.center,
              textDirection: item.arabic.isNotEmpty
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF33421F),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 42.r,
            height: 42.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF9AAA63)),
            ),
            child: Text(
              '${item.target}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4C5A34),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapButton extends StatefulWidget {
  const _TapButton({
    required this.progress,
    required this.label,
    required this.onTap,
  });

  final double progress;
  final String label;
  final VoidCallback onTap;

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final size = 184.r;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DottedRingPainter(progress: widget.progress),
          child: Center(
            child: AnimatedScale(
              scale: _down ? 0.94 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: size * 0.82,
                height: size * 0.82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFEDF3DF), Color(0xFFC9DBA3)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C9A4E).withValues(alpha: .25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4C5A34),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress ring of dots for the current zikr (design `devImg/img_18.png`).
///
/// Counting fills the ring clockwise from the top: counted dots turn olive and
/// grow, the leading dot is the darkest, the rest stay pale green.
class _DottedRingPainter extends CustomPainter {
  const _DottedRingPainter({required this.progress});

  final double progress;

  static const int _dotCount = 33;
  static const Color _empty = Color(0xFFD3E2B7);
  static const Color _fillStart = Color(0xFF9BB165);
  static const Color _fillEnd = Color(0xFF3F5C24);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const maxDot = 6.2;
    final radius = size.width / 2 - maxDot - 1;

    final clamped = progress.clamp(0.0, 1.0);
    final filled = (clamped * _dotCount).round();

    for (var i = 0; i < _dotCount; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * (i / _dotCount);
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;

      final Color color;
      final double dotRadius;
      if (i < filled) {
        // 0 at the start of the arc, 1 at the leading (most recent) dot.
        final rel = filled <= 1 ? 1.0 : i / (filled - 1);
        color = Color.lerp(_fillStart, _fillEnd, rel)!;
        dotRadius = 4.4 + 1.8 * rel;
      } else {
        color = _empty;
        dotRadius = 4.4;
      }
      canvas.drawCircle(pos, dotRadius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 44.0;
        final fillWidth = (width * progress).clamp(height, width);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE8C4),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              if (progress > 0)
                Container(
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBD08C),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: (fillWidth - height).clamp(0.0, width - height),
                  ),
                  child: Container(
                    width: height,
                    height: height,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFCFE0AE),
                    ),
                    child: Text(
                      '$percent %',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4C5A34),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
