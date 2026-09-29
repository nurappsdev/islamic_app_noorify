import 'quran_reading_text.dart';
import '../../domain/arabic_font.dart';
import 'quran_share.dart';
import 'quran_modal.dart';
import '../../domain/translation_edition.dart';
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
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

class QuranAyahDetails extends StatefulWidget {
  const QuranAyahDetails({
    super.key,
    required this.surah,
    required this.ayah,
    required this.translation,
    required this.totalAyah,
    this.service,
    this.surahName = '',
    this.onTranslationSelected,
    this.onTafsir,
  });
  final int surah, ayah, translation, totalAyah;
  final QuranContentService? service;
  final String surahName;
  final ValueChanged<int>? onTranslationSelected;
  final ValueChanged<bool>? onTafsir;
  @override
  State<QuranAyahDetails> createState() => _QuranAyahDetailsState();
}

class _QuranAyahDetailsState extends State<QuranAyahDetails> {
  late final _api = widget.service ?? QuranContentService.shared;
  late int _translation = widget.translation;
  late Future<List<TranslationEdition>> _editions = _api.loadTranslations();
  late Future<QuranAyah> _future = _load();
  void _select(int resource) {
    if (_translation == resource) return;
    setState(() {
      _translation = resource;
      _future = _load();
    });
    widget.onTranslationSelected?.call(resource);
  }

  Future<QuranAyah> _load() =>
      _api.loadAyah(widget.surah, widget.ayah, translation: _translation);
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                  QuranSheetHeading(AppText.of(context).quranTranslateHeading),
                  Text(
                    context.localizedDigits(
                      AppText.of(context).quranVerseInfo.fill({
                        'key': a.verseKey,
                        'para': a.paraNumber,
                        'page': a.pageNumber,
                      }),
                    ),
                    style: const TextStyle(color: quranInk),
                  ),
                  const SizedBox(height: 16),
                  QuranReadingText(
                    ayahs: [a],
                    active: 0,
                    scale: 1.2,
                    font: arabicFontById('noorehuda'),
                    ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<TranslationEdition>>(
                    future: _editions,
                    builder: (context, catalog) => Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppText.of(context).quranSelectTranslateLanguage,
                          style: TextStyle(color: quranInk),
                        ),
                        if (catalog.hasError)
                          TextButton(
                            onPressed: () => setState(
                              () => _editions = _api.loadTranslations(),
                            ),
                            child: Text(
                              AppText.of(context).quranRetryLanguages,
                            ),
                          ),
                        if (catalog.connectionState == ConnectionState.waiting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        for (final language in [
                          (161, 'Bangla'),
                          (20, 'English'),
                        ])
                          ChoiceChip(
                            label: Text(language.$2),
                            selected: _translation == language.$1,
                            selectedColor: quranBorder,
                            onSelected:
                                catalog.data?.any(
                                      (e) => e.resourceId == language.$1,
                                    ) ==
                                    true
                                ? (_) => _select(language.$1)
                                : null,
                          ),
                        if (catalog.hasData && catalog.requireData.isEmpty)
                          Text(AppText.of(context).quranNoTranslations),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    a.translations[_translation]?.text ??
                        AppText.of(context).quranTranslationUnavailable,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: () => shareQuranAyah(
                          context,
                          a,
                          translation: _translation,
                          surahName: widget.surahName,
                          copy: true,
                        ),
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(AppText.of(context).quranCopy),
                      ),
                      TextButton.icon(
                        onPressed: () => shareQuranAyah(
                          context,
                          a,
                          translation: _translation,
                          surahName: widget.surahName,
                        ),
                        icon: const Icon(Icons.share_outlined),
                        label: Text(AppText.of(context).quranShare),
                      ),
                      TextButton.icon(
                        onPressed: widget.onTafsir != null
                            ? () => widget.onTafsir!(_translation == 161)
                            : () => openTafsirSheet(
                                context,
                                a.verseKey,
                                _translation == 161,
                              ),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(AppText.of(context).tafsirTitle),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      BlocBuilder<AyahAudioBloc, AyahAudioState>(
                        builder: (context, state) => IconButton(
                          tooltip: AppText.of(context).quranPlayAyah,
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
                          label: Text(
                            context.localizedDigits(
                              '${state.repeatCountFor(a.verseKey)}',
                            ),
                          ),
                        ),
                      ),
                      BlocBuilder<AyahBookmarkBloc, AyahBookmarkState>(
                        builder: (context, state) => IconButton(
                          tooltip: AppText.of(context).quranBookmarkAyah,
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
                  if (a.sajdahNumber != null)
                    Text(
                      context.localizedDigits(
                        AppText.of(
                          context,
                        ).quranSajdah.fill({'n': a.sajdahNumber}),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
