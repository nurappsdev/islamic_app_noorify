import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// The hadith of the intro screen: the text in quotation marks, and its source
/// on a line below.
class _HadithQuote extends StatelessWidget {
  const _HadithQuote();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '“$hadithIntroQuote”',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.inkColor(const Color(0xFF4C5346)),
            fontSize: 15.sp,
            height: 1.7,
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          '— $hadithIntroQuoteSource',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.inkColor(const Color(0xFF7D8765)),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The hadith shown on the intro screen (Bangla, whatever the app language),
/// and where it comes from.
const hadithIntroQuote =
    'যে ব্যক্তি ইলম বা দ্বীনি জ্ঞান অর্জনের জন্য কোনো পথ অবলম্বন করে, '
    'আল্লাহ তার জন্য জান্নাতের পথ সুগম করে দেন। আর ফেরেশতারা ইলম '
    'অন্বেষণকারীর (শিক্ষার্থীর) কাজে সন্তুষ্ট হয়ে তাদের ডানা বিছিয়ে দেয়।';
const hadithIntroQuoteSource = 'সুনানে আবু দাউদ, হাদিস: ৩৬৪১';

/// Intro / "get started" screen for the Hadith section.
///
/// Reached from the Hadith card on the Home screen. Shows the title, a hadith
/// about seeking knowledge with its source, and the primary action, which
/// pushes the Hadith library screen.
class HadithIntroScreen extends StatelessWidget {
  const HadithIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDFEFB), Color(0xFFF1F5E4), Color(0xFFD8E5BC)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 18.w),
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFDFDE68),
                      foregroundColor: Color(0xFF303629),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    children: [
                      SizedBox(height: 70.h),
                      Text(
                        appText.hadithIntroTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.inkColor(Color(0xFF7D8765)),
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 22.h),
                      const _HadithQuote(),
                      SizedBox(height: 36.h),
                      Icon(
                        Icons.menu_book_rounded,
                        size: 190.sp,
                        color: context.inkColor(
                          Colors.white.withValues(alpha: .55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(40.w, 12.h, 40.w, 26.h),
                child: SizedBox(
                  height: 52.h,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.hadithLibrary),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: Text(
                      appText.hadithIntroStartButton,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
