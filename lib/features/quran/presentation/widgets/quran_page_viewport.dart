import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

import 'quran_design.dart' show quranBorder, quranInk, quranOlive;
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
    this.zoomLabel,
    this.magnify = 1,
  });
  final int pageNumber;
  final Widget? header;
  final Widget child, footer;
  final VoidCallback? onNext, onPrevious;
  final ValueChanged<double>? onPinchUpdate;
  final VoidCallback? onPinchEnd;
  final bool busy, showHeader;

  /// The Arabic zoom while a pinch changes it ("120%"), shown in a small
  /// pill; null when no pinch is under way.
  final String? zoomLabel;

  /// How much a pinch in progress magnifies the page, about the point
  /// between the fingers: it zooms smoothly as one picture, and the text is
  /// laid out at its new size only once the pinch ends.
  final double magnify;
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

/// How far a sideways swipe must go to turn the page (a quick flick turns
/// it sooner).
const _turnDistance = 48.0;
const _scrollbarThickness = 4.0;
const ValueListenable<double> _noInset = AlwaysStoppedAnimation(0);

class _QuranPageViewportState extends State<QuranPageViewport> {
  bool _forward = true;
  double _dragDistance = 0;
  final _pointers = <int, Offset>{};
  double? _pinchStartSpan;
  // Set by a pinch and kept until every finger lifts, so the drag that ends
  // with it never turns the page.
  bool _pinched = false;

  // How far the finger has dragged sideways, for the page-turn indicator.
  final _swipe = ValueNotifier<double>(0);

  // The zoom pill's label, kept a moment after the pinch so the final zoom
  // can be read, and whether it shows.
  String _zoomShown = '';
  bool _zoomVisible = false;
  Timer? _zoomHide;

  @override
  void initState() {
    super.initState();
    _showZoom(widget.zoomLabel);
  }

