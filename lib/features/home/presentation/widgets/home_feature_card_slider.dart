import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// One fixed slot on the home screen that cycles through [children] with a
/// vertical, Reels-style transition.
///
/// * A vertical swipe inside the slot moves exactly one card and never
///   scrolls the enclosing page (a [PageView] wins the gesture arena).
/// * The pages travel only a fraction of the slot height, so it reads as one
///   card area whose content changes: the leaving card scales down and fades,
///   the arriving one scales up and fades in.
/// * Cards advance on their own every [autoPlayInterval], loop forever, pause
///   while a finger is down and resume [resumeDelay] after it lifts.
/// * Taps and buttons inside the cards work as normal. A held card never
///   changes its own appearance.
///
/// Only the visible card (and its neighbour mid-transition) is mounted.
class HomeFeatureCardSlider extends StatefulWidget {
  const HomeFeatureCardSlider({
    super.key,
    required this.children,
    this.height = 340,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.resumeDelay = const Duration(seconds: 3),
    this.transitionDuration = const Duration(milliseconds: 650),
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.showIndicator = true,
    this.controller,
    this.onIndexChanged,
  }) : assert(children.length > 0);

  final List<Widget> children;

  /// Height of the slot, including room for the cards' shadows.
  final double height;

  final Duration autoPlayInterval;

  /// How long after the finger lifts before auto-play resumes.
  final Duration resumeDelay;

  final Duration transitionDuration;

  /// Space kept around each card inside the clipped slot.
  final EdgeInsets padding;

  final bool showIndicator;

  /// Optional externally owned controller. It must be a vertical-friendly
  /// controller created with `viewportFraction: 1`; its page is an unbounded
  /// looping counter, so use `page % children.length` for the real index.
  /// When omitted the slider creates and disposes its own.
  final PageController? controller;

  /// Called with the real card index (0 until [children].length - 1).
  final ValueChanged<int>? onIndexChanged;

  @override
  State<HomeFeatureCardSlider> createState() => _HomeFeatureCardSliderState();
}

