import 'package:islami_app_noorify/shared/widgets/coming_soon_screen.dart';
import '../screens/quran_plan_screen.dart';
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

/// Owns tab content and keeps the Quran subtree and navigation bar mounted.
class QuranTabShell extends StatefulWidget {
  const QuranTabShell({super.key, required this.child});
  final Widget child;

  @override
  State<QuranTabShell> createState() => _QuranTabShellState();
}

class _QuranTabShellState extends State<QuranTabShell> {
  String _selected = 'home';

  void _select(String section) {
    FocusScope.of(context).unfocus();
    if (_selected != section) setState(() => _selected = section);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final sections = ['home', 'learn', 'topic', 'plan', 'dashboard'];
    return PopScope(
      canPop: _selected == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _select('home');
      },
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: IndexedStack(
          index: sections.indexOf(_selected),
          children: [
            widget.child,
            ComingSoonScreen(
              title: text.learn.isNotEmpty ? text.learn : 'Learn',
              onBack: () => _select('home'),
            ),
            ComingSoonScreen(title: 'Topic', onBack: () => _select('home')),
            QuranPlanScreen(onBack: () => _select('home')),
            ComingSoonScreen(
              title: text.dashboard.isNotEmpty ? text.dashboard : 'Dashboard',
              onBack: () => _select('home'),
            ),
          ],
        ),
        bottomNavigationBar: QuranBottomNav(
          selected: _selected,
          onSelected: _select,
        ),
      ),
    );
  }
}

/// Tab selection changes content in the owning shell, without pushing routes.
class QuranBottomNav extends StatelessWidget {
  const QuranBottomNav({super.key, this.selected = 'home', this.onSelected});
  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final items = [
      ('home', text.home, Icons.home_outlined),
      (
        'learn',
        text.learn.isNotEmpty ? text.learn : 'Learn',
        Icons.school_outlined,
      ),
      ('topic', 'Topic', Icons.topic_outlined),
      (
        'plan',
        text.planner.isNotEmpty ? text.planner : 'Plan',
        Icons.assignment_turned_in_outlined,
      ),
      (
        'dashboard',
        text.dashboard.isNotEmpty ? text.dashboard : 'Dashboard',
        Icons.grid_view_outlined,
      ),
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
                    flex: item.$1 == selected && showLabel ? 2 : 1,
                    child: Semantics(
                      selected: item.$1 == selected,
                      button: true,
                      child: Tooltip(
                        message: item.$2,
                        child: Material(
                          color: item.$1 == selected
                              ? const Color(0xff5d886b)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            key: ValueKey('quran-nav-${item.$1}'),
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => onSelected?.call(item.$1),
                            child: SizedBox(
                              height: 56,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.$3, color: Colors.white, size: 24),
                                  if (item.$1 == selected && showLabel) ...[
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