  void _showZoom(String? label) {
    if (label != null) {
      _zoomHide?.cancel();
      _zoomShown = label;
      _zoomVisible = true;
    } else if (_zoomVisible) {
      _zoomHide?.cancel();
      _zoomHide = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _zoomVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _zoomHide?.cancel();
    _swipe.dispose();
    super.dispose();
  }

  void _endSwipe() => _swipe.value = 0;

  @override
  void didUpdateWidget(QuranPageViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoomLabel != widget.zoomLabel) _showZoom(widget.zoomLabel);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _forward = widget.pageNumber > oldWidget.pageNumber;
    }
  }

  /// The pinch's focal point as an alignment within the page's interior
  /// (the viewport of [size] less [padding]).
  Alignment _focalAlignment(Size size, EdgeInsets padding) {
    final inner = padding.deflateRect(Offset.zero & size);
    if (inner.width <= 0 || inner.height <= 0) return Alignment.center;
    return Alignment(
      ((_focal.dx - inner.left) / inner.width * 2 - 1).clamp(-1.0, 1.0),
      ((_focal.dy - inner.top) / inner.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  double get _span {
    final points = _pointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  // Where each finger is on the page, and the point a pinch zooms about.
  final _local = <int, Offset>{};
  Offset _focal = Offset.zero;

  void _pointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) _pinched = false;
    _pointers[event.pointer] = event.position;
    _local[event.pointer] = event.localPosition;
    if (_pointers.length == 2 && widget.onPinchUpdate != null) {
      final points = _local.values.take(2).toList();
      setState(() {
        _pinched = true;
        _pinchStartSpan = _span;
        _focal = (points[0] + points[1]) / 2;
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
    _local.remove(event.pointer);
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
      // The page runs up behind the status bar and notch: a Surah's opening
      // pattern fills that strip, while the framed page and its text start
      // below it.
      final notch = MediaQuery.paddingOf(context).top;
      final headerTop = notch + _headerTop;
      final top = headerTop + artHeight * _artBand + _gap;
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
          onHorizontalDragUpdate: (details) {
            _dragDistance += details.delta.dx;
            final was = _swipe.value.abs() >= _turnDistance;
            _swipe.value = widget.busy || _pinched ? 0 : _dragDistance;
            // A light tick as the swipe becomes far enough to turn the page.
            if (!was &&
                _swipe.value.abs() >= _turnDistance &&
                (_swipe.value > 0 ? widget.onNext : widget.onPrevious) !=
                    null) {
              HapticFeedback.selectionClick();
            }
          },
          onHorizontalDragCancel: _endSwipe,
          onHorizontalDragEnd: (details) {
            _endSwipe();
            if (widget.busy || _pinched) return;
            final velocity = details.primaryVelocity ?? 0;
            if (_dragDistance.abs() < _turnDistance && velocity.abs() < 350) {
              return;
            }
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
                    child: Transform.scale(
                      key: const ValueKey('quran-page-magnify'),
                      scale: widget.magnify,
                      alignment: _focalAlignment(
                        bounds.biggest,
                        widget.header == null
                            ? EdgeInsets.fromLTRB(side, top, side, bottom)
                            : EdgeInsets.only(bottom: bottom),
                      ),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
              ),
              if (widget.showHeader)
                Positioned(
                  top: headerTop,
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
              // Which way the swipe turns the page, from the edge the new
              // page comes in at.
              ValueListenableBuilder<double>(
                valueListenable: _swipe,
                builder: (context, drag, _) {
                  final forward = drag > 0;
                  final turns = forward ? widget.onNext : widget.onPrevious;
                  if (drag == 0 || turns == null) return const SizedBox();
                  final progress = (drag.abs() / _turnDistance).clamp(0.0, 1.0);
                  final ready = progress >= 1;
                  return Align(
                    alignment: forward
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: Offset((forward ? 1 : -1) * 18 * progress, 0),
                        child: Opacity(
                          opacity: progress,
                          child: AnimatedContainer(
                            key: const ValueKey('quran-swipe-indicator'),
                            duration: const Duration(milliseconds: 120),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ready
                                  ? quranOlive
                                  : context.surfaceColor(Colors.white),
                              border: Border.all(color: quranBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              forward
                                  ? Icons.chevron_right_rounded
                                  : Icons.chevron_left_rounded,
                              color: ready ? Colors.white : quranInk,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // The zoom while pinching.
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _zoomVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        key: const ValueKey('quran-zoom-pill'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: quranInk.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _zoomShown,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Kept clear of the reader's floating player while it shows,
              // and shown only while the header and bottom bar are hidden.
              ValueListenableBuilder<double>(
                valueListenable:
                    QuranReadingInsets.bottomOf(context) ?? _noInset,
                builder: (context, cover, footer) => Positioned(
                  bottom: math.max(4.0, cover + 4),
                  left: 0,
                  right: 0,
                  child: footer!,
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable:
                      QuranReadingInsets.chromeOf(context) ?? _noInset,
                  builder: (context, chrome, footer) => IgnorePointer(
                    ignoring: chrome > 0,
                    child: Opacity(opacity: 1 - chrome, child: footer),
                  ),
                  child: Center(child: widget.footer),
                ),
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
    // A slim olive thumb that shows while the page scrolls and fades once
    // it stops; it can be dragged to move through a long page. Only a page
    // longer than its frame gets one.
    child: RawScrollbar(
      key: const ValueKey('quran-page-scrollbar'),
      controller: _controller,
      thumbColor: quranOlive.withValues(alpha: .7),
      radius: const Radius.circular(4),
      thickness: _scrollbarThickness,
      minThumbLength: 40,
      mainAxisMargin: 4,
      fadeDuration: const Duration(milliseconds: 300),
      timeToFade: const Duration(milliseconds: 900),
      child: ScrollConfiguration(
        // No second, platform scrollbar on desktop.
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _controller,
          clipBehavior: Clip.hardEdge,
          physics: widget.locked
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          // A gutter for the thumb, so it never covers the text.
          padding: const EdgeInsetsDirectional.only(
            end: _scrollbarThickness + 4,
          ),
          child: widget.child,
        ),
      ),
    ),
  );
}
