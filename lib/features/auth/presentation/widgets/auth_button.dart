import 'package:flutter/material.dart';

import '../../../../core/utils/app_color.dart';
import 'auth_button_metrics.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AuthButtonMetrics.height;

    return SizedBox(
      height: buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: AuthButtonMetrics.horizontalPadding,
          ),
          // The slimmer frame leaves no room for the default 48dp tap
          // padding to grow the button back to its old height.
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
            : AuthButtonLabel(
                label,
                style: TextStyle(fontSize: AuthButtonMetrics.labelSize),
              ),
      ),
    );
  }
}
