import 'package:animations/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Shows one of [cards] at a time in a single fixed slot; pulling it
/// vertically swaps in its neighbour.
///
/// While the finger is down an [AnimationController] follows the pull: the
/// card shrinks slightly, drifts with the finger and fades. On release, past
/// the threshold (or a fling), the card is swapped through an
/// [AnimatedSwitcher] using [FadeThroughTransition] plus a slight vertical
/// slide - the next card rises from the bottom on a pull up, the previous one
/// drops from the top on a pull down. Short of the threshold the card springs
/// back. Manual only: no timer, no auto-advance, no PageView.
///
/// At the first card a downward pull, and at the last an upward pull, is not
/// claimed, so the enclosing scroll view scrolls instead.
///
/// Only the visible card is mounted; the others are rebuilt when swiped to.
class VerticalCardSwitcher extends StatefulWidget {
  const VerticalCardSwitcher({
    super.key,
    required this.cards,
    required this.height,
    this.onIndexChanged,
  }) : assert(cards.length > 0);

  final List<Widget> cards;

  /// Height of the slot. Include any room the cards need for their shadow.
  final double height;

  final ValueChanged<int>? onIndexChanged;

  @override
  State<VerticalCardSwitcher> createState() => _VerticalCardSwitcherState();
}

class _VerticalCardSwitcherState extends State<VerticalCardSwitcher>
    with SingleTickerProviderStateMixin {
  /// Fraction of the slot height the finger travels for a full pull.
  static const _pullExtent = 0.6;

  /// Peak effect of a full pull on the card being pulled.
  static const _shrink = 0.08;
  static const _lift = 0.06;
  static const _fade = 0.5;

  /// Fraction of a full pull, or fling speed (px/s), that commits a swap.
  static const _commitAt = 0.33;
  static const _flingSpeed = 500.0;

  /// How far the swapped cards slide, as a fraction of the slot.
  static const _slide = 0.25;

  /// Signed pull: +1 is a full pull up (towards the next card), -1 a full
  /// pull down (towards the previous one).
  late final AnimationController _pull = AnimationController(
    vsync: this,
    lowerBound: -1,
    upperBound: 1,
    value: 0,
  );

  int _index = 0;

  /// +1 when the last swap moved to the next card, -1 to the previous one.
  int _direction = 1;

  int get _last => widget.cards.length - 1;

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) => _pull.stop();

  void _onDragUpdate(DragUpdateDetails d) {
    final next = _pull.value - d.delta.dy / (widget.height * _pullExtent);
    // Never pull towards a card that doesn't exist.
    _pull.value = next.clamp(
      _index > 0 ? -1.0 : 0.0,
      _index < _last ? 1.0 : 0.0,
    );
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = -(d.primaryVelocity ?? 0); // positive when flinging up
    final pulled = _pull.value;
    final wantsNext = pulled > _commitAt || velocity > _flingSpeed;
    final wantsPrevious = pulled < -_commitAt || velocity < -_flingSpeed;
    if (wantsNext && _index < _last) {
      _swapTo(_index + 1);
    } else if (wantsPrevious && _index > 0) {
      _swapTo(_index - 1);
    } else {
      _settle(const Duration(milliseconds: 250));
    }
  }

  void _swapTo(int index) {
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
    });
    widget.onIndexChanged?.call(index);
    // The pull effect eases back to rest while the switcher brings the new
    // card in.
    _settle(const Duration(milliseconds: 400));
  }

  void _settle(Duration duration) {
    _pull.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
  }

  /// Whether a drag moving by [dy] (negative = up) still has a card to go to.
  bool _canDrag(double dy) => dy < 0 ? _index < _last : _index > 0;

  Widget _transition(Widget child, Animation<double> animation) {
    final incoming = child.key == ValueKey(_index);
    // The incoming card rises from the direction of travel; the outgoing one
    // leaves the opposite way.
    final offset = Offset(0, (incoming ? _direction : -_direction) * _slide);
    return SlideTransition(
      position: Tween<Offset>(
        begin: offset,
        end: Offset.zero,
      ).animate(animation),
      child: FadeThroughTransition(
        animation: animation,
        secondaryAnimation: kAlwaysDismissedAnimation,
        fillColor: Colors.transparent,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final switcher = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: _transition,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(_index), child: widget.cards[_index]),
    );

    return RawGestureDetector(
      gestures: {
        _EdgeAwareVerticalDrag:
            GestureRecognizerFactoryWithHandlers<_EdgeAwareVerticalDrag>(
              () => _EdgeAwareVerticalDrag(_canDrag),
              (r) => r
                ..onStart = _onDragStart
                ..onUpdate = _onDragUpdate
                ..onEnd = _onDragEnd,
            ),
      },
      child: SizedBox(
        height: widget.height,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _pull,
            child: switcher,
            builder: (context, child) {
              final p = _pull.value;
              final t = p.abs();
              return Opacity(
                opacity: 1 - _fade * t,
                child: Transform.translate(
                  offset: Offset(0, -p * widget.height * _lift),
                  child: Transform.scale(scale: 1 - _shrink * t, child: child),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A vertical drag that steps aside (lets the page scroll instead) when it
/// starts moving in a direction with no card left to go to.
class _EdgeAwareVerticalDrag extends VerticalDragGestureRecognizer {
  _EdgeAwareVerticalDrag(this.canDrag);

  final bool Function(double dy) canDrag;
  double _travelled = 0;
  bool _decided = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _travelled = 0;
    _decided = false;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && !_decided) {
      _travelled += event.delta.dy;
      if (_travelled.abs() > 3) {
        _decided = true;
        if (!canDrag(_travelled)) {
          resolvePointer(event.pointer, GestureDisposition.rejected);
          return;
        }
      }
    }
    super.handleEvent(event);
  }
}
