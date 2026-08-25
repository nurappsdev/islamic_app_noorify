import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_ayah_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

String revelationPlaceLabel(AppText appText, String rawPlace) {
  final normalized = rawPlace.toLowerCase();
  if (normalized.startsWith('mecc') || normalized.startsWith('makk')) {
    return appText.meccan;
  }
  if (normalized.startsWith('madin') || normalized.startsWith('medin')) {
    return appText.medinian;
  }
  return rawPlace;
}

String _formatReadingTime(AppText appText, List<String> arabicAyahs) {
  final wordCount = arabicAyahs.fold<int>(
    0,
    (sum, ayah) => sum + ayah.trim().split(RegExp(r'\s+')).length,
  );
  final totalSeconds = (wordCount * 0.45).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes ${appText.minLabel} $seconds ${appText.secLabel}';
}

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({super.key, required this.surahNo});

  final int surahNo;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  bool _recorded = false;
  final ScrollController _scrollController = ScrollController();

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

  void _scrollToAyahs() {
    _scrollController.animateTo(
      340.h,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                      appText.categoryQuran,
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
                      controller: _scrollController,
                      padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
                      children: [
                        _SurahHeroCard(
                          appText: appText,
                          detail: detail,
                          onViewFullSura: _scrollToAyahs,
                        ),
                        SizedBox(height: 10.h),
                        Center(
                          child: Text(
                            '${appText.yourReadingTimeIs} '
                            '${_formatReadingTime(appText, detail.arabicAyahs)}',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
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

class _SurahHeroCard extends StatelessWidget {
  const _SurahHeroCard({
    required this.appText,
    required this.detail,
    required this.onViewFullSura,
  });

  final AppText appText;
  final SurahDetail detail;
  final VoidCallback onViewFullSura;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FA05C), Color(0xFF56682F)],
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        children: [
          Text(
            detail.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            detail.translation,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          SizedBox(height: 10.h),
          Container(height: 1, color: Colors.white24),
          SizedBox(height: 10.h),
          Text(
            '${revelationPlaceLabel(appText, detail.revelationPlace).toUpperCase()} • '
            '${detail.totalAyah} ${appText.ayahWord.toUpperCase()}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 14.h),
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/bismillah.png',
              height: 30.h,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewFullSura,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                  child: Text(
                    appText.viewFullSura,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 14.sp),
                    SizedBox(width: 6.w),
                    Text(
                      '${appText.pointsLabel} : '
                      '${detail.totalAyah.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
