import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_category_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Opens the reader for a Hadith library collection. Books without bundled
/// content ([HadithBook.isAvailable] is false) show a "coming soon" notice
/// instead.
void openHadithCollection(BuildContext context, HadithBook book) {
  if (!book.isAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.of(context).hadithBookComingSoon)),
    );
    return;
  }
  Navigator.of(
    context,
  ).pushNamed(RouteNames.hadithBookReader, arguments: book.slug);
}

/// Opens an API-backed collection: its category list
/// (`GET /hadiths/categories?bookId=...`).
void openHadithLibraryBook(BuildContext context, HadithLibraryBook book) {
  Navigator.of(context).pushNamed(
    RouteNames.hadithCategory,
    arguments: HadithCategoryArgs(bookId: book.id, title: book.titleEn),
  );
}

/// Opens every hadith of an API-backed collection, one card after another
/// (`GET /hadiths?bookId=...`).
void openAllHadithsOfBook(BuildContext context, HadithLibraryBook book) {
  final isBangla =
      context.read<LanguageBloc>().state.language == AppLanguage.bangla;
  final name = isBangla && book.titleBn.isNotEmpty
      ? book.titleBn
      : book.titleEn;
  Navigator.of(context).pushNamed(
    RouteNames.hadithDetail,
    arguments: HadithDetailArgs(bookId: book.id, title: name),
  );
}

/// `176337` -> `1,76,337` (lakh grouping, as the design shows it).
String formatHadithCount(int value) {
  final digits = value.toString();
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final grouped = head.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+$)'),
    (m) => '${m[1]},',
  );
  return '$grouped,$tail';
}

/// Shared shell for the Hadith list screens (library "See All" and the
/// per-collection category list). Renders the centered title with a pill back
/// button, a search field and then [children] in a scroll view.
class HadithListScaffold extends StatelessWidget {
  const HadithListScaffold({
    super.key,
    required this.title,
    required this.children,
    this.controller,
    this.onSearchChanged,
  });

  final String title;
  final List<Widget> children;

  /// Lets a screen listen to scrolling (e.g. for pagination).
  final ScrollController? controller;

  /// Called as the search text changes; when null the field does nothing.
  final ValueChanged<String>? onSearchChanged;

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
              child: HadithSearchField(
                hint: appText.searchHere,
                onChanged: onSearchChanged,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView(
                controller: controller,
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

class HadithSearchField extends StatelessWidget {
  const HadithSearchField({super.key, required this.hint, this.onChanged});

  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
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
