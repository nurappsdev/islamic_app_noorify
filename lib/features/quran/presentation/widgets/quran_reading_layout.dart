import 'dart:async';
import 'package:flutter/material.dart';

/// Keeps controls mounted (including audio listeners) while reclaiming their
/// layout space during reading. Pointer input never competes with page gestures.
class QuranReadingLayout extends StatefulWidget {
  const QuranReadingLayout({
    super.key,
    required this.top,
    required this.page,
    required this.bottom,
    this.extension,
    this.idleDuration = const Duration(seconds: 5),
  });
  final Widget top, page, bottom;
  final Widget? extension;
  final Duration idleDuration;
  @override
  State<QuranReadingLayout> createState() => _QuranReadingLayoutState();
}

class _QuranReadingLayoutState extends State<QuranReadingLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controls = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final CurvedAnimation _size = CurvedAnimation(
    parent: _controls,
    curve: Curves.easeInOut,
  );
  final _scroll = ScrollController();
  Timer? _idle;
  final Set<int> _pointers = {};
  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void _scheduleHide() {
    _idle?.cancel();
    if (_pointers.isEmpty) {
      _idle = Timer(widget.idleDuration, () {
        if (mounted) _controls.reverse();
      });
    }
  }

  void _reveal() {
    _idle?.cancel();
    _controls.forward();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _scroll.dispose();
    _size.dispose();
    _controls.dispose();
    super.dispose();
  }

  Widget _chrome(Widget child) => SizeTransition(
    sizeFactor: _size,
    alignment: Alignment.topCenter,
    child: FadeTransition(opacity: _controls, child: child),
  );
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      _pointers.add(event.pointer);
      _reveal();
    },
    onPointerMove: (_) => _reveal(),
    onPointerUp: (event) {
      _pointers.remove(event.pointer);
      _scheduleHide();
    },
    onPointerCancel: (event) {
      _pointers.remove(event.pointer);
      _scheduleHide();
    },
    onPointerSignal: (_) {
      _reveal();
      _scheduleHide();
    },
    child: LayoutBuilder(
      builder: (context, bounds) => NotificationListener<OverscrollNotification>(
        onNotification: (notification) {
          // Continue a vertical drag below the framed Arabic page once its
          // own scroll view reaches the end. Horizontal page swipes stay local.
          if (widget.extension != null &&
              notification.depth > 0 &&
              notification.metrics.axis == Axis.vertical &&
              notification.dragDetails != null &&
              _scroll.hasClients) {
            final position = _scroll.position;
            final next = (position.pixels + notification.overscroll).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            );
            if (next != position.pixels) _scroll.jumpTo(next);
          }
          return false;
        },
        child: SingleChildScrollView(
          key: const ValueKey('quran-reader-scroll'),
          controller: _scroll,
          physics: widget.extension == null
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Keep this viewport and its subtree unchanged when Tafsir opens.
              SizedBox(
                height: bounds.maxHeight,
                child: Column(
                  children: [
                    _chrome(widget.top),
                    Expanded(child: widget.page),
                    _chrome(widget.bottom),
                  ],
                ),
              ),
              if (widget.extension != null) widget.extension!,
            ],
          ),
        ),
      ),
    ),
  );
}
