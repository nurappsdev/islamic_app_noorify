import 'package:flutter/material.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';

/// The Quiz & Learn section: Home, Learn, Planner and Dashboard behind one
/// sticky [QuizBottomNav]. Switching tabs only swaps the content - the bar
/// stays put, and each tab keeps its state once it has been opened.
class QuizShell extends StatefulWidget {
  const QuizShell({super.key, required this.tabs, this.initialTab = 0})
    : assert(tabs.length == QuizBottomNav.tabCount);

  /// The route that opens the section on each tab.
  static const tabRoutes = [
    RouteNames.winQuiz,
    RouteNames.learning,
    RouteNames.planner,
    RouteNames.quizDashboard,
  ];

  /// Builds each tab's page, in [QuizBottomNav] order. A tab is built the
  /// first time it is shown.
  final List<WidgetBuilder> tabs;
  final int initialTab;

  /// Returns to the open Quiz section (closing any pages above it) and shows
  /// [tab]. Used by pages pushed over the section, such as the quiz result.
  static void switchTo(BuildContext context, int tab) {
    final shell = _QuizShellState._active;
    if (shell == null || !shell.mounted) {
      // No section open underneath: open one on that tab.
      Navigator.of(context).pushReplacementNamed(tabRoutes[tab]);
      return;
    }
    final route = ModalRoute.of(shell.context);
    if (route != null) Navigator.of(context).popUntil((r) => r == route);
    shell._select(tab);
  }

  @override
  State<QuizShell> createState() => _QuizShellState();
}

class _QuizShellState extends State<QuizShell> {
  /// The most recently opened section, for [QuizShell.switchTo].
  static _QuizShellState? _active;

  late int _selected = widget.initialTab.clamp(0, widget.tabs.length - 1);

  /// Each tab's page, built once on first visit and then reused, so switching
  /// tabs never rebuilds a page.
  final Map<int, Widget> _pages = {};

  @override
  void initState() {
    super.initState();
    _active = this;
  }

  @override
  void dispose() {
    if (_active == this) _active = null;
    super.dispose();
  }

  void _select(int tab) {
    if (tab == _selected || tab < 0 || tab >= widget.tabs.length) return;
    setState(() => _selected = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _selected,
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              if (i == _selected || _pages.containsKey(i))
                // Only the shown tab's tickers and animations run.
                TickerMode(
                  enabled: i == _selected,
                  child: _pages[i] ??= Builder(builder: widget.tabs[i]),
                )
              else
                const SizedBox.shrink(),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: QuizBottomNav(selectedIndex: _selected, onSelected: _select),
          ),
        ),
      ],
    );
  }
}
