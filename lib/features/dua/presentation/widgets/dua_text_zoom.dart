import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// How far the reader's text may be scaled. Shared by the settings sliders
/// ([DuaFontSizeControls]) and the pinch gesture, so neither reaches a size
/// the other cannot.
abstract final class DuaFontSizeLimits {
  /// 16-50px: the 20px default scaled down to 80% and up to 250%, the same
  /// reach the Quran and Hadith readers allow.
  static const arabicMin = 16.0;
  static const arabicMax = 50.0;

  /// 10-30px, around the 12px default. Carries both the Bangla
  /// pronunciation and the Bangla translation.
  static const translationMin = 10.0;
  static const translationMax = 30.0;
}

/// The Arabic and translation font sizes a pinch of [scale] reaches, from
/// the sizes the gesture started at ([arabic], [translation]).
///
/// Both move by one factor, so the proportion the reader was set up with is
/// kept, and that factor is held inside [DuaFontSizeLimits] — a pinch can
/// never reach a size the sliders could not. A stored size from outside the
/// limits is brought back into them first.
({double arabic, double translation}) duaZoomedFontSizes({
  required double arabic,
  required double translation,
  required double scale,
}) {
  final fromArabic = arabic.clamp(
    DuaFontSizeLimits.arabicMin,
    DuaFontSizeLimits.arabicMax,
  );
  final fromTranslation = translation.clamp(
    DuaFontSizeLimits.translationMin,
    DuaFontSizeLimits.translationMax,
  );
  // Whichever of the two runs out of room first ends the pinch for both.
  // Each bound is on its own side of 1.0, so the range is never empty.
  final smallest = math.max(
    DuaFontSizeLimits.arabicMin / fromArabic,
    DuaFontSizeLimits.translationMin / fromTranslation,
  );
  final largest = math.min(
    DuaFontSizeLimits.arabicMax / fromArabic,
    DuaFontSizeLimits.translationMax / fromTranslation,
  );
  final factor = scale.isFinite && scale > 0
      ? scale.clamp(smallest, largest)
      : 1.0;
  return (arabic: fromArabic * factor, translation: fromTranslation * factor);
}

/// Reports a two-finger pinch over [child] as a scale factor.
///
/// One finger is never taken: the gesture is claimed only once a second
/// finger is down, so a scrolling child goes on scrolling and its buttons go
/// on being tapped exactly as before. Lifting back to one finger holds the
/// size reached rather than letting it collapse towards a single point.
///
/// [onZoomStart] always comes before the factors it applies to, and
/// [onZoomEnd] once for each pinch that started. A pinch resumed after a
/// finger was lifted is reported as a new one, so [onZoomStart] must read
/// the size on screen rather than the last saved one.
class DuaTextZoomDetector extends StatefulWidget {
  const DuaTextZoomDetector({
    super.key,
    required this.onZoomStart,
    required this.onZoomUpdate,
    required this.onZoomEnd,
    required this.child,
  });

  /// The second finger has landed: the sizes on screen now are what the
  /// factors below apply to.
  final VoidCallback onZoomStart;

  /// The live pinch factor, 1.0 being the size the pinch started at.
  final ValueChanged<double> onZoomUpdate;

  /// The fingers are off: the size reached is the one to keep.
  final VoidCallback onZoomEnd;

  final Widget child;

  @override
  State<DuaTextZoomDetector> createState() => _DuaTextZoomDetectorState();
}

class _DuaTextZoomDetectorState extends State<DuaTextZoomDetector> {
  /// Whether a pinch of ours is running. [ScaleGestureRecognizer] ends and
  /// restarts its gesture whenever the fingers change, which must not reach
  /// the reader as a pinch that never began.
  bool _zooming = false;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _TwoFingerScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              _TwoFingerScaleGestureRecognizer
            >(
              () => _TwoFingerScaleGestureRecognizer(debugOwner: this),
              (recognizer) => recognizer
                ..onStart = (details) {
                  if (details.pointerCount < 2 || _zooming) return;
                  _zooming = true;
                  widget.onZoomStart();
                }
                ..onUpdate = (details) {
                  // A single remaining finger has no span to measure, so its
                  // updates are left out and the last size stands.
                  if (!_zooming || details.pointerCount < 2) return;
                  widget.onZoomUpdate(details.scale);
                }
                ..onEnd = (_) {
                  if (!_zooming) return;
                  _zooming = false;
                  widget.onZoomEnd();
                },
            ),
      },
      child: widget.child,
    );
  }
}

/// A scale recognizer that only ever wins with two fingers on the screen.
///
/// [ScaleGestureRecognizer] treats one moving finger as a scale as well,
/// which would take the drag the scrollable underneath needs. This one
/// refuses to be accepted below two pointers, and claims the gesture as soon
/// as the second lands, so the pinch answers immediately instead of waiting
/// out the slop.
class _TwoFingerScaleGestureRecognizer extends ScaleGestureRecognizer {
  _TwoFingerScaleGestureRecognizer({super.debugOwner});

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerDownEvent && pointerCount >= 2) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    // Staying undecided leaves the arena to the scrollable's own drag; a
    // rejection would be just as final but is not ours to declare, since a
    // second finger may still arrive.
    if (disposition == GestureDisposition.accepted && pointerCount < 2) return;
    super.resolve(disposition);
  }
}
