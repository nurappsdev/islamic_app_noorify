import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';

/// Full-detail bottom sheet for one name, opened from its card's
/// "Click to see details" button.
class AsmaNameDetailSheet extends StatelessWidget {
  const AsmaNameDetailSheet({super.key, required this.name});

  final AsmaName name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E7D3),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 18.h),
            Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE7EAD4),
                shape: BoxShape.circle,
              ),
              child: Text(
                name.orderLabel,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.authLogo,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              name.nameArabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E6B2E),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              name.nameTransliteration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.authLogo,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              name.nameBangla,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: AppColor.authHint),
            ),
            SizedBox(height: 14.h),
            Text(
              name.meaningBangla,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.5,
                color: const Color(0xFF4B5540),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
