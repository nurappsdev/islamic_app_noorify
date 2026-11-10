import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

class AmolMyPointsBar extends StatelessWidget {
  const AmolMyPointsBar({
    super.key,
    required this.myPoints,
    required this.totalPoints,
  });

  final int myPoints;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: ShapeDecoration(
        color: context.surfaceColor(Color(0xFFDCE7AC)),
        shape: StadiumBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                context.localizedDigits(
                  '${AppText.of(context).myPoints} : $myPoints',
                ),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.inkColor(Colors.black),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D8067),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                context.localizedDigits('$totalPoints'),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.inkColor(Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
