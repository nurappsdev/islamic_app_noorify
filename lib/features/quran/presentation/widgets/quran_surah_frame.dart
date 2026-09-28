import 'package:flutter/material.dart';
import '../../domain/surah_summary.dart';
import 'quran_design.dart';

/// Reuses the two supplied transparent ornaments around live content.
class QuranSurahFrame extends StatelessWidget {
  const QuranSurahFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: child,
      ),
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: 95,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/quran_new_Design/second_surah_component_left.png',
            fit: BoxFit.fill,
          ),
        ),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: 95,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/quran_new_Design/second_surah_ui_component_right.png',
            fit: BoxFit.fill,
          ),
        ),
      ),
    ],
  );
}

class QuranSurahComponent extends StatelessWidget {
  const QuranSurahComponent({
    super.key,
    required this.surah,
    this.onTap,
    this.label,
  });
  final SurahSummary surah;
  final VoidCallback? onTap;
  final String? label;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: QuranSurahFrame(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            if (label != null)
              Text(label!, style: const TextStyle(color: quranInk)),
            Image.asset('assets/images/quran/Quran.png', height: 76),
            const SizedBox(height: 8),
            Text(
              surah.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, color: quranOlive),
            ),
            Text(
              surah.nameArabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Noorehuda', fontSize: 25),
            ),
            Text(
              '${surah.number} · ${surah.totalAyah} ayahs',
              style: const TextStyle(color: quranInk),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A reading frame keeps ornaments at their natural aspect ratio even when
/// Tafsir content is much taller than a Surah title card.
class QuranTextFrame extends StatelessWidget {
  const QuranTextFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: child,
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/quran/header.png',
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/quran/footer.png',
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    ],
  );
}
