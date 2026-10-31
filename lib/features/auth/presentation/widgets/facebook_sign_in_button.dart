import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Facebook's branded sign-in button: the white "f" mark on Facebook blue.
///
/// Geometry (height, corner radius, tile size, label size) deliberately
/// mirrors [GoogleSignInButton] so the two social buttons stack as one pair
/// of identical controls.
///
/// UI only for now: no Facebook login is wired up behind [onPressed].
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
    final buttonHeight = height ?? 50.h;
    // The white mark sits inside the pill with an even margin all round.
    final tileSize = buttonHeight - 10.h;

    return SizedBox(
      height: buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _facebookBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _facebookBlue.withValues(alpha: .5),
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29.r),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 18.w,
                height: 18.h,
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
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
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
