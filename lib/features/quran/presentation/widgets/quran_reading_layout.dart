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
    this.idleDuration = const Duration(seconds: 5),
  });
  final Widget top, page, bottom;
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
    child: Column(
      children: [
        _chrome(widget.top),
        Expanded(child: widget.page),
        _chrome(widget.bottom),
      ],
    ),
  );
}
