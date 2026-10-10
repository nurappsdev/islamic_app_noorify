import 'package:tuhfatul_muslim/shared/widgets/coming_soon_screen.dart';
import '../screens/quran_dashboard_screen.dart';
import '../screens/quran_plan_screen.dart';
import '../screens/quran_saved_screen.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../quran_text.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';

const quranOlive = Color(0xffa1ae57);
const quranInk = Color(0xff889569);
const quranBorder = Color(0xffd7e5a6);
const quranPale = Color(0xfff3f6e7);

class QuranRetry extends StatelessWidget {
  const QuranRetry({super.key, required this.onRetry, this.offline = false});
  final VoidCallback onRetry;

  /// The content is not on the device and the server is unreachable.
  final bool offline;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            offline
                ? QuranText.of(context).offlineNotDownloaded
                : AppText.of(context).quranLoadError,
            key: offline ? const ValueKey('quran-offline-message') : null,
            textAlign: TextAlign.center,
          ),
        ),
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
  Widget build(BuildContext context) {
    // The badge grows with the user's text size, so the number always fits.
    final badge = MediaQuery.textScalerOf(context).scale(35);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: quranBorder)),
        ),
        child: Row(
          children: [
            CustomPaint(
              painter: _NumberStar(),
              child: SizedBox.square(
                dimension: badge,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      QuranText.of(context).n(number),
                      style: const TextStyle(
                        color: Color(0xff608568),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: context.inkColor(const Color(0xff302647)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
  const QuranTabShell({super.key, required this.child, this.onExit});
  final Widget child;

  /// Called for a back from the home tab when there is no route below to
  /// return to (e.g. Quran replaced the app's Home), instead of closing the
  /// app.
  final VoidCallback? onExit;

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
    final sections = ['home', 'learn', 'saved', 'plan', 'dashboard'];
    final hasRouteBelow = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: _selected == 'home' && (hasRouteBelow || widget.onExit == null),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selected != 'home') {
          _select('home');
        } else {
          widget.onExit?.call();
        }
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
            QuranSavedScreen(
              onBack: () => _select('home'),
              active: _selected == 'saved',
            ),
            QuranPlanScreen(onBack: () => _select('home')),
            QuranDashboardScreen(
              onBack: () => _select('home'),
              active: _selected == 'dashboard',
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
      (
        'saved',
        text.saved.isNotEmpty ? text.saved : 'Saved',
        Icons.bookmark_border_rounded,
      ),
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
    return AppBottomNavBar(
      selectedIndex: items.indexWhere((item) => item.$1 == selected),
      items: [
        for (final item in items)
          AppBottomNavItem(
            key: ValueKey('quran-nav-${item.$1}'),
            icon: item.$3,
            label: item.$2,
            onTap: () => onSelected?.call(item.$1),
          ),
      ],
    );
  }
}
