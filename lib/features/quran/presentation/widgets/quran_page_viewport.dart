import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

import 'quran_reading_layout.dart' show QuranReadingInsets;

/// The ornaments stay still. Both vertical scrolling and the page-turn
/// animation are clipped to the interior rectangle, below the frame artwork.
///
/// A two-finger pinch reports a zoom factor through [onPinchUpdate] (relative
/// to the pinch's start) and [onPinchEnd]; while pinching, the page neither
/// scrolls nor turns.
class QuranPageViewport extends StatefulWidget {
  const QuranPageViewport({
    super.key,
    required this.pageNumber,
    required this.child,
    required this.footer,
    this.onNext,
    this.onPrevious,
    this.onPinchUpdate,
    this.onPinchEnd,
    this.busy = false,
    this.showHeader = true,
    this.header,
  });
  final int pageNumber;
  final Widget? header;
  final Widget child, footer;
  final VoidCallback? onNext, onPrevious;
  final ValueChanged<double>? onPinchUpdate;
  final VoidCallback? onPinchEnd;
  final bool busy, showHeader;
  @override
  State<QuranPageViewport> createState() => _QuranPageViewportState();
}

// The header/footer artwork (402×133) is a frame of corner ornaments: a band
// about 20% of its height along the top (footer: bottom) edge and scrollwork
// about 7% of its width down each side. Text is kept clear of both.
const _artAspect = 402 / 133;
const _artBand = .2;
const _artSide = .075;
const _artInset = 4.0; // left/right offset of the artwork
const _headerTop = 8.0;
const _footerBottom = 16.0;
const _gap = 6.0;
const ValueListenable<double> _noInset = AlwaysStoppedAnimation(0);

class _QuranPageViewportState extends State<QuranPageViewport> {
  bool _forward = true;
  double _dragDistance = 0;
  final _pointers = <int, Offset>{};
  double? _pinchStartSpan;
  // Set by a pinch and kept until every finger lifts, so the drag that ends
  // with it never turns the page.
  bool _pinched = false;

  @override
  void didUpdateWidget(QuranPageViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _forward = widget.pageNumber > oldWidget.pageNumber;
    }
  }

  double get _span {
    final points = _pointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _pointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) _pinched = false;
    _pointers[event.pointer] = event.position;
    if (_pointers.length == 2 && widget.onPinchUpdate != null) {
      setState(() {
        _pinched = true;
        _pinchStartSpan = _span;
      });
    }
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    final start = _pinchStartSpan;
    if (start != null && start > 0 && _pointers.length >= 2) {
      widget.onPinchUpdate?.call(_span / start);
    }
  }

  void _pointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pinchStartSpan != null && _pointers.length < 2) {
      setState(() => _pinchStartSpan = null);
      widget.onPinchEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final artWidth = math.max(0.0, bounds.maxWidth - 2 * _artInset);
      final artHeight = artWidth / _artAspect;
      final side = _artInset + artWidth * _artSide + _gap;
      final top = _headerTop + artHeight * _artBand + _gap;
      // The footer button sits over the bottom band; keep room for it too.
      final bottom = math.max(
        64.0,
        _footerBottom + artHeight * _artBand + _gap,
      );
      return Listener(
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerUp,
        onPointerCancel: _pointerUp,
        child: GestureDetector(
          key: const ValueKey('quran-page-gesture'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _dragDistance = 0,
          onHorizontalDragUpdate: (details) =>
              _dragDistance += details.delta.dx,
          onHorizontalDragEnd: (details) {
            if (widget.busy || _pinched) return;
            final velocity = details.primaryVelocity ?? 0;
            if (_dragDistance.abs() < 48 && velocity.abs() < 350) return;
            final swipedRight = velocity.abs() >= 350
                ? velocity > 0
                : _dragDistance > 0;
            // Pages turn like an Arabic book: swiping right moves forward.
            if (swipedRight) {
              widget.onNext?.call();
            } else {
              widget.onPrevious?.call();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                // This padding is OUTSIDE the scroll view; scrolling can never
                // move text into the header/footer or beyond either side
                // border.
                child: Padding(
                  padding: widget.header == null
                      ? EdgeInsets.fromLTRB(side, top, side, bottom)
                      : EdgeInsets.only(bottom: bottom),
                  child: ClipRect(
                    key: const ValueKey('quran-frame-interior'),
                    clipBehavior: Clip.hardEdge,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      transitionBuilder: (child, animation) {
                        final incoming =
                            child.key == ValueKey(widget.pageNumber);
                        // A next page enters from the left, following the
                        // right-swipe that turned it.
                        final direction =
                            (_forward ? -1.0 : 1.0) * (incoming ? 1 : -1);
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(direction, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _PageScrollBody(
                        key: ValueKey(widget.pageNumber),
                        locked: _pinchStartSpan != null,
                        child: widget.header == null
                            ? widget.child
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  widget.header!,
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: side,
                                    ),
                                    child: ColoredBox(
                                      color: context.pageColor(Colors.white),
                                      child: ClipRect(child: widget.child),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showHeader)
                Positioned(
                  top: _headerTop,
                  left: _artInset,
                  right: _artInset,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/quran/header.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              Positioned(
                bottom: _footerBottom,
                left: _artInset,
                right: _artInset,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/quran/footer.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              // Kept clear of the reader's floating player while it shows.
              ValueListenableBuilder<double>(
                valueListenable:
                    QuranReadingInsets.bottomOf(context) ?? _noInset,
                builder: (context, cover, footer) => Positioned(
                  bottom: math.max(4.0, cover + 4),
                  left: 0,
                  right: 0,
                  child: footer!,
                ),
                child: Center(child: widget.footer),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Each animated page owns its scroll position. Replacing translations keeps
/// this state; turning a page starts at the top without moving the outgoing page.
class _PageScrollBody extends StatefulWidget {
  const _PageScrollBody({super.key, required this.child, this.locked = false});
  final Widget child;

  /// Stops scrolling, e.g. while a pinch resizes the text.
  final bool locked;
  @override
  State<_PageScrollBody> createState() => _PageScrollBodyState();
}

class _PageScrollBodyState extends State<_PageScrollBody> {
  final _controller = ScrollController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.pageColor(Colors.white),
    child: SingleChildScrollView(
      controller: _controller,
      clipBehavior: Clip.hardEdge,
      physics: widget.locked
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      child: widget.child,
    ),
  );
}
