import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';

/// Full "Hadith Library" collection list.
///
/// Reached from the "See All" action next to the Hadith Library section on
/// [HadithLibraryScreen]. Each card's "Explore" action opens the
/// [HadithCategoryScreen] for that collection.
class HadithLibraryListScreen extends StatelessWidget {
  const HadithLibraryListScreen({super.key});

  static const _collections = <_LibraryCollection>[
    _LibraryCollection(name: 'Sahih  Bukhari', total: 1327),
    _LibraryCollection(name: 'Riadus salehin', total: 761),
    _LibraryCollection(name: 'Sahih Muslim', total: 1172),
    _LibraryCollection(name: 'Abu Dawud', total: 940),
    _LibraryCollection(name: 'Jami at-Tirmidhi', total: 856),
    _LibraryCollection(name: 'Sunan an-Nasai', total: 812),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return HadithListScaffold(
      title: appText.hadithLibraryTitle,
      children: [
        for (final collection in _collections) ...[
          _LibraryCard(collection: collection, appText: appText),
          SizedBox(height: 14.h),
        ],
      ],
    );
  }
}

class _LibraryCollection {
  const _LibraryCollection({required this.name, required this.total});

  final String name;
  final int total;
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.collection, required this.appText});

  final _LibraryCollection collection;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8AE),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9BAE6C)),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 20.sp,
                  color: const Color(0xFF5F6E3E),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  RouteNames.hadithCategory,
                  arguments: collection.name,
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(Icons.north_east_rounded, size: 15.sp),
                label: Text(appText.explore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4C5A34),
                  side: const BorderSide(color: Color(0xFF9BAE6C)),
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  minimumSize: Size(0, 36.h),
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            collection.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3320),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${appText.hadithTotalHadith} : ${collection.total}',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF5D6B44)),
          ),
        ],
      ),
    );
  }
}
