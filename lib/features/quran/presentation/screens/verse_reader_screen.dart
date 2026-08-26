import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/verse_reader/verse_reader_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/ayah_card.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_shimmer.dart';

class VerseReaderScreen extends StatelessWidget {
  const VerseReaderScreen({super.key, required this.juzNumber});

  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final title = '${appText.juzWord} $juzNumber';
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
                  SizedBox(
                    height: 40.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
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
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<VerseReaderBloc, VerseReaderState>(
                      builder: (context, state) {
                        if (state.isLoading && state.verses.isEmpty) {
                          return const VerseReaderShimmer();
                        }
                        if (state.hasError && state.verses.isEmpty) {
                          return Center(
                            child: Text(
                              appText.quranLoadError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13.sp,
                              ),
                            ),
                          );
                        }
                        final verses = state.verses;
                        var previousSurahNo = -1;
                        return ListView.builder(
                          padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
                          itemCount: verses.length,
                          itemBuilder: (context, index) {
                            final verse = verses[index];
                            final showHeader =
                                verse.surahNo != previousSurahNo;
                            previousSurahNo = verse.surahNo;
                            final surahName =
                                state.surahNames[verse.surahNo] ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) ...[
                                  if (index != 0) SizedBox(height: 8.h),
                                  Text(
                                    surahName,
                                    style: TextStyle(
                                      color: AppColor.primary,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                ],
                                AyahCard(
                                  surahNo: verse.surahNo,
                                  ayahNo: verse.ayahNo,
                                  surahName: surahName,
                                  arabic: verse.arabic,
                                  translation: verse.translation,
                                ),
                                SizedBox(height: 10.h),
                              ],
                            );
                          },
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
