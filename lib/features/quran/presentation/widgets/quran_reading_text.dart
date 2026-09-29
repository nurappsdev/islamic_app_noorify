import 'quran_ayah_marker.dart';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../domain/arabic_font.dart';
import '../../domain/quran_ayah.dart';
import 'quran_design.dart';

class QuranReadingText extends StatefulWidget {
  const QuranReadingText({
    super.key,
    required this.ayahs,
    required this.active,
    required this.scale,
    required this.font,
    required this.onTap,
  });
  final List<QuranAyah> ayahs;
  final int active;
  final double scale;
  final ArabicFont font;
  final ValueChanged<QuranAyah> onTap;
  @override
  State<QuranReadingText> createState() => _QuranReadingTextState();
}

class _QuranReadingTextState extends State<QuranReadingText> {
  final _textKey = GlobalKey();
  final _recognizers = <TapGestureRecognizer>[];
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
    for (final ayah in widget.ayahs) {
      _recognizers.add(
        TapGestureRecognizer()..onTap = () => widget.onTap(ayah),
      );
    }
  }

  @override
  void didUpdateWidget(QuranReadingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayahs != widget.ayahs) _bind();
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
  Widget build(BuildContext context) {
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
            recognizer: _recognizers[i],
            style: TextStyle(
              backgroundColor: widget.active == a.ayahNumber
                  ? context.surfaceColor(quranPale).withValues(alpha: .7)
                  : null,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => widget.onTap(a),
              child: QuranAyahMarker(
                key: ValueKey('ayah-marker-${a.verseKey}'),
                number: a.ayahNumber,
                scale: widget.scale,
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
