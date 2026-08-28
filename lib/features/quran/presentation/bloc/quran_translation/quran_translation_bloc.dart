import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_offline_database.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_offline_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_translation_downloader.dart';
import 'package:islami_app_noorify/features/quran/domain/translation_edition.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

import 'quran_translation_event.dart';
import 'quran_translation_state.dart';

export 'quran_translation_event.dart';
export 'quran_translation_state.dart';

/// Holds every reader-display preference for a surah screen: translation
/// language / edition, the two font zooms, and the Arabic / translation
/// visibility toggles. Surah-wide choices are persisted; per-ayah overrides
/// are not.
class QuranTranslationBloc
    extends Bloc<QuranTranslationEvent, QuranTranslationState> {
  QuranTranslationBloc({
    QuranLocalStore? store,
    QuranOfflineDatabase? database,
    QuranOfflineService? offlineService,
    QuranReaderService? readerService,
    QuranTranslationDownloader? downloader,
    AppLanguage? initial,
  }) : _store = store,
       _db = database ?? QuranOfflineDatabase(),
       _offlineService = offlineService ?? QuranOfflineService(),
       _reader = readerService ?? QuranComReaderService(),
       _downloader = downloader ?? QuranTranslationDownloader(),
       super(QuranTranslationState(surahLang: initial ?? AppLanguage.english)) {
    on<LoadTranslationPreference>(_onLoad);
    on<SetSurahTranslationLang>(_onSetSurah);
    on<SetAyahTranslationLang>(_onSetAyah);
    on<SetArabicFontScale>(_onSetArabicFontScale);
    on<SetTranslationFontScale>(_onSetTranslationFontScale);
    on<SetShowArabic>(_onSetShowArabic);
    on<SetShowTranslation>(_onSetShowTranslation);
    on<LoadTranslationEditions>(_onLoadEditions);
    on<SelectTranslationEdition>(_onSelectEdition);
    on<DownloadTranslationEdition>(_onDownloadEdition);
    on<DeleteTranslationEdition>(_onDeleteEdition);
    on<LoadSurahEditionText>(_onLoadSurahEditionText);
  }

  QuranLocalStore? _store;
  final QuranOfflineDatabase _db;
  final QuranOfflineService _offlineService;
  final QuranReaderService _reader;
  final QuranTranslationDownloader _downloader;

  int? _currentSurahNo;

  Future<QuranLocalStore> _resolveStore() async =>
      _store ??= await QuranLocalStore.create();

  Future<void> _onLoad(
    LoadTranslationPreference event,
    Emitter<QuranTranslationState> emit,
  ) async {
    final store = await _resolveStore();
    Set<String> downloaded;
    try {
      downloaded = await _db.downloadedEditionIds();
    } catch (_) {
      downloaded = const {};
    }
    final lang = store.translationLanguage() ?? event.uiFallback;
    var editionId = store.selectedTranslationEditionId();
    // A custom edition that is no longer on the device falls back to English.
    if (!isBuiltInEditionId(editionId) && !downloaded.contains(editionId)) {
      editionId = kBuiltInEnglishId;
    }
    // Keep the built-in edition in step with the persisted pill language.
    if (isBuiltInEditionId(editionId)) {
      editionId = lang == AppLanguage.bangla
          ? kBuiltInBengaliId
          : kBuiltInEnglishId;
    }
    emit(
      state.copyWith(
        surahLang: lang,
        arabicFontScale: store.arabicFontScale(),
        translationFontScale: store.translationFontScale(),
        showArabic: store.showArabic(),
        showTranslation: store.showTranslation(),
        selectedEditionId: editionId,
        downloadedEditionIds: downloaded,
        ayahOverrides: const {},
        loaded: true,
      ),
    );
  }

  Future<void> _onSetSurah(
    SetSurahTranslationLang event,
    Emitter<QuranTranslationState> emit,
  ) async {
    final id = event.lang == AppLanguage.bangla
        ? kBuiltInBengaliId
        : kBuiltInEnglishId;
    emit(
      state.copyWith(
        surahLang: event.lang,
        selectedEditionId: id,
        surahEditionText: const {},
        ayahOverrides: const {},
        loaded: true,
      ),
    );
    final store = await _resolveStore();
    await store.setTranslationLanguage(event.lang);
    await store.setSelectedTranslationEditionId(id);
  }

  void _onSetAyah(
    SetAyahTranslationLang event,
    Emitter<QuranTranslationState> emit,
  ) {
    final overrides = Map<int, AppLanguage>.from(state.ayahOverrides)
      ..remove(event.ayahNo);
    if (event.lang != state.surahLang) {
      overrides[event.ayahNo] = event.lang;
    }
    emit(state.copyWith(ayahOverrides: overrides));
  }

  Future<void> _onSetArabicFontScale(
    SetArabicFontScale event,
    Emitter<QuranTranslationState> emit,
  ) async {
    emit(state.copyWith(arabicFontScale: event.value));
    await (await _resolveStore()).setArabicFontScale(event.value);
  }

  Future<void> _onSetTranslationFontScale(
    SetTranslationFontScale event,
    Emitter<QuranTranslationState> emit,
  ) async {
    emit(state.copyWith(translationFontScale: event.value));
    await (await _resolveStore()).setTranslationFontScale(event.value);
  }

  Future<void> _onSetShowArabic(
    SetShowArabic event,
    Emitter<QuranTranslationState> emit,
  ) async {
    // Keep at least one of Arabic / translation visible.
    final resolved = !event.value && !state.showTranslation
        ? true
        : event.value;
    emit(state.copyWith(showArabic: resolved));
    await (await _resolveStore()).setShowArabic(resolved);
  }

  Future<void> _onSetShowTranslation(
    SetShowTranslation event,
    Emitter<QuranTranslationState> emit,
  ) async {
    final resolved = !event.value && !state.showArabic ? true : event.value;
    emit(state.copyWith(showTranslation: resolved));
    await (await _resolveStore()).setShowTranslation(resolved);
  }

  Future<void> _onLoadEditions(
    LoadTranslationEditions event,
    Emitter<QuranTranslationState> emit,
  ) async {
    try {
      emit(
        state.copyWith(downloadedEditionIds: await _db.downloadedEditionIds()),
      );
    } catch (_) {
      // keep whatever we have
    }
  }

  Future<void> _onSelectEdition(
    SelectTranslationEdition event,
    Emitter<QuranTranslationState> emit,
  ) async {
    final id = event.editionId;
    final store = await _resolveStore();
    await store.setSelectedTranslationEditionId(id);

    if (id == kBuiltInEnglishId || id == kBuiltInBengaliId) {
      final lang = id == kBuiltInBengaliId
          ? AppLanguage.bangla
          : AppLanguage.english;
      await store.setTranslationLanguage(lang);
      emit(
        state.copyWith(
          selectedEditionId: id,
          surahLang: lang,
          surahEditionText: const {},
          ayahOverrides: const {},
        ),
      );
      return;
    }

    emit(state.copyWith(selectedEditionId: id, surahEditionText: const {}));
    final surahNo = _currentSurahNo;
    if (surahNo != null) add(LoadSurahEditionText(surahNo));
  }

  Future<void> _onDownloadEdition(
    DownloadTranslationEdition event,
    Emitter<QuranTranslationState> emit,
  ) async {
    final edition = event.edition;
    if (state.editionDownload?.editionId == edition.id &&
        !(state.editionDownload?.failed ?? true)) {
      return;
    }
    emit(
      state.copyWith(
        editionDownload: EditionDownloadProgress(editionId: edition.id),
      ),
    );
    try {
      await emit.forEach<QuranSetupProgress>(
        _downloader.downloadEdition(edition),
        onData: (progress) => state.copyWith(
          editionDownload: EditionDownloadProgress(
            editionId: edition.id,
            done: progress.done,
            total: progress.total,
          ),
        ),
      );
      emit(
        state.copyWith(
          clearEditionDownload: true,
          downloadedEditionIds: {...state.downloadedEditionIds, edition.id},
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          editionDownload: EditionDownloadProgress(
            editionId: edition.id,
            done: state.editionDownload?.done ?? 0,
            total: state.editionDownload?.total ?? 0,
            failed: true,
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteEdition(
    DeleteTranslationEdition event,
    Emitter<QuranTranslationState> emit,
  ) async {
    await _db.deleteEdition(event.editionId);
    final remaining = {...state.downloadedEditionIds}..remove(event.editionId);
    final wasSelected = state.selectedEditionId == event.editionId;
    emit(
      state.copyWith(
        downloadedEditionIds: remaining,
        selectedEditionId: wasSelected ? kBuiltInEnglishId : null,
        surahLang: wasSelected ? AppLanguage.english : null,
        surahEditionText: wasSelected ? const {} : null,
      ),
    );
    if (wasSelected) {
      final store = await _resolveStore();
      await store.setSelectedTranslationEditionId(kBuiltInEnglishId);
    }
  }

  Future<void> _onLoadSurahEditionText(
    LoadSurahEditionText event,
    Emitter<QuranTranslationState> emit,
  ) async {
    _currentSurahNo = event.surahNo;
    final id = state.selectedEditionId;
    if (isBuiltInEditionId(id)) {
      emit(
        state.copyWith(
          surahEditionText: const {},
          editionTextSurahNo: event.surahNo,
        ),
      );
      return;
    }
    final edition = translationEditionById(id);
    if (edition?.resourceId == null) {
      emit(state.copyWith(surahEditionText: const {}));
      return;
    }

    var text = await _offlineService.editionSurahText(id, event.surahNo);
    if (text.isEmpty) {
      try {
        text = await _reader.loadChapterTranslation(
          edition!.resourceId!,
          event.surahNo,
        );
        if (text.isNotEmpty) {
          await _db.upsertEditionSurahText(id, event.surahNo, text);
        }
      } catch (_) {
        text = {};
      }
    }
    emit(
      state.copyWith(surahEditionText: text, editionTextSurahNo: event.surahNo),
    );
  }
}
