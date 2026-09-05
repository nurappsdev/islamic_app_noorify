import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_page_header.dart';

/// Browse-all categories for the Dua flow (design `devImg/img_2.png`),
/// reached from the "Duas Category" section's "See All" on
/// [DuaDashboardScreen].
class DuaAllCategoryScreen extends StatelessWidget {
  const DuaAllCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final categories = DuaCatalog.categories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          children: [
            SizedBox(height: 6.h),
            DuaPageHeader(title: appText.duaAllCategoryTitle),
            SizedBox(height: 16.h),
            Text(
              '${appText.duaTotalCategoryLabel} ( ${categories.length} )',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D6B44)),
            ),
            SizedBox(height: 12.h),
            TextField(
              decoration: InputDecoration(
                hintText: appText.duaSearchCategoryHint,
                hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
                prefixIcon: const Icon(Icons.search, color: AppColor.authIcon),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
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
            SizedBox(height: 18.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 96.h,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
              ),
              itemBuilder: (context, index) =>
                  DuaCategoryTile(category: categories[index]),
            ),
          ],
        ),
      ),
    );
  }
}
