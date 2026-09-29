import 'dart:async';
import 'package:flutter/gestures.dart' show kTouchSlop;
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
    with TickerProviderStateMixin {
  // The header and the bottom bar show and hide on their own: a touch in the
  // upper half of the screen brings back the header, one in the lower half
  // the bottom bar. A drag (scroll or page swipe) brings back both.
  late final AnimationController _top = _chromeController();
  late final AnimationController _bottom = _chromeController();
  late final CurvedAnimation _topSize = _curve(_top);
  late final CurvedAnimation _bottomSize = _curve(_bottom);
  final _scroll = ScrollController();
  Timer? _idle;
  // Where each finger touching the reader landed.
  final Map<int, Offset> _pointers = {};

  AnimationController _chromeController() => AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  static CurvedAnimation _curve(AnimationController parent) =>
      CurvedAnimation(parent: parent, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void _scheduleHide() {
    _idle?.cancel();
    if (_pointers.isEmpty) {
      _idle = Timer(widget.idleDuration, () {
        if (!mounted) return;
        _top.reverse();
        _bottom.reverse();
      });
    }
  }

  void _reveal({bool top = true, bool bottom = true}) {
    _idle?.cancel();
    if (top) _top.forward();
    if (bottom) _bottom.forward();
  }

  /// Reveals the header or the bottom bar, whichever half [dy] falls in.
  void _revealHalf(double dy) {
    final height = context.size?.height ?? 0;
    final upper = height > 0 && dy < height / 2;
    _reveal(top: upper, bottom: !upper);
  }

  @override
  void dispose() {
    _idle?.cancel();
    _scroll.dispose();
    _topSize.dispose();
    _bottomSize.dispose();
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  Widget _chrome(
    Widget child,
    AnimationController controller,
    Animation<double> size,
  ) => SizeTransition(
    sizeFactor: size,
    alignment: Alignment.topCenter,
    child: FadeTransition(opacity: controller, child: child),
  );
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      _pointers[event.pointer] = event.localPosition;
      _revealHalf(event.localPosition.dy);
    },
    onPointerMove: (event) {
      // A finger resting on an ayah jitters a little; only a real drag counts.
      final landed = _pointers[event.pointer];
      if (landed == null ||
          (event.localPosition - landed).distance > kTouchSlop) {
        _reveal();
      }
    },
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
                    _chrome(widget.top, _top, _topSize),
                    Expanded(child: widget.page),
                    _chrome(widget.bottom, _bottom, _bottomSize),
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
