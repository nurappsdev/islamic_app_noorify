import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_shimmer.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_ayah_card.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_hero_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({
    super.key,
    required this.surahNo,
    this.surahName = '',
    this.offline = false,
  });

  final int surahNo;
  final String surahName;

  /// When true the screen renders from the bundled offline database: no
  /// per-ayah audio/reciter controls and no "view full surah" action.
  final bool offline;

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
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
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
                              onPressed: () =>
                                  context.read<SurahDetailBloc>().add(
                                    LoadSurahDetail(widget.surahNo),
                                  ),
                              child: Text(appText.tryAgain),
                            ),
                          ],
                        ),
                      );
                    }
                    final detail = state.detail!;
                    _recordLastRead(detail);
                    final translations = isBangla
                        ? detail.bengaliAyahs
                        : detail.englishAyahs;
                    return ListView(
                      padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
                      children: [
                        SurahHeroCard(
                          appText: appText,
                          detail: detail,
                          actionLabel: widget.offline
                              ? null
                              : appText.viewFullSura,
                          onAction: widget.offline
                              ? null
                              : () => Navigator.of(context).pushNamed(
                                  RouteNames.quranFullSurah,
                                  arguments: detail.number,
                                ),
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
                        if (widget.offline) ...[
                          SizedBox(height: 12.h),
                          _OfflineAudioDownload(
                            surahNo: detail.number,
                            totalAyah: detail.arabicAyahs.length,
                          ),
                        ],
                        SizedBox(height: 18.h),
                        for (
                          var i = 0;
                          i < detail.arabicAyahs.length;
                          i++
                        ) ...[
                          SurahAyahCard(
                            surahNo: detail.number,
                            ayahNo: i + 1,
                            surahName: detail.name,
                            arabic: detail.arabicAyahs[i],
                            translation: i < translations.length
                                ? translations[i]
                                : '',
                            isBangla: isBangla,
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
    );
  }
}

/// Offline-only strip: downloads the whole surah's recitation (for the
/// currently selected reciter) so it plays without a connection.
class _OfflineAudioDownload extends StatefulWidget {
  const _OfflineAudioDownload({
    required this.surahNo,
    required this.totalAyah,
  });

  final int surahNo;
  final int totalAyah;

  @override
  State<_OfflineAudioDownload> createState() => _OfflineAudioDownloadState();
}

class _OfflineAudioDownloadState extends State<_OfflineAudioDownload> {
  int? _checkedForReciter;

  void _check(int reciterId) {
    if (_checkedForReciter == reciterId) return;
    _checkedForReciter = reciterId;
    context.read<SurahAudioDownloadBloc>().add(
      CheckSurahAudioStatus(
        reciterId: reciterId,
        surahNo: widget.surahNo,
        totalAyah: widget.totalAyah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final reciterId =
        context.watch<ReciterBloc>().state.selectedId ?? defaultRecitationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check(reciterId);
    });

    return BlocBuilder<SurahAudioDownloadBloc, SurahAudioDownloadState>(
      builder: (context, state) {
        final percent = state.progress == null
            ? null
            : (state.progress! * 100).round();

        Widget content;
        switch (state.status) {
          case SurahAudioDownloadStatus.downloading:
            content = Row(
              children: [
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${appText.quranDownloadSurahAudio}  ${percent ?? 0}%',
                  style: TextStyle(fontSize: 12.sp, color: AppColor.primary),
                ),
              ],
            );
          case SurahAudioDownloadStatus.complete:
            content = Row(
              children: [
                Icon(
                  Icons.download_done_rounded,
                  size: 16.sp,
                  color: AppColor.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  appText.quranAudioDownloaded,
                  style: TextStyle(fontSize: 12.sp, color: AppColor.primary),
                ),
              ],
            );
          case SurahAudioDownloadStatus.idle:
          case SurahAudioDownloadStatus.checking:
          case SurahAudioDownloadStatus.failed:
            content = InkWell(
              onTap: state.status == SurahAudioDownloadStatus.checking
                  ? null
                  : () => context.read<SurahAudioDownloadBloc>().add(
                      StartSurahAudioDownload(
                        reciterId: reciterId,
                        surahNo: widget.surahNo,
                        totalAyah: widget.totalAyah,
                      ),
                    ),
              child: Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 16.sp,
                    color: AppColor.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    state.status == SurahAudioDownloadStatus.failed
                        ? '${appText.quranDownloadSurahAudio} · ${appText.tryAgain}'
                        : appText.quranDownloadSurahAudio,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColor.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            );
        }

        return Center(child: content);
      },
    );
  }
}
