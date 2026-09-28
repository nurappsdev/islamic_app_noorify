import 'package:flutter/material.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// The ornaments stay still. Both vertical scrolling and the page-turn
/// animation are clipped to the interior rectangle, below the frame artwork.
class QuranPageViewport extends StatefulWidget {
  const QuranPageViewport({
    super.key,
    required this.pageNumber,
    required this.child,
    required this.footer,
    this.onNext,
    this.onPrevious,
    this.busy = false,
    this.showHeader = true,
    this.header,
  });
  final int pageNumber;
  final Widget? header;
  final Widget child, footer;
  final VoidCallback? onNext, onPrevious;
  final bool busy, showHeader;
  @override
  State<QuranPageViewport> createState() => _QuranPageViewportState();
}

class _QuranPageViewportState extends State<QuranPageViewport> {
  bool _forward = true;
  double _dragDistance = 0;
  @override
  void didUpdateWidget(QuranPageViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _forward = widget.pageNumber > oldWidget.pageNumber;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('quran-page-gesture'),
    behavior: HitTestBehavior.opaque,
    onHorizontalDragStart: (_) => _dragDistance = 0,
    onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
    onHorizontalDragEnd: (details) {
      if (widget.busy) return;
      final velocity = details.primaryVelocity ?? 0;
      if (_dragDistance.abs() < 48 && velocity.abs() < 350) return;
      final swipedLeft = velocity.abs() >= 350
          ? velocity < 0
          : _dragDistance < 0;
      if (swipedLeft) {
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
          // move text into the header/footer or beyond either side border.
          child: Padding(
            padding: widget.header == null
                ? const EdgeInsets.fromLTRB(24, 28, 24, 64)
                : const EdgeInsets.only(bottom: 64),
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
                  final incoming = child.key == ValueKey(widget.pageNumber);
                  final direction =
                      (_forward ? 1.0 : -1.0) * (incoming ? 1 : -1);
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(direction, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _PageScrollBody(
                  key: ValueKey(widget.pageNumber),
                  child: widget.header == null
                      ? widget.child
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            widget.header!,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
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
            top: 8,
            left: 4,
            right: 4,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/quran/header.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          left: 4,
          right: 4,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/quran/footer.png',
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: Center(child: widget.footer),
        ),
      ],
    ),
  );
}

/// Each animated page owns its scroll position. Replacing translations keeps
/// this state; turning a page starts at the top without moving the outgoing page.
class _PageScrollBody extends StatefulWidget {
  const _PageScrollBody({super.key, required this.child});
  final Widget child;
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
      physics: const ClampingScrollPhysics(),
      child: widget.child,
    ),
  );
}
