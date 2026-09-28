import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/surah_summary.dart';
import 'quran_design.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';
import 'package:islami_app_noorify/core/localization/localization_context.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

/// One scrolling header: ornament, live metadata, then Bismillah.
/// Only the decorative image is positioned; text determines the header height.
class QuranSurahHeading extends StatelessWidget {
  const QuranSurahHeading({
    super.key,
    required this.surah,
    required this.showBismillah,
  });
  final SurahSummary surah;
  final bool showBismillah;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final width = bounds.maxWidth;
      final patternHeight = width * 380 / 402;
      return Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/quran/starting_sura_pattern.png',
                key: const ValueKey('surah-background-pattern'),
                height: patternHeight,
                width: width,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                excludeFromSemantics: true,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: patternHeight + 24),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                width * .12,
                width * .57,
                width * .12,
                24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width * .52),
                      child: Text(
                        surah.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 27,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                          color: quranOlive,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.localizedDigits(
                        AppText.of(context).quranSurahHeadingInfo.fill({
                          // English keeps the API's own spelling; Bangla uses the app's
                          // translated place name.
                          'place':
                              (context.appLanguage == AppLanguage.bangla
                                      ? revelationPlaceLabel(
                                          AppText.of(context),
                                          surah.revelationPlace,
                                        )
                                      : surah.revelationPlace)
                                  .toUpperCase(),
                          'n': surah.totalAyah,
                        }),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: quranOlive,
                      ),
                    ),
                    if (showBismillah)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Image.asset(
                          'assets/images/bismillah.png',
                          width: math.min(260, width * .72),
                          height: 48,
                          fit: BoxFit.contain,
                          color: quranOlive,
                          semanticLabel: AppText.of(context).quranBismillah,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
