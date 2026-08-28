import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

import 'quran_translation_event.dart';
import 'quran_translation_state.dart';

export 'quran_translation_event.dart';
export 'quran_translation_state.dart';

/// Holds the translation language for a surah screen, independent of the app
/// UI language. The surah-wide choice is persisted; per-ayah overrides are not.
class QuranTranslationBloc
    extends Bloc<QuranTranslationEvent, QuranTranslationState> {
  QuranTranslationBloc({QuranLocalStore? store, AppLanguage? initial})
    : _store = store,
      super(QuranTranslationState(surahLang: initial ?? AppLanguage.english)) {
    on<LoadTranslationPreference>(_onLoad);
    on<SetSurahTranslationLang>(_onSetSurah);
    on<SetAyahTranslationLang>(_onSetAyah);
    on<SetFontSizeMultiplier>(_onSetFontSize);
  }

  QuranLocalStore? _store;

  Future<QuranLocalStore> _resolveStore() async =>
      _store ??= await QuranLocalStore.create();

  Future<void> _onLoad(
    LoadTranslationPreference event,
    Emitter<QuranTranslationState> emit,
  ) async {
    final store = await _resolveStore();
    emit(
      state.copyWith(
        surahLang: store.translationLanguage() ?? event.uiFallback,
        fontSizeMultiplier: store.fontSizeMultiplier(),
        ayahOverrides: const {},
        loaded: true,
      ),
    );
  }

  Future<void> _onSetSurah(
    SetSurahTranslationLang event,
    Emitter<QuranTranslationState> emit,
  ) async {
    emit(
      state.copyWith(
        surahLang: event.lang,
        ayahOverrides: const {},
        loaded: true,
      ),
    );
    final store = await _resolveStore();
    await store.setTranslationLanguage(event.lang);
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

  Future<void> _onSetFontSize(
    SetFontSizeMultiplier event,
    Emitter<QuranTranslationState> emit,
  ) async {
    emit(state.copyWith(fontSizeMultiplier: event.multiplier));
    final store = await _resolveStore();
    await store.setFontSizeMultiplier(event.multiplier);
  }
}
