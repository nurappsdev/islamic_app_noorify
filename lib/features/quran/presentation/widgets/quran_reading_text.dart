import 'quran_ayah_marker.dart';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../domain/arabic_font.dart';
import '../../domain/quran_ayah.dart';
import 'quran_design.dart';

/// How long an ayah must be pressed before its details open, so a plain tap
/// while reading or scrolling does not.
const kAyahHoldDuration = Duration(milliseconds: 800);

/// A hold on one ayah: [onPress] as the finger lands, [onRelease] when it
/// lifts or the press turns into a scroll, [onHold] once the hold completes,
/// [onTap] when it lifts before that without having moved.
_AyahHoldRecognizer _holdRecognizer({
  required VoidCallback onHold,
  required VoidCallback onPress,
  required VoidCallback onRelease,
  VoidCallback? onTap,
}) => _AyahHoldRecognizer(onRejected: onRelease, onTap: onTap)
  ..onLongPressDown = ((_) => onPress())
  ..onLongPressCancel = onRelease
  ..onLongPressEnd = ((_) => onRelease())
  ..onLongPress = () {
    HapticFeedback.mediumImpact();
    onHold();
  };

/// A long press that also reports losing the arena. When a scroll claims the
/// drag first, [LongPressGestureRecognizer] goes quiet without calling
/// `onLongPressCancel`, which would leave the press tint on screen.
///
/// It reports a tap too ([onTap]): a press lifted before the hold completes.
/// One that moved past the touch slop (a scroll or page swipe) is never
/// lifted here, as it stops tracking the pointer first. A text span takes a
/// single recognizer, so the hold and the tap share this one.
class _AyahHoldRecognizer extends LongPressGestureRecognizer {
  _AyahHoldRecognizer({required this.onRejected, this.onTap})
    : super(duration: kAyahHoldDuration);
  final VoidCallback onRejected;
  final VoidCallback? onTap;

  /// The hold completed for the press under way.
  bool _held = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _held = false;
    super.addAllowedPointer(event);
  }

  @override
  void didExceedDeadline() {
    _held = true;
    super.didExceedDeadline();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent &&
        !_held &&
        state == GestureRecognizerState.possible) {
      onTap?.call();
    }
    super.handlePrimaryPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    final pending = state == GestureRecognizerState.possible;
    super.rejectGesture(pointer);
    if (pending) onRejected();
  }
}

/// The ayah currently playing: the existing subtle page tint.
Color _playingTint(BuildContext context) =>
    context.surfaceColor(quranPale).withValues(alpha: .7);

/// Drives the press feedback. [touch] fades the olive press tint in as the
/// finger lands and back out on release; [hold] deepens it towards
/// [kAyahHoldDuration]. The tint blends over [base] (the playing tint, or
/// none), so the press shows on a playing ayah too and release returns to it
/// smoothly.
mixin _HoldFeedback<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late final hold = AnimationController(
    vsync: this,
    duration: kAyahHoldDuration,
  );
  late final touch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Listenable feedback = Listenable.merge([hold, touch]);

  void startHold() {
    touch.forward();
    hold.forward(from: 0);
  }

  void endHold() {
    hold.stop();
    touch.reverse();
  }

  /// How deep the press is, 0-1: fades with [touch] so release is smooth.
  double get pressDepth => Curves.easeOut.transform(hold.value) * touch.value;

  /// [base] with the olive press tint over it: faint on touch, deeper near
  /// the threshold, never so strong the Arabic stops reading well.
  Color? pressTint(Color? base) {
    if (touch.value == 0) return base;
    final pressed = quranOlive.withValues(
      alpha: .16 + .22 * Curves.easeOut.transform(hold.value),
    );
    return Color.lerp(
      base ?? quranOlive.withValues(alpha: 0),
      pressed,
      touch.value,
    );
  }

  @override
  void dispose() {
    hold.dispose();
    touch.dispose();
    super.dispose();
  }
}

/// Calls [onHold] once [child] has been pressed for [kAyahHoldDuration],
/// tinting it as the press builds up.
class QuranAyahHold extends StatefulWidget {
  const QuranAyahHold({
    super.key,
    required this.onHold,
    required this.child,
    this.onTap,
  });
  final VoidCallback onHold;

  /// A plain tap on [child].
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<QuranAyahHold> createState() => _QuranAyahHoldState();
}

