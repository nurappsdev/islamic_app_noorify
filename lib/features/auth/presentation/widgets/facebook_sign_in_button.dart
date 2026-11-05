import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'auth_button_metrics.dart';

/// Facebook's branded sign-in button: the white "f" mark on Facebook blue.
///
/// Geometry (height, corner radius, tile size, label size) comes from
/// [AuthButtonMetrics], the same source [GoogleSignInButton] reads, so the
/// two social buttons stack as one pair of identical controls.
class FacebookSignInButton extends StatelessWidget {
  const FacebookSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
  });

  /// Facebook's brand blue. Fixed in both themes, as with Google's: the
  /// button is Facebook's and recolouring it would breach their branding
  /// guidelines.
  static const Color _facebookBlue = Color(0xFF1877F2);

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AuthButtonMetrics.height;
    // The white mark sits inside the pill with an even margin all round.
    final tileSize = buttonHeight - 8.h;

    return SizedBox(
      height: buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _facebookBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _facebookBlue.withValues(alpha: .5),
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthButtonMetrics.radius),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: AuthButtonMetrics.spinnerSize,
                height: AuthButtonMetrics.spinnerSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                children: [
                  // The mark already carries its own white disc, so unlike
                  // Google's tile it needs no white backing or padding.
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: SvgPicture.asset(
                      'assets/facebookIcon.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Expanded(
                    child: AuthButtonLabel(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AuthButtonMetrics.labelSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Balances the mark so the label is centred in the button,
                  // not in the space left over beside it.
                  SizedBox(width: tileSize),
                ],
              ),
      ),
    );
  }
}
