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
/// lifts or the press turns into a scroll, [onHold] once the hold completes.
LongPressGestureRecognizer _holdRecognizer({
  required VoidCallback onHold,
  required VoidCallback onPress,
  required VoidCallback onRelease,
}) => LongPressGestureRecognizer(duration: kAyahHoldDuration)
  ..onLongPressDown = ((_) => onPress())
  ..onLongPressCancel = onRelease
  ..onLongPressEnd = ((_) => onRelease())
  ..onLongPress = () {
    HapticFeedback.mediumImpact();
    onHold();
  };

/// The tint a held ayah fills with over [kAyahHoldDuration]: visible from
/// the moment the finger lands, and clearly stronger than the highlight of
/// the ayah being played, on light and dark pages alike.
Color _holdTint(BuildContext context, double progress) => quranOlive.withValues(
  alpha: .18 + .27 * Curves.easeOut.transform(progress),
);

/// Drives the hold feedback: runs forward while pressed, fades back out on
/// release.
mixin _HoldFeedback<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final hold = AnimationController(
    vsync: this,
    duration: kAyahHoldDuration,
    reverseDuration: const Duration(milliseconds: 180),
  );

  void startHold() => hold.forward(from: 0);
  void endHold() => hold.reverse();

  @override
  void dispose() {
    hold.dispose();
    super.dispose();
  }
}

/// Calls [onHold] once [child] has been pressed for [kAyahHoldDuration],
/// tinting it as the press builds up.
class QuranAyahHold extends StatefulWidget {
  const QuranAyahHold({super.key, required this.onHold, required this.child});
  final VoidCallback onHold;
  final Widget child;

  @override
  State<QuranAyahHold> createState() => _QuranAyahHoldState();
}

class _QuranAyahHoldState extends State<QuranAyahHold>
    with SingleTickerProviderStateMixin, _HoldFeedback {
  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => _holdRecognizer(
              onHold: () => widget.onHold(),
              onPress: startHold,
              onRelease: endHold,
            ),
            (_) {},
          ),
    },
    child: AnimatedBuilder(
      animation: hold,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: hold.value == 0 ? null : _holdTint(context, hold.value),
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
  });
  final List<QuranAyah> ayahs;
  final int active;
  final double scale;
  final ArabicFont font;

  /// An ayah held for [kAyahHoldDuration]; null leaves the text inert.
  final ValueChanged<QuranAyah>? onHold;
  @override
  State<QuranReadingText> createState() => _QuranReadingTextState();
}

class _QuranReadingTextState extends State<QuranReadingText>
    with SingleTickerProviderStateMixin, _HoldFeedback {
  final _textKey = GlobalKey();
  final _recognizers = <LongPressGestureRecognizer>[];

  /// The ayah being pressed, shown with the hold tint.
  int? _pressed;

  LongPressGestureRecognizer _recognizerFor(QuranAyah ayah) => _holdRecognizer(
    onHold: () => widget.onHold?.call(ayah),
    onPress: () {
      setState(() => _pressed = ayah.ayahNumber);
      startHold();
    },
    onRelease: endHold,
  );
  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    if (widget.onHold == null) return;
    for (final ayah in widget.ayahs) {
      _recognizers.add(_recognizerFor(ayah));
    }
  }

  @override
  void didUpdateWidget(QuranReadingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayahs != widget.ayahs ||
        (oldWidget.onHold == null) != (widget.onHold == null)) {
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
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: hold, builder: (context, _) => _text(context));

  Widget _text(BuildContext context) {
    // How far the pressed ayah's hold has come, 0 when nothing is pressed.
    double held(QuranAyah a) => _pressed == a.ayahNumber ? hold.value : 0;
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
            recognizer: widget.onHold == null ? null : _recognizers[i],
            style: TextStyle(
              backgroundColor: held(a) > 0
                  ? _holdTint(context, held(a))
                  : widget.active == a.ayahNumber
                  ? context.surfaceColor(quranPale).withValues(alpha: .7)
                  : null,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: RawGestureDetector(
              gestures: {
                if (widget.onHold != null)
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(() => _recognizerFor(a), (_) {}),
              },
              child: Transform.scale(
                // The marker swells slightly as the hold builds.
                scale: 1 + .12 * Curves.easeOut.transform(held(a)),
                child: QuranAyahMarker(
                  key: ValueKey('ayah-marker-${a.verseKey}'),
                  number: a.ayahNumber,
                  scale: widget.scale,
                ),
              ),
            ),
          ),
        ],
      ],
    );
    final scaler = MediaQuery.textScalerOf(context);
    return CustomPaint(
      painter: _ReadingRules(
        _textKey,
        widget.ayahs.fold<int>(0, (length, a) => length + _segmentLength(a)),
        context.lineColor(const Color(0xffe9e9e9)),
      ),
      child: RichText(
        key: _textKey,
        text: span,
        textScaler: scaler,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
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
