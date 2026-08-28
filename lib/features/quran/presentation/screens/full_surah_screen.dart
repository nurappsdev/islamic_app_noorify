import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_sheets.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_shimmer.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_translation_switch.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_zoom_control.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_hero_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class FullSurahScreen extends StatelessWidget {
  const FullSurahScreen({super.key, required this.surahNo});

  final int surahNo;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (context) {
        final uiLang = context.read<LanguageBloc>().state.language;
        return QuranTranslationBloc(initial: uiLang)
          ..add(LoadTranslationPreference(uiLang))
          ..add(const LoadTranslationEditions());
      },
      child: Builder(builder: (context) => _buildScaffold(context, appText)),
    );
  }

  Widget _buildScaffold(BuildContext context, AppText appText) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7EA),
      body: SafeArea(
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
                    child: Padding(
                      padding: EdgeInsets.only(left: 18.w),
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
                  ),
                  Text(
                    appText.categoryQuran,
                    style: TextStyle(
                      color: const Color(0xFF6B7458),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 18.w),
                      child: IconButton(
                        onPressed: () => showQuranReaderSettingsSheet(
                          context,
                          bloc: context.read<QuranTranslationBloc>(),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE7A6),
                          foregroundColor: AppColor.authLogo,
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SurahDetailBloc, SurahDetailState>(
                builder: (context, state) {
                  if (state.isLoading && state.detail == null) {
                    return const FullSurahShimmer();
                  }
                  if (state.hasError && state.detail == null) {
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
                  final detail = state.detail!;
                  final tState = context.watch<QuranTranslationBloc>().state;
                  final isBangla = tState.surahLang == AppLanguage.bangla;
                  final editionReady =
                      tState.usingCustomEdition &&
                      tState.editionTextSurahNo == detail.number;
                  final translations = editionReady
                      ? [
                          for (var i = 1; i <= detail.arabicAyahs.length; i++)
                            tState.surahEditionText[i] ?? '',
                        ]
                      : (isBangla ? detail.bengaliAyahs : detail.englishAyahs);
                  return _PlaybackAudioGate(
                    detail: detail,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 12.h),
                            children: [
                              SurahHeroCard(
                                appText: appText,
                                detail: detail,
                                actionLabel: appText.viewInAyat,
                                onAction: () => Navigator.maybePop(context),
                              ),
                              SizedBox(height: 10.h),
                              Center(
                                child: Text(
                                  '${appText.yourReadingTimeIs} '
                                  '${formatReadingTime(appText, detail.arabicAyahs)}',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                children: [
                                  Text(
                                    appText.quranTranslationLabel,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF6B7458),
                                    ),
                                  ),
                                  const Spacer(),
                                  const SurahTranslationSwitch(),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              const QuranZoomControl(),
                              SizedBox(height: 16.h),
                              _ContinuousAyahText(
                                arabicAyahs: detail.arabicAyahs,
                              ),
                              SizedBox(height: 16.h),
                              _CurrentAyahDetails(
                                surahNo: detail.number,
                                translations: translations,
                                isBangla: isBangla,
                              ),
                            ],
                          ),
                        ),
                        _NowPlayingBar(detail: detail),
                      ],
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

/// Wraps the full-surah player: keeps the surah's audio-download status in
/// sync with the reciter and, when the user presses play before the audio is
/// downloaded, shows the download modal and resumes playback afterwards.
class _PlaybackAudioGate extends StatefulWidget {
  const _PlaybackAudioGate({required this.detail, required this.child});

  final SurahDetail detail;
  final Widget child;

  @override
  State<_PlaybackAudioGate> createState() => _PlaybackAudioGateState();
}

class _PlaybackAudioGateState extends State<_PlaybackAudioGate> {
  @override
  void initState() {
    super.initState();
    context.read<QuranTranslationBloc>().add(
      LoadSurahEditionText(widget.detail.number),
    );
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
        BlocListener<QuranTranslationBloc, QuranTranslationState>(
          listenWhen: (p, c) => p.selectedEditionId != c.selectedEditionId,
          listener: (context, _) => context.read<QuranTranslationBloc>().add(
            LoadSurahEditionText(widget.detail.number),
          ),
        ),
      ],
      child: widget.child,
    );
  }
}

class _ContinuousAyahText extends StatelessWidget {
  const _ContinuousAyahText({required this.arabicAyahs});

  final List<String> arabicAyahs;

  static const _readColor = Color(0xFFB9C79A);

  @override
  Widget build(BuildContext context) {
    final multiplier = context.select<QuranTranslationBloc, double>(
      (bloc) => bloc.state.arabicFontScale,
    );
    return BlocBuilder<SurahPlaybackBloc, SurahPlaybackState>(
      builder: (context, playState) {
        final currentAyahNo = playState.currentAyahNo;
        return RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          text: TextSpan(
            style: TextStyle(
              color: Colors.black87,
              fontSize: 19.sp * multiplier,
              height: 2.0,
            ),
            children: [
              for (var i = 0; i < arabicAyahs.length; i++)
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${arabicAyahs[i]} ',
                      style: i + 1 < currentAyahNo
                          ? const TextStyle(color: _readColor)
                          : null,
                    ),
                    TextSpan(
                      text: '﴿${i + 1}﴾  ',
                      style: TextStyle(
                        color: i + 1 < currentAyahNo
                            ? _readColor
                            : AppColor.primary,
                        fontSize: 14.sp * multiplier,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentAyahDetails extends StatelessWidget {
  const _CurrentAyahDetails({
    required this.surahNo,
    required this.translations,
    required this.isBangla,
  });

  final int surahNo;
  final List<String> translations;
  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final tState = context.watch<QuranTranslationBloc>().state;
    final multiplier = tState.translationFontScale;
    final showTranslation = tState.showTranslation;
    return BlocBuilder<SurahPlaybackBloc, SurahPlaybackState>(
      builder: (context, playState) {
        // currentAyahNo == 0 is the opening Bismillah; show ayah 1's details.
        final displayAyah = playState.currentAyahNo < 1
            ? 1
            : playState.currentAyahNo;
        final index = displayAyah - 1;
        final translation = index >= 0 && index < translations.length
            ? translations[index]
            : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTranslation && translation.isNotEmpty)
              Text(
                translation,
                style: TextStyle(
                  fontSize: 13.sp * multiplier,
                  height: 1.4,
                  color: const Color(0xFF444444),
                ),
              ),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () =>
                  openTafsirSheet(context, '$surahNo:$displayAyah', isBangla),
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
        );
      },
    );
  }
}

class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar({required this.detail});

  final SurahDetail detail;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2DD),
        border: const Border(top: BorderSide(color: Color(0xFFD8E2B0))),
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
                            BlocBuilder<SurahPlaybackBloc, SurahPlaybackState>(
                              builder: (context, state) {
                                if (state.repeatCount <= 1) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${state.repeatCount}',
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
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
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
    );
  }
}