class _QuranAyahHoldState extends State<QuranAyahHold>
    with TickerProviderStateMixin, _HoldFeedback {
  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _AyahHoldRecognizer:
          GestureRecognizerFactoryWithHandlers<_AyahHoldRecognizer>(
            () => _holdRecognizer(
              onHold: () => widget.onHold(),
              onPress: startHold,
              onRelease: endHold,
              onTap: () => widget.onTap?.call(),
            ),
            // The platform's touch slop, the same one scrolling uses.
            (recognizer) => recognizer.gestureSettings =
                MediaQuery.maybeGestureSettingsOf(context),
          ),
    },
    child: AnimatedBuilder(
      animation: feedback,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: pressTint(null),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
      child: widget.child,
    ),
  );
}

class QuranReadingText extends StatefulWidget {
  const QuranReadingText({
    super.key,
    required this.ayahs,
    required this.active,
    required this.scale,
    required this.font,
    this.onHold,
    this.onTap,
  });
  final List<QuranAyah> ayahs;
  final int active;
  final double scale;
  final ArabicFont font;

  /// An ayah held for [kAyahHoldDuration]; null leaves the text inert.
  final ValueChanged<QuranAyah>? onHold;

  /// An ayah tapped (pressed and lifted before the hold completes).
  final ValueChanged<QuranAyah>? onTap;

  bool get _interactive => onHold != null || onTap != null;
  @override
  State<QuranReadingText> createState() => _QuranReadingTextState();
}

class _QuranReadingTextState extends State<QuranReadingText>
    with TickerProviderStateMixin, _HoldFeedback {
  final _textKey = GlobalKey();
  final _recognizers = <_AyahHoldRecognizer>[];

  /// The ayah being pressed, shown with the hold tint.
  int? _pressed;

  // Reads the ayah at hold time, so a re-emitted list with the same ayahs
  // keeps its recognizers and a press in progress is not dropped.
  _AyahHoldRecognizer _recognizerFor(int index) => _holdRecognizer(
    onHold: () => widget.onHold?.call(widget.ayahs[index]),
    onTap: () => widget.onTap?.call(widget.ayahs[index]),
    onPress: () {
      setState(() => _pressed = widget.ayahs[index].ayahNumber);
      startHold();
    },
    onRelease: endHold,
  )..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The platform's touch slop, the same one scrolling uses.
    final settings = MediaQuery.maybeGestureSettingsOf(context);
    if (_recognizers.isEmpty) _bind();
    for (final recognizer in _recognizers) {
      recognizer.gestureSettings = settings;
    }
  }

  void _bind() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    if (!widget._interactive) return;
    for (var i = 0; i < widget.ayahs.length; i++) {
      _recognizers.add(_recognizerFor(i));
    }
  }

  static bool _sameAyahs(List<QuranAyah> a, List<QuranAyah> b) =>
      identical(a, b) ||
      (a.length == b.length &&
          [
            for (var i = 0; i < a.length; i++) i,
          ].every((i) => a[i].verseKey == b[i].verseKey));

  @override
  void didUpdateWidget(QuranReadingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameAyahs(oldWidget.ayahs, widget.ayahs) ||
        oldWidget._interactive != widget._interactive) {
      _bind();
    }
    if (oldWidget.active != widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  // A WidgetSpan occupies one object-replacement character in the paragraph.
  int _segmentLength(QuranAyah a) => a.textArabic.length + 1;
  void _follow() {
    if (!mounted) return;
    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph) return;
    var offset = 0;
    for (final ayah in widget.ayahs) {
      final length = _segmentLength(ayah);
      if (ayah.ayahNumber == widget.active) {
        final boxes = render.getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + length),
        );
        if (boxes.isNotEmpty) {
          final scroll = Scrollable.maybeOf(context);
          if (scroll != null) {
            final viewport = scroll.context.findRenderObject();
            if (viewport is RenderBox) {
              final point = viewport.globalToLocal(
                render.localToGlobal(Offset(0, boxes.first.top)),
              );
              final target = (scroll.position.pixels + point.dy - 80).clamp(
                0.0,
                scroll.position.maxScrollExtent,
              );
              scroll.position.animateTo(
                target,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          }
        }
        return;
      }
      offset += length;
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: feedback,
    builder: (context, _) => _text(context),
  );

  Widget _text(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // The marker sizes itself with the Arabic as it is actually rendered,
    // including the system text scale, so its margin keeps pace on zoom.
    final markerScale = scaler.scale(20 * widget.scale) / 20;
    bool pressed(QuranAyah a) => _pressed == a.ayahNumber;
    // The playing ayah keeps its tint; a press shows over it, taking priority.
    Color? tint(QuranAyah a) {
      final base = widget.active == a.ayahNumber ? _playingTint(context) : null;
      return pressed(a) ? pressTint(base) : base;
    }

    final span = TextSpan(
      style: widget.font.apply(
        TextStyle(
          fontSize: 20 * widget.scale,
          height: 2.1,
          color: context.inkColor(Colors.black),
        ),
      ),
      children: [
        for (final (i, a) in widget.ayahs.indexed) ...[
          TextSpan(
            text: a.textArabic,
            recognizer: widget._interactive ? _recognizers[i] : null,
            style: TextStyle(backgroundColor: tint(a)),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: RawGestureDetector(
              gestures: {
                if (widget._interactive)
                  _AyahHoldRecognizer:
                      GestureRecognizerFactoryWithHandlers<_AyahHoldRecognizer>(
                        () => _recognizerFor(i),
                        (_) {},
                      ),
              },
              child: Transform.scale(
                // The marker swells slightly as the hold builds.
                scale: 1 + .12 * (pressed(a) ? pressDepth : 0),
                child: QuranAyahMarker(
                  key: ValueKey('ayah-marker-${a.verseKey}'),
                  number: a.ayahNumber,
                  scale: markerScale,
                ),
              ),
            ),
          ),
        ],
      ],
    );
    return CustomPaint(
      painter: _ReadingRules(
        _textKey,
        widget.ayahs.fold<int>(0, (length, a) => length + _segmentLength(a)),
        context.lineColor(const Color(0xffe9e9e9)),
      ),
      child: _AyahRichText(
        key: _textKey,
        text: span,
        textScaler: scaler,
        textDirection: TextDirection.rtl,
        // Zoomed in, a line holds only a few words and justifying it
        // stretches the gaps between them; keep the edge ragged instead.
        textAlign: widget.scale <= kDefaultArabicFontScale
            ? TextAlign.justify
            : TextAlign.start,
      ),
    );
  }
}

