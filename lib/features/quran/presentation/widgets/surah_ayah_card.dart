import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_audio/ayah_audio_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/tafsir/tafsir_bloc.dart';

class SurahAyahCard extends StatelessWidget {
  const SurahAyahCard({
    super.key,
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.arabic,
    required this.translation,
    required this.isBangla,
  });

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final String arabic;
  final String translation;
  final bool isBangla;

  String get _verseKey => '$surahNo:$ayahNo';

  void _openReciterPicker(BuildContext context) {
    final reciterBloc = context.read<ReciterBloc>();
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: reciterBloc,
        child: const _ReciterPickerSheet(),
      ),
    );
  }

  void _openTafsir(BuildContext context) {
    final resourceId = isBangla
        ? banglaTafsirResourceId
        : englishTafsirResourceId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) =>
            TafsirBloc(tafsirResourceId: resourceId)
              ..add(LoadTafsir(_verseKey)),
        child: const _TafsirSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
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
                        onTap: () => _openReciterPicker(context),
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
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () => _openTafsir(context),
              child: Text(
                appText.viewQuranTafsir,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColor.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterPickerSheet extends StatelessWidget {
  const _ReciterPickerSheet();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.selectReciterTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            BlocBuilder<ReciterBloc, ReciterState>(
              builder: (context, state) {
                if (state.isLoading && state.reciters.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColor.primary,
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 360.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.reciters.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: const Color(0xFFE3ECC5),
                    ),
                    itemBuilder: (context, index) {
                      final reciter = state.reciters[index];
                      final selected = reciter.id == state.selectedId;
                      return ListTile(
                        title: Text(
                          reciter.name,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColor.primary,
                              )
                            : null,
                        onTap: () {
                          context.read<ReciterBloc>().add(
                            SelectReciter(reciter.id),
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TafsirSheet extends StatelessWidget {
  const _TafsirSheet();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.tafsirTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 420.h),
              child: BlocBuilder<TafsirBloc, TafsirState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                        ),
                      ),
                    );
                  }
                  if (state.hasError) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          appText.quranLoadError,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: Text(
                      state.text,
                      style: TextStyle(fontSize: 13.sp, height: 1.5),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
