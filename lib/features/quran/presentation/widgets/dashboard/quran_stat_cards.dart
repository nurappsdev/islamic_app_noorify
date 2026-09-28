import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Card container with a dashed border matching the design specification.
class QuranDashedCard extends StatelessWidget {
  const QuranDashedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: const Color(0xFFC7D4A0)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(16.r),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Stat card for "Total Quran Reading time".
class QuranTotalReadingTimeCard extends StatelessWidget {
  const QuranTotalReadingTimeCard({
    super.key,
    required this.readingTime,
    this.label = 'Total Quran Reading time',
  });

  final String readingTime;
  final String label;

  @override
  Widget build(BuildContext context) {
    return QuranDashedCard(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.w400,
              color: context.inkColor(const Color(0xFF222222)),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            readingTime,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.5.sp,
              fontWeight: FontWeight.w500,
              color: context.inkColor(const Color(0xFF1E211A)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card for "Most Reading Sura".
class QuranMostReadingSurahCard extends StatelessWidget {
  const QuranMostReadingSurahCard({
    super.key,
    required this.surahName,
    required this.time,
    this.label = 'Most Reading Sura',
  });

  final String surahName;
  final String time;
  final String label;

  @override
  Widget build(BuildContext context) {
    return QuranDashedCard(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.w400,
              color: context.inkColor(const Color(0xFF222222)),
            ),
          ),
          SizedBox(height: 12.h),
          // Wraps onto two lines when a long Surah name doesn't fit.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14.w,
            runSpacing: 4.h,
            children: [
              Text(
                surahName,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20.sp,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(const Color(0xFF1E211A)),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.w400,
                  color: context.inkColor(const Color(0xFF1E211A)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
