import '../../data/services/quran_reader_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/quran_ayah.dart';
import '../../domain/arabic_font.dart';
import '../bloc/tafsir/tafsir_bloc.dart';
import '../widgets/quran_design.dart';
import '../widgets/quran_reading_text.dart';
import '../widgets/quran_surah_frame.dart';

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
  late bool _bangla = widget.isBangla;
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
      title: Text('Tafsir · ${widget.verseKey}'),
      actions: [
        IconButton(
          tooltip: 'Close tafsir',
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
            return const Center(child: Text('No ayahs available'));
          }
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Text(
                'Surah: ${widget.surahName ?? ayahs.first.surahNumber} · Page ${ayahs.first.pageNumber}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              QuranTextFrame(
                child: QuranReadingText(
                  ayahs: ayahs,
                  active: int.parse(widget.verseKey.split(':').last),
                  scale: 1,
                  font: arabicFontById('noorehuda'),
                  onTap: (_) {},
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
                  label: const Text('Close tafsir'),
                ),
              ),
              if (widget.player != null) widget.player!,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Bangla'),
                    selected: _bangla,
                    selectedColor: quranBorder,
                    onSelected: (_) => setState(() => _bangla = true),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('English'),
                    selected: !_bangla,
                    selectedColor: quranBorder,
                    onSelected: (_) => setState(() => _bangla = false),
                  ),
                ],
              ),
              // Each bloc uses the existing Tafsir service and owns one verse. The
              // requested range is only the currently displayed Quran page.
              QuranTextFrame(
                child: Column(
                  children: [
                    for (final ayah in ayahs)
                      BlocProvider(
                        key: ValueKey('${ayah.verseKey}:$_bangla'),
                        create: (_) => TafsirBloc(
                          readerService: widget.readerService,
                          tafsirResourceId: _bangla
                              ? banglaTafsirResourceId
                              : englishTafsirResourceId,
                        )..add(LoadTafsir(ayah.verseKey)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Quran ${ayah.verseKey}',
                                style: const TextStyle(color: quranInk),
                              ),
                              const SizedBox(height: 8),
                              BlocBuilder<TafsirBloc, TafsirState>(
                                builder: (context, state) {
                                  if (state.isLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (state.hasError) {
                                    return QuranRetry(
                                      onRetry: () => context
                                          .read<TafsirBloc>()
                                          .add(LoadTafsir(ayah.verseKey)),
                                    );
                                  }
                                  return SelectableText(
                                    state.text.isEmpty
                                        ? 'No Tafsir available for this ayah'
                                        : state.text,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.65,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
