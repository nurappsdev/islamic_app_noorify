import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class SurahDetailScreen extends StatelessWidget {
  const SurahDetailScreen({super.key, required this.surahNo});

  final int surahNo;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/quranBack.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEDE7A6),
                        foregroundColor: AppColor.authLogo,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<SurahDetailBloc, SurahDetailState>(
                      builder: (context, state) {
                        if (state.isLoading && state.detail == null) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColor.primary,
                            ),
                          );
                        }
                        if (state.hasError && state.detail == null) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  appText.quranLoadError,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                TextButton(
                                  onPressed: () =>
                                      context.read<SurahDetailBloc>().add(
                                        LoadSurahDetail(surahNo),
                                      ),
                                  child: Text(appText.tryAgain),
                                ),
                              ],
                            ),
                          );
                        }
                        final detail = state.detail!;
                        final translations = isBangla
                            ? detail.bengaliAyahs
                            : detail.englishAyahs;
                        return ListView(
                          padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
                          children: [
                            Text(
                              detail.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.primary,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              detail.nameArabic,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20.sp),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              '${detail.translation} • ${detail.revelationPlace} • '
                              '${detail.totalAyah} ${appText.ayahWord}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.authLogo,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            for (
                              var i = 0;
                              i < detail.arabicAyahs.length;
                              i++
                            ) ...[
                              _AyahCard(
                                number: i + 1,
                                arabic: detail.arabicAyahs[i],
                                translation: i < translations.length
                                    ? translations[i]
                                    : '',
                              ),
                              SizedBox(height: 10.h),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.number,
    required this.arabic,
    required this.translation,
  });

  final int number;
  final String arabic;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDDE8C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13.r,
            backgroundColor: const Color(0xFFDFE9B9),
            child: Text(
              '$number',
              style: TextStyle(color: AppColor.primary, fontSize: 11.sp),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 19.sp, height: 1.8),
          ),
          if (translation.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              translation,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: const Color(0xFF444444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
