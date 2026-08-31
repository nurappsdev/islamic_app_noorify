import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';

/// Per-collection Hadith category list.
///
/// Reached from a collection card's "Explore" action on
/// [HadithLibraryListScreen]. Shows the ordered chapters/categories with a
/// read-progress ring.
class HadithCategoryScreen extends StatelessWidget {
  const HadithCategoryScreen({super.key, this.collectionName});

  final String? collectionName;

  static const _categories = <_HadithCategory>[
    _HadithCategory(title: 'Ohir Sucona', count: 7, progress: 0.6),
    _HadithCategory(title: 'Prayer', count: 20, progress: 0.35),
    _HadithCategory(title: 'Iman', count: 17, progress: 0.8),
    _HadithCategory(title: 'Society', count: 11, progress: 0.5),
    _HadithCategory(title: 'Knowledge', count: 14, progress: 0.15),
    _HadithCategory(title: 'Purification', count: 9, progress: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return HadithListScaffold(
      title: appText.hadithCategory,
      children: [
        for (var i = 0; i < _categories.length; i++) ...[
          _CategoryCard(
            index: i + 1,
            category: _categories[i],
            hadithWord: appText.categoryHadith,
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

class _HadithCategory {
  const _HadithCategory({
    required this.title,
    required this.count,
    required this.progress,
  });

  final String title;
  final int count;
  final double progress;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.index,
    required this.category,
    required this.hadithWord,
  });

  final int index;
  final _HadithCategory category;
  final String hadithWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE3E7D3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF8B9A4B),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3320),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${category.count} $hadithWord',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF9BA85B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          _ProgressRing(value: category.progress),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46.r,
      height: 46.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46.r,
            height: 46.r,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4.r,
              backgroundColor: const Color(0xFFEDEFE0),
              valueColor: const AlwaysStoppedAnimation(AppColor.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7D8765),
            ),
          ),
        ],
      ),
    );
  }
}
