import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

const quranOlive = Color(0xffa1ae57);
const quranInk = Color(0xff889569);
const quranBorder = Color(0xffd7e5a6);
const quranPale = Color(0xfff3f6e7);

class QuranRetry extends StatelessWidget {
  const QuranRetry({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppText.of(context).quranLoadError, textAlign: TextAlign.center),
        TextButton(
          onPressed: onRetry,
          child: Text(AppText.of(context).tryAgain),
        ),
      ],
    ),
  );
}

class QuranListRow extends StatelessWidget {
  const QuranListRow({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.arabic,
  });
  final int number;
  final String title, subtitle;
  final String? arabic;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: quranBorder)),
      ),
      child: Row(
        children: [
          CustomPaint(
            painter: _NumberStar(),
            child: SizedBox(
              width: 35,
              height: 35,
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Color(0xff608568),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: context.inkColor(const Color(0xff302647)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff9090ac),
                  ),
                ),
              ],
            ),
          ),
          if (arabic != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                arabic!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Noorehuda',
                  fontSize: 20,
                  color: quranInk,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _NumberStar extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final radius = size.width * (i.isEven ? .47 : .35);
      final point = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = quranBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(_NumberStar oldDelegate) => false;
}

/// Quran-specific styling keeps the rest of the application's navigation intact.
class QuranBottomNav extends StatelessWidget {
  const QuranBottomNav({super.key});
  void _openRoot(BuildContext context, String destination) {
    var found = false;
    final navigator = Navigator.of(context);
    navigator.popUntil((route) {
      found =
          route.settings.name == destination ||
          (destination == RouteNames.quran &&
              route.settings.name == RouteNames.quranSurahs);
      return found || route.isFirst;
    });
    if (!found) navigator.pushReplacementNamed(destination);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(19, 12, 19, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: quranOlive,
        borderRadius: BorderRadius.circular(38),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _openRoot(context, RouteNames.home),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(
                      AppText.of(context).home,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openRoot(context, RouteNames.quran),
                    isSelected: true,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xff5d886b),
                    ),
                    tooltip: 'Quran',
                    icon: Icon(Icons.menu_book_outlined, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: 'Bookmarks',
                    onPressed: () =>
                        Navigator.pushNamed(context, RouteNames.quranBookmarks),
                    icon: const Icon(
                      Icons.bookmarks_outlined,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reading history',
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.quranReadingHistory,
                    ),
                    icon: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Home',
                    onPressed: () => _openRoot(context, RouteNames.home),
                    icon: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                    ),
                  ),
                ].indexed
                .map(
                  (entry) =>
                      Expanded(flex: entry.$1 == 0 ? 2 : 1, child: entry.$2),
                )
                .toList(),
      ),
    ),
  );
}
