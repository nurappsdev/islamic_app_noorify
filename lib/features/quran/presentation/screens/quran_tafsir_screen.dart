import '../widgets/quran_tafsir_content.dart';
import '../../data/services/quran_reader_service.dart';
import 'package:flutter/material.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/quran_ayah.dart';
import '../../domain/arabic_font.dart';
import '../widgets/quran_design.dart';
import '../widgets/quran_reading_text.dart';
import '../widgets/quran_surah_frame.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

class QuranTafsirScreen extends StatefulWidget {
  const QuranTafsirScreen({
    super.key,
    required this.verseKey,
    required this.isBangla,
    this.ayahs,
    this.player,
    this.service,
    this.readerService,
    this.surahName,
  });
  final String verseKey;
  final String? surahName;
  final bool isBangla;
  final List<QuranAyah>? ayahs;
  final Widget? player;
  final QuranContentService? service;
  final QuranReaderService? readerService;
  @override
  State<QuranTafsirScreen> createState() => _QuranTafsirScreenState();
}

class _QuranTafsirScreenState extends State<QuranTafsirScreen> {
  late Future<List<QuranAyah>> _future = _load();
  Future<List<QuranAyah>> _load() async {
    if (widget.ayahs != null) return widget.ayahs!;
    final parts = widget.verseKey.split(':').map(int.parse).toList();
    return [
      await (widget.service ?? QuranContentService.shared).loadAyah(
        parts[0],
        parts[1],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.pageColor(Colors.white),
    appBar: AppBar(
      title: Text(
        context.localizedDigits(
          AppText.of(context).quranTafsirVerse.fill({'key': widget.verseKey}),
        ),
      ),
      actions: [
        IconButton(
          tooltip: AppText.of(context).quranCloseTafsir,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<List<QuranAyah>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return QuranRetry(onRetry: () => setState(() => _future = _load()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ayahs = snapshot.requireData;
          if (ayahs.isEmpty) {
            return Center(child: Text(AppText.of(context).quranNoAyahs));
          }
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Text(
                context.localizedDigits(
                  AppText.of(context).quranSurahPage.fill({
                    'name': widget.surahName ?? ayahs.first.surahNumber,
                    'page': ayahs.first.pageNumber,
                  }),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              QuranTextFrame(
                child: QuranReadingText(
                  ayahs: ayahs,
                  active: int.parse(widget.verseKey.split(':').last),
                  scale: 1,
                  font: arabicFontById('noorehuda'),
                ),
              ),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 16,
                  ),
                  label: Text(AppText.of(context).quranCloseTafsir),
                ),
              ),
              if (widget.player != null) widget.player!,
              QuranTafsirContent(
                ayahs: ayahs,
                isBangla: widget.isBangla,
                readerService: widget.readerService,
              ),
            ],
          );
        },
      ),
    ),
  );
}
