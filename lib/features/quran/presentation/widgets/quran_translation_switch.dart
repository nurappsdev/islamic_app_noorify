import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Endonyms — the same in any UI language.
String translationLangLabel(AppLanguage lang) =>
    lang == AppLanguage.bangla ? 'বাংলা' : 'English';

AppLanguage otherTranslationLang(AppLanguage lang) =>
    lang == AppLanguage.bangla ? AppLanguage.english : AppLanguage.bangla;

/// Surah-wide translation language selector (a two-option pill).
class SurahTranslationSwitch extends StatelessWidget {
  const SurahTranslationSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<QuranTranslationBloc, AppLanguage>(
      (bloc) => bloc.state.surahLang,
    );
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EECB),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in AppLanguage.values)
            GestureDetector(
              onTap: () => context.read<QuranTranslationBloc>().add(
                SetSurahTranslationLang(lang),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: lang == selected
                      ? AppColor.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  translationLangLabel(lang),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: lang == selected
                        ? Colors.white
                        : const Color(0xFF6B7458),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Per-ayah override toggle — shows the ayah's current translation language
/// and flips it on tap.
class AyahTranslationToggle extends StatelessWidget {
  const AyahTranslationToggle({super.key, required this.ayahNo});

  final int ayahNo;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<QuranTranslationBloc, AppLanguage>(
      (bloc) => bloc.state.langForAyah(ayahNo),
    );
    return InkWell(
      onTap: () => context.read<QuranTranslationBloc>().add(
        SetAyahTranslationLang(ayahNo, otherTranslationLang(lang)),
      ),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFC9D89A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 12.sp, color: AppColor.primary),
            SizedBox(width: 5.w),
            Text(
              translationLangLabel(lang),
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColor.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
