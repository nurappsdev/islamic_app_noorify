import '../../data/services/quran_audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import '../../domain/surah_detail.dart';
import '../bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import '../bloc/reciter/reciter_bloc.dart';
import '../bloc/surah_audio_download/surah_audio_download_bloc.dart';
import '../bloc/surah_playback/surah_playback_bloc.dart';
import 'quran_sheets.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

class QuranPlaybackAudioGate extends StatefulWidget {
  const QuranPlaybackAudioGate({
    super.key,
    required this.detail,
    required this.child,
  });

  final SurahDetail detail;
  final Widget child;

  @override
  State<QuranPlaybackAudioGate> createState() => QuranPlaybackAudioGateState();
}

class QuranPlaybackAudioGateState extends State<QuranPlaybackAudioGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshStatus();
    });
  }

  int get _reciterId =>
      context.read<ReciterBloc>().state.selectedId ?? defaultRecitationId;

  void _refreshStatus() {
    context.read<SurahAudioDownloadBloc>().add(
      CheckSurahAudioStatus(
        reciterId: _reciterId,
        surahNo: widget.detail.number,
        totalAyah: widget.detail.totalAyah,
      ),
    );
  }

  Future<void> _promptDownload() async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final saved = await showSurahAudioSheet(
      context,
      downloadBloc: context.read<SurahAudioDownloadBloc>(),
      reciterId: _reciterId,
      surahNo: widget.detail.number,
      totalAyah: widget.detail.totalAyah,
    );
    if (saved && mounted) {
      context.read<SurahPlaybackBloc>().add(
        PlaySurah(
          surahNo: widget.detail.number,
          totalAyah: widget.detail.totalAyah,
          recitationId: _reciterId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ReciterBloc, ReciterState>(
          listenWhen: (p, c) => p.selectedId != c.selectedId,
          listener: (context, _) => _refreshStatus(),
        ),
        BlocListener<SurahPlaybackBloc, SurahPlaybackState>(
          listenWhen: (p, c) => !p.needsDownload && c.needsDownload,
          listener: (context, _) => _promptDownload(),
        ),
      ],
      child: widget.child,
    );
  }
}

class QuranNowPlayingBar extends StatelessWidget {
  const QuranNowPlayingBar({super.key, required this.detail});

  final SurahDetail detail;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return _AudioProgress(
      surahNo: detail.number,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 6, 18, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.surfaceColor(Color(0xFFEEF2DD)),
          border: Border.all(color: context.lineColor(const Color(0xFFD8E2B0))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
            child: BlocBuilder<SurahPlaybackBloc, SurahPlaybackState>(
              builder: (context, playState) {
                // ayah 0 is the opening Bismillah — treat it as ayah 1 here.
                final ayahNo = playState.currentAyahNo < 1
                    ? 1
                    : playState.currentAyahNo;
                return BlocProvider<AyahBookmarkBloc>(
                  key: ValueKey(ayahNo),
                  create: (_) => AyahBookmarkBloc(
                    surahNo: detail.number,
                    ayahNo: ayahNo,
                    surahName: detail.name,
                    snippet: detail.name,
                  )..add(const LoadBookmarkStatus()),
                  child: Row(
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
                          context.localizedDigits('$ayahNo'),
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
                                  color: context.surfaceColor(Colors.white),
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
                                          color: context.inkColor(
                                            Color(0xFF6B6B6B),
                                          ),
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
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: () {
                          final current = context
                              .read<SurahPlaybackBloc>()
                              .state
                              .repeatCount;
                          final next = current == 1
                              ? 2
                              : current == 2
                              ? 3
                              : current == 3
                              ? 5
                              : 1;
                          context.read<SurahPlaybackBloc>().add(
                            SetRepeatCount(next),
                          );
                        },
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 4.h,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                color: AppColor.primary,
                                size: 18.sp,
                              ),
                              BlocBuilder<
                                SurahPlaybackBloc,
                                SurahPlaybackState
                              >(
                                builder: (context, state) {
                                  if (state.repeatCount <= 1) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    context.localizedDigits(
                                      '${state.repeatCount}',
                                    ),
                                    style: TextStyle(
                                      color: AppColor.primary,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.read<SurahPlaybackBloc>().add(
                            SetActiveAyah(ayahNo),
                          );
                          final recitationId =
                              context.read<ReciterBloc>().state.selectedId ??
                              defaultRecitationId;
                          context.read<SurahPlaybackBloc>().add(
                            PlaySurah(
                              surahNo: detail.number,
                              totalAyah: detail.totalAyah,
                              recitationId: recitationId,
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
                        builder: (context, bookmarkState) {
                          return InkWell(
                            onTap: () => context.read<AyahBookmarkBloc>().add(
                              const ToggleAyahBookmark(),
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Icon(
                                bookmarkState.isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: AppColor.primary,
                                size: 18.sp,
                              ),
                            ),
                          );
                        },
                      ),
                      InkWell(
                        onTap: () {
                          if (playState.isPlaying) {
                            context.read<SurahPlaybackBloc>().add(
                              const PauseSurah(),
                            );
                            return;
                          }
                          final recitationId =
                              context.read<ReciterBloc>().state.selectedId ??
                              defaultRecitationId;
                          context.read<SurahPlaybackBloc>().add(
                            PlaySurah(
                              surahNo: detail.number,
                              totalAyah: detail.totalAyah,
                              recitationId: recitationId,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: playState.isBuffering
                              ? SizedBox(
                                  width: 18.sp,
                                  height: 18.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.primary,
                                  ),
                                )
                              : Icon(
                                  playState.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow_outlined,
                                  color: AppColor.primary,
                                  size: 24.sp,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioProgress extends StatelessWidget {
  const _AudioProgress({required this.surahNo, required this.child});
  final int surahNo;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned(
        left: 30,
        right: 30,
        bottom: 9,
        child: StreamBuilder<Duration>(
          stream: quranAudioHandler.positionStream,
          builder: (context, snapshot) {
            final duration = quranAudioHandler.duration?.inMilliseconds ?? 0;
            final active =
                quranAudioHandler.mediaItem.value?.id.startsWith('$surahNo:') ??
                false;
            return LinearProgressIndicator(
              minHeight: 2,
              value: active && duration > 0
                  ? ((snapshot.data?.inMilliseconds ?? 0) / duration).clamp(
                      0.0,
                      1.0,
                    )
                  : 0,
              color: AppColor.primary,
              backgroundColor: Colors.transparent,
            );
          },
        ),
      ),
    ],
  );
}
