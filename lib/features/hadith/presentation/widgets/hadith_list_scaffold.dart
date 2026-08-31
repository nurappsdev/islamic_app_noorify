import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Shared shell for the Hadith list screens (library "See All" and the
/// per-collection category list). Renders the centered title with a pill back
/// button, a search field and then [children] in a scroll view.
class HadithListScaffold extends StatelessWidget {
  const HadithListScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _HadithListHeader(title: title),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _HadithSearchField(hint: appText.searchHere),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithListHeader extends StatelessWidget {
  const _HadithListHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 14.w),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFCBD16B),
                  foregroundColor: const Color(0xFF303629),
                  minimumSize: Size(38.r, 38.r),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColor.authLogo,
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithSearchField extends StatelessWidget {
  const _HadithSearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: Color(0xFFE3E7D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: AppColor.primary),
        ),
      ),
    );
  }
}
