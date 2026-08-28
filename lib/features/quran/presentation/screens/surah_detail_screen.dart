import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_audio/ayah_audio_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_sheets.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_shimmer.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_translation_switch.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_ayah_card.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_hero_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({
    super.key,
    required this.surahNo,
    this.surahName = '',
  });

  final int surahNo;
  final String surahName;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  bool _recorded = false;

  void _recordLastRead(SurahDetail detail) {
    if (_recorded) return;
    _recorded = true;
    QuranLocalStore.create().then((store) {
      return store.recordSurahOpened(
        surahNo: detail.number,
        surahName: detail.name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (context) {
        final uiLang = context.read<LanguageBloc>().state.language;
        return QuranTranslationBloc(initial: uiLang)
          ..add(LoadTranslationPreference(uiLang));
      },
      child: _buildScaffold(context, appText),
    );
  }

  Widget _buildScaffold(BuildContext context, AppText appText) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7EA),
      body: SafeArea(
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
                      widget.surahName.isNotEmpty
                          ? widget.surahName
                          : appText.categoryQuran,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF6B7458),
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<SurahDetailBloc, SurahDetailState>(
                  builder: (context, state) {
                    if (state.isLoading && state.detail == null) {
                      return const SurahDetailShimmer();
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
                              onPressed: () => context
                                  .read<SurahDetailBloc>()
                                  .add(LoadSurahDetail(widget.surahNo)),
                              child: Text(appText.tryAgain),
                            ),
                          ],
                        ),
                      );
                    }
                    final detail = state.detail!;
                    _recordLastRead(detail);
                    return _SurahBody(detail: detail, appText: appText);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The loaded surah. Turns a "needs download" play attempt into the download
/// modal, then resumes playback once the recitation is saved.
class _SurahBody extends StatelessWidget {
  const _SurahBody({required this.detail, required this.appText});

  final SurahDetail detail;
  final AppText appText;

  int _reciterId(BuildContext context) =>
      context.read<ReciterBloc>().state.selectedId ?? defaultRecitationId;

  Future<void> _promptDownload(BuildContext context, String verseKey) async {
    // Ignore repeat triggers while the sheet is already up.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final saved = await showSurahAudioSheet(
      context,
      downloadBloc: context.read<SurahAudioDownloadBloc>(),
      reciterId: _reciterId(context),
      surahNo: detail.number,
      totalAyah: detail.totalAyah,
    );
    if (saved && context.mounted) {
      context.read<AyahAudioBloc>().add(
        PlayAyahAudio(
          verseKey: verseKey,
          recitationId: _reciterId(context),
          restart: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AyahAudioBloc, AyahAudioState>(
      listenWhen: (p, c) =>
          c.needsDownloadForVerseKey != null &&
          p.needsDownloadForVerseKey != c.needsDownloadForVerseKey,
      listener: (context, state) =>
          _promptDownload(context, state.needsDownloadForVerseKey!),
      child: ListView(
        padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
        children: [
          SurahHeroCard(
            appText: appText,
            detail: detail,
            actionLabel: appText.viewFullSura,
            onAction: () => Navigator.of(
              context,
            ).pushNamed(RouteNames.quranFullSurah, arguments: detail.number),
          ),
          SizedBox(height: 10.h),
          Center(
            child: Text(
              '${appText.yourReadingTimeIs} '
              '${formatReadingTime(appText, detail.arabicAyahs)}',
              style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
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
          SizedBox(height: 16.h),
          for (var i = 0; i < detail.arabicAyahs.length; i++) ...[
            SurahAyahCard(
              surahNo: detail.number,
              ayahNo: i + 1,
              surahName: detail.name,
              arabic: detail.arabicAyahs[i],
              englishTranslation: i < detail.englishAyahs.length
                  ? detail.englishAyahs[i]
                  : '',
              bengaliTranslation: i < detail.bengaliAyahs.length
                  ? detail.bengaliAyahs[i]
                  : '',
            ),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}
