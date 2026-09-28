import 'package:islami_app_noorify/shared/widgets/coming_soon_screen.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// The active Quran tab retains its screen. Other bottom-bar destinations
/// use the shared Coming Soon page without changing existing feature routes.
class QuranBottomNav extends StatefulWidget {
  const QuranBottomNav({super.key});
  @override
  State<QuranBottomNav> createState() => _QuranBottomNavState();
}

class _QuranBottomNavState extends State<QuranBottomNav> {
  bool _opening = false;
  Future<void> _comingSoon(String title, String section) async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          settings: RouteSettings(name: '/quran/coming-soon/$section'),
          builder: (_) => ComingSoonScreen(title: title),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  void _quran() {
    if (_opening) return;
    // This bar belongs to the Quran screen; retain its search and scroll state.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final items = [
      ('home', text.home, Icons.home_outlined),
      ('quran', 'Quran', Icons.menu_book_rounded),
      ('bookmarks', text.bookmarksTitle, Icons.bookmarks_outlined),
      ('history', text.readingHistoryTitle, Icons.history_rounded),
      ('more', 'More', Icons.grid_view_rounded),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: quranOlive,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: quranInk.withValues(alpha: .16),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final showLabel = bounds.maxWidth >= 300;
            return Row(
              children: [
                for (final item in items)
                  Expanded(
                    flex: item.$1 == 'quran' && showLabel ? 2 : 1,
                    child: Semantics(
                      selected: item.$1 == 'quran',
                      button: true,
                      child: Tooltip(
                        message: item.$2,
                        child: Material(
                          color: item.$1 == 'quran'
                              ? const Color(0xff5d886b)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            key: ValueKey('quran-nav-${item.$1}'),
                            borderRadius: BorderRadius.circular(28),
                            onTap: item.$1 == 'quran'
                                ? _quran
                                : () => _comingSoon(item.$2, item.$1),
                            child: SizedBox(
                              height: 56,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.$3, color: Colors.white, size: 24),
                                  if (item.$1 == 'quran' && showLabel) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        item.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
