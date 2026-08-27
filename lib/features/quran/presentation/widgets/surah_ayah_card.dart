import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_audio/ayah_audio_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_sheets.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_translation_switch.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class SurahAyahCard extends StatelessWidget {
  const SurahAyahCard({
    super.key,
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.arabic,
    required this.englishTranslation,
    required this.bengaliTranslation,
  });

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final String arabic;
  final String englishTranslation;
  final String bengaliTranslation;

  String get _verseKey => '$surahNo:$ayahNo';

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final lang = context.select<QuranTranslationBloc, AppLanguage>(
      (bloc) => bloc.state.langForAyah(ayahNo),
    );
    final isBangla = lang == AppLanguage.bangla;
    final translation = isBangla ? bengaliTranslation : englishTranslation;
    return BlocProvider(
      create: (_) => AyahBookmarkBloc(
        surahNo: surahNo,
        ayahNo: ayahNo,
        surahName: surahName,
        snippet: translation,
      )..add(const LoadBookmarkStatus()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2DD),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFD8E2B0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Text(
                    '$ayahNo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: BlocBuilder<ReciterBloc, ReciterState>(
                    builder: (context, reciterState) {
                      final name = reciterState.selectedName;
                      return InkWell(
                        onTap: () => openReciterPicker(
                          context,
                          context.read<ReciterBloc>(),
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty
                                      ? appText.selectReciterTitle
                                      : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF6B6B6B),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16.sp,
                                color: AppColor.primary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () {
                    final recitationId =
                        context.read<ReciterBloc>().state.selectedId ??
                        defaultRecitationId;
                    context.read<AyahAudioBloc>().add(
                      PlayAyahAudio(
                        verseKey: _verseKey,
                        recitationId: recitationId,
                        restart: true,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.replay_rounded,
                      color: AppColor.primary,
                      size: 18.sp,
                    ),
                  ),
                ),
                BlocBuilder<AyahBookmarkBloc, AyahBookmarkState>(
                  builder: (context, state) {
                    return InkWell(
                      onTap: () => context.read<AyahBookmarkBloc>().add(
                        const ToggleAyahBookmark(),
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          state.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: AppColor.primary,
                          size: 18.sp,
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<AyahAudioBloc, AyahAudioState>(
                  builder: (context, audioState) {
                    final isPlaying = audioState.playingVerseKey == _verseKey;
                    final isBuffering = isPlaying && audioState.isBuffering;
                    return InkWell(
                      onTap: () {
                        final recitationId =
                            context.read<ReciterBloc>().state.selectedId ??
                            defaultRecitationId;
                        context.read<AyahAudioBloc>().add(
                          PlayAyahAudio(
                            verseKey: _verseKey,
                            recitationId: recitationId,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: isBuffering
                            ? SizedBox(
                                width: 18.sp,
                                height: 18.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.primary,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: AppColor.primary,
                                size: 22.sp,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 19.sp, height: 1.8),
            ),
            if (translation.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                translation,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: const Color(0xFF444444),
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Row(
              children: [
                GestureDetector(
                  onTap: () => openTafsirSheet(context, _verseKey, isBangla),
                  child: Text(
                    appText.viewQuranTafsir,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColor.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Spacer(),
                AyahTranslationToggle(ayahNo: ayahNo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
