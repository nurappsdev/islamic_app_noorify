import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/quran_reader_service.dart';
import '../../domain/quran_ayah.dart';
import '../bloc/tafsir/tafsir_bloc.dart';
import 'quran_design.dart';
import 'quran_surah_frame.dart';

/// Embedded Tafsir content. Scrolling is owned by its host reader; no routes
/// or additional audio players are created when this section opens.
class QuranTafsirContent extends StatefulWidget {
  const QuranTafsirContent({
    super.key,
    required this.ayahs,
    required this.isBangla,
    this.readerService,
    this.onClose,
  });
  final List<QuranAyah> ayahs;
  final bool isBangla;
  final QuranReaderService? readerService;
  final VoidCallback? onClose;
  @override
  State<QuranTafsirContent> createState() => _QuranTafsirContentState();
}

class _QuranTafsirContentState extends State<QuranTafsirContent> {
  late bool _bangla = widget.isBangla;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Tafsir',
                  style: TextStyle(fontSize: 20, color: quranInk),
                ),
              ),
            ),
            if (widget.onClose != null)
              IconButton(
                tooltip: 'Close tafsir',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Bangla'),
              selected: _bangla,
              selectedColor: quranBorder,
              onSelected: (_) => setState(() => _bangla = true),
            ),
            ChoiceChip(
              label: const Text('English'),
              selected: !_bangla,
              selectedColor: quranBorder,
              onSelected: (_) => setState(() => _bangla = false),
            ),
          ],
        ),
        if (widget.ayahs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No ayahs available'),
          ),
        if (widget.ayahs.isNotEmpty)
          QuranTextFrame(
            child: Column(
              children: [
                for (final ayah in widget.ayahs)
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
                                  onRetry: () => context.read<TafsirBloc>().add(
                                    LoadTafsir(ayah.verseKey),
                                  ),
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
    ),
  );
}