class _HomeFeatureCardSliderState extends State<HomeFeatureCardSlider>
    with WidgetsBindingObserver {
  /// Start far from 0 so the user can also swipe "back" past the first card.
  static const _loopOrigin = 10000;

  /// Peak effect of a full page of distance on a card.
  static const _minScale = 0.88;
  static const _travel = 0.72; // share of the slot the pages do NOT travel

  late final PageController _controller;
  late final bool _ownsController;
  final ValueNotifier<int> _index = ValueNotifier(0);

  Timer? _autoTimer;
  Offset? _downPosition;
  bool _appActive = true;

  int get _count => widget.children.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        PageController(initialPage: _loopOrigin - _loopOrigin % _count);
    _lastKnownPage = _controller.initialPage.toDouble();
    _startAuto();
  }

  @override
  void didUpdateWidget(HomeFeatureCardSlider old) {
    super.didUpdateWidget(old);
    if (old.autoPlayInterval != widget.autoPlayInterval) _startAuto();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _index.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
  }

  // ---- auto play ---------------------------------------------------------

  void _startAuto([Duration? firstDelay]) {
    _autoTimer?.cancel();
    if (_count < 2) return;
    _autoTimer = Timer(firstDelay ?? widget.autoPlayInterval, _autoTick);
  }

  void _autoTick() {
    if (!mounted) return;
    // Skip this beat (and try again later) if the user is busy, the app is in
    // the background, or the slot is off-screen / under another route.
    final idle =
        _downPosition == null &&
        _appActive &&
        TickerMode.valuesOf(context).enabled;
    if (idle && _controller.hasClients) {
      _controller.nextPage(
        duration: widget.transitionDuration,
        curve: Curves.easeInOutCubic,
      );
    }
    _startAuto();
  }

  void _pauseAuto() => _autoTimer?.cancel();

  // ---- pointer handling (does not join the gesture arena) -----------------

  void _onPointerDown(PointerDownEvent e) {
    _pauseAuto();
    _downPosition = e.position;
  }

  void _onPointerEnd(PointerEvent _) {
    _downPosition = null;
    _startAuto(widget.resumeDelay);
  }

  // ---- build --------------------------------------------------------------

  void _onPageChanged(int page) {
    final index = page % _count;
    _index.value = index;
    widget.onIndexChanged?.call(index);
  }

  // The page the controller last reported while it had a measured viewport.
  // Used as `_Page`'s fallback when the position is momentarily unmeasured
  // (e.g. the first frame); falling back to `_controller.initialPage` (the
  // loop-origin constant, ~10000) instead would make `_Page`'s
  // distance-from-current calculation see a huge, clamped delta and render
  // the card fully transparent for that frame.
  double _lastKnownPage = 0;

  double get _page {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      _lastKnownPage = _controller.page ?? _lastKnownPage;
    }
    return _lastKnownPage;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: ScrollConfiguration(
                  behavior: const _NoOverscrollIndicatorBehavior(),
                  child: PageView.builder(
                    controller: _controller,
                    scrollDirection: Axis.vertical,
                    physics: const PageScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, page) => _Page(
                      controller: _controller,
                      page: page,
                      fallbackPage: _page,
                      height: widget.height,
                      minScale: _minScale,
                      travel: _travel,
                      padding: widget.padding,
                      child: widget.children[page % _count],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showIndicator && _count > 1)
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _Dots(count: _count, index: _index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Suppresses the platform's default glow/stretch overscroll indicator on
/// the card `PageView`, which otherwise flashes the scaffold's background
/// behind a card during a held touch. Purely visual: scroll physics and
/// gestures are untouched.
class _NoOverscrollIndicatorBehavior extends ScrollBehavior {
  const _NoOverscrollIndicatorBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// Applies the per-card transition from its distance to the current page.
class _Page extends StatelessWidget {
  const _Page({
    required this.controller,
    required this.page,
    required this.fallbackPage,
    required this.height,
    required this.minScale,
    required this.travel,
    required this.padding,
    required this.child,
  });

  final PageController controller;
  final int page;
  final double fallbackPage;
  final double height;
  final double minScale;
  final double travel;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A card taller than the slot is scaled down to fit instead of overflowing,
    // but is still laid out wide enough to fill the full width afterwards.
    final card = Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.topCenter,
        child: _ScaleToFitHeight(child: child),
      ),
    );
    return AnimatedBuilder(
      animation: controller,
      child: card,
      builder: (context, child) {
        final current =
            controller.hasClients &&
                controller.position.haveDimensions &&
                controller.page != null
            ? controller.page!
            : fallbackPage;
        // -1 = the card that just left upwards, +1 = the one about to arrive
        // from below.
        final delta = (page - current).clamp(-1.0, 1.0);
        final t = delta.abs();
        final eased = Curves.easeOut.transform(t);
        return Opacity(
          opacity: (1 - eased * 1.15).clamp(0.0, 1.0),
          child: Transform.translate(
            // Cancel most of the page's own travel: the cards swap in place.
            offset: Offset(0, -delta * height * travel),
            child: Transform.scale(
              scale: 1 - (1 - minScale) * eased,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Minimal vertical position dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final ValueListenable<int> index;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<int>(
      valueListenable: index,
      builder: (context, current, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(vertical: 2),
              width: 4,
              height: i == current ? 14 : 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: i == current ? 0.8 : 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sizes [child] to the full available width; when it comes out taller than
/// the available height it is laid out wider by 1/scale and painted scaled
/// down by `scale`, so it still fills the width after shrinking.
class _ScaleToFitHeight extends SingleChildRenderObjectWidget {
  const _ScaleToFitHeight({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScaleToFitHeight();
}

class _RenderScaleToFitHeight extends RenderShiftedBox {
  _RenderScaleToFitHeight() : super(null);

  double _scale = 1;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    child.layout(
      BoxConstraints(minWidth: maxW, maxWidth: maxW),
      parentUsesSize: true,
    );
    _scale = 1;
    if (child.size.height > maxH) {
      _scale = maxH / child.size.height;
      child.layout(
        BoxConstraints(minWidth: maxW / _scale, maxWidth: maxW / _scale),
        parentUsesSize: true,
      );
    }
    size = constraints.constrain(Size(maxW, child.size.height * _scale));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      context.paintChild(child, offset);
      return;
    }
    context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.diagonal3Values(_scale, _scale, 1),
      (context, offset) => context.paintChild(child, offset),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.scaleByDouble(_scale, _scale, 1, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: Matrix4.diagonal3Values(_scale, _scale, 1),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }
}