/// [RichText] whose ayah markers land beside their own ayahs. The engine
/// reports inline-widget boxes line by line in visual (left-to-right) order,
/// but [RenderParagraph] hands them to the markers in text order; in RTL text
/// any line with two markers had them swapped.
class _AyahRichText extends RichText {
  _AyahRichText({
    super.key,
    required super.text,
    super.textScaler,
    super.textDirection,
    super.textAlign,
  });

  @override
  RenderParagraph createRenderObject(BuildContext context) =>
      _AyahRenderParagraph(
        text,
        textAlign: textAlign,
        textDirection: textDirection ?? Directionality.of(context),
        textScaler: textScaler,
        locale: Localizations.maybeLocaleOf(context),
        devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0,
      );
}

class _AyahRenderParagraph extends RenderParagraph {
  _AyahRenderParagraph(
    super.text, {
    required super.textDirection,
    super.textAlign,
    super.textScaler,
    super.locale,
    super.devicePixelRatio,
  });

  @override
  void positionInlineChildren(List<ui.TextBox> boxes) =>
      super.positionInlineChildren(
        textDirection == TextDirection.rtl ? _rightToLeft(boxes) : boxes,
      );

  /// [boxes] in reading order: each line's boxes from the right edge.
  static List<ui.TextBox> _rightToLeft(List<ui.TextBox> boxes) {
    final ordered = <ui.TextBox>[];
    var line = <ui.TextBox>[];
    void endLine() {
      ordered.addAll(line..sort((a, b) => b.right.compareTo(a.right)));
      line = [];
    }

    for (final box in boxes) {
      final sameLine = line.any(
        (b) => box.top < b.bottom && box.bottom > b.top,
      );
      if (line.isNotEmpty && !sameLine) endLine();
      line.add(box);
    }
    endLine();
    return ordered;
  }
}

/// Use the rendered paragraph's actual boxes, including inline ayah markers.
/// A second TextPainter would not know the WidgetSpan dimensions.
class _ReadingRules extends CustomPainter {
  const _ReadingRules(this.textKey, this.textLength, this.color);
  final GlobalKey textKey;
  final int textLength;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paragraph = textKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph || !paragraph.hasSize) return;
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: textLength),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    final pen = Paint()
      ..color = color
      ..strokeWidth = .6;
    final bottoms = <double>{};
    for (final box in boxes) {
      final y = box.bottom;
      if (bottoms.any((bottom) => (bottom - y).abs() < 1)) continue;
      bottoms.add(y);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    }
  }

  @override
  bool shouldRepaint(_ReadingRules oldDelegate) => true;
}
