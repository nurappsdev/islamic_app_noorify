import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/surah_summary.dart';
import 'quran_design.dart';

/// Live Surah metadata. The ornament is owned by the screen background.
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
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: patternHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            width * .12,
            width * .61,
            width * .12,
            16,
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
                  '${surah.revelationPlace.toUpperCase()} • ${surah.totalAyah} AYAT',
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
                      semanticLabel: 'Bismillah',
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Full-bleed ornament behind safe-area content, outside the reader flex flow.
class QuranSurahBackdrop extends StatelessWidget {
  const QuranSurahBackdrop({
    super.key,
    required this.visible,
    required this.child,
  });
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (visible)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/quran/starting_sura_pattern.png',
              key: const ValueKey('surah-background-pattern'),
              width: double.infinity,
              height: MediaQuery.sizeOf(context).width * 380 / 402,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
            ),
          ),
        ),
      SafeArea(child: child),
    ],
  );
}
