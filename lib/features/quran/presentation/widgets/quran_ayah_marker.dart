import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// Draw the ornament inside explicit bounds: Quran-font bracket glyphs can
/// paint outside their advance width and overlap adjacent Arabic words.
class QuranAyahMarker extends StatelessWidget {
  const QuranAyahMarker({
    super.key,
    required this.number,
    required this.scale,
    this.sign = '',
    this.signStyle,
  });
  final int number;
  final double scale;

  /// The ayah's end marks (waqf signs, ruku), drawn centred above the ring,
  /// in [signStyle]: the Arabic's own font, whose glyphs they are.
  final String sign;
  final TextStyle? signStyle;

  @override
  Widget build(BuildContext context) {
    final color = context.inkColor(Colors.black);
    // Bangla digits (U+09E6 onwards), the readers' own numerals.
    final digits = number
        .toString()
        .split('')
        .map((digit) => String.fromCharCode(0x9E6 + int.parse(digit)))
        .join();
    // A snug ring around the number: just wide enough for its digits, so
    // single-digit ayahs get the smallest marker.
    final size = (17.0 + 3 * digits.length) * scale;
    final ring = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _Ornament(color),
        // The Quran font has no Bangla digits, so the app font draws them;
        // scaled down if needed so three digits stay inside the ring.
        child: Padding(
          padding: EdgeInsets.all(size * .18),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                digits,
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 12 * scale,
                  height: 1,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Room for the small marks (small alif/waw) that Quran fonts
    // hang past the last word's advance width, so they stay out of the ring.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: sign.isEmpty
          ? ring
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ring,
                // Above the ring, outside the marker's own size, so a
                // signed ayah's line is no taller than any other. The line
                // height (2.1) leaves room for it.
                // The font draws a mark high over the space it sits on, and
                // a little left of it: these offsets centre it just clear
                // of the ring.
                Positioned(
                  left: -size + 3.5 * scale,
                  right: -size - 3.5 * scale,
                  top: -10 * scale,
                  child: Text(
                    // On a space: a mark with nothing before it would be
                    // drawn on a dotted circle.
                    ' $sign',
                    key: const ValueKey('ayah-end-sign'),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    textScaler: TextScaler.noScaling,
                    style: (signStyle ?? const TextStyle()).copyWith(
                      fontSize: 20 * scale,
                      height: 1,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Ornament extends CustomPainter {
  const _Ornament(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()..color = color;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .44;
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        size.shortestSide * .024,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_Ornament oldDelegate) => oldDelegate.color != color;
}
