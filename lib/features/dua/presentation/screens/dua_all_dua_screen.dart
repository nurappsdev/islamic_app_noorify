import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_item_tile.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_page_header.dart';

/// Full "All dua" list for a Dua group (design `devImg/img_5.png`), reached
/// from the "All dua" section's "See All" on [DuaGroupScreen].
class DuaAllDuaScreen extends StatelessWidget {
  const DuaAllDuaScreen({super.key, required this.featured});

  final DuaFeatured featured;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final duaNames = DuaCatalog.groupDuaNames;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          children: [
            SizedBox(height: 6.h),
            DuaPageHeader(title: appText.duaAllDuaTitle),
            SizedBox(height: 16.h),
            Text(
              '${appText.duaTotalDuaLabel} ( ${duaNames.length} )',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D6B44)),
            ),
            SizedBox(height: 12.h),
            TextField(
              decoration: InputDecoration(
                hintText: appText.searchHere,
                hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: AppColor.authFieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: AppColor.authFieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: AppColor.primary),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            for (var i = 0; i < duaNames.length; i++) ...[
              DuaItemTile(name: duaNames[i]),
              if (i != duaNames.length - 1) SizedBox(height: 10.h),
            ],
          ],
        ),
      ),
    );
  }
}
