import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';

/// "Saved Hadith" folders, reached from index 2 ("Saved") of the Hadith
/// navigation bar. Static mock list of saved folders with reading progress.
class HadithSavedScreen extends StatelessWidget {
  const HadithSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final folders = <_SavedFolder>[
      _SavedFolder(name: appText.hadithCategorySample, count: 6, progress: .6),
      const _SavedFolder(name: 'Prayer', count: 6, progress: .6),
      const _SavedFolder(name: 'Iman', count: 6, progress: .6),
      const _SavedFolder(name: 'Society', count: 6, progress: .6),
      _SavedFolder(name: appText.newFolder, totalSaved: 7, progress: .6),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 6.h),
                _Header(title: appText.savedHadithTitle),
                SizedBox(height: 18.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _SearchField(hint: appText.searchHere),
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
                    itemCount: folders.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) =>
                        _FolderCard(folder: folders[index], appText: appText),
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HadithBottomNav(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedFolder {
  const _SavedFolder({
    required this.name,
    required this.progress,
    this.count,
    this.totalSaved,
  });

  final String name;
  final double progress;
  final int? count;
  final int? totalSaved;
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});

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

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.appText});

  final _SavedFolder folder;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final subtitle = folder.totalSaved != null
        ? '${appText.totalSavedLabel} : ${folder.totalSaved.toString().padLeft(2, '0')}'
        : '${appText.hadithNoLabel} : 1-${folder.count}';

    return Container(
      height: 76.h,
      padding: EdgeInsets.fromLTRB(12.w, 0, 16.w, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E7D3)),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF9BAE6C),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: TextStyle(
                    color: const Color(0xFF2C3320),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFFA1AD59),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _ProgressRing(value: folder.progress),
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
      width: 40.r,
      height: 40.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40.r,
            height: 40.r,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 3.5,
              backgroundColor: const Color(0xFFE8ECD8),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8FA33F)),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: const Color(0xFF8FA33F),
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
