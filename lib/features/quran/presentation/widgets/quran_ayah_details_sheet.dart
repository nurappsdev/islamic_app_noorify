import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/quran_ayah.dart';
import '../bloc/ayah_audio/ayah_audio_bloc.dart';
import '../bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import '../bloc/reciter/reciter_bloc.dart';
import '../bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'quran_design.dart';
import 'quran_sheets.dart';

class QuranAyahDetails extends StatefulWidget {
  const QuranAyahDetails({
    super.key,
    required this.surah,
    required this.ayah,
    required this.translation,
    required this.totalAyah,
  });
  final int surah, ayah, translation, totalAyah;
  @override
  State<QuranAyahDetails> createState() => _QuranAyahDetailsState();
}

class _QuranAyahDetailsState extends State<QuranAyahDetails> {
  late Future<QuranAyah> _future = _load();
  Future<QuranAyah> _load() => QuranContentService.shared.loadAyah(
    widget.surah,
    widget.ayah,
    translation: widget.translation,
  );
  Future<void> _download(BuildContext context, String verseKey) async {
    final reciter =
        context.read<ReciterBloc>().state.selectedId ?? defaultRecitationId;
    final saved = await showSurahAudioSheet(
      context,
      downloadBloc: context.read<SurahAudioDownloadBloc>(),
      reciterId: reciter,
      surahNo: widget.surah,
      totalAyah: widget.totalAyah,
    );
    if (saved && context.mounted) {
      context.read<AyahAudioBloc>().add(
        PlayAyahAudio(verseKey: verseKey, recitationId: reciter, restart: true),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<AyahAudioBloc, AyahAudioState>(
    listenWhen: (p, c) =>
        c.needsDownloadForVerseKey != null &&
        p.needsDownloadForVerseKey != c.needsDownloadForVerseKey,
    listener: (context, state) =>
        _download(context, state.needsDownloadForVerseKey!),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<QuranAyah>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return QuranRetry(
                onRetry: () => setState(() => _future = _load()),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final a = snapshot.requireData;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${a.verseKey} · Para ${a.paraNumber} · Page ${a.pageNumber}',
                    style: const TextStyle(color: quranInk),
                  ),
                  Row(
                    children: [
                      BlocBuilder<AyahAudioBloc, AyahAudioState>(
                        builder: (context, state) => IconButton(
                          tooltip: 'Play ayah',
                          onPressed: () => context.read<AyahAudioBloc>().add(
                            PlayAyahAudio(
                              verseKey: a.verseKey,
                              recitationId:
                                  context
                                      .read<ReciterBloc>()
                                      .state
                                      .selectedId ??
                                  defaultRecitationId,
                            ),
                          ),
                          icon: Icon(
                            state.playingVerseKey == a.verseKey
                                ? Icons.stop
                                : Icons.play_arrow,
                          ),
                        ),
                      ),
                      BlocBuilder<AyahAudioBloc, AyahAudioState>(
                        builder: (context, state) => TextButton.icon(
                          onPressed: () => context.read<AyahAudioBloc>().add(
                            SetAyahRepeatCount(
                              a.verseKey,
                              state.repeatCountFor(a.verseKey) == 3
                                  ? 1
                                  : state.repeatCountFor(a.verseKey) + 1,
                            ),
                          ),
                          icon: const Icon(Icons.repeat),
                          label: Text('${state.repeatCountFor(a.verseKey)}'),
                        ),
                      ),
                      BlocBuilder<AyahBookmarkBloc, AyahBookmarkState>(
                        builder: (context, state) => IconButton(
                          tooltip: 'Bookmark ayah',
                          onPressed: () => context.read<AyahBookmarkBloc>().add(
                            const ToggleAyahBookmark(),
                          ),
                          icon: Icon(
                            state.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    a.textArabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Noorehuda',
                      fontSize: 28,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    a.translations[widget.translation]?.text ??
                        'Translation unavailable for this ayah',
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  if (a.sajdahNumber != null) Text('Sajdah ${a.sajdahNumber}'),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
