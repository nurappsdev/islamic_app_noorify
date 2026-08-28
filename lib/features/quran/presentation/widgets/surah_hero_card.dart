import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';

class SurahHeroCard extends StatelessWidget {
  const SurahHeroCard({
    super.key,
    required this.appText,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final AppText appText;
  final SurahDetail detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FA05C), Color(0xFF56682F)],
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        children: [
          Text(
            detail.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            detail.translation,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          SizedBox(height: 10.h),
          Container(height: 1, color: Colors.white24),
          SizedBox(height: 10.h),
          Text(
            '${revelationPlaceLabel(appText, detail.revelationPlace).toUpperCase()} • '
            '${detail.totalAyah} ${appText.ayahWord.toUpperCase()}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 14.h),
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image.asset(
              'assets/images/bismillah.png',
              height: 30.h,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              if (actionLabel != null && onAction != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .12),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
              ] else
                const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 14.sp),
                    SizedBox(width: 6.w),
                    Text(
                      '${appText.pointsLabel} : '
                      '${detail.totalAyah.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
