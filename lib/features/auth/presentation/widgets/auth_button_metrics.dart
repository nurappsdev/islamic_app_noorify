import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One source of truth for how every authentication button is sized.
///
/// Sign in, Sign up, Google, Facebook, Sign out and the guest sign-in prompt
/// all read these numbers, so the controls stay a matched set: change a value
/// here and the whole auth surface moves together.
///
/// The values are deliberately slimmer than Material's defaults — a shorter
/// frame with tighter padding and a hairline border reads as more compact and
/// premium — while staying at or above the 44dp minimum tap target.
class AuthButtonMetrics {
  const AuthButtonMetrics._();

  /// Full-width buttons: Sign in, Sign up, Google, Facebook.
  static double get height => 44.h;

  /// Buttons that sit two-to-a-row, such as the guest prompt's
  /// "Not now" / "Sign in" pair, where the narrower cell needs a tighter box.
  static double get compactHeight => 42.h;

  /// Sign out, which carries a leading icon and a trailing chevron.
  static double get signOutHeight => 46.h;

  /// Pill corner. Larger than half the height, so Flutter clamps it to a true
  /// pill no matter which height above is used.
  static double get radius => 26.r;

  /// Corner for the square-ish buttons inside the guest prompt dialog.
  static double get dialogRadius => 14.r;

  static double get horizontalPadding => 14.w;
  static double get compactHorizontalPadding => 10.w;

  /// Hairline border. Thinner than the old 1.4 so the outline reads as a
  /// crisp edge rather than a frame.
  static const double borderWidth = 1.0;

  static double get labelSize => 13.5.sp;
  static double get compactLabelSize => 13.sp;
  static double get spinnerSize => 16.w;
  static double get iconSize => 16.sp;

  /// Gap between stacked auth buttons.
  static double get gap => 12.h;
}

/// A button label that can never wrap, clip or break across lines.
///
/// Auth labels are translated ("Continue with Facebook" is far longer in
/// Bangla) and the app applies its own [TextScaler], so a fixed font size can
/// overflow a narrow button on small screens or at large text sizes. This
/// keeps the text on one line and scales it down only as far as the available
/// width actually requires, so the button looks identical wherever it fits.
class AuthButtonLabel extends StatelessWidget {
  const AuthButtonLabel(this.label, {super.key, this.style, this.textAlign});

  final String label;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
