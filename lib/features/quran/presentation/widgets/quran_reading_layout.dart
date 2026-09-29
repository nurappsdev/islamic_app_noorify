import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// How much of the page's bottom edge the floating player covers right now,
/// so the page can keep its own bottom controls (the Tafsir button) above it.
class QuranReadingInsets extends InheritedWidget {
  const QuranReadingInsets({
    super.key,
    required this.bottom,
    required super.child,
  });
  final ValueListenable<double> bottom;

  static ValueListenable<double>? bottomOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QuranReadingInsets>()?.bottom;

  @override
  bool updateShouldNotify(QuranReadingInsets oldWidget) =>
      bottom != oldWidget.bottom;
}

/// Keeps controls mounted (including audio listeners) and floats them over
/// the page, so showing or hiding them never resizes or moves the Quran text.
/// Pointer input never competes with page gestures.
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
  late final CurvedAnimation _topCurve = _curve(_top);
  late final CurvedAnimation _bottomCurve = _curve(_bottom);
  final _scroll = ScrollController();
  Timer? _idle;
  // Where each finger touching the reader landed.
  final Map<int, Offset> _pointers = {};
  // The player's height, and how much of the page it covers as it slides.
  double _bottomHeight = 0;
  final _bottomCover = ValueNotifier<double>(0);

  void _updateCover() =>
      _bottomCover.value = _bottomHeight * _bottomCurve.value;

  AnimationController _chromeController() => AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 200),
    value: 1,
  );

  static CurvedAnimation _curve(AnimationController parent) => CurvedAnimation(
    parent: parent,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _bottomCurve.addListener(_updateCover);
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
    _bottomCover.dispose();
    _topCurve.dispose();
    _bottomCurve.dispose();
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  /// A control bar that fades in while sliding a short way in from its own
  /// edge ([from] -1 for the top, 1 for the bottom). Hidden, it takes no
  /// touches, so taps reach the page beneath it.
  Widget _chrome(Widget child, AnimationController controller, double from) {
    final curve = from < 0 ? _topCurve : _bottomCurve;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) =>
          IgnorePointer(ignoring: controller.value == 0, child: child),
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, .35 * from),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      ),
    );
  }

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
      final slop =
          MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;
      if (landed == null || (event.localPosition - landed).distance > slop) {
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: QuranReadingInsets(
                        bottom: _bottomCover,
                        child: widget.page,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _chrome(widget.top, _top, -1),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _MeasureHeight(
                        onHeight: (height) {
                          _bottomHeight = height;
                          _updateCover();
                        },
                        child: _chrome(widget.bottom, _bottom, 1),
                      ),
                    ),
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

/// Reports [child]'s laid-out height whenever it changes.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, required super.child});
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight);
  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    // Not during layout: listeners may rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(height));
  }
}
