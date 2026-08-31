import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_audio/ayah_audio_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_sheets.dart';

/// A single ayah in the plain mushaf style: centered Arabic text with no
/// card/border, a row of small action icons (tafsir, play, bookmark)
/// beneath it, and a dotted divider before the next ayah.
class QuranAyahTile extends StatelessWidget {
  const QuranAyahTile({
    super.key,
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.arabic,
    required this.snippet,
    required this.isBangla,
    this.showDivider = true,
  });

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final String arabic;
  final String snippet;
  final bool isBangla;
  final bool showDivider;

  String get _verseKey => '$surahNo:$ayahNo';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AyahBookmarkBloc(
        surahNo: surahNo,
        ayahNo: ayahNo,
        surahName: surahName,
        snippet: snippet,
      )..add(const LoadBookmarkStatus()),
      child: Column(
        children: [
          if (showDivider) const _AyahDivider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Text(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 21.sp,
                height: 1.9,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => openTafsirSheet(context, _verseKey, isBangla),
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(5.w),
                  child: Icon(
                    Icons.school_outlined,
                    color: AppColor.primary,
                    size: 17.sp,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
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
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.all(5.w),
                      child: isBuffering
                          ? SizedBox(
                              width: 15.sp,
                              height: 15.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.primary,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              color: AppColor.primary,
                              size: 17.sp,
                            ),
                    ),
                  );
                },
              ),
              SizedBox(width: 6.w),
              BlocBuilder<AyahBookmarkBloc, AyahBookmarkState>(
                builder: (context, state) {
                  return InkWell(
                    onTap: () => context.read<AyahBookmarkBloc>().add(
                      const ToggleAyahBookmark(),
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.all(5.w),
                      child: Icon(
                        state.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: AppColor.primary,
                        size: 17.sp,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AyahDivider extends StatelessWidget {
  const _AyahDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '•••',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }
}
