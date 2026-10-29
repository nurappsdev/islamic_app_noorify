import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Google's branded sign-in button: the white logo tile on Google blue.
///
/// Geometry (height, corner radius, label size) deliberately matches
/// [AuthButton] so it sits directly under the primary action without
/// looking like a different control.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
  });

  /// Google's brand blue. Fixed in both themes: the button is Google's, and
  /// recolouring it would breach their branding guidelines.
  static const Color _googleBlue = Color(0xFF4285F4);

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? 50.h;
    // The white tile sits inside the pill with an even margin all round.
    final tileSize = buttonHeight - 10.h;

    return SizedBox(
      height: buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _googleBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _googleBlue.withValues(alpha: .5),
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
                  Container(
                    width: tileSize,
                    height: tileSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    padding: EdgeInsets.all(7.r),
                    child: Image.asset(
                      'assets/googleIcon.png',
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
                  // Balances the tile so the label is centred in the button,
                  // not in the space left over beside it.
                  SizedBox(width: tileSize),
                ],
              ),
      ),
    );
  }
}
