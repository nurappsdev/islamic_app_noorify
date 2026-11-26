import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';

/// A labelled text field in the same rounded style as the Edit Profile and
/// auth forms, so the support and feedback forms match the rest of the app.
class SettingsFormField extends StatelessWidget {
  const SettingsFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(maxLines > 1 ? 18.r : 24.r);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: context.lineColor(AppColor.authFieldBorder),
      ),
    );
    final icon = prefixIcon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.inkColor(AppColor.authLogo),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines : null,
          keyboardType:
              keyboardType ??
              (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          textInputAction: textInputAction,
          style: TextStyle(fontSize: 13.sp),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
            prefixIcon: icon == null
                ? null
                : Padding(
                    // Keeps the icon at the first line of a multi-line box
                    // instead of centring it vertically.
                    padding: EdgeInsets.only(
                      bottom: maxLines > 1 ? (maxLines - 1) * 20.h : 0,
                    ),
                    child: Icon(icon, color: AppColor.authIcon, size: 18.sp),
                  ),
            filled: true,
            fillColor: context.surfaceColor(Colors.white),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 13.h,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

/// The filled, pill-shaped primary button the support and feedback forms
/// submit with. Shows a spinner and blocks taps while [isBusy].
class SettingsSubmitButton extends StatelessWidget {
  const SettingsSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.r),
          ),
        ),
        child: isBusy
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
