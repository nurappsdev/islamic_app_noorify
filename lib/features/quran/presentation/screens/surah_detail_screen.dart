import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
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
                          actionLabel: appText.viewFullSura,
                          onAction: () => Navigator.of(context).pushNamed(
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
